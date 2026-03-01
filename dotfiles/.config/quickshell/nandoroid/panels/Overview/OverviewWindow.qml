pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

/**
 * OverviewWindow.qml
 * Visual representation of an individual window in the workspace overview.
 * High visual fidelity with robust 'ii' classic drag & drop logic.
 */
Item {
    id: root
    
    property var windowData: null
    property var toplevel: null
    property var overviewRoot: null
    property real itemScale: (overviewRoot?.workspaceScale || 0.12)
    property bool pressed: false
    property bool hovered: false

    // Dimensions
    property real targetWidth: (windowData?.size[0] || 100) * root.itemScale
    property real targetHeight: (windowData?.size[1] || 100) * root.itemScale
    
    width: targetWidth
    height: targetHeight
    
    // Z-order: bring to top when dragging
    z: root.pressed ? 10000 : (windowData?.focusHistoryID === 0 ? 500 : 1)
    
    // Visual scaling and behaviors
    scale: root.pressed ? 1.05 : (root.hovered ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
    
    // Smooth Resizing
    Behavior on width { enabled: !root.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on height { enabled: !root.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

    // Position transitions (Disabled during drag for precision)
    Behavior on x { enabled: !root.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
    Behavior on y { enabled: !root.pressed; NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }

    // Attached properties for 'ii' drag pattern
    Drag.active: root.pressed
    Drag.source: root
    Drag.keys: ["window"]

    // Windows Body
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 8
        color: "#2a2a2a" // Solid dark
        border.width: root.hovered ? 2 : 1
        border.color: root.hovered ? Appearance.m3colors.m3primary : Qt.rgba(1, 1, 1, 0.2)
        clip: true
        
        // Screencopy Preview
        ScreencopyView {
            id: preview
            anchors.fill: parent
            captureSource: root.toplevel
            live: false
            opacity: 0.95
            visible: !!captureSource && status === ScreencopyView.Ready
        }
        
        // Final fallback if screencopy is totally missing
        Rectangle {
            anchors.fill: parent
            visible: !preview.visible
            color: "#383838"
        }
        
        // Identity Footer
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.min(25, parent.height * 0.45)
            color: Qt.rgba(0, 0, 0, 0.75)
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                spacing: 4
                
                Image {
                    id: iconImg
                    readonly property string resolvedIcon: {
                        if (typeof AppSearch !== "undefined" && root.windowData) {
                            return AppSearch.guessIcon(
                                root.windowData.class, 
                                root.windowData.initialClass, 
                                root.windowData.title
                            );
                        }
                        return "application-x-executable";
                    }
                    source: Quickshell.iconPath(resolvedIcon, "application-x-executable")
                    
                    Layout.preferredWidth: 14 
                    Layout.preferredHeight: 14 
                    sourceSize: Qt.size(32, 32)
                    
                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = Quickshell.iconPath("application-x-executable");
                        }
                    }
                }
                
                Text {
                    text: windowData?.class || "App"
                    Layout.fillWidth: true
                    color: "white"
                    opacity: 0.95
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }
    
    // Interactions
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        
        // Axis-locked dragging disabled to ensure full freedom to drop
        drag.target: root
        drag.threshold: 8
        
        onPressed: (mouse) => {
            root.pressed = true
            // Explicitly set Drag.active for older QML compatibility if needed
            root.Drag.active = true
            root.Drag.source = root
            root.Drag.hotSpot.x = mouse.x
            root.Drag.hotSpot.y = mouse.y
            if (overviewRoot) overviewRoot.draggingWindowAddress = (windowData?.address || "");
        }
        
        onReleased: {
            // Ported 'ii' classic drop trigger logic
            if (overviewRoot && overviewRoot.draggingTargetWorkspace !== -1) {
                const targetWS = overviewRoot.draggingTargetWorkspace;
                const addr = windowData?.address;
                const currentWS = windowData?.workspace.id;
                
                if (addr && targetWS !== currentWS) {
                    Hyprland.dispatch(`movetoworkspacesilent ${targetWS},address:${addr}`);
                    HyprlandData.updateWindowList();
                }
            }
            
            // Clean up state
            root.pressed = false
            root.Drag.active = false
            if (overviewRoot) {
                overviewRoot.draggingTargetWorkspace = -1;
                overviewRoot.draggingWindowAddress = "";
            }
            
            // Re-trigger layout sync
            Qt.callLater(() => HyprlandData.updateWindowList());
        }
        
        onClicked: (event) => {
            if (event.button === Qt.LeftButton) {
                Hyprland.dispatch(`focuswindow address:${root.windowData.address}`)
                GlobalStates.overviewOpen = false
            } else if (event.button === Qt.MiddleButton) {
                Hyprland.dispatch(`closewindow address:${windowData.address}`)
                HyprlandData.updateWindowList()
            }
        }
    }

    // Drag data
    function getWindowAddress() { return windowData?.address; }
}
