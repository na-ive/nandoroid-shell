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
    
    Process {
        id: layoutProc
    }

    function cycleLayout(forward = true) {
        const layouts = ["dwindle", "master", "scrolling"];
        const current = root.activeWorkspace?.tiledLayout || "dwindle";
        let index = layouts.indexOf(current);
        if (index === -1) index = 0;
        
        if (forward) {
            index = (index + 1) % layouts.length;
        } else {
            index = (index - 1 + layouts.length) % layouts.length;
        }
        
        const nextLayout = layouts[index];
        layoutProc.exec(["hyprctl", "keyword", "general:layout", nextLayout]);
        GlobalStates.hyprlandLayout = nextLayout;
        root.layoutChanged();
        refreshTimer.restart(); // Refresh data with a small delay
    }
    
    Component.onCompleted: updateAll()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast", "mousemove"].includes(event.name)) return;
            // Debounce updates to avoid hanging the shell and flooding processes
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 100
        repeat: false
        onTriggered: updateAll()
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                try {
                    const data = clientsCollector.text.toString().trim();
                    if (data && data !== "null") {
                        root.windowList = JSON.parse(data);
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
                root.monitors = JSON.parse(monitorsCollector.text);
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                var raw = JSON.parse(workspacesCollector.text);
                root.workspaces = raw.filter(ws => ws.id >= 1 && ws.id <= 100);
                let temp = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    temp[ws.id] = ws;
                }
                root.workspaceById = temp;
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                root.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
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
                if (raw === "{}" || raw === "" || raw === "null") {
                    root.activeWindow = null;
                } else {
                    root.activeWindow = JSON.parse(raw);
                }
            }
        }
    }
}
