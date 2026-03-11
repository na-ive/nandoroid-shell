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
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        // Keep window mapped as long as it's open OR the panel is still visually fading out
        visible: (GlobalStates.dashboardOpen && isActive) || (content && content.panelOpacity > 0 && isActive)
        exclusiveZone: 0
        WlrLayershell.namespace: "nandoroid:dashboard"
        WlrLayershell.layer: (GlobalStates.dashboardOpen && isActive) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.keyboardFocus: (GlobalStates.dashboardOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        // Full desktop overlay bounds
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Close when clicking the transparent background outside the actual panel
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.dashboardOpen = false
        }

        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.dashboardOpen && isActive
            windows: [panelWindow]
            onCleared: {
                GlobalStates.dashboardOpen = false
            }
        }

        DashboardContent {
            id: content
            anchors.fill: parent
            visible: isActive
            onClosed: {
                GlobalStates.dashboardOpen = false;
            }
        }
    }
}
