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
 * Centered below the status bar, visually fused with it via RoundCorner
 * concave corner pieces at the top-left and top-right edges.
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

        // Anchor to LEFT only — then use margins.left to offset from
        // the left edge by (screenWidth - dashboardWidth) / 2, centering it.
        anchors {
            top: true
            left: true
            right: false
        }
        margins.top: Appearance.sizes.statusBarHeight
        margins.left: Math.max(0, Math.round((screen.width - Appearance.sizes.dashboardWidth) / 2))

        implicitWidth: Appearance.sizes.dashboardWidth
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : Appearance.sizes.dashboardHeight

        // ── Concave top corners (RoundCorner) that "fuse" the panel with the statusbar ──
        // These sit ABOVE the panel (negative y) to draw the inverse-corner fill
        // using the statusbar background color
        RoundCorner {
            id: tlCorner
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: -implicitSize
            implicitSize: Appearance.rounding.large
            corner: RoundCorner.CornerEnum.BottomLeft
            color: Appearance.colors.colStatusBarSolid
        }
        RoundCorner {
            id: trCorner
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -implicitSize
            implicitSize: Appearance.rounding.large
            corner: RoundCorner.CornerEnum.BottomRight
            color: Appearance.colors.colStatusBarSolid
        }

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
