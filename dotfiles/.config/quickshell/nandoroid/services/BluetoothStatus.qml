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
                // Use internal logic to set state without potentially creating a loop if we add more listeners
                if (!shouldBeEnabled) {
                    Bluetooth.devices.values.forEach(d => {
                        if (d.connected) d.disconnect();
                    });
                }
                Bluetooth.defaultAdapter.enabled = shouldBeEnabled;
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() { root.enforcePreference(); }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { root.enforcePreference(); }
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

    readonly property var connectedDevices: Bluetooth.devices.values.filter(d => d.connected && d.address !== pairingAddress).sort(sortFunction)
    readonly property var pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => (d.paired || d.trusted) && !d.connected && d.address !== pairingAddress).sort(sortFunction)
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
