pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../core"

/**
 * Real Bluetooth status service using Quickshell.Bluetooth.
 * Exposes: available, enabled, connected, device count, and device lists.
 */
Singleton {
    id: root

    // ENFORCEMENT: On startup, make reality match the user's last preference
    function enforcePreference() {
        if (Config.ready && Config.options.system && Bluetooth.defaultAdapter) {
            const shouldBeEnabled = Config.options.system.bluetoothEnabled;
            if (Bluetooth.defaultAdapter.enabled !== shouldBeEnabled) {

                if (!shouldBeEnabled) {
                    Bluetooth.devices.values.forEach(d => {
                        if (d.connected) d.disconnect();
                    });
                }
                Bluetooth.defaultAdapter.enabled = shouldBeEnabled;
            }
        }
    }

    // Enforce preference on startup and when adapter re-initializes (e.g. after sleep)
    Connections {
        target: Config
        function onReadyChanged() { root.enforcePreference(); }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() {
            Qt.callLater(() => root.enforcePreference());
        }
    }

    // Catch kernel/hardware resetting the enabled state (e.g. after sleep/wake)
    Connections {
        target: Bluetooth.defaultAdapter
        function onEnabledChanged() {
            if (!Config.ready || !Config.options.system) return;
            if (Bluetooth.defaultAdapter.enabled === Config.options.system.bluetoothEnabled) return;
            Bluetooth.defaultAdapter.enabled = Config.options.system.bluetoothEnabled;
        }
    }

    signal deviceConnected(var device)
    property string pairingAddress: ""
    property var lastPairingDevice: null
    readonly property var pairingDevice: Bluetooth.devices.values.find(d => d.address === pairingAddress) || null
    
    onPairingAddressChanged: if (pairingAddress === "") lastPairingDevice = null;

    onPairingDeviceChanged: {
        if (pairingDevice) {
            lastPairingDevice = pairingDevice;
            setupPairingListeners(pairingDevice);
        }
    }

    function setupPairingListeners(device) {
        // Disconnect any existing listeners on the safetyTimer device
        if (safetyTimer.device && safetyTimer.device !== device) {
            try {
                if (safetyTimer.onPaired) safetyTimer.device.pairedChanged.disconnect(safetyTimer.onPaired);
                if (safetyTimer.onConnected) safetyTimer.device.connectedChanged.disconnect(safetyTimer.onConnected);
                if (safetyTimer.onBattery) safetyTimer.device.batteryAvailableChanged.disconnect(safetyTimer.onBattery);
            } catch(e) {}
        }

        const onBatteryChanged = () => {
            if (device.batteryAvailable && device.connected) {

                root.finishPairing();
            }
        };

        const onConnectedChanged = () => {
            if (device.connected) {
                device.trusted = true;
                device.batteryAvailableChanged.connect(onBatteryChanged);
                stabilityTimer.restart();
                if (device.batteryAvailable) onBatteryChanged();
            } else {
                stabilityTimer.stop();
                try { device.batteryAvailableChanged.disconnect(onBatteryChanged); } catch(e) {}
            }
        };

        const onPairedChanged = () => {
            if (device.paired) {
                device.trusted = true;
                settleTimer.start();
            }
        };

        device.pairedChanged.connect(onPairedChanged);
        device.connectedChanged.connect(onConnectedChanged);

        safetyTimer.device = device;
        safetyTimer.onPaired = onPairedChanged;
        safetyTimer.onConnected = onConnectedChanged;
        safetyTimer.onBattery = onBatteryChanged;

        // If it's already in a state, trigger the logic
        if (device.connected) onConnectedChanged();
        else if (device.paired) onPairedChanged();
    }

    Timer {
        id: safetyTimer
        interval: 20000 // Increased for retries
        repeat: false
        property var device: null
        property var onPaired: null
        property var onConnected: null
        property var onBattery: null
        
        onTriggered: cleanup()
        
        function cleanup() {
            if (device) {
                if (onPaired) device.pairedChanged.disconnect(onPaired);
                if (onConnected) device.connectedChanged.disconnect(onConnected);
                if (onBattery) device.batteryAvailableChanged.disconnect(onBattery);
            }
            settleTimer.stop();
            retryTimer.stop();
            stabilityTimer.stop();
            root.pairingAddress = "";
            device = null;
            onPaired = null;
            onConnected = null;
            onBattery = null;
        }
    }

    property int retryCount: 0
    Timer {
        id: settleTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (safetyTimer.device) {
                root.retryCount = 0;
                safetyTimer.device.connect();
                retryTimer.start();
            }
        }
    }

    Timer {
        id: retryTimer
        interval: 3500
        repeat: true
        onTriggered: {
            const dev = safetyTimer.device;
            if (!dev) { stop(); return; }
            
            // If connected, we wait for stability. If NOT connected, we retry.
            if (dev.connected) return; 
            
            if (root.retryCount < 6) { // Increased retries for TWS
                root.retryCount++;

                dev.connect();
            } else {

                stop();
                safetyTimer.cleanup();
            }
        }
    }

    Timer {
        id: stabilityTimer
        interval: 10000 // 10s stability check for TWS
        repeat: false
        onTriggered: {

            BluetoothStatus.finishPairing();
        }
    }

    function finishPairing() {
        const device = safetyTimer.device;
        if (device) root.deviceConnected(device);
        safetyTimer.cleanup();
    }

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ?? false
    readonly property bool connected: {
        let isConnected = false;
        Bluetooth.devices.values.forEach(d => { if (d.connected) isConnected = true; });
        return isConnected;
    }
    readonly property int activeDeviceCount: Bluetooth.devices.values.filter(d => d.connected).length

    // Control
    function enable(enabled = true) {
        if (Config.ready && Config.options.system) {
            Config.options.system.bluetoothEnabled = enabled;
        }

        if (Bluetooth.defaultAdapter) {
            if (!enabled) {
                // Gracefully disconnect connected devices before powering off
                Bluetooth.devices.values.forEach(d => {
                    if (d.connected) d.disconnect();
                });
            }
            Bluetooth.defaultAdapter.enabled = enabled;
        }
    }

    function toggle() {
        enable(!enabled);
    }

    function startDiscovery() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.discovering = true;
        }
    }

    function stopDiscovery() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.discovering = false;
        }
    }

    function pairAndTrust(device) {
        if (!device) return;
        pairingAddress = device.address;
        
        // setupPairingListeners will be triggered by onPairingDeviceChanged
        
        safetyTimer.start();

        if (device.paired) {
            device.trusted = true;
            settleTimer.start();
        } else {
            device.pair();
        }
    }

    // ── Per-profile control (BlueZ) ─────────────────────────────
    // Quickshell does not expose the profile UUID list, so we probe devices
    // with bluetoothctl (a guaranteed dependency) and drive single profiles
    // with busctl against org.bluez.Device1. If probing fails the UI simply
    // hides the per-profile toggles.
    readonly property string audioSinkUuid: "0000110b-0000-1000-8000-00805f9b34fb"
    readonly property string audioSourceUuid: "0000110a-0000-1000-8000-00805f9b34fb"
    readonly property string handsfreeUuid: "0000111e-0000-1000-8000-00805f9b34fb"
    readonly property string headsetUuid: "00001108-0000-1000-8000-00805f9b34fb"
    readonly property string phonebookUuid: "0000112f-0000-1000-8000-00805f9b34fb"

    // address -> [uuid, ...] probed from bluetoothctl info
    property var deviceUuids: ({})

    function fetchDeviceUuids(device) {
        if (!device || !device.address) return;
        uuidProbeProc.targetAddress = device.address;
        uuidProbeProc.exec(["bluetoothctl", "info", device.address]);
    }

    Process {
        id: uuidProbeProc
        property string targetAddress: ""
        stdout: StdioCollector {
            onStreamFinished: {
                const uuids = [];
                const re = /([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})/g;
                let m;
                while ((m = re.exec(text)) !== null) uuids.push(m[1].toLowerCase());
                if (uuidProbeProc.targetAddress === "") return;
                const next = Object.assign({}, root.deviceUuids);
                next[uuidProbeProc.targetAddress] = uuids;
                root.deviceUuids = next;
            }
        }
    }

    // Pick the concrete UUID to (dis)connect for a capability.
    function a2dpUuidFor(uuids) {
        if (!uuids) return "";
        if (uuids.includes(audioSinkUuid)) return audioSinkUuid;
        if (uuids.includes(audioSourceUuid)) return audioSourceUuid;
        return "";
    }
    function hfpUuidFor(uuids) {
        if (!uuids) return "";
        if (uuids.includes(handsfreeUuid)) return handsfreeUuid;
        if (uuids.includes(headsetUuid)) return headsetUuid;
        return "";
    }
    function hasPhonebook(uuids) {
        return !!uuids && uuids.includes(phonebookUuid);
    }

    // Optimistic per-profile state: connecting a device brings every
    // supported profile up, so the default is "on"; overrides are dropped
    // again when the device disconnects.
    property var profileOverrides: ({})
    function profileEnabled(address, key) {
        const o = profileOverrides[address];
        return (o && o[key] !== undefined) ? o[key] : true;
    }
    function setProfileEnabled(address, key, value) {
        const next = Object.assign({}, profileOverrides);
        next[address] = Object.assign({}, next[address] || {}, { [key]: value });
        profileOverrides = next;
    }

    // Connect/disconnect a single profile (A2DP audio, HFP calls, PBAP contacts).
    function connectProfile(device, uuid) {
        if (!device || !uuid || !device.dbusPath) return;
        profileProc.exec(["busctl", "call", "org.bluez", device.dbusPath, "org.bluez.Device1", "ConnectProfile", "s", uuid]);
    }
    function disconnectProfile(device, uuid) {
        if (!device || !uuid || !device.dbusPath) return;
        profileProc.exec(["busctl", "call", "org.bluez", device.dbusPath, "org.bluez.Device1", "DisconnectProfile", "s", uuid]);
    }
    Process { id: profileProc }

    onConnectedDevicesChanged: {
        // Reset optimistic per-profile overrides for devices that are no
        // longer connected, so reconnecting starts with every profile on.
        let next = null;
        for (const addr in profileOverrides) {
            const dev = Bluetooth.devices.values.find(d => d.address === addr);
            if (!dev || !dev.connected) {
                if (next === null) next = Object.assign({}, profileOverrides);
                delete next[addr];
            }
        }
        if (next !== null) profileOverrides = next;
    }

    // Material symbol for a BlueZ device icon / device type string.
    // BlueZ reports the class the peripheral claims ("audio-headset",
    // "input-gaming", ...), which is the same source Android uses, so
    // TWS earbuds show up as headsets and gamepads as gaming devices.
    function deviceIcon(type) {
        if (!type) return "bluetooth";
        switch (String(type)) {
            case "phone": return "smartphone";
            case "computer": return "computer";
            case "audio-headset": return "headset";
            case "audio-headphones": return "headphones";
            case "audio-card": return "speaker";
            case "input-gaming": return "sports_esports";
            case "input-keyboard": return "keyboard";
            case "input-mouse": return "mouse";
            case "input-tablet": return "draw";
            case "camera-video": return "videocam";
            case "camera-photo": return "photo_camera";
            case "multimedia-player": return "music_note";
            case "printer": return "print";
            case "network-wireless": return "router";
            default: return "bluetooth";
        }
    }

    // Resolve the icon for a device object: prefer BlueZ's reported icon
    // string; deviceType only exists on some Quickshell builds.
    function deviceTypeIcon(device) {
        if (!device) return "bluetooth";
        return deviceIcon(device.icon || device.deviceType || "");
    }

    // M3 container pair per device category, so each kind of peripheral gets
    // a distinct tint: audio=primary, gaming=tertiary, phone/PC/input=secondary.
    function deviceColors(type) {
        const audioPair = { container: Appearance.colors.colPrimaryContainer, on: Appearance.colors.colOnPrimaryContainer };
        if (!type) return audioPair;
        const t = String(type);
        if (t === "input-gaming")
            return { container: Appearance.colors.colTertiaryContainer, on: Appearance.colors.colOnTertiaryContainer };
        if (t.startsWith("input") || t === "phone" || t === "computer")
            return { container: Appearance.colors.colSecondaryContainer, on: Appearance.colors.colOnSecondaryContainer };
        return audioPair;
    }

    function deviceTypeColors(device) {
        if (!device) return { container: Appearance.colors.colPrimaryContainer, on: Appearance.colors.colOnPrimaryContainer };
        return deviceColors(device.icon || device.deviceType || "");
    }

    function sortFunction(a, b) {
        // Ones with meaningful names before MAC addresses
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        // Alphabetical by name
        return a.name.localeCompare(b.name);
    }

    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    readonly property var pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => (d.paired || d.trusted) && !d.connected).sort(sortFunction)
    readonly property var unpairedDevices: {
        let list = Bluetooth.devices.values.filter(d => (!d.paired && !d.trusted && !d.connected) || d.address === pairingAddress);
        if (pairingAddress !== "" && !list.some(d => d.address === pairingAddress) && lastPairingDevice) {
            list.push(lastPairingDevice);
        }
        return list.sort(sortFunction);
    }
    readonly property var friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]

    // Material symbol for status bar
    property string materialSymbol: {
        if (!available || !enabled) return "bluetooth_disabled";
        if (connected) return "bluetooth_connected";
        return "bluetooth";
    }
}
