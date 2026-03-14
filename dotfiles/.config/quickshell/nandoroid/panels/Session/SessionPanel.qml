import "../../core"
import "../../core/functions" as Functions
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
    id: root
    model: Quickshell.screens

    delegate: Loader {
        id: panelLoader
        required property var modelData
        active: GlobalStates.sessionOpen && GlobalStates.activeScreen === modelData
        sourceComponent: PanelWindow {
            id: sessionWindow
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nandoroid:session"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"

            // ── Tonal Scrim (Backdrop) ──
            Rectangle {
                id: backdrop
                anchors.fill: parent
                color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.2)
                opacity: GlobalStates.sessionOpen ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuart
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.sessionOpen = false
                }
            }

            // Content centered
            SessionContent {
                anchors.centerIn: parent
            }
        }
    }
}
