pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../core"

/**
 * Provides Hyprland workspace and window data via hyprctl JSON.
 * Listens to raw Hyprland events and refreshes data on changes.
 */
Singleton {
    id: root
    signal layoutChanged()
    property var windowList: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var activeWindow: null
    
    function hyprlandClientsForWorkspace(workspaceId) {
        return root.windowList.filter(win => win.workspace.id === workspaceId);
    }

    readonly property bool fullscreenActive: {
        if (!activeWorkspace) return false;
        return windowList.some(win => win.workspace.id === activeWorkspace.id && (win.fullscreen || win.fullscreenClient !== 0));
    }

    function updateWindowList() { getClients.running = true; }
    function updateMonitors() { getMonitors.running = true; }
    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }
    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateWorkspaces();
        updateActiveWindow();
    }

    function updateActiveWindow() { getActiveWindow.running = true; }
    
    function updateMonitorsDelayed(delayMs) {
        const d = delayMs !== undefined ? delayMs : 800;
        monitorUpdateTimer.interval = d;
        monitorUpdateTimer.restart();
    }
    
    // Targeted Update Timers
    Timer { id: windowUpdateTimer; interval: 350; repeat: false; onTriggered: updateWindowList() }
    Timer { id: workspaceUpdateTimer; interval: 200; repeat: false; onTriggered: updateWorkspaces() }
    Timer { id: monitorUpdateTimer; interval: 1000; repeat: false; onTriggered: updateMonitors() }
    Timer { id: activeWinUpdateTimer; interval: 150; repeat: false; onTriggered: updateActiveWindow() }

    Process {
        id: layoutProc
    }

    readonly property string persistencePath: HyprlandCompat.isLua
        ? "~/.config/hypr/nandoroid/user_persistence.lua"
        : "~/.config/hypr/nandoroid/user_persistence.conf"

    function cycleLayout(forward = true) {
        const layouts = ["dwindle", "master", "scrolling"];
        const current = root.activeWorkspace?.tiledLayout || GlobalStates.hyprlandLayout || "dwindle";
        let index = layouts.indexOf(current);
        if (index === -1) index = 0;
        
        if (forward) {
            index = (index + 1) % layouts.length;
        } else {
            index = (index - 1 + layouts.length) % layouts.length;
        }
        
        const nextLayout = layouts[index];
        
        // Apply immediately
        layoutProc.exec(HyprlandCompat.keyword("general", "layout", `"${nextLayout}"`));
        
        if (HyprlandCompat.isLua) {
            const luaBlock = `-- LAYOUT_START\n` +
                             `hl.config({\n` +
                             `    general = {\n` +
                             `        layout = "${nextLayout}"\n` +
                             `    }\n` +
                             `})\n` +
                             `-- LAYOUT_END`
            const pyCmd = `import sys, re; path = sys.argv[1]; new_block = sys.argv[2]\n` +
                          `try:\n` +
                          `    content = open(path).read()\n` +
                          `except Exception:\n` +
                          `    content = ""\n` +
                          `pattern = r"-- LAYOUT_START.*?-- LAYOUT_END\\s*"\n` +
                          `content = re.sub(pattern, "", content, flags=re.DOTALL)\n` +
                          `content = content.strip()\n` +
                          `if content:\n` +
                          `    content += chr(10) + chr(10)\n` +
                          `content += new_block + chr(10)\n` +
                          `open(path, "w").write(content)`
            const realPath = root.persistencePath.replace(/^~/, Directories.home.replace("file://", ""));
            Quickshell.execDetached(["python3", "-c", pyCmd, realPath, luaBlock]);
        } else {
            const cmd = `sed -i '/general:layout/d' ${root.persistencePath} 2>/dev/null || true; echo "general:layout = ${nextLayout}" >> ${root.persistencePath}`;
            Quickshell.execDetached(["bash", "-c", cmd]);
        }
        
        GlobalStates.hyprlandLayout = nextLayout;
        root.layoutChanged();
        workspaceUpdateTimer.restart(); // Refresh data with a small delay
    }

    function fetchInitialLayout() {
        fetchLayoutProc.running = true;
    }

    Process {
        id: fetchLayoutProc
        command: ["hyprctl", "getoption", "general:layout", "-j"]
        onExited: (code) => {
            if (code === 0) {
                try {
                    const data = JSON.parse(stdout.readAll());
                    if (data && data.str) {
                        GlobalStates.hyprlandLayout = data.str;
                    }
                } catch(e) {}
            }
        }
    }
    
    Component.onCompleted: {
        updateAll();
        fetchInitialLayout();
    }
    
    Component.onDestruction: {
        getClients.terminate();
        getMonitors.terminate();
        getWorkspaces.terminate();
        getActiveWorkspace.terminate();
        getActiveWindow.window = null;
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = event.name;
            
            // Ignore high-frequency / irrelevant events
            if (["openlayer", "closelayer", "screencast", "mousemove", "power"].includes(name)) return;
            
            if (name === "workspace" || name === "focusedmon") {
                workspaceUpdateTimer.restart();
                activeWinUpdateTimer.restart();
            } else if (name === "activewindow" || name === "activewindowv2") {
                activeWinUpdateTimer.restart();
            } else if (["openwindow", "closewindow", "movewindow", "windowtitle", "fullscreen", "changefloatingmode"].includes(name)) {
                windowUpdateTimer.restart();
            } else if (name === "monitoradded" || name === "monitorremoved") {
                monitorUpdateTimer.restart();
            } else if (name === "activelayout") {
                // Just refresh data without heavy window listing if possible
                workspaceUpdateTimer.restart();
            } else {
                // Fallback for other events
                refreshTimer.restart();
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 400
        repeat: false
        onTriggered: {
            updateWorkspaces();
            updateActiveWindow();
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                const results = clientsCollector.text.toString().trim();
                Qt.callLater(() => {
                    try {
                        if (results && results !== "null") {
                            root.windowList = JSON.parse(results);
                            let temp = {};
                            for (let i = 0; i < root.windowList.length; ++i) {
                                let win = root.windowList[i];
                                temp[win.address] = win;
                            }
                            root.windowByAddress = temp;
                        }
                    } catch (e) {
                        console.error("HyprlandData: JSON Parse error for clients: " + e);
                    }
                });
            }
        }
        stderr: StdioCollector {
            id: clientsStderr
            onStreamFinished: {
                const err = clientsStderr.text.trim();
                if (err) console.warn("HyprlandData Stderr: " + err);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                const results = monitorsCollector.text.trim();
                Qt.callLater(() => {
                    try {
                        if (results) root.monitors = JSON.parse(results);
                    } catch(e) { console.error("HyprlandData: JSON Parse error for monitors", e) }
                });
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                const results = workspacesCollector.text.trim();
                Qt.callLater(() => {
                    try {
                        if (results) {
                            var raw = JSON.parse(results);
                            root.workspaces = raw.filter(ws => ws.id >= 1 && ws.id <= 100);
                            let temp = {};
                            for (var i = 0; i < root.workspaces.length; ++i) {
                                var ws = root.workspaces[i];
                                temp[ws.id] = ws;
                            }
                            root.workspaceById = temp;
                        }
                    } catch(e) { console.error("HyprlandData: JSON Parse error for workspaces", e) }
                });
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                const results = activeWorkspaceCollector.text.trim();
                Qt.callLater(() => {
                    try {
                        if (results) root.activeWorkspace = JSON.parse(results);
                    } catch(e) { console.error("HyprlandData: JSON Parse error for active workspace", e) }
                });
            }
        }
    }

    Process {
        id: getActiveWindow
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            id: activeWindowCollector
            onStreamFinished: {
                var raw = activeWindowCollector.text.trim();
                Qt.callLater(() => {
                    try {
                        if (raw === "{}" || raw === "" || raw === "null") {
                            root.activeWindow = null;
                        } else {
                            root.activeWindow = JSON.parse(raw);
                        }
                    } catch(e) { console.error("HyprlandData: JSON Parse error for active window", e) }
                });
            }
        }
    }
}
