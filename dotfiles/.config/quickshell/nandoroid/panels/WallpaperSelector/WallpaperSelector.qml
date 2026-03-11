import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Loader {
        id: panelLoader
        active: GlobalStates.wallpaperSelectorOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            screen: Quickshell.screens[0]
            exclusiveZone: 0
            WlrLayershell.namespace: "nandoroid:wallpaperselector"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            implicitWidth: 1100
            implicitHeight: 800

            Component.onCompleted: GlobalStates.wallpaperSelectorWindow = panelWindow
            Component.onDestruction: GlobalStates.wallpaperSelectorWindow = null

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

            // HyprlandFocusGrab removed in favor of full-screen MouseArea logic
            // similar to Settings and QuickWallpaper for better concurrency.

            WallpaperSelectorContent {
                id: content
                width: 1100
                height: 800
                anchors.centerIn: parent
                onClosed: {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }
        }
    }
}
