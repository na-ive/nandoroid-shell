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
 * Contains the clock, at a glance, and future widgets on a separate layer above the wallpaper.
 *
 * HOW TO ADD A NEW WIDGET HERE:
 * ---------------------------------------------------------
 * 1. Ensure you have added the config in `core/Config.qml` (see WIDGET CONFIGURATION GUIDE there).
 * 2. Wrap your visual widget in an `AbstractWidget` below.
 * 3. Assign the config: `configObject: Config.ready ? Config.options.appearance.yourWidget : null`
 * 4. Pass the right-click menu: 
 *      onRequestContextMenu: (reqX, reqY) => {
 *          desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.yourWidget, "Title", "Search Keyword");
 *      }
 * 5. Add your visual component inside the wrapper! (No MouseArea needed inside your component).
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
                    desktopContextMenu.openAt(mouse.x, mouse.y, null);
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
                configObject: Config.ready ? Config.options.appearance.clock : null

                property string activeAlign: nandoClockItem.alignment

                property bool _canUpdateAnchor: false
                
                Timer {
                    id: startupAnchorTimer
                    interval: 500
                    running: Config.ready
                    onTriggered: clockWrapper._canUpdateAnchor = true
                }

                onActiveAlignChanged: {
                    if (!Config.ready || !_canUpdateAnchor) return;
                    // Unconditionally update the corresponding anchor coordinate to the current physical position
                    // so that the widget stays exactly in place when the user switches alignments.
                    if (activeAlign === "right") {
                        Config.options.appearance.clock.desktopRightX = x + width;
                    } else if (activeAlign === "center") {
                        Config.options.appearance.clock.desktopCenterX = x + (width / 2);
                    } else if (activeAlign === "left") {
                        Config.options.appearance.clock.desktopX = x;
                    }
                }

                property real targetX: {
                    if (!Config.ready) return (parent.width - width) / 2;
                    
                    if (activeAlign === "right") {
                        if (Config.options.appearance.clock.desktopRightX !== -1) {
                            return Config.options.appearance.clock.desktopRightX - width;
                        }
                    } else if (activeAlign === "center") {
                        if (Config.options.appearance.clock.desktopCenterX !== -1) {
                            return Config.options.appearance.clock.desktopCenterX - (width / 2);
                        }
                    } else {
                        if (Config.options.appearance.clock.desktopX !== -1) {
                            return Config.options.appearance.clock.desktopX;
                        }
                    }
                    
                    return (parent.width - width) / 2;
                }

                property real targetY: (Config.ready && Config.options.appearance.clock.desktopY !== -1) ? Config.options.appearance.clock.desktopY : (parent.height - height) / 2
                
                x: targetX
                y: targetY

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.clock.desktopY = newY;
                        
                        if (activeAlign === "right") {
                            Config.options.appearance.clock.desktopRightX = newX + width;
                        } else if (activeAlign === "center") {
                            Config.options.appearance.clock.desktopCenterX = newX + (width / 2);
                        } else {
                            Config.options.appearance.clock.desktopX = newX;
                        }
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.clock, "Clock", "Clock Style");
                }

                opacity: (!GlobalStates.screenLocked && nandoClockItem.visible) ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                NandoClock {
                    id: nandoClockItem
                    isLockscreen: false
                    interactive: true
                }
            }

            AbstractWidget {
                id: atAGlanceWrapper
                z: 10
                width: atAGlanceItem.width
                height: atAGlanceItem.height
                gridSize: 24
                configObject: Config.ready ? Config.options.appearance.atAGlance : null
                visible: Config.ready && Config.options.appearance.atAGlance.show && !GlobalStates.screenLocked
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                x: Config.ready ? Config.options.appearance.atAGlance.desktopX : 64
                y: Config.ready ? Config.options.appearance.atAGlance.desktopY : 64

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.atAGlance.desktopX = newX;
                        Config.options.appearance.atAGlance.desktopY = newY;
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.atAGlance, "At a Glance", "At a Glance");
                }

                AtAGlance {
                    id: atAGlanceItem
                    interactive: true
                }
            }
        }

        Timer {
            id: reopenTimer
            interval: 150 // Wait for close animation
            property real nextX: 0
            property real nextY: 0
            property var nextConfig: null
            property string nextTitle: ""
            property string nextKeyword: ""
            onTriggered: {
                desktopContextMenu.openAt(nextX, nextY, nextConfig, nextTitle, nextKeyword)
            }
        }

        function handleMenuRelocation(x, y) {
            if (!widgetRoot.isDesktopEmpty) {
                desktopContextMenu.close();
                return;
            }

            let widgetConfig = null;
            let widgetTitle = "";
            let widgetKeyword = "";

            // Check if clock is clicked
            if (clockWrapper.visible && 
                x >= clockWrapper.x && x <= clockWrapper.x + clockWrapper.width &&
                y >= clockWrapper.y && y <= clockWrapper.y + clockWrapper.height) {
                widgetConfig = Config.options.appearance.clock;
                widgetTitle = "Clock";
                widgetKeyword = "Clock Style";
            }
            // Check if at a glance is clicked
            else if (atAGlanceWrapper && atAGlanceWrapper.visible &&
                     x >= atAGlanceWrapper.x && x <= atAGlanceWrapper.x + atAGlanceWrapper.width &&
                     y >= atAGlanceWrapper.y && y <= atAGlanceWrapper.y + atAGlanceWrapper.height) {
                widgetConfig = Config.options.appearance.atAGlance;
                widgetTitle = "At a Glance";
                widgetKeyword = "At a Glance";
            }

            desktopContextMenu.close();
            
            reopenTimer.nextX = x;
            reopenTimer.nextY = y;
            reopenTimer.nextConfig = widgetConfig;
            reopenTimer.nextTitle = widgetTitle;
            reopenTimer.nextKeyword = widgetKeyword;
            reopenTimer.restart();
        }

        DesktopContextMenu {
            id: desktopContextMenu
            screen: widgetRoot.modelData
            visible: false
            
            onBackgroundRightClicked: (x, y) => handleMenuRelocation(x, y)
        }

        Connections {
            target: HyprlandData
            function onActiveWorkspaceChanged() {
                desktopContextMenu.close();
            }
        }
    }
}
