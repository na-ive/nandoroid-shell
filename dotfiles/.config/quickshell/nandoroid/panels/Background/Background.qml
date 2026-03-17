pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Background panel.
 * Draws the wallpaper and optionally clock/weather on the bottommost layer.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot
        required property var modelData

        // Basic positioning
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Color handling
        color: Appearance.colors.colLayer0


        // Desktop status tracking
        readonly property bool isDesktopEmpty: {
            if (!Config.ready || GlobalStates.screenLocked || GlobalStates.launcherOpen) return false;
            let currentWsId = HyprlandData.activeWorkspace ? HyprlandData.activeWorkspace.id : -1;
            let windowsOnWs = HyprlandData.hyprlandClientsForWorkspace(currentWsId);
            return windowsOnWs.length === 0;
        }

        // Auto-dismiss on workspace change
        Connections {
            target: HyprlandData
            function onActiveWorkspaceChanged() {
                desktopContextMenu.close();
            }
        }

        // Simplified polished cross-fade logic
        property string currentPath: (Config.ready && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.wallpaperPath) ? Config.options.appearance.background.wallpaperPath : ""
        
        // Random Transition Logic
        property string currentTransitionMode: "fade"
        readonly property var transitionModes: ["fade", "zoomIn", "zoomOut", "slideUp", "slideDown", "slideLeft", "slideRight"]

        onCurrentPathChanged: {
            if (currentPath === "" || currentPath === undefined) return;
            
            // Pick a random transition mode
            currentTransitionMode = transitionModes[Math.floor(Math.random() * transitionModes.length)];

            if (wallpaper1.visible) {
                wallpaper2.source = currentPath;
                if (wallpaper2.status === Image.Ready) transAnim2.restart();
                else {
                    const conn = (status) => {
                        if (wallpaper2.status === Image.Ready) {
                            transAnim2.restart();
                            wallpaper2.statusChanged.disconnect(conn);
                        }
                    }
                    wallpaper2.statusChanged.connect(conn);
                }
            } else {
                wallpaper1.source = currentPath;
                if (wallpaper1.status === Image.Ready) transAnim1.restart();
                else {
                    const conn = (status) => {
                        if (wallpaper1.status === Image.Ready) {
                            transAnim1.restart();
                            wallpaper1.statusChanged.disconnect(conn);
                        }
                    }
                    wallpaper1.statusChanged.connect(conn);
                }
            }
        }

        // --- Wallpaper Layers ---
        Image {
            id: wallpaper1
            width: bgRoot.width
            height: bgRoot.height
            source: bgRoot.currentPath
            fillMode: Image.PreserveAspectCrop
            visible: true
            z: 1
            opacity: 1
            scale: 1.0
            transformOrigin: Item.Center
        }

        Image {
            id: wallpaper2
            width: bgRoot.width
            height: bgRoot.height
            fillMode: Image.PreserveAspectCrop
            visible: false
            z: 1
            opacity: 0
            scale: 1.0
            transformOrigin: Item.Center
        }

        // --- Polished Transitions (Randomized & Optimized) ---
        SequentialAnimation {
            id: transAnim1
            ScriptAction { 
                script: { 
                    wallpaper1.visible = true; wallpaper1.z = 2; wallpaper2.z = 1; 
                    wallpaper1.x = 0; wallpaper1.y = 0;
                } 
            }
            ParallelAnimation {
                NumberAnimation { target: wallpaper1; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
                NumberAnimation { 
                    target: wallpaper1; property: "scale"
                    from: currentTransitionMode === "zoomIn" ? 0.9 : (currentTransitionMode === "zoomOut" ? 1.1 : 1.0)
                    to: 1.0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper1; property: "y"
                    from: currentTransitionMode === "slideUp" ? (bgRoot.height * 0.15) : (currentTransitionMode === "slideDown" ? -(bgRoot.height * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper1; property: "x"
                    from: currentTransitionMode === "slideLeft" ? (bgRoot.width * 0.15) : (currentTransitionMode === "slideRight" ? -(bgRoot.width * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
            }
            ScriptAction { script: { wallpaper2.visible = false; wallpaper2.opacity = 0; wallpaper2.scale = 1.0; wallpaper2.x = 0; wallpaper2.y = 0; } }
        }

        SequentialAnimation {
            id: transAnim2
            ScriptAction { 
                script: { 
                    wallpaper2.visible = true; wallpaper2.z = 2; wallpaper1.z = 1; 
                    wallpaper2.x = 0; wallpaper2.y = 0;
                } 
            }
            ParallelAnimation {
                NumberAnimation { target: wallpaper2; property: "opacity"; from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic }
                NumberAnimation { 
                    target: wallpaper2; property: "scale"
                    from: currentTransitionMode === "zoomIn" ? 0.9 : (currentTransitionMode === "zoomOut" ? 1.1 : 1.0)
                    to: 1.0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper2; property: "y"
                    from: currentTransitionMode === "slideUp" ? (bgRoot.height * 0.15) : (currentTransitionMode === "slideDown" ? -(bgRoot.height * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
                NumberAnimation { 
                    target: wallpaper2; property: "x"
                    from: currentTransitionMode === "slideLeft" ? (bgRoot.width * 0.15) : (currentTransitionMode === "slideRight" ? -(bgRoot.width * 0.15) : 0)
                    to: 0; duration: 700; easing.type: Easing.OutExpo 
                }
            }
            ScriptAction { script: { wallpaper1.visible = false; wallpaper1.opacity = 0; wallpaper1.scale = 1.0; wallpaper1.x = 0; wallpaper1.y = 0; } }
        }

        Rectangle {
            id: overlay
            anchors.fill: parent
            color: "black"
            opacity: GlobalStates.screenLocked ? 0.3 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        // Swipe-up gesture area - BELOW clock (z: 0)
        MouseArea {
            id: gestureArea
            anchors.fill: parent
            hoverEnabled: true
            z: 0
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property int startY: 0
            property bool isDragging: false

            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton && bgRoot.isDesktopEmpty) {
                    desktopContextMenu.anchor.window = bgRoot;
                    desktopContextMenu.openAt(mouse.x, mouse.y, false);
                    mouse.accepted = true;
                    return;
                }

                if (mouse.button === Qt.LeftButton) {
                    desktopContextMenu.close();
                }

                startY = mouse.y;
                isDragging = true;
            }

            onPositionChanged: (mouse) => {
                if (isDragging) {
                    let deltaY = startY - mouse.y;
                    if (deltaY > 100) {
                        isDragging = false;
                        GlobalStates.launcherOpen = true;
                    }
                }
            }

            onReleased: {
                isDragging = false;
            }
        }

        // Clock is placed directly in PanelWindow, ABOVE gestureArea (z: 10)
        NandoClock {
            z: 10
            isLockscreen: false
            interactive: true // Always interactive for clock menu
            opacity: (!GlobalStates.screenLocked && visible) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            onRequestContextMenu: (x, y, isClock) => {
                desktopContextMenu.anchor.window = bgRoot;
                desktopContextMenu.openAt(x, y, isClock);
            }
        }

        DesktopContextMenu {
            id: desktopContextMenu
            visible: false
            anchor.edges: Edges.Top | Edges.Left
        }
    }
}
