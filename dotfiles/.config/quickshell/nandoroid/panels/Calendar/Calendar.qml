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
        visible: GlobalStates.calendarOpen || (contentLoader.item && contentLoader.item.contentOpacity > 0)
        exclusiveZone: 0
        WlrLayershell.namespace: "nandoroid:calendar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        // Full-width, anchored exactly flush to the bottom of the status bar.
        // wlr-layer-shell automatically positions top-anchored surfaces AFTER the
        // StatusBar's exclusiveZone — no explicit margins.top needed.
        anchors {
            top: true
            left: true
            right: true
        }

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
            // Stay active while animation is playing (contentOpacity > 0)
            // so content isn't destroyed before the close animation finishes
            active: GlobalStates.calendarOpen || (item && item.contentOpacity > 0)
            sourceComponent: CalendarContent {
                onClosed: {
                    GlobalStates.calendarOpen = false;
                }
            }
        }
    }
}
