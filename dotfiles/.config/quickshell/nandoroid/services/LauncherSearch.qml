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
        { name: "Log Out", subtitle: "Exit Hyprland", id: "cmd-logout", icon: "logout", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.logout(); root.closeAll(); } },
        { name: "Suspend", subtitle: "Session Action", id: "cmd-suspend", icon: "bedtime", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.suspend(); root.closeAll(); } },
        { name: "Hibernate", subtitle: "Session Action", id: "cmd-hibernate", icon: "save", isPlugin: true, category: "Command", emoji: "", execute: () => { Session.hibernate(); root.closeAll(); } },
        { name: "Open Dashboard", subtitle: "Shell Interface", id: "cmd-dashboard", icon: "dashboard", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.dashboardOpen = true; root.closeAll(); } },
        { name: "Open Settings", subtitle: "Shell Interface", id: "cmd-settings", icon: "settings", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "System Monitor", subtitle: "Shell Interface", id: "cmd-monitor", icon: "monitoring", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.systemMonitorOpen = true; root.closeAll(); } },
        { name: "Workspace Overview", subtitle: "Shell Interface", id: "cmd-overview", icon: "grid_view", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.overviewOpen = true; root.closeAll(); } },
        { name: "Wallpaper & Style", subtitle: "Shell Interface", id: "cmd-wallpaper", icon: "palette", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsPageIndex = 4; GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "Bluetooth Settings", subtitle: "Shell Interface", id: "cmd-bluetooth", icon: "bluetooth", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsPageIndex = 1; GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "Network Settings", subtitle: "Shell Interface", id: "cmd-network", icon: "wifi", isPlugin: true, category: "Command", emoji: "", execute: () => { GlobalStates.settingsPageIndex = 0; GlobalStates.settingsOpen = true; root.closeAll(); } },
        { name: "Restart Shell", subtitle: "Maintenance", id: "cmd-shell-restart", icon: "refresh", isPlugin: true, category: "Command", emoji: "", execute: () => { Quickshell.execDetached([Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/scripts/restartshell.sh"]); root.closeAll(); } }
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
                
                if (JSON.stringify(newHistory) !== JSON.stringify(root.clipboardHistory)) {
                    root.clipboardHistory = newHistory;
                }
            }
        }
    }

    Timer {
        id: cliphistTimer
        interval: 2500
        running: GlobalStates.launcherOpen || GlobalStates.spotlightOpen
        repeat: true
        onTriggered: cliphistProc.running = true
    }

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
            triggerUpdate();
        }
    }

    function recordExecution(appId) {
        if (!appId) return;
        const currentCount = root.usageData[appId] || 0;
        root.usageData[appId] = currentCount + 1;
        const dataStr = JSON.stringify(root.usageData);
        const path = Quickshell.shellPath("data/app_usage.json");
        const cmd = "printf '%s' '" + dataStr.replace(/'/g, "'\\''") + "' > '" + path + "'";
        Quickshell.execDetached(["bash", "-c", cmd]);
        triggerUpdate();
    }

    property var allApps: []
    property string selectedCategory: "All"
    
    Timer {
        id: debounceUpdateTimer
        interval: 500
        repeat: false
        onTriggered: root.updateAppModel()
    }

    function triggerUpdate() {
        debounceUpdateTimer.restart()
    }

    readonly property var categories: {
        const cats = new Set(["All"]);
        allApps.forEach(app => {
            if (app.category && app.category !== "Application" && app.category !== "Other") {
                cats.add(app.category);
            }
        });
        const sortedCats = Array.from(cats).sort((a, b) => {
            if (a === "All") return -1;
            if (b === "All") return 1;
            return a.localeCompare(b);
        });
        if (allApps.some(app => app.category === "Other")) sortedCats.push("Other");
        return sortedCats;
    }
    
    Timer {
        id: retryTimer
        interval: 2000
        running: allApps.length < 5
        repeat: true
        onTriggered: triggerUpdate()
    }
    
    Component.onCompleted: {
        triggerUpdate()
        cliphistProc.running = true
        usageFile.reload()
    }

    Connections {
        target: GlobalStates
        function onLauncherOpenChanged() {
            if (GlobalStates.launcherOpen && allApps.length === 0) triggerUpdate()
        }
        function onSpotlightOpenChanged() {
            if (GlobalStates.spotlightOpen && allApps.length === 0) triggerUpdate()
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { triggerUpdate() }
    }

    function updateAppModel() {
        const apps = Array.from(DesktopEntries.applications.values);
        if (apps.length === 0) return;
        
        const uniqueApps = new Map();
        for (const app of apps) {
            if (!uniqueApps.has(app.id)) uniqueApps.set(app.id, app);
        }
        
        const mapped = Array.from(uniqueApps.values()).map(app => {
            let category = "Other";
            
            if (app.categories && Array.isArray(app.categories)) {
                const cats = app.categories;
                if (cats.includes("Game")) category = "Games";
                else if (cats.includes("Development")) category = "Development";
                else if (cats.includes("Office")) category = "Office";
                else if (cats.includes("Network") || cats.includes("WebBrowser")) category = "Internet";
                else if (cats.includes("AudioVideo") || cats.includes("Audio") || cats.includes("Video")) category = "Multimedia";
                else if (cats.includes("Settings")) category = "Settings";
                else if (cats.includes("System")) category = "System";
                else if (cats.includes("Graphics")) category = "Graphics";
                else if (cats.includes("Utility")) category = "Utility";
            }
            
            if (category === "Other") {
                const id = app.id.toLowerCase();
                const name = app.name.toLowerCase();
                if (id.includes("game") || id.includes("steam") || id.includes("retroarch")) category = "Games";
                else if (id.includes("code") || id.includes("vsc") || id.includes("studio") || id.includes("devel") || id.includes("python") || id.includes("rust")) category = "Development";
                else if (id.includes("office") || id.includes("word") || id.includes("excel") || id.includes("calc") || id.includes("pdf") || id.includes("note")) category = "Office";
                else if (id.includes("browser") || id.includes("firefox") || id.includes("chrome") || id.includes("internet") || id.includes("mail")) category = "Internet";
                else if (id.includes("player") || id.includes("vlc") || id.includes("mpv") || id.includes("music") || id.includes("video") || id.includes("audio")) category = "Multimedia";
                else if (id.includes("setting") || id.includes("config") || id.includes("control") || id.includes("tweak")) category = "Settings";
                else if (id.includes("terminal") || id.includes("system") || id.includes("monitor") || id.includes("file") || id.includes("manage")) category = "System";
                else if (id.includes("graphic") || id.includes("draw") || id.includes("paint") || id.includes("photo") || id.includes("gimp") || id.includes("inkscape")) category = "Graphics";
            }

            return {
                name: app.name,
                icon: app.icon || "application-x-executable",
                id: app.id,
                execute: () => { recordExecution(app.id); app.execute(); },
                isPlugin: false,
                subtitle: app.id,
                category: category,
                emoji: ""
            };
        }).sort((a, b) => {
            const countA = root.usageData[a.id] || 0;
            const countB = root.usageData[b.id] || 0;
            if (countB !== countA) return countB - countA;
            return a.name.localeCompare(b.name);
        });
        
        allApps = mapped;
        _triggerVal++;

    }
    
    property int _triggerVal: 0

    Process {
        id: mathProc
        property string result: ""
        command: ["qalc", "-t"]
        stdout: StdioCollector {
            onStreamFinished: { mathProc.result = this.text.trim(); }
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
                if (match) list.push({ emoji: match[1], name: match[2] });
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
        if (isClipboard) clipboardHistory; 
        _triggerVal
        
        if (strippedQuery === "") {
            if (Config.ready && Config.options.search && Config.options.search.enableGrouping && selectedCategory !== "All") {
                return allApps.filter(app => app.category === selectedCategory);
            }
            return allApps;
        }

        const results = [];
        if (!Config.ready || !Config.options.search) return allApps;

        if (strippedQuery.startsWith(Config.options.search.mathPrefix)) {
            const mathExpr = strippedQuery.slice(Config.options.search.mathPrefix.length).trim();
            if (mathExpr.length > 0) {
                mathProc.calculate(mathExpr);
                results.push({
                    name: "Math Result",
                    subtitle: mathExpr + " = " + (mathProc.result || "..."),
                    id: "math-result", icon: "calculate", isPlugin: true, category: "Command", emoji: "",
                    execute: () => { Quickshell.clipboardText = mathProc.result; root.closeAll(); }
                });
            }
        } else if (strippedQuery.startsWith(Config.options.search.webPrefix)) {
            const webQuery = strippedQuery.slice(Config.options.search.webPrefix.length).trim();
            if (webQuery.length > 0) {
                results.push({
                    name: "Search Web", subtitle: webQuery, id: "web-search", icon: "public", isPlugin: true, category: "Command", emoji: "",
                    execute: () => { Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(webQuery)); root.closeAll(); }
                });
            }
        } else if (strippedQuery.startsWith(Config.options.search.emojiPrefix)) {
            const emojiQuery = strippedQuery.slice(Config.options.search.emojiPrefix.length).toLowerCase().trim();
            for (const item of emojiList) {
                if (item.name.includes(emojiQuery) || emojiQuery === "") {
                    results.push({
                        name: item.name, subtitle: "Emoji", emoji: item.emoji, category: "Emoji", id: "emoji-" + item.name, icon: "face", isPlugin: true,
                        execute: () => { Quickshell.clipboardText = item.emoji; root.closeAll(); }
                    });
                }
                if (results.length > 50) break;
            }
        } else if (strippedQuery.startsWith(Config.options.search.clipboardPrefix)) {
            const clipQuery = strippedQuery.slice(Config.options.search.clipboardPrefix.length).toLowerCase().trim();
            for (const entryObj of clipboardHistory) {
                const entry = entryObj.raw;
                if (entry.toLowerCase().includes(clipQuery) || clipQuery === "") {
                    const cleanName = entry.replace(/^\d+\t/, "").trim();
                    const thumbPath = entryObj.isImage ? (root.clipboardThumbnailDir + "/" + entryObj.id + ".png") : "";
                    results.push({
                        name: entryObj.isImage ? "Clipboard Image" : "Clipboard Entry",
                        subtitle: cleanName, rawValue: entry, id: "clip-" + entryObj.id, icon: entryObj.isImage ? "image" : "content_paste",
                        isPlugin: true, isImage: entryObj.isImage, imagePath: thumbPath, category: "Command", emoji: "",
                        execute: () => {
                            const escapedEntry = entry.replace(/'/g, "'\\''");
                            Quickshell.execDetached(["bash", "-c", "printf '" + escapedEntry + "' | cliphist decode | wl-copy"]);
                            root.closeAll();
                        }
                    });
                }
                if (results.length > 50) break;
            }
        } else if (strippedQuery.startsWith(Config.options.search.commandPrefix)) {
            const cmdQuery = strippedQuery.slice(Config.options.search.commandPrefix.length).toLowerCase().trim();
            for (const cmd of root.quickCommands) {
                if (cmd.name.toLowerCase().includes(cmdQuery) || cmd.id.toLowerCase().includes(cmdQuery) || cmdQuery === "") results.push(cmd);
            }
        } else if (strippedQuery.startsWith(Config.options.search.filePrefix)) {
            results.push(...fileSearchProc.results);
            if (fileSearchProc.results.length === 0 && strippedQuery.length > 1) {
                 results.push({
                    name: "Searching Files...", subtitle: "Please wait", id: "file-searching", icon: "search", isPlugin: true, category: "Command", emoji: "", execute: () => {}
                });
            }
        }

        if (!isPluginSearch) {
            const loweredQuery = strippedQuery.toLowerCase();
            const filteredApps = allApps.filter(app =>
                app.name.toLowerCase().includes(loweredQuery) ||
                app.id.toLowerCase().includes(loweredQuery)
            );
            results.push(...filteredApps);
        }

        return (results.length > 0 || strippedQuery === "") ? results : allApps;
    }
}
