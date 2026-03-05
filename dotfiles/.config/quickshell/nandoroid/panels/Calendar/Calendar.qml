import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Calendar / Dashboard panel — centered below the status bar.
 * Uses only top: true anchor so wlr-layer-shell auto-centers it horizontally.
 */
Scope {
    id: root

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.calendarOpen
        exclusiveZone: 0
        WlrLayershell.namespace: "nandoroid:calendar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        // Only top anchor — wlr-layer-shell auto-centers on x-axis when
        // neither left nor right is anchored, matching the status bar island style
        anchors {
            top: true
            left: false
            right: false
        }
        margins.top: Appearance.sizes.statusBarHeight

        implicitWidth: Appearance.sizes.dashboardWidth
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : Appearance.sizes.dashboardHeight

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
