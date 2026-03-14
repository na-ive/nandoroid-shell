pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "./network"

/**
 * Network service using nmcli.
 */
Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false
    property var wiredConnections: []

    property bool wifiEnabled: false
    onWifiEnabledChanged: if (wifiEnabled) update()
    
    // WARP VPN properties
    property bool warpConnected: false
    property bool warpCLIInstalled: false

    function toggleWarp() {
        if (!warpCLIInstalled) return;
        // Do NOT optimistically set warpConnected here — let warpStatusProc
        // set the real state after the command exits.
        if (warpConnected) {
            warpDisconnectProc.running = true;
        } else {
            warpConnectProc.running = true;
        }
    }

    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    property var wifiNetworks: []
    readonly property var friendlyWifiNetworks: {
        const p = root.savedPriorities;
        return wifiNetworks.slice().sort((a, b) => {
            if (a.active && !b.active) return -1;
            if (!a.active && b.active) return 1;
            if (a.priority !== b.priority) return b.priority - a.priority;
            return b.strength - a.strength;
        });
    }
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength: 0
    property var savedConnections: []
    property string materialSymbol: root.ethernet
        ? "lan"
        : root.wifiEnabled
            ? (
                root.networkStrength > 83 ? "signal_wifi_4_bar" :
                root.networkStrength > 67 ? "network_wifi" :
                root.networkStrength > 50 ? "network_wifi_3_bar" :
                root.networkStrength > 33 ? "network_wifi_2_bar" :
                root.networkStrength > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_off"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true) {
        enableWifiProc.exec(["nmcli", "radio", "wifi", enabled ? "on" : "off"]);
    }

    function toggleWifi() {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi() {
        wifiScanning = true;
        rescanProcess.exec(rescanProcess.command);
    }

    function connectToWifiNetwork(accessPoint) {
        accessPoint.askingPassword = false;
        root.wifiConnectTarget = accessPoint;
        connectProc.exec(["nmcli", "dev", "wifi", "connect", accessPoint.ssid]);
    }

    function disconnectWifiNetwork() {
        if (activeNetwork) disconnectProc.exec(["nmcli", "connection", "down", activeNetwork.ssid]);
    }

    function forgetNetwork(ssidOrName) {
        forgetProc.exec(["sh", "-c", `
            target="$1"
            nmcli connection delete id "$target"
            current_ssid=$(nmcli -t -f ACTIVE,SSID d w | grep '^yes:' | cut -d: -f2)
            if [ "$current_ssid" = "$target" ]; then
                dev=$(nmcli -t -f DEVICE,TYPE d | grep 'wifi' | cut -d: -f1 | head -n1)
                if [ -n "$dev" ]; then
                    nmcli device disconnect "$dev"
                fi
            fi
        `, "sh", ssidOrName]);
    }

    function setAutoConnect(ssid, enabled) {
        autoConnectProc.exec(["nmcli", "connection", "modify", "id", ssid, "connection.autoconnect", enabled ? "yes" : "no"]);
    }

    function setPriority(ssid, priority) {
        // Update locally first for immediate UI response
        let p = Object.assign({}, savedPriorities);
        p[ssid] = priority;
        savedPriorities = p;
        autoConnectProc.exec(["nmcli", "connection", "modify", "id", ssid, "connection.autoconnect-priority", priority.toString()]);
    }

    function connectWithPassword(ssid, password, hidden = false, autoconnect = true) {
        const cmd = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        if (hidden) cmd.push("hidden", "yes");
        // nmcli dev wifi connect doesn't have a direct autoconnect flag, 
        // but we can modify the connection immediately after.
        connectProc.exec(cmd);
        if (!autoconnect) {
            // We'll need a way to target the connection after it's created if we want to disable autoconnect immediately.
            // But usually devs want autoconnect: true.
        }
    }

    function openAdvancedSettings() {
        advancedSettingsProc.start();
    }

    function getSavedPassword(ssid) {
        // Use pkexec to force polkit authentication for viewing sensitive data
        passwordRecoveryProc.exec(["pkexec", "nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", ssid]);
    }

    function toggleWiredConnection(uuid, active) {
        if (active) {
            wiredDownProc.exec(["nmcli", "connection", "down", uuid]);
        } else {
            wiredUpProc.exec(["nmcli", "connection", "up", uuid]);
        }
    }

    Process { id: wiredUpProc; onExited: root.update() }
    Process { id: wiredDownProc; onExited: root.update() }

    property var wiredDetails: ({})
    function fetchWiredDetails(uuid) {
        wiredDetailsProc.exec(["nmcli", "-t", "-f", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,GENERAL.HWADDR", "connection", "show", uuid]);
    }

    Process {
        id: wiredDetailsProc
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const details = {};
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2) {
                        details[parts[0].toLowerCase()] = parts[1];
                    }
                });
                root.wiredDetails = details;
            }
        }
    }

    signal passwordRecovered(string password)

    readonly property WifiAccessPoint activeNetwork: wifiNetworks.find(n => n.active) ?? null

    Process { id: enableWifiProc }

    Process {
        id: connectProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: SplitParser {
            onRead: line => root.update()
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.includes("Secrets were required") && root.wifiConnectTarget) {
                    root.wifiConnectTarget.askingPassword = true;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (root.wifiConnectTarget) {
                root.wifiConnectTarget.askingPassword = (exitCode !== 0 && exitCode !== 10);
            }
            root.wifiConnectTarget = null;
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: line => root.update()
        }
    }

    Process {
        id: forgetProc
        onExited: (exitCode, exitStatus) => root.update()
    }

    Process {
        id: warpStatusProc
        command: ["bash", "-c", "command -v warp-cli >/dev/null 2>&1 && warp-cli status || echo 'MISSING'"]
        stdout: SplitParser {
            onRead: data => {
                const text = data.trim();
                if (text === "MISSING") {
                    root.warpCLIInstalled = false;
                    root.warpConnected = false;
                } else {
                    root.warpCLIInstalled = true;
                    if (data.includes("Connected")) root.warpConnected = true;
                    else if (data.includes("Disconnected")) root.warpConnected = false;
                }
            }
        }
    }

    Process {
        id: warpConnectProc
        command: ["warp-cli", "connect"]
        onExited: {
            // Give warp-cli a moment to fully establish the connection,
            // then read the real status instead of trusting exit code alone.
            warpPollTimer.restart();
        }
    }

    Process {
        id: warpDisconnectProc
        command: ["warp-cli", "disconnect"]
        onExited: {
            warpPollTimer.restart();
        }
    }

    // Poll warp-cli status every 1 second so that manual terminal
    // connections (warp-cli connect / disconnect) are reflected near-instantly.
    Timer {
        id: warpPollTimer
        interval: 1000
        repeat: true
        running: root.warpCLIInstalled  // only poll when warp-cli is present
        triggeredOnStart: true
        onTriggered: {
            if (!warpStatusProc.running)
                warpStatusProc.running = true;
        }
    }

    Process {
        id: autoConnectProc
    }

    Process {
        id: advancedSettingsProc
        command: ["nm-connection-editor"]
    }

    Process {
        id: passwordRecoveryProc
        stdout: StdioCollector {
            onStreamFinished: root.passwordRecovered(text.trim())
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        stdout: SplitParser {
            onRead: {
                wifiScanning = false;
                getNetworks.running = true;
            }
        }
    }

    Timer {
        id: debounceUpdateTimer
        interval: 300
        repeat: false
        onTriggered: {
            wifiStatusProcess.exec(wifiStatusProcess.command);
            updateSavedConnections.exec(updateSavedConnections.command);
            if (!root.wifiEnabled) return;
            updateConnectionType.startCheck();
            updateNetworkName.exec(updateNetworkName.command);
            updateNetworkStrength.exec(updateNetworkStrength.command);
            getNetworks.exec(getNetworks.command);
        }
    }

    // Status update
    function update() {
        debounceUpdateTimer.restart();
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateSavedConnections
        command: ["nmcli", "-t", "-f", "NAME,TYPE,AUTOCONNECT-PRIORITY,UUID,DEVICE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                const names = [];
                const wired = [];
                const priorities = {};
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length >= 2) {
                        const name = parts[0];
                        const type = parts[1];
                        const priority = parts[2] ? parseInt(parts[2]) : 0;
                        const uuid = parts[3];
                        const device = parts[4];

                        if (type === "802-11-wireless") {
                            names.push(name);
                            priorities[name] = priority;
                        } else if (type === "802-3-ethernet") {
                            wired.push({
                                name: name,
                                type: type,
                                priority: priority,
                                uuid: uuid,
                                device: device,
                                active: device !== "" && device !== "--"
                            });
                        }
                    }
                });
                root.savedConnections = names;
                root.savedPriorities = priorities;
                root.wiredConnections = wired;
            }
        }
    }

    property var savedPriorities: ({})

    Component.onCompleted: {
        update()
        // Initial check; warpPollTimer will keep polling afterwards.
        warpStatusProc.running = true
    }

    Process {
        id: updateConnectionType
        property string buffer: ""
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            buffer = "";
            running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = buffer.trim().split('\n');
            const connectivity = lines.pop();
            let hasEthernet = false;
            let hasWifi = false;
            let status = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) status = "disconnected";
                    else if (line.includes("connected")) {
                        hasWifi = true;
                        status = "connected";
                        if (connectivity === "limited") {
                            hasWifi = false;
                            status = "limited";
                        }
                    }
                    else if (line.includes("connecting")) status = "connecting";
                    else if (line.includes("unavailable")) status = "disabled";
                }
            });
            root.wifiStatus = status;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME,TYPE c show --active | awk -F: '$2 != \"loopback\" {print $1; exit}'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: { root.networkName = text.trim(); }
        }
    }

    Process {
        id: updateNetworkStrength
        running: false
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: StdioCollector {
            onStreamFinished: { root.networkStrength = parseInt(text.trim()) || 0; }
        }
    }

    Process {
        id: getNetworks
        running: false
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                const rep = new RegExp("\\\\:", "g");
                const PLACEHOLDER = "___COLON___";
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3] ? net[3].replace(rep2, ":") : "",
                        bssid: net[4] ? net[4].replace(rep2, ":") : "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);


                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing || (network.active && !existing.active) || (!network.active && !existing.active && network.strength > existing.strength)) {
                        networkMap.set(network.ssid, network);
                    }
                }

                const wifiNetworksData = Array.from(networkMap.values());
                const currentNetworks = root.wifiNetworks.slice();

                // Remove networks no longer seen
                for (let i = currentNetworks.length - 1; i >= 0; i--) {
                    const rn = currentNetworks[i];
                    if (!wifiNetworksData.find(n => n.ssid === rn.ssid)) {
                        let removed = currentNetworks.splice(i, 1);
                        removed.forEach(n => Qt.callLater(() => { if(n) n.destroy(); }));
                    }
                }

                // Add or update networks
                for (const network of wifiNetworksData) {
                    const match = currentNetworks.find(n => n.ssid === network.ssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        currentNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
                root.wifiNetworks = currentNetworks;
            }
        }
    }

    Component {
        id: apComp
        WifiAccessPoint {}
    }
}
