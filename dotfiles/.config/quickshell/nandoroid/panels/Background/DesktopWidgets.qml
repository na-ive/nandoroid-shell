pragma ComponentBehavior: Bound

import "../../core"
import "../../services"
import "../../widgets"
import "../../widgets/widgetCanvas"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Desktop Widgets Panel.
 * Contains the clock and visualizer on a separate layer above the wallpaper.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: widgetRoot
        required property var modelData
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "quickshell:desktop-widgets"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"
        visible: !GlobalStates.screenLocked && !forceHideTimer.running

        // Mouse region masking: Only capture input when desktop is empty
        mask: Region {
            item: widgetRoot.isDesktopEmpty ? gestureArea : null
        }

        Timer {
            id: forceHideTimer
            interval: 100
            repeat: false
        }

        function forceTop() {
            forceHideTimer.restart();
        }

        Timer {
            id: delayedRefreshTimer
            interval: 2500 // 2.5 seconds - enough for wallpaper engine to init
            repeat: false
            onTriggered: widgetRoot.forceTop()
        }

        Connections {
            target: WallpaperEngineService
            function onIsRunningChanged() { 
                if (WallpaperEngineService.isRunning) {
                    delayedRefreshTimer.restart();
                }
            }
            
            // Also refresh when Matugen finishes (screenshot version increases)
            function onScreenshotVersionChanged() {
                widgetRoot.forceTop();
            }
        }

        // Centralized desktop state tracking
        readonly property bool isDesktopEmpty: {
            if (!Config.ready || GlobalStates.screenLocked) return false;
            
            let currentWsId = HyprlandData.activeWorkspace ? HyprlandData.activeWorkspace.id : -1;
            let windowsOnWs = HyprlandData.hyprlandClientsForWorkspace(currentWsId);
            
            // Ignore wallpaper engine and other shell-related windows
            const ignoreClasses = ["linux-wallpaperengine", "Quickshell", "waybar", "ags", "fuzzel", "com.github.casainho.linux-wallpaperengine"];
            const ignoreTitles = ["linux-wallpaperengine", "Wallpaper Engine"];
            
            let realWindows = windowsOnWs.filter(win => {
                if (!win.mapped || win.class === "") return false;
                if (ignoreClasses.includes(win.class)) return false;
                if (ignoreTitles.some(t => win.title.includes(t))) return false;
                return true;
            });
            
            return realWindows.length === 0;
        }

        // Mouse interaction for the desktop
        MouseArea {
            id: gestureArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property int startY: 0
            property bool isDragging: false
            
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton && widgetRoot.isDesktopEmpty) {
                    desktopContextMenu.openAt(mouse.x, mouse.y, false);
                    mouse.accepted = true;
                    return;
                }
                if (mouse.button === Qt.LeftButton) desktopContextMenu.close();
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
            onReleased: { isDragging = false; }
        }

        WaveVisualizer {
            id: desktopWave
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.4
            z: 5
            color: Appearance.m3colors.m3primary
            opacityMultiplier: Config.options.appearance.background.cavaOpacity
            
            readonly property bool shouldVisualize: {
                if (!Config.ready || !Config.options.appearance.background.showCava) return false;
                return widgetRoot.isDesktopEmpty && MprisController.isPlaying;
            }

            opacity: shouldVisualize ? 1.0 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }

            // Manage CavaService reference counting
            onShouldVisualizeChanged: {
                if (shouldVisualize) {
                    CavaService.refCount++;
                } else {
                    CavaService.refCount--;
                }
            }

            Component.onDestruction: {
                if (shouldVisualize) CavaService.refCount--;
            }
        }

        WidgetCanvas {
            id: widgetCanvas
            anchors.fill: parent
            z: 9
            gridSize: 24

            AbstractWidget {
                id: clockWrapper
                z: 10
                width: nandoClockItem.width
                height: nandoClockItem.height
                gridSize: 24
                draggable: Config.ready ? !Config.options.appearance.clock.locked : true

                property real targetX: (Config.ready && Config.options.appearance.clock.desktopX !== -1) ? Config.options.appearance.clock.desktopX : (parent.width - width) / 2
                property real targetY: (Config.ready && Config.options.appearance.clock.desktopY !== -1) ? Config.options.appearance.clock.desktopY : (parent.height - height) / 2
                
                x: targetX
                y: targetY

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.clock.desktopX = newX;
                        Config.options.appearance.clock.desktopY = newY;
                    }
                }

                opacity: (!GlobalStates.screenLocked && nandoClockItem.visible) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                NandoClock {
                    id: nandoClockItem
                    isLockscreen: false
                    interactive: true
                    onRequestContextMenu: (x, y, isClock) => {
                        desktopContextMenu.openAt(x, y, isClock);
                    }
                }
            }
        }

        DesktopContextMenu {
            id: desktopContextMenu
            screen: widgetRoot.modelData
            visible: false
        }

        Connections {
            target: HyprlandData
            function onActiveWorkspaceChanged() {
                desktopContextMenu.close();
            }
        }
    }
}
