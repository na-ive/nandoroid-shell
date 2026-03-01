import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Calendar panel — positioned top-right, directly below the status bar.
 */
Scope {
    id: root


    PanelWindow {
        id: panelWindow
        visible: GlobalStates.calendarOpen
        exclusiveZone: 0 // Prevent window manager from reserving space for this panel
        WlrLayershell.namespace: "nandoroid:calendar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            left: false
            right: false
        }

        implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

        HyprlandFocusGrab {
            id: focusGrab
            active: panelWindow.visible
            windows: [panelWindow]
            onCleared: {
                GlobalStates.calendarOpen = false
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: GlobalStates.calendarOpen
            sourceComponent: CalendarContent {
                onClosed: {
                    GlobalStates.calendarOpen = false;
                }
            }
        }
    }
}
