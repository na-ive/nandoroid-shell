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
    readonly property bool isOpen: GlobalStates.quickActionsOpen && isActive

    visible: isOpen || closeTimer.running

    exclusiveZone: 0
    WlrLayershell.namespace: "nandoroid:quick-actions"
    WlrLayershell.layer: isOpen ? WlrLayer.Top : WlrLayer.Background
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 72 * Appearance.effectiveScale

    Timer { id: closeTimer; interval: 300 }

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
        GlobalStates.quickActionsOpen = false;
      }
    }

    QuickActionsContent {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: panelWindow.isOpen ? 0 : -implicitHeight
      opacity: panelWindow.isOpen ? 1 : 0

      Behavior on anchors.bottomMargin {
        NumberAnimation { duration: 300; easing.bezierCurve: Appearance.animationCurves.emphasizedDecel }
      }
      Behavior on opacity {
        NumberAnimation { duration: 200 }
      }

      onClosed: GlobalStates.quickActionsOpen = false
    }
  }
}
