
import "../../core"
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Connections {
        target: GlobalStates
        function onSessionOpenChanged() {
            if (GlobalStates.sessionOpen) panelLoader.active = true;
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.sessionOpen
        sourceComponent: PanelWindow {
            id: sessionWindow

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

            // Background removed for cleaner look, handled by SessionContent island


            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.sessionOpen = false
            }

            // Content centered
            SessionContent {
                anchors.centerIn: parent

                Connections {
                    target: GlobalStates
                    function onSessionOpenChanged() {
                        if (!GlobalStates.sessionOpen) panelLoader.active = false
                    }
                }
            }
        }
    }
}
