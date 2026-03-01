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

            property int startY: 0
            property bool isDragging: false

            onPressed: (mouse) => {
                let currentWsId = HyprlandData.activeWorkspace ? HyprlandData.activeWorkspace.id : -1;
                let windowsOnWs = HyprlandData.hyprlandClientsForWorkspace(currentWsId);

                if (windowsOnWs.length === 0 && !GlobalStates.launcherOpen && !GlobalStates.screenLocked) {
                    startY = mouse.y;
                    isDragging = true;
                }
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
            opacity: (!GlobalStates.screenLocked && visible) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
    }
}
