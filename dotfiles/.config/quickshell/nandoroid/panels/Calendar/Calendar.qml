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
            left: true
            right: true
        }
        margins.top: Appearance.sizes.statusBarHeight + 6

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
            // Explicit centering — anchors.horizontalCenter unreliable with WlrLayershell
            x: Math.round((parent.width - width) / 2)
            y: 0
            width: Appearance.sizes.dashboardWidth
            height: parent.height
            active: GlobalStates.calendarOpen
            sourceComponent: CalendarContent {
                onClosed: {
                    GlobalStates.calendarOpen = false;
                }
            }
        }
    }
}
