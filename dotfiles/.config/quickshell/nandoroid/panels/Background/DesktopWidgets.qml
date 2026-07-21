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
        WlrLayershell.keyboardFocus: (desktopCurrencyWidgetItem && desktopCurrencyWidgetItem.showingSettings) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        
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

        property bool isWorkspaceChanging: false
        Timer {
            id: wsChangeBlockTimer
            interval: 250
            onTriggered: widgetRoot.isWorkspaceChanging = false
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

        // ── Desktop Visualizer State ──
        readonly property bool _showVisualizer: {
            if (!Config.ready || !Config.options.appearance.background.showCava) return false;
            return MprisController.isPlaying;
        }
        property bool _cavaActive: false
        on_ShowVisualizerChanged: {
            if (_showVisualizer && !_cavaActive) {
                CavaService.refCount++;
                _cavaActive = true;
            } else if (!_showVisualizer && _cavaActive) {
                CavaService.refCount--;
                _cavaActive = false;
            }
        }
        Component.onDestruction: {
            if (_cavaActive) CavaService.refCount--;
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
                if (mouse.button === Qt.RightButton && widgetRoot.isDesktopEmpty && !widgetRoot.isWorkspaceChanging) {
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
            opacity: widgetRoot._showVisualizer ? 1.0 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
        }

        WidgetCanvas {
            id: widgetCanvas
            anchors.fill: parent
            z: 9
            gridSize: Config.ready ? Config.options.appearance.background.gridSpacing : 12
            showGrid: Config.ready ? Config.options.appearance.background.showGrid : false

            AbstractWidget {
                id: clockWrapper
                z: 10
                width: nandoClockItem.width
                height: nandoClockItem.height
                gridSize: 12
                configObject: Config.ready ? Config.options.appearance.clock : null
                
                animateXPos: false
                animateYPos: false

                property string activeAlign: nandoClockItem.alignment
                snapAlign: activeAlign

                property bool _canUpdateAnchor: false
                
                Timer {
                    id: startupAnchorTimer
                    interval: 500
                    running: Config.ready
                    onTriggered: clockWrapper._canUpdateAnchor = true
                }

                Timer {
                    id: convertResetToAnchorTimer
                    interval: 100
                    running: Config.ready && Config.options.appearance.clock.desktopX === -1 && parent.width > 0 && width > 0
                    onTriggered: {
                        let cx = parent.width / 2;
                        let cy = parent.height / 2;
                        Config.options.appearance.clock.desktopX = cx - (width / 2);
                        Config.options.appearance.clock.desktopCenterX = cx;
                        Config.options.appearance.clock.desktopRightX = cx + (width / 2);
                        Config.options.appearance.clock.desktopY = cy - (height / 2);
                        Config.options.appearance.clock.desktopCenterY = cy;
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

                property real targetY: {
                    if (!Config.ready) return (parent.height - height) / 2;
                    if (Config.options.appearance.clock.desktopCenterY !== -1) {
                        return Config.options.appearance.clock.desktopCenterY - (height / 2);
                    }
                    if (Config.options.appearance.clock.desktopY !== -1) {
                        return Config.options.appearance.clock.desktopY;
                    }
                    return (parent.height - height) / 2;
                }
                
                x: targetX
                y: targetY

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.clock.desktopY = newY;
                        Config.options.appearance.clock.desktopCenterY = newY + (height / 2);
                        
                        Config.options.appearance.clock.desktopX = newX;
                        Config.options.appearance.clock.desktopCenterX = newX + (width / 2);
                        Config.options.appearance.clock.desktopRightX = newX + width;
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.clock, "Clock", "Clock Style");
                }

                // Read config directly — avoid circular dep (nandoClockItem.visible depends on clockWrapper.visible)
                readonly property bool shouldShow: !GlobalStates.screenLocked && (!Config.ready || Config.options.appearance.clock.showOnDesktop)
                visible: shouldShow || fadeOutTimer.running
                opacity: shouldShow ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                // Keep visible=true until fade-out animation completes
                Timer {
                    id: fadeOutTimer
                    interval: 300
                    running: false
                }
                onShouldShowChanged: {
                    if (!shouldShow) fadeOutTimer.restart();
                }

                NandoClock {
                    id: nandoClockItem
                    isLockscreen: false
                    interactive: true
                }
                property string childId: "clockWrapper"
            }

            AbstractWidget {
                id: atAGlanceWrapper
                z: 10
                width: atAGlanceItem.width
                height: atAGlanceItem.height
                gridSize: 12
                configObject: Config.ready ? Config.options.appearance.atAGlance : null
                snapAlign: Config.ready ? Config.options.appearance.atAGlance.alignment : "left"
                visible: Config.ready && Config.options.appearance.atAGlance.show && !GlobalStates.screenLocked
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                property string childId: "atAGlanceWrapper"

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
            
            AbstractWidget {
                id: mediaWidgetWrapper
                z: 10
                width: desktopMediaWidgetItem.width
                height: desktopMediaWidgetItem.height
                gridSize: 12
                configObject: Config.ready ? Config.options.appearance.mediaWidget : null
                visible: Config.ready && Config.options.appearance.mediaWidget.showOnDesktop && !GlobalStates.screenLocked
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                property string childId: "mediaWidgetWrapper"

                property real targetX: {
                    if (!Config.ready) return (parent.width - width) / 2;
                    if (Config.options.appearance.mediaWidget.desktopCenterX !== -1) {
                        return Config.options.appearance.mediaWidget.desktopCenterX - (width / 2);
                    }
                    if (Config.options.appearance.mediaWidget.desktopX !== -1) {
                        return Config.options.appearance.mediaWidget.desktopX;
                    }
                    return (parent.width - width) / 2;
                }

                property real targetY: {
                    if (!Config.ready) return (parent.height - height) / 2;
                    if (Config.options.appearance.mediaWidget.desktopCenterY !== -1) {
                        return Config.options.appearance.mediaWidget.desktopCenterY - (height / 2);
                    }
                    if (Config.options.appearance.mediaWidget.desktopY !== -1) {
                        return Config.options.appearance.mediaWidget.desktopY;
                    }
                    return (parent.height - height) / 2;
                }
                
                x: targetX
                y: targetY

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.mediaWidget.desktopY = newY;
                        Config.options.appearance.mediaWidget.desktopCenterY = newY + (height / 2);
                        
                        Config.options.appearance.mediaWidget.desktopX = newX;
                        Config.options.appearance.mediaWidget.desktopCenterX = newX + (width / 2);
                        Config.options.appearance.mediaWidget.desktopRightX = newX + width;
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.mediaWidget, "Media Player", "Media Player");
                }

                DesktopMediaWidget {
                    id: desktopMediaWidgetItem
                }
            }

            AbstractWidget {
                id: systemMonitorWrapper
                z: 10
                width: desktopSystemMonitorWidgetItem.width
                height: desktopSystemMonitorWidgetItem.height
                gridSize: 12
                configObject: Config.ready ? Config.options.appearance.systemMonitor : null
                visible: Config.ready && Config.options.appearance.systemMonitor.showOnDesktop && !GlobalStates.screenLocked
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                property string childId: "systemMonitorWrapper"

                x: Config.ready && Config.options.appearance.systemMonitor.desktopX !== -1 ? Config.options.appearance.systemMonitor.desktopX : 64
                y: Config.ready && Config.options.appearance.systemMonitor.desktopY !== -1 ? Config.options.appearance.systemMonitor.desktopY : 300

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.systemMonitor.desktopX = newX;
                        Config.options.appearance.systemMonitor.desktopY = newY;
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.systemMonitor, "System Monitor", "System Monitor");
                }

                 DesktopSystemMonitorWidget {
                    id: desktopSystemMonitorWidgetItem
                }
            }

            AbstractWidget {
                id: weatherWidgetWrapper
                z: 10
                width: desktopWeatherWidgetItem.width
                height: desktopWeatherWidgetItem.height
                gridSize: 12
                configObject: Config.ready ? Config.options.appearance.weatherWidget : null
                visible: Config.ready
                    && (Config.options.weather?.enable ?? true)
                    && Config.options.appearance.weatherWidget.showOnDesktop
                    && !GlobalStates.screenLocked
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                property string childId: "weatherWidgetWrapper"

                x: Config.ready && Config.options.appearance.weatherWidget.desktopX !== -1 ? Config.options.appearance.weatherWidget.desktopX : 64
                y: Config.ready && Config.options.appearance.weatherWidget.desktopY !== -1 ? Config.options.appearance.weatherWidget.desktopY : 420

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.weatherWidget.desktopX = newX;
                        Config.options.appearance.weatherWidget.desktopY = newY;
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.weatherWidget, "Weather", "Weather");
                }

                DesktopWeatherWidget {
                    id: desktopWeatherWidgetItem
                    interactive: !weatherWidgetWrapper.dragging
                }
            }

            AbstractWidget {
                id: currencyWidgetWrapper
                z: 10
                width: desktopCurrencyWidgetItem.width
                height: desktopCurrencyWidgetItem.height
                gridSize: 12
                configObject: Config.ready ? Config.options.appearance.currencyWidget : null
                visible: Config.ready && Config.options.appearance.currencyWidget.showOnDesktop && !GlobalStates.screenLocked
                opacity: visible ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                property string childId: "currencyWidgetWrapper"

                x: Config.ready && Config.options.appearance.currencyWidget.desktopX !== -1 ? Config.options.appearance.currencyWidget.desktopX : 64
                y: Config.ready && Config.options.appearance.currencyWidget.desktopY !== -1 ? Config.options.appearance.currencyWidget.desktopY : 540

                onDragFinished: (newX, newY) => {
                    if (Config.ready) {
                        Config.options.appearance.currencyWidget.desktopX = newX;
                        Config.options.appearance.currencyWidget.desktopY = newY;
                    }
                }

                onRequestContextMenu: (reqX, reqY) => {
                    desktopContextMenu.openAt(reqX, reqY, Config.options.appearance.currencyWidget, "Currency", "Currency");
                }

                DesktopCurrencyWidget {
                    id: desktopCurrencyWidgetItem
                    interactive: !currencyWidgetWrapper.dragging
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
            // Check if media widget is clicked
            else if (mediaWidgetWrapper && mediaWidgetWrapper.visible &&
                     x >= mediaWidgetWrapper.x && x <= mediaWidgetWrapper.x + mediaWidgetWrapper.width &&
                     y >= mediaWidgetWrapper.y && y <= mediaWidgetWrapper.y + mediaWidgetWrapper.height) {
                widgetConfig = Config.options.appearance.mediaWidget;
                widgetTitle = "Media Player";
                widgetKeyword = "Media Player";
            }
            // Check if system monitor widget is clicked
            else if (systemMonitorWrapper && systemMonitorWrapper.visible &&
                     x >= systemMonitorWrapper.x && x <= systemMonitorWrapper.x + systemMonitorWrapper.width &&
                     y >= systemMonitorWrapper.y && y <= systemMonitorWrapper.y + systemMonitorWrapper.height) {
                widgetConfig = Config.options.appearance.systemMonitor;
                widgetTitle = "System Monitor";
                widgetKeyword = "System Monitor";
            }
            // Check if weather widget is clicked
            else if (weatherWidgetWrapper && weatherWidgetWrapper.visible &&
                     x >= weatherWidgetWrapper.x && x <= weatherWidgetWrapper.x + weatherWidgetWrapper.width &&
                     y >= weatherWidgetWrapper.y && y <= weatherWidgetWrapper.y + weatherWidgetWrapper.height) {
                widgetConfig = Config.options.appearance.weatherWidget;
                widgetTitle = "Weather";
                widgetKeyword = "Weather";
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
                widgetRoot.isWorkspaceChanging = true;
                wsChangeBlockTimer.restart();
                desktopContextMenu.close();
            }
        }
    }
}
