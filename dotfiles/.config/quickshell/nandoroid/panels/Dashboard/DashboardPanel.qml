import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: panelWindow
    required property var modelData
    screen: modelData

    readonly property bool isActive: GlobalStates.activeScreen === modelData
    readonly property bool isOpen: GlobalStates.dashboardOpen && isActive

    visible: isOpen || closeTimer.running

    exclusiveZone: 0
    WlrLayershell.namespace: "nandoroid:dashboard"
    WlrLayershell.layer: isOpen ? WlrLayer.Top : WlrLayer.Background
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors.top: true
    anchors.left: true

    readonly property real shoulderRadius: Math.max(1, (Config.ready && Config.options.statusBar
      ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20) * Appearance.effectiveScale)
    readonly property real dashWidth: Appearance.sizes.dashboardWidth + 2 * panelWindow.shoulderRadius
    readonly property real dashHeight: Appearance.sizes.dashboardHeight
    readonly property real centeredX: Math.max(0, Math.round((modelData.width - panelWindow.dashWidth) / 2))

    margins.left: panelWindow.centeredX
    implicitWidth: panelWindow.dashWidth
    implicitHeight: panelWindow.dashHeight

    Timer { id: closeTimer; interval: 400 }

    onIsOpenChanged: {
      if (isOpen) {
        GlobalFocusGrab.addDismissable(panelWindow);
      } else {
        GlobalFocusGrab.removeDismissable(panelWindow);
        closeTimer.restart();
      }
    }

    Connections {
      target: GlobalFocusGrab
      function onDismissed() {
        GlobalStates.dashboardOpen = false;
      }
    }

    DashboardContent {
      onClosed: GlobalStates.dashboardOpen = false
    }
  }
}
