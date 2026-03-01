import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Quick Wallpaper panel — positioned top-right, similar to Quick Settings.
 */
Scope {
    id: root

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.quickWallpaperOpen
        WlrLayershell.namespace: "nandoroid:quickwallpaper"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.quickWallpaperOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }


        // Trap clicks on the whole window to close when clicking outside the modal
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.quickWallpaperOpen = false
        }

        implicitWidth: screen.width
        implicitHeight: screen.height

        // HyprlandFocusGrab removed in favor of full-screen MouseArea logic
        // consistent with Settings and WallpaperSelector.

        // Modal Container
        Rectangle {
            id: modalContainer
            width: Math.min(1100, panelWindow.screen.width * 0.85)
            height: Math.min(800, panelWindow.screen.height * 0.8)
            anchors.centerIn: parent
            radius: 28
            color: Appearance.colors.colLayer0
            clip: true
            border.width: 0

            // Trap clicks
            TapHandler {}

            Loader {
                id: contentLoader
                anchors.fill: parent
                active: GlobalStates.quickWallpaperOpen
                sourceComponent: QuickWallpaperContent {
                    onClosed: {
                        GlobalStates.quickWallpaperOpen = false;
                    }
                }
            }
        }
    }
}
