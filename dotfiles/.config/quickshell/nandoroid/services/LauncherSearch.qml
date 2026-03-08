pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions"

Singleton {
    id: root

    property string query: ""
    property var clipboardHistory: []
    property var usageData: ({})
    readonly property string clipboardThumbnailDir: "/tmp/nandoroid/clipboard"

    onClipboardHistoryChanged: {
        if (!clipboardHistory || clipboardHistory.length === 0) return;
        Quickshell.execDetached(["mkdir", "-p", root.clipboardThumbnailDir]);
        clipboardHistory.forEach(entry => {
            if (entry.isImage) {
                const thumbPath = root.clipboardThumbnailDir + "/" + entry.id + ".png";
                // Check if already exists to avoid redundant decodes
                const checkCmd = "test -f " + thumbPath + " || cliphist decode " + entry.id + " > " + thumbPath;
                Quickshell.execDetached(["bash", "-c", checkCmd]);
            }
        });
    }

    function closeAll() {
        GlobalStates.launcherOpen = false;
        GlobalStates.spotlightOpen = false;
    }

    readonly property var quickCommands: [
        { name: "Lock Screen", subtitle: "Session Action", id: "cmd-lock", icon: "lock", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.lock(); root.closeAll(); } },
        { name: "Reboot System", subtitle: "Session Action", id: "cmd-reboot", icon: "restart_alt", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.reboot(); root.closeAll(); } },
        { name: "Power Off", subtitle: "Session Action", id: "cmd-poweroff", icon: "power_settings_new", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.poweroff(); root.closeAll(); } },
        { name: "Shutdown", subtitle: "Session Action", id: "cmd-shutdown", icon: "power_settings_new", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.poweroff(); root.closeAll(); } },
        { name: "Log Out", subtitle: "Session Action", id: "cmd-logout", icon: "logout", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.logout(); root.closeAll(); } },
        { name: "Exit Shell", subtitle: "Session Action", id: "cmd-exit", icon: "logout", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.logout(); root.closeAll(); } },
        { name: "Suspend", subtitle: "Session Action", id: "cmd-suspend", icon: "bedtime", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.suspend(); root.closeAll(); } },
        { name: "Hibernate", subtitle: "Session Action", id: "cmd-hibernate", icon: "save", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.hibernate(); root.closeAll(); } },
        { name: "Open Dashboard", subtitle: "Shell Interface", id: "cmd-dashboard", icon: "dashboard", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.dashboardOpen = true; root.closeAll(); } },
        { name: "Open Settings", subtitle: "Shell Interface", id: "cmd-settings", icon: "settings", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "System Monitor", subtitle: "Shell Interface", id: "cmd-monitor", icon: "monitoring", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.systemMonitorOpen = true; root.closeAll(); } },
        { name: "Workspace Overview", subtitle: "Shell Interface", id: "cmd-overview", icon: "grid_view", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.overviewOpen = true; root.closeAll(); } },
        { name: "Wallpaper & Style", subtitle: "Shell Interface", id: "cmd-wallpaper", icon: "palette", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsPageIndex = 4; GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "Bluetooth Settings", subtitle: "Shell Interface", id: "cmd-bluetooth", icon: "bluetooth", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsPageIndex = 1; GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "Network Settings", subtitle: "Shell Interface", id: "cmd-network", icon: "wifi", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsPageIndex = 0; GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "Reload Hyprland", subtitle: "Compositor Action", id: "cmd-hypr-reload", icon: "refresh", isPlugin: true, category: "Command", emoji: "", execute: () => { Quickshell.execDetached(["hyprctl", "reload"]); root.closeAll(); } },
        { name: "Reload Shell", subtitle: "Maintenance", id: "cmd-reload", icon: "refresh", isPlugin: true, category: "Command", emoji: "", execute: () => { Quickshell.reload(); root.closeAll(); } }
    ]

    Timer {
        id: fileSearchTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (!Config.ready || !Config.options.search) return;
            const term = root.query.trim().slice(Config.options.search.filePrefix.length).trim();
            if (term.length > 0) {
                fileSearchProc.runSearch(term);
            } else {
                fileSearchProc.results = [];
                _triggerVal++;
            }
        }
    }

    Process {
        id: fileSearchProc
        running: false
        property var results: []
        command: ["fd", "-i", "-t", "f", "--max-results", "20", "", "/home"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n").filter(l => l.length > 0);
                fileSearchProc.results = lines.map(path => {
                    const parts = path.split("/");
                    const name = parts[parts.length - 1];
                    return {
                        name: name,
                        subtitle: path,
                        id: "file-" + path,
                        icon: "insert_drive_file",
                        isPlugin: true,
                        category: "File",
                        emoji: "",
                        execute: () => { 
                            Quickshell.execDetached(["xdg-open", path]); 
                            root.closeAll(); 
                        }
                    };
                });
                _triggerVal++;
            }
        }
        function runSearch(term) {
            running = false;
            const home = FileUtils.trimFileProtocol(Directories.home.toString());
            command = ["fd", "-i", "-t", "f", "--max-results", "20", term, home];
            running = true;
        }
    }

    onQueryChanged: {
        if (Config.ready && Config.options.search && query.trim().startsWith(Config.options.search.filePrefix)) {
            fileSearchTimer.restart();
        }
    }

    Process {
        id: cliphistProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0);
                const newHistory = lines.slice(0, 50).map(line => {
                    const id = line.split("\t")[0];
                    const isImage = line.includes("[[ binary data");
                    return { id: id, raw: line, isImage: isImage };
                });
                
                // Only update if something actually changed to avoid model re-renders/scroll jumping
                if (JSON.stringify(newHistory) !== JSON.stringify(root.clipboardHistory)) {
                    root.clipboardHistory = newHistory;
                }
            }
        }
    }

    Timer {
        id: cliphistTimer
        interval: 2500 // Increased interval
        running: GlobalStates.launcherOpen || GlobalStates.spotlightOpen
        repeat: true
        onTriggered: cliphistProc.running = true
    }

    // Load usage data
    FileView {
        id: usageFile
        path: Quickshell.shellPath("data/app_usage.json")
        watchChanges: true
        onLoaded: {
            try {
                root.usageData = JSON.parse(text());
            } catch(e) {
                root.usageData = {};
            }
            updateAppModel();
        }
    }

    // Function to save usage
    function recordExecution(appId) {
        if (!appId) return;
        const currentCount = root.usageData[appId] || 0;
        root.usageData[appId] = currentCount + 1;
        
        // Write back to file via shell command using a pipe to avoid argument length limits
        const dataStr = JSON.stringify(root.usageData);
        const path = Quickshell.shellPath("data/app_usage.json");
        // We use a temporary file and mv for atomic-ish save
        const cmd = "printf '%s' '" + dataStr.replace(/'/g, "'\\''") + "' > '" + path + "'";
        Quickshell.execDetached(["bash", "-c", cmd]);
        
        // Force update our list to reflect the new order
        updateAppModel();
    }

    // Stable cached apps list to prevent Repeater re-rendering everyone on every open
    property var allApps: []
    
    // Periodically update if we have no apps yet (DesktopEntries is async)
    Timer {
        id: retryTimer
        interval: 2000
        running: allApps.length < 5
        repeat: true
        onTriggered: updateAppModel()
    }
    
    Component.onCompleted: {
        updateAppModel()
        cliphistProc.running = true
        usageFile.reload()
    }

    Connections {
        target: GlobalStates
        function onLauncherOpenChanged() {
            if (GlobalStates.launcherOpen && allApps.length === 0) root.updateAppModel()
        }
        function onSpotlightOpenChanged() {
            if (GlobalStates.spotlightOpen && allApps.length === 0) root.updateAppModel()
        }
    }

    // Refresh model when system entries change, not every open
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.updateAppModel() }
    }

    function updateAppModel() {
        const apps = Array.from(DesktopEntries.applications.values);
        const uniqueApps = new Map();
        for (const app of apps) {
            if (!uniqueApps.has(app.id)) {
                uniqueApps.set(app.id, app);
            }
        }
        allApps = Array.from(uniqueApps.values()).map(app => ({
            name: app.name,
            icon: app.icon || "application-x-executable",
            id: app.id,
            execute: () => { 
                recordExecution(app.id); 
                app.execute(); 
            },
            isPlugin: false,
            subtitle: app.id,
            category: "Application",
            emoji: ""
        })).sort((a, b) => {
            const countA = root.usageData[a.id] || 0;
            const countB = root.usageData[b.id] || 0;
            
            if (countB !== countA) {
                return countB - countA; // Higher usage first
            }
            return a.name.localeCompare(b.name); // Then alphabetical
        });
        console.log("[LauncherSearch] Updated. allApps count: " + allApps.length);
        _triggerVal++
    }
    
    property int _triggerVal: 0

    Process {
        id: mathProc
        property string result: ""
        command: ["qalc", "-t"]
        stdout: StdioCollector {
            onStreamFinished: {
                mathProc.result = this.text.trim();
            }
        }
        function calculate(expr) {
            running = false;
            command = ["qalc", "-t", expr];
            running = true;
        }
    }

    property var emojiList: []
    property bool emojisLoaded: false

    FileView {
        id: emojiFile
        path: Quickshell.shellPath("data/emojis.txt")
        onLoaded: {
            const lines = text().split("\n");
            const list = [];
            for (const line of lines) {
                const match = line.match(/^(\S+)\s+(.+)$/);
                if (match) {
                    list.push({ emoji: match[1], name: match[2] });
                }
            }
            emojiList = list;
            emojisLoaded = true;
        }
    }

    readonly property bool isPluginSearch: {
        const stripped = query.trim();
        if (!Config.ready || !Config.options.search) return false;
        return [
            Config.options.search.mathPrefix,
            Config.options.search.webPrefix,
            Config.options.search.emojiPrefix,
            Config.options.search.clipboardPrefix,
            Config.options.search.filePrefix,
            Config.options.search.commandPrefix
        ].some(p => stripped.startsWith(p));
    }

    readonly property var results: {
        const strippedQuery = query.trim();
        const isClipboard = strippedQuery.startsWith(Config.options.search.clipboardPrefix);
        
        // Only trigger full update on clipboard change if we are actually viewing clipboard
        if (isClipboard) {
            clipboardHistory; 
        }
        
        _triggerVal
        
        if (strippedQuery === "") return allApps;

        const results = [];
        if (!Config.ready || !Config.options.search) return allApps;

        // 1. Math Plugin (Prefix: =)
        if (strippedQuery.startsWith(Config.options.search.mathPrefix)) {
            const mathExpr = strippedQuery.slice(Config.options.search.mathPrefix.length).trim();
            if (mathExpr.length > 0) {
                mathProc.calculate(mathExpr);
                results.push({
                    name: "Math Result",
                    subtitle: mathExpr + " = " + (mathProc.result || "..."),
                    id: "math-result",
                    icon: "calculate",
                    isPlugin: true,
                    category: "Command",
                    emoji: "",
                    execute: () => { Quickshell.clipboardText = mathProc.result; root.closeAll(); }
                });
            }
        }

        // 2. Web Search Plugin (Prefix: !)
        if (strippedQuery.startsWith(Config.options.search.webPrefix)) {
            const webQuery = strippedQuery.slice(Config.options.search.webPrefix.length).trim();
            if (webQuery.length > 0) {
                results.push({
                    name: "Search Web",
                    subtitle: webQuery,
                    id: "web-search",
                    icon: "public",
                    isPlugin: true,
                    category: "Command",
                    emoji: "",
                    execute: () => { Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(webQuery)); root.closeAll(); }
                });
            }
        }

        // 3. Emoji Plugin (Prefix: :)
        if (strippedQuery.startsWith(Config.options.search.emojiPrefix)) {
            const emojiQuery = strippedQuery.slice(Config.options.search.emojiPrefix.length).toLowerCase().trim();
            for (const item of emojiList) {
                if (item.name.includes(emojiQuery) || emojiQuery === "") {
                    results.push({
                        name: item.name,
                        subtitle: "Emoji",
                        emoji: item.emoji,
                        category: "Emoji",
                        id: "emoji-" + item.name,
                        icon: "face",
                        isPlugin: true,
                        execute: () => { Quickshell.clipboardText = item.emoji; root.closeAll(); }
                    });
                }
                if (results.length > 50) break;
            }
        }

        // 4. Clipboard Plugin (Prefix: ;)
        if (strippedQuery.startsWith(Config.options.search.clipboardPrefix)) {
            const clipQuery = strippedQuery.slice(Config.options.search.clipboardPrefix.length).toLowerCase().trim();
            for (const entryObj of clipboardHistory) {
                const entry = entryObj.raw;
                if (entry.toLowerCase().includes(clipQuery) || clipQuery === "") {
                    const cleanName = entry.replace(/^\d+\t/, "").trim();
                    const thumbPath = entryObj.isImage ? (root.clipboardThumbnailDir + "/" + entryObj.id + ".png") : "";
                    
                    results.push({
                        name: entryObj.isImage ? "Clipboard Image" : "Clipboard Entry",
                        subtitle: cleanName,
                        rawValue: entry,
                        id: "clip-" + entryObj.id,
                        icon: entryObj.isImage ? "image" : "content_paste",
                        isPlugin: true,
                        isImage: entryObj.isImage,
                        imagePath: thumbPath,
                        category: "Command",
                        emoji: "",
                        execute: () => {
                            const escapedEntry = entry.replace(/'/g, "'\\''");
                            Quickshell.execDetached(["bash", "-c", "printf '" + escapedEntry + "' | cliphist decode | wl-copy"]);
                            root.closeAll();
                        }
                    });
                }
                if (results.length > 50) break;
            }
        }

        // 5. Quick Commands (Prefix: >)
        if (strippedQuery.startsWith(Config.options.search.commandPrefix)) {
            const cmdQuery = strippedQuery.slice(Config.options.search.commandPrefix.length).toLowerCase().trim();
            for (const cmd of root.quickCommands) {
                if (cmd.name.toLowerCase().includes(cmdQuery) || cmd.id.toLowerCase().includes(cmdQuery) || cmdQuery === "") {
                    results.push(cmd);
                }
            }
        }

        // 6. File Search (Prefix: ?)
        if (strippedQuery.startsWith(Config.options.search.filePrefix)) {
            results.push(...fileSearchProc.results);
            if (fileSearchProc.results.length === 0 && strippedQuery.length > 1) {
                 results.push({
                    name: "Searching Files...",
                    subtitle: "Please wait",
                    id: "file-searching",
                    icon: "search",
                    isPlugin: true,
                    category: "Command",
                    emoji: "",
                    execute: () => {}
                });
            }
        }

        // 7. Regular App Filtering
        if (!isPluginSearch) {
            const loweredQuery = strippedQuery.toLowerCase();
            const filteredApps = allApps.filter(app =>
                app.name.toLowerCase().includes(loweredQuery) ||
                app.id.toLowerCase().includes(loweredQuery)
            );
            results.push(...filteredApps);
        }

        // Avoid identity change if we revert to empty
        return (results.length > 0 || strippedQuery === "") ? results : allApps;
    }
}
