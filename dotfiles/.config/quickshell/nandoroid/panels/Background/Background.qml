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
                desktopContextMenu.visible = false;
            }
        }

        Image {
            id: wallpaper
            anchors.fill: parent
            source: (Config.ready && Config.options.appearance?.background?.wallpaperPath) 
                ? Config.options.appearance.background.wallpaperPath 
                : ""
            fillMode: Image.PreserveAspectCrop
            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500 } }
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
                    desktopContextMenu.isClockMenu = false;
                    desktopContextMenu.anchor.window = bgRoot;
                    desktopContextMenu.anchor.rect = Qt.rect(mouse.x, mouse.y, 0, 0);
                    // Repositioning: setting same rect might not trigger move if already visible
                    // but Quickshell popups usually follow strictly. 
                    // To be safe, we could toggle, but user says it's not responsive.
                    // Let's just update and let it move.
                    desktopContextMenu.visible = true;
                    mouse.accepted = true;
                    return;
                }

                if (mouse.button === Qt.LeftButton) {
                    desktopContextMenu.visible = false;
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
                desktopContextMenu.isClockMenu = isClock;
                desktopContextMenu.anchor.window = bgRoot;
                desktopContextMenu.anchor.rect = Qt.rect(x, y, 0, 0);
                desktopContextMenu.visible = true;
            }
        }

        DesktopContextMenu {
            id: desktopContextMenu
            visible: false
            anchor.edges: Edges.Top | Edges.Left
        }
    }
}
