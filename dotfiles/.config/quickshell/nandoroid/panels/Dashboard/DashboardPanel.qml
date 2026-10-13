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
    WlrLayershell.layer: isOpen || closeTimer.running ? WlrLayer.Overlay : WlrLayer.Background
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors.top: true
    anchors.left: true

    // Width follows the content (panel + shoulder pieces) — single source
    // of truth lives in DashboardContent, no duplicated radius math here.
    readonly property real dashWidth: dashContent.implicitWidth
    readonly property real dashHeight: Appearance.sizes.dashboardHeight
    readonly property real centeredX: Math.max(0, Math.round((modelData.width - panelWindow.dashWidth) / 2))

    // Docking mengikuti kontennya sendiri: docking (top=0) hanya saat
    // shoulder ditampilkan (bar base solid, bukan M3 — lih. showShoulders
    // di DashboardContent). Selain itu floating 4px seperti QS/NC.
    // Bind langsung ke showShoulders agar tidak pernah drift lagi.
    margins.top: dashContent.showShoulders ? 0 : 4 * Appearance.effectiveScale
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
      id: dashContent
      onClosed: GlobalStates.dashboardOpen = false
    }
  }
}
