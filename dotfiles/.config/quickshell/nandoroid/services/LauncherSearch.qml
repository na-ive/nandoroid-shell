pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property string query: ""
    property var clipboardHistory: []
    property var usageData: ({})

    Process {
        id: cliphistProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0);
                root.clipboardHistory = lines.slice(0, 50); // Limit to 50 entries
            }
        }
    }

    Timer {
        id: cliphistTimer
        interval: 1000
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
            if (GlobalStates.launcherOpen) root.updateAppModel()
        }
        function onSpotlightOpenChanged() {
            if (GlobalStates.spotlightOpen) root.updateAppModel()
        }
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
            Config.options.search.clipboardPrefix
        ].some(p => stripped.startsWith(p));
    }

    readonly property var results: {
        _triggerVal
        const strippedQuery = query.trim();
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
                    execute: () => { Quickshell.clipboardText = mathProc.result; GlobalStates.launcherOpen = false; GlobalStates.spotlightOpen = false; }
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
                    execute: () => { Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(webQuery)); GlobalStates.launcherOpen = false; GlobalStates.spotlightOpen = false; }
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
                        execute: () => { Quickshell.clipboardText = item.emoji; GlobalStates.launcherOpen = false; GlobalStates.spotlightOpen = false; }
                    });
                }
                if (results.length > 50) break;
            }
        }

        // 4. Clipboard Plugin (Prefix: ;)
        if (strippedQuery.startsWith(Config.options.search.clipboardPrefix)) {
            const clipQuery = strippedQuery.slice(Config.options.search.clipboardPrefix.length).toLowerCase().trim();
            for (const entry of clipboardHistory) {
                if (entry.toLowerCase().includes(clipQuery) || clipQuery === "") {
                    const cleanName = entry.replace(/^\d+\t/, "").trim();
                    results.push({
                        name: "Clipboard Entry",
                        subtitle: cleanName,
                        rawValue: entry,
                        id: "clip-" + entry.split("\t")[0],
                        icon: "content_paste",
                        isPlugin: true,
                        category: "Command",
                        emoji: "",
                        execute: () => {
                            const escapedEntry = entry.replace(/'/g, "'\\''");
                            Quickshell.execDetached(["bash", "-c", "printf '" + escapedEntry + "' | cliphist decode | wl-copy"]);
                            GlobalStates.launcherOpen = false;
                            GlobalStates.spotlightOpen = false;
                        }
                    });
                }
                if (results.length > 50) break;
            }
        }

        // 5. Regular App Filtering
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
