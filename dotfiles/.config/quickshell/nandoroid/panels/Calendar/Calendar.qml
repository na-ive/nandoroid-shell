import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Calendar / Dashboard panel.
 * Full-width overlay window (same as StatusBar) — sits directly below the
 * status bar with margins.top = statusBarHeight. The CalendarContent
 * positions itself centred within the full-width window.
 * RoundCorner pieces inside CalendarContent produce the inverted concave
 * shoulder corners that visually fuse the panel to the status bar.
 */
Scope {
    id: root

    PanelWindow {
        id: panelWindow
        // Toggle visibility directly on the window to prevent grabbing background inputs when closed
        visible: GlobalStates.calendarOpen
        exclusiveZone: 0
        WlrLayershell.namespace: "nandoroid:calendar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        // Centered horizontally by wlr-layer-shell when left/right are omitted.
        anchors {
            top: true
        }

        // Implicit width must encompass the panel AND the overhanging shoulder pieces
        implicitWidth: content.implicitWidth

        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.calendarOpen
            windows: [panelWindow]
            onCleared: {
                GlobalStates.calendarOpen = false
            }
        }

        CalendarContent {
            id: content
            anchors.fill: parent
            onClosed: {
                GlobalStates.calendarOpen = false;
            }
        }
    }
}
