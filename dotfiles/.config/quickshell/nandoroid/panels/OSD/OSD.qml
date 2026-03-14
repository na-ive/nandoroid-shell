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
    ]

    function triggerOsd() {
        if (!root.ready) return;
        osdLoader.active = true;
        osdTimeout.restart();
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

            anchors {
                bottom: true
            }
            
            margins {
                bottom: 80 // Android 16 style bottom margin (elevated)
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
            implicitWidth: osdIndicatorLoader.implicitWidth + 40
            implicitHeight: osdIndicatorLoader.implicitHeight + 20
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
