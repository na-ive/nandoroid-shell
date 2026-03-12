import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
    id: root
    model: Quickshell.screens

    Loader {
        id: panelLoader
        required property var modelData
        active: GlobalStates.wallpaperSelectorOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            screen: modelData
            exclusiveZone: 0
            WlrLayershell.namespace: "nandoroid:wallpaperselector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.wallpaperSelectorOpen = false
            }

            mask: Region {
                item: content
            }

            WallpaperSelectorContent {
                id: content
                anchors.centerIn: parent
                onClosed: {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }
        }
    }
}
