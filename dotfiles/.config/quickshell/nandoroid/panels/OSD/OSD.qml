import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"

/**
 * Refactored OSD (On-Screen Display) for v1.1
 * Horizontal Mode inspired by Android 16 (Material 3 Expressive).
 * Positioned bottom-center of the screen.
 */
Scope {
    id: root
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    property string currentIndicator: "volume"
    property bool ready: false

    Timer {
        interval: 2500
        running: true
        repeat: false
        onTriggered: root.ready = true
    }

    property var indicators: [
        { id: "volume",         sourceUrl: "indicators/VolumeIndicator.qml" },
        { id: "brightness",     sourceUrl: "indicators/BrightnessIndicator.qml" },
        { id: "playerVolume",   sourceUrl: "indicators/PlayerVolumeIndicator.qml" },
        { id: "charging",       sourceUrl: "indicators/ChargingIndicator.qml" },
        { id: "powerMode",      sourceUrl: "indicators/PowerModeIndicator.qml" },
        { id: "conservation",   sourceUrl: "indicators/ConservationIndicator.qml" },
        { id: "layout",         sourceUrl: "indicators/LayoutIndicator.qml" },
        { id: "microphone",     sourceUrl: "indicators/MicrophoneIndicator.qml" },
    ]

    readonly property bool isPcIslandActive: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "pcIsland"
    // Fullscreen detection: if any window on active workspace is fullscreen
    readonly property bool hasFullscreen: {
        if (!Hyprland.focusedMonitor || !Hyprland.focusedMonitor.activeWorkspace) return false
        const wsId = Hyprland.focusedMonitor.activeWorkspace.id
        return HyprlandData.windowList.some(w => w.workspace.id === wsId && w.fullscreen)
    }

    function triggerOsd() {
        if (!root.ready) return;
        // Bridge to PcIsland when bar visible, otherwise show floating OSD
        if (root.isPcIslandActive && !root.hasFullscreen) {
            GlobalStates.osdIndicatorType = root.currentIndicator
            GlobalStates.osdVolumeOpen = true
            pcIslandOsdTimer.restart()
            return
        }
        osdLoader.active = true;
        osdTimeout.restart();
    }

    Timer {
        id: pcIslandOsdTimer
        interval: (Config.options.osd && Config.options.osd.timeout) ? Config.options.osd.timeout : 2000
        onTriggered: GlobalStates.osdVolumeOpen = false
    }

    Timer {
        id: osdTimeout
        interval: (Config.options.osd && Config.options.osd.timeout) ? Config.options.osd.timeout : 2000
        repeat: false
        running: false
        onTriggered: {
            osdLoader.active = false;
            root.protectionMessage = "";
        }
    }

    // ── Signal Connections ──
    Connections {
        target: Brightness
        function onBrightnessUpdated() {
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }
    }

    Connections {
        target: Hyprsunset
        function onGammaChangeAttempt() {
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }
    }

    Connections {
        target: Audio.sink && Audio.sink.audio ? Audio.sink.audio : null
        function onVolumeChanged() {
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
        function onMutedChanged() {
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
    }

    Connections {
        target: Audio.source && Audio.source.audio ? Audio.source.audio : null
        function onVolumeChanged() {
            // Ignore background volume auto-adjustments from apps like Zoom/Discord/Meet
            if (Privacy.microphoneActive) return;
            root.currentIndicator = "microphone";
            root.triggerOsd();
        }
        function onMutedChanged() {
            root.currentIndicator = "microphone";
            root.triggerOsd();
        }
    }

    Connections {
        target: Battery
        function onIsPluggedInChanged() {
            root.currentIndicator = "charging";
            root.triggerOsd();
        }
    }

    Connections {
        target: PowerProfileService
        function onCurrentProfileChanged() {
            root.currentIndicator = "powerMode";
            root.triggerOsd();
        }
    }

    Connections {
        target: ConservationMode
        enabled: ConservationMode.available
        function onActiveChanged() {
            root.currentIndicator = "conservation";
            root.triggerOsd();
        }
    }

    Connections {
        target: HyprlandData
        function onLayoutChanged() {
            root.currentIndicator = "layout";
            root.triggerOsd();
        }
    }

    // ── OSD Visual Layer ──
    Loader {
        id: osdLoader
        active: false

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            // While locked, show at the top (below the lock statusbar) so it
            // doesn't overlap the lock screen's bottom island.
            anchors {
                bottom: !GlobalStates.screenLocked
                top: GlobalStates.screenLocked
            }
            
            margins {
                bottom: GlobalStates.screenLocked ? 0 : 80 * Appearance.effectiveScale // Android 16 style bottom margin (elevated)
                top: GlobalStates.screenLocked ? Appearance.sizes.statusBarHeightCurrent + 12 * Appearance.effectiveScale : 0
            }

            // Sync screen with Hyprland focus
            screen: root.focusedScreen
            Connections {
                target: root
                function onFocusedScreenChanged() { osdRoot.screen = root.focusedScreen; }
            }

            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: -1 // Floating

            // Window is 40px wider than the OSD pill to provide 'rendering air' and prevent noise
            implicitWidth: osdIndicatorLoader.implicitWidth + (40 * Appearance.effectiveScale)
            implicitHeight: osdIndicatorLoader.implicitHeight + (20 * Appearance.effectiveScale)
            visible: osdLoader.active

            // Animation for appearance
            onVisibleChanged: {
                if (visible) {
                    osdIndicatorLoader.opacity = 0;
                    osdIndicatorLoader.scale = 0.95;
                    contentAnim.restart();
                }
            }

            ParallelAnimation {
                id: contentAnim
                NumberAnimation { target: osdIndicatorLoader; property: "opacity"; from: 0; to: 1; duration: 250; easing.type: Easing.OutQuint }
                NumberAnimation { target: osdIndicatorLoader; property: "scale"; from: 0.95; to: 1; duration: 350; easing.type: Easing.OutQuint }
            }

            Loader {
                id: osdIndicatorLoader
                anchors.centerIn: parent
                source: root.indicators.find(i => i.id === root.currentIndicator)?.sourceUrl
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: osdLoader.active = false // Quick hide on hover
                }
            }
        }
    }

    // ── IPC Handlers ──
    IpcHandler {
        target: "osd"
        function showBrightness() { root.currentIndicator = "brightness"; root.triggerOsd(); }
        function showVolume() { root.currentIndicator = "volume"; root.triggerOsd(); }
    }
}
