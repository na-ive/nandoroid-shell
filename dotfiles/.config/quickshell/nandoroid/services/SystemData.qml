pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Service providing system performance metrics using 'dgop'.
 * Highly accurate CPU, RAM, Swap, and Temperature tracking.
 * Supports multiple disk monitoring via Config settings.
 */
Singleton {
    id: root

    property real cpuUsage: 0
    property real cpuTemperature: 0
    property string cpuModel: ""
    property int cpuThreads: 1
    property int physicalCores: 1
    
    Process {
        id: coreDetectProc
        command: ["bash", "-c", "grep '^cpu cores' /proc/cpuinfo | head -n1 | awk '{print $4}' || echo 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(this.text.trim());
                if (!isNaN(val)) root.physicalCores = val;
            }
        }
    }
    
    property real memUsage: 0
    property real swapUsage: 0
    property real totalMemoryMB: 0
    property real usedMemoryMB: 0
    
    property real networkRxRate: 0
    property real networkTxRate: 0
    readonly property real networkTotalRate: networkRxRate + networkTxRate
    
    property real diskReadRate: 0
    property real diskWriteRate: 0
    readonly property real diskTotalRate: diskReadRate + diskWriteRate
    
    // System stats
    property string loadAverage: ""
    property int processCount: 0
    property int threadCount: 0
    property string uptime: ""
    
    // List of objects: { mount: string, usage: real, total: real, used: real }
    property var diskStats: []
    
    // Processes (Disabled for now to fix SIGSEGV)
    property var allProcesses: []
    
    // GPUs (Disabled for now to fix SIGSEGV)
    property var availableGpus: []
    readonly property bool hasValidGpuData: {
        if (availableGpus.length === 0) return false;
        // Check if at least one GPU has valid temperature or usage data
        // For iGPUs, dgop often returns 0 for everything
        return availableGpus.some(gpu => gpu.temp > 0 || (gpu.usage !== undefined && gpu.usage > 0));
    }

    // History tracking
    readonly property int historySize: 60
    property var cpuHistory: []
    property var memHistory: []
    property var networkRxHistory: []
    property var networkTxHistory: []
    property var diskReadHistory: []
    property var diskWriteHistory: []

    function addToHistory(array, value) {
        let newArray = (array || []).slice();
        newArray.push(value);
        if (newArray.length > historySize) {
            newArray.shift();
        }
        return newArray;
    }

    // State for adaptive polling
    property int cycleCount: 0
    readonly property bool isMonitorActive: GlobalStates.systemMonitorOpen
    readonly property bool isQuickSettingsOpen: GlobalStates.quickSettingsOpen
    readonly property bool isOverviewOpen: GlobalStates.overviewOpen
    readonly property bool isFullscreen: HyprlandData.fullscreenActive
    
    // showSpeed determines if the status bar needs network stats
    readonly property bool showSpeed: Config.options.bar ? Config.options.bar.show_network_speed : false
    
    // We pause polling when no panel consuming the metrics is open
    readonly property bool isAnyPanelOpen: isMonitorActive || isQuickSettingsOpen || isOverviewOpen || (!isFullscreen && showSpeed)
    readonly property bool shouldPause: !isAnyPanelOpen
    
    // Command and interval selection
    readonly property string activeModules: {
        if (shouldPause) return "";
        // Fetch all modules when active, including processes and gpu
        if (isMonitorActive) return "cpu,memory,diskmounts,network,disk,system,processes,gpu";
        
        return "cpu,memory,diskmounts,network,disk,system";
    }

    readonly property int activeInterval: 1000

    // Internal state for rate calculations
    property var lastNetworkStats: null
    property var lastDiskStats: null
    property var lastUpdateTime: 0
    property bool updatePending: false

    function update() {
        if (shouldPause) return;
        if (!dgopProcess.running && !updatePending) {
            updatePending = true;
            dgopProcess.running = true;
            cycleCount++;
        }
    }

    Timer {
        id: updateTimer
        interval: root.activeInterval
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: root.update()
    }
    
    // Trigger update immediately when monitor opens for snappier feel
    Connections {
        target: GlobalStates
        function onSystemMonitorOpenChanged() {
            if (GlobalStates.systemMonitorOpen) {
                root.update();
            }
        }
    }

    Process {
        id: dgopProcess
        command: ["/usr/bin/dgop", "meta", "--json", "--modules", root.activeModules]
        
        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text;
                root.updatePending = false; // Allow next update
                
                if (!results || results.trim() === "") return;
                
                // Offload processing to next event loop tick to avoid blocking/SIGSEGV in signal handler
                Qt.callLater(() => {
                    try {
                        let jsonText = results.trim();
                        let start = jsonText.indexOf('{');
                        let end = jsonText.lastIndexOf('}');
                        if (start === -1 || end === -1) return;
                        
                        const data = JSON.parse(jsonText.substring(start, end + 1));
                        const now = Date.now();
                        const timeDiff = root.lastUpdateTime > 0 ? Math.max(0.1, (now - root.lastUpdateTime) / 1000) : (root.activeInterval / 1000);
                        root.lastUpdateTime = now;

                        if (data.cpu) {
                            root.cpuUsage = (data.cpu.usage || 0) / 100;
                            root.cpuTemperature = data.cpu.temperature || 0;
                            root.cpuModel = data.cpu.model || "";
                            root.cpuThreads = data.cpu.count || 1;
                            root.cpuHistory = root.addToHistory(root.cpuHistory, root.cpuUsage * 100);
                        }

                        if (data.memory) {
                            root.memUsage = (data.memory.usedPercent || 0) / 100;
                            root.totalMemoryMB = Math.round((data.memory.total || 0) / 1024);
                            root.usedMemoryMB = Math.round((data.memory.used || (data.memory.total - data.memory.available) || 0) / 1024);
                            const totalSwap = data.memory.swaptotal || 0;
                            const freeSwap = data.memory.swapfree || 0;
                            root.swapUsage = totalSwap > 0 ? (totalSwap - freeSwap) / totalSwap : 0;
                            root.memHistory = root.addToHistory(root.memHistory, root.memUsage * 100);
                        }

                        if (data.network && Array.isArray(data.network)) {
                            let totalRx = 0, totalTx = 0;
                            data.network.forEach(iface => { totalRx += iface.rx || 0; totalTx += iface.tx || 0; });
                            if (root.lastNetworkStats) {
                                root.networkRxRate = Math.max(0, (totalRx - root.lastNetworkStats.rx) / timeDiff);
                                root.networkTxRate = Math.max(0, (totalTx - root.lastNetworkStats.tx) / timeDiff);
                            }
                            root.lastNetworkStats = { rx: totalRx, tx: totalTx };
                            root.networkRxHistory = root.addToHistory(root.networkRxHistory, root.networkRxRate / 1024);
                            root.networkTxHistory = root.addToHistory(root.networkTxHistory, root.networkTxRate / 1024);
                        }

                        if (data.disk && Array.isArray(data.disk)) {
                            let totalRead = 0, totalWrite = 0;
                            data.disk.forEach(disk => { totalRead += (disk.read || 0) * 512; totalWrite += (disk.write || 0) * 512; });
                            if (root.lastDiskStats) {
                                root.diskReadRate = Math.max(0, (totalRead - root.lastDiskStats.read) / timeDiff);
                                root.diskWriteRate = Math.max(0, (totalWrite - root.lastDiskStats.write) / timeDiff);
                            }
                            root.lastDiskStats = { read: totalRead, write: totalWrite };
                            root.diskReadHistory = root.addToHistory(root.diskReadHistory, root.diskReadRate / (1024 * 1024));
                            root.diskWriteHistory = root.addToHistory(root.diskWriteHistory, root.diskWriteRate / (1024 * 1024));
                        }

                        if (data.system) {
                            root.loadAverage = data.system.loadavg || "";
                            root.processCount = data.system.processes || 0;
                            root.threadCount = data.system.threads || 0;
                            if (data.system.boottime) {
                                const bootDate = new Date(data.system.boottime.replace(" ", "T"));
                                if (!isNaN(bootDate.getTime())) {
                                    const seconds = Math.floor((now - bootDate) / 1000);
                                    const days = Math.floor(seconds / (24 * 3600)), remHours = Math.floor((seconds % (24 * 3600)) / 3600), remMins = Math.floor((seconds % 3600) / 60);
                                    if (days > 0) root.uptime = `${days}d ${remHours}h ${remMins}m`;
                                    else if (remHours > 0) root.uptime = `${remHours}h ${remMins}m`;
                                    else root.uptime = `${remMins}m`;
                                }
                            }
                        }

                        if (data.diskmounts && Array.isArray(data.diskmounts)) {
                            let monitored = [{ "path": "/", "alias": "System" }];
                            if (Config.options.system && Config.options.system.monitoredDisks) {
                                monitored = Config.options.system.monitoredDisks;
                            }
                            let newStats = [];
                            monitored.forEach(diskInfo => {
                                const path = diskInfo.path || "/", alias = diskInfo.alias || "", hasAlias = alias !== "" && alias !== path, displayLabel = hasAlias ? alias : path;
                                const disk = data.diskmounts.find(m => m.mount === path || m.mountpoint === path);
                                if (disk) {
                                    let pctValue = disk.percent_used || 0;
                                    if (typeof disk.percent === 'string') pctValue = parseFloat(disk.percent.replace('%', ''));
                                    newStats.push({ path: path, label: displayLabel.toUpperCase(), hasAlias: hasAlias, usage: isNaN(pctValue) ? 0 : pctValue / 100, total: Math.round((disk.total_bytes || 0) / (1024 * 1024)) || 0, used: Math.round((disk.used_bytes || 0) / (1024 * 1024)) || 0 });
                                }
                            });
                            if (JSON.stringify(root.diskStats) !== JSON.stringify(newStats)) root.diskStats = newStats;
                        }

                        if (data.processes && Array.isArray(data.processes)) {
                            // Cap at top 150 by CPU to avoid inflating the ListView
                            // with hundreds of idle processes — most have cpu=0 anyway.
                            const sorted = data.processes.slice().sort((a, b) => (b.cpu || 0) - (a.cpu || 0));
                            root.allProcesses = sorted.slice(0, 150).map(proc => ({
                                pid: proc.pid || 0,
                                command: proc.command || "",
                                fullCommand: proc.fullCommand || "",
                                cpu: proc.cpu || 0,
                                memoryKB: proc.memoryKB || proc.pssKB || 0,
                                username: proc.username || ""
                            }));
                        } else if (!isMonitorActive) {
                            root.allProcesses = []; // Clear when not monitoring to save memory
                        }

                        if (data.gpu && (data.gpu.gpus || Array.isArray(data.gpu))) {
                            const gpus = Array.isArray(data.gpu) ? data.gpu : data.gpu.gpus;
                            root.availableGpus = gpus.map(gpu => ({
                                name: gpu.displayName || gpu.name || "GPU",
                                vendor: gpu.vendor || "",
                                temp: gpu.temperature || 0,
                                pciId: gpu.pciId || ""
                            }));
                        } else if (!isMonitorActive) {
                            root.availableGpus = []; // Clear when not monitoring
                        }
                    } catch (e) {

                    }
                });
            }
        }
        
        onExited: {
            dgopProcess.running = false;
            root.updatePending = false;
        }
    }

    function prePopulateDisks() {
        let monitored = [{ "path": "/", "alias": "System" }];
        if (Config.options.system && Config.options.system.monitoredDisks) {
            monitored = Config.options.system.monitoredDisks;
        }
        root.diskStats = monitored.map(d => ({
            path: d.path || "/",
            label: (d.alias || d.path || "/").toUpperCase(),
            hasAlias: !!d.alias,
            usage: 0,
            total: 0,
            used: 0
        }));
    }

    Component.onCompleted: {
        root.prePopulateDisks();
        Qt.callLater(() => root.update());
    }

    Component.onDestruction: {
        dgopProcess.terminate();
    }
}
