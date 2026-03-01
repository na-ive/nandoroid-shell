import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

/**
 * OverviewContent.qml
 * Clean, solid workspace overview following 'ii' classic patterns.
 * No headers, purely functional workspace grid.
 */
FocusScope {
    id: root
    
    // Config values
    readonly property real workspaceScale: (Config.options.overview?.scale ?? 0.12)
    readonly property int columns: 4
    readonly property int rows: 3
    readonly property int maxWorkspaces: columns * rows
    
    // Monitor data
    readonly property var monitor: Hyprland.monitorFor(Quickshell.screens[0])
    readonly property var monitorData: HyprlandData.monitors.find(m => m.id === (monitor?.id ?? 0)) || ({x:0, y:0, width:1920, height:1080})
    readonly property real monWidth: monitorData.width
    readonly property real monHeight: monitorData.height
    
    // Drag & Drop state (Internalized tracking)
    property int draggingTargetWorkspace: -1
    property string draggingWindowAddress: ""
    
    // Dimensions
    readonly property real wsWidth: monWidth * workspaceScale
    readonly property real wsHeight: monHeight * workspaceScale
    readonly property real spacing: 20
    
    // --- Organized Layout (Dwindle Simulation) ---
    readonly property var workspaceLayouts: {
        let layouts = {};
        const winList = ToplevelManager.toplevels.values;
        
        for (let wsId = 1; wsId <= root.maxWorkspaces; wsId++) {
            let wsWins = winList.filter(t => {
                if (!t.HyprlandToplevel) return false;
                const addr = "0x" + t.HyprlandToplevel.address.toLowerCase();
                const hw = HyprlandData.windowByAddress[addr];
                return hw && hw.workspace.id === wsId;
            }).map(t => {
                const addr = "0x" + t.HyprlandToplevel.address.toLowerCase();
                return HyprlandData.windowByAddress[addr];
            });
            
            // Sort by address for stable layout during transitions
            wsWins.sort((a,b) => a.address.localeCompare(b.address));
            layouts[wsId] = root.calculateDwindle(wsWins, root.wsWidth, root.wsHeight);
        }
        return layouts;
    }

    function calculateDwindle(wins, w, h) {
        let results = {};
        if (wins.length === 0) return results;
        const g = 4; // Layout gap
        
        function split(list, x, y, curW, curH, vert) {
            if (list.length === 0) return;
            if (list.length === 1) {
                results[list[0].address] = {x: x + g, y: y + g, w: curW - g*2, h: curH - g*2};
                return;
            }
            if (vert) {
                let s = curW / 2;
                results[list[0].address] = {x: x + g, y: y + g, w: s - g*1.5, h: curH - g*2};
                split(list.slice(1), x + s, y, s, curH, !vert);
            } else {
                let s = curH / 2;
                results[list[0].address] = {x: x + g, y: y + g, w: curW - g*2, h: s - g*1.5};
                split(list.slice(1), x, y + s, curW, s, !vert);
            }
        }
        split(wins, 0, 0, w, h, true);
        return results;
    }

    // 1. Invisible Background (Close on click)
    Item {
        anchors.fill: parent
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.overviewOpen = false
        }
    }
    
    // 2. The Solid Overview Panel
    Rectangle {
        id: gridPanel
        anchors.centerIn: parent
        width: gridLayout.contentWidth + 40
        height: gridLayout.contentHeight + 40
        radius: 24
        color: "#161616" // Solid background as requested
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        
        // --- Grid of Workspaces ---
        Grid {
            id: gridLayout
            anchors.centerIn: parent
            columns: root.columns
            rows: root.rows
            spacing: root.spacing
            
            // Content dimensions for the parent container
            readonly property real contentWidth: (root.wsWidth * columns) + (spacing * (columns - 1))
            readonly property real contentHeight: (root.wsHeight * rows) + (spacing * (rows - 1))
            
            Repeater {
                model: root.maxWorkspaces
                
                delegate: Rectangle {
                    id: wsCard
                    readonly property int wsId: index + 1
                    readonly property bool isActive: HyprlandData.activeWorkspace?.id === wsId
                    
                    width: root.wsWidth
                    height: root.wsHeight
                    radius: 12
                    color: isActive ? Qt.rgba(Appearance.m3colors.m3primary.r, Appearance.m3colors.m3primary.g, Appearance.m3colors.m3primary.b, 0.15) : "#1f1f1f"
                    border.width: isActive ? 2 : 1
                    border.color: isActive ? Appearance.m3colors.m3primary : Qt.rgba(1, 1, 1, 0.08)
                    
                    // Workspace ID Label
                    Text {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 10
                        text: wsId
                        color: "white"
                        opacity: 0.4
                        font.pixelSize: 14
                        font.weight: Font.Black
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Hyprland.dispatch(`workspace ${wsId}`)
                            GlobalStates.overviewOpen = false
                        }
                    }

                    // --- Drop Detection ---
                    DropArea {
                        anchors.fill: parent
                        keys: ["window"]
                        onEntered: root.draggingTargetWorkspace = wsId
                        onExited: {
                            if (root.draggingTargetWorkspace === wsId) 
                                root.draggingTargetWorkspace = -1
                        }
                        
                        // Active Drop Highlight
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Appearance.m3colors.m3primary
                            opacity: 0.15
                            visible: root.draggingTargetWorkspace === wsId
                        }
                    }
                }
            }
        }
        
        // --- Windows Overlay Layer ---
        Item {
            id: windowsLayer
            anchors.fill: gridLayout // Same coordinate space as the grid
            
            Repeater {
                // Use ToplevelManager for reliable per-window surfaces
                model: ToplevelManager.toplevels.values
                
                delegate: OverviewWindow {
                    id: overviewWindow
                    readonly property var hyprWin: {
                        if (!modelData.HyprlandToplevel) return null;
                        const addr = "0x" + modelData.HyprlandToplevel.address.toLowerCase();
                        return HyprlandData.windowByAddress[addr] || null;
                    }
                    
                    // Display filter
                    visible: hyprWin && hyprWin.workspace.id >= 1 && hyprWin.workspace.id <= root.maxWorkspaces
                    
                    windowData: hyprWin
                    toplevel: modelData
                    overviewRoot: root
                    
                    // Grid Alignment
                    readonly property int wsId: hyprWin ? hyprWin.workspace.id : 1
                    readonly property int col: (wsId - 1) % root.columns
                    readonly property int row: Math.floor((wsId - 1) / root.columns)
                    
                    readonly property real slotX: col * (root.wsWidth + root.spacing)
                    readonly property real slotY: row * (root.wsHeight + root.spacing)
                    
                    // --- Dwindle Layout Application ---
                    readonly property var layoutObj: root.workspaceLayouts[wsId]?.[hyprWin.address] || null
                    
                    Binding on x {
                        when: !overviewWindow.pressed
                        value: slotX + (layoutObj ? layoutObj.x : 0)
                    }

                    Binding on y {
                        when: !overviewWindow.pressed
                        value: slotY + (layoutObj ? layoutObj.y : 0)
                    }
                    
                    Binding on targetWidth {
                        when: !overviewWindow.pressed
                        value: layoutObj ? layoutObj.w : (hyprWin ? hyprWin.size[0] * root.workspaceScale : 100)
                    }
                    
                    Binding on targetHeight {
                        when: !overviewWindow.pressed
                        value: layoutObj ? layoutObj.h : (hyprWin ? hyprWin.size[1] * root.workspaceScale : 100)
                    }
                }
            }
        }
    }
}
