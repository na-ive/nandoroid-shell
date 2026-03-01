import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Notification Center panel — slides down from the left side of the status bar.
 * Contains: Media controls, Weather widget, Notification list.
 */
Scope {
    id: root


    PanelWindow {
        id: panelWindow
        visible: GlobalStates.notificationCenterOpen
        exclusiveZone: (Config.options?.panels?.keep_left_sidebar_loaded && GlobalStates.notificationCenterOpen && contentLoader.item) ? contentLoader.item.implicitWidth : 0
        WlrLayershell.namespace: "nandoroid:notificationCenter"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.notificationCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            left: true
        }

        implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

        HyprlandFocusGrab {
            id: focusGrab
            active: panelWindow.visible
            windows: [panelWindow]
            onCleared: {
                if (contentLoader.item) contentLoader.item.close();
                else GlobalStates.notificationCenterOpen = false;
            }
        }

        Connections {
            target: GlobalStates
            function onNotificationCenterOpenChanged() {
                if (!GlobalStates.notificationCenterOpen && contentLoader.item) contentLoader.item.close();
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: GlobalStates.notificationCenterOpen || Config.options?.panels?.keep_left_sidebar_loaded
            sourceComponent: NotificationCenterContent {
                onClosed: {
                    GlobalStates.notificationCenterOpen = false;
                }
            }
        }
    }
}
