import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"

Scope {
    id: root
    property string protectionMessage: ""
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

    property string currentIndicator: "volume"
    property var indicators: [
        {
            id: "volume",
            sourceUrl: "indicators/VolumeIndicator.qml"
        },
        {
            id: "brightness",
            sourceUrl: "indicators/BrightnessIndicator.qml"
        },
        {
            id: "playerVolume",
            sourceUrl: "indicators/PlayerVolumeIndicator.qml"
        },
        {
            id: "charging",
            sourceUrl: "indicators/ChargingIndicator.qml"
        },
        {
            id: "powerMode",
            sourceUrl: "indicators/PowerModeIndicator.qml"
        },
        {
            id: "conservation",
            sourceUrl: "indicators/ConservationIndicator.qml"
        },
    ]

    function triggerOsd() {
        // GlobalStates might not exist, using internal visible prop or similar if needed.
        // But let's assume GlobalStates or similar. 
        // Wait, user used "root.visible" in previous OSD. 
        // Let's use "osdOpen" property on root? 
        // Or if GlobalStates is available (it was imported in example).
        // I don't see GlobalStates in my file list. I'll use local property.
        
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

    Connections {
        target: Brightness
        function onBrightnessUpdated() {
            root.protectionMessage = "";
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }
    }

    Connections {
        // Listen to volume changes
        target: Audio.sink && Audio.sink.audio ? Audio.sink.audio : null
        function onVolumeChanged() {
            // console.log("DEBUG: Volume " + Audio.sink.audio.volume)
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
            root.protectionMessage = "";
            root.currentIndicator = "charging";
            root.triggerOsd();
        }
    }

    Connections {
        target: PowerProfileService
        function onCurrentProfileChanged() {
            root.protectionMessage = "";
            root.currentIndicator = "powerMode";
            root.triggerOsd();
        }
    }

    Connections {
        target: ConservationMode
        function onActiveChanged() {
            root.protectionMessage = "";
            root.currentIndicator = "conservation";
            root.triggerOsd();
        }
    }

    Loader {
        id: osdLoader
        active: false // Default hidden

        sourceComponent: PanelWindow {
            id: osdRoot
            color: "transparent"

            Connections {
                target: root
                function onFocusedScreenChanged() {
                    osdRoot.screen = root.focusedScreen;
                }
            }

            WlrLayershell.namespace: "quickshell:osd"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: -1 // Explicitly floating
            
            // Ensure no full-width anchoring
            anchors {
                bottom: true
            }
            margins {
                bottom: 60 // Closer to bottom
            }

            // Implicit width/height from content
            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight
            visible: osdLoader.active

            ColumnLayout {
                id: columnLayout
                anchors.centerIn: parent

                Item {
                    id: osdValuesWrapper
                    // Extra space for shadow
                    implicitHeight: contentColumnLayout.implicitHeight
                    implicitWidth: contentColumnLayout.implicitWidth
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: osdLoader.active = false
                    }

                    Column {
                        id: contentColumnLayout
                        anchors.centerIn: parent
                        spacing: 0

                        Loader {
                            id: osdIndicatorLoader
                            source: root.indicators.find(i => i.id === root.currentIndicator)?.sourceUrl
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osd"

        function showBrightness() {
            root.currentIndicator = "brightness";
            root.triggerOsd();
        }

        function showVolume() {
            root.currentIndicator = "volume";
            root.triggerOsd();
        }
    }
}
