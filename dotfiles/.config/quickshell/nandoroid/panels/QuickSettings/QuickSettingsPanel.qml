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
    readonly property bool isOpen: GlobalStates.quickSettingsOpen && isActive

    visible: isOpen || closeTimer.running

    exclusiveZone: 0
    WlrLayershell.namespace: "nandoroid:quick-settings"
    WlrLayershell.layer: isOpen || closeTimer.running ? WlrLayer.Overlay : WlrLayer.Background
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors.top: true
    anchors.right: true

    readonly property bool isCentered: GlobalStates.isCenteredStatusbar
    readonly property real centeredWidth: Config.ready && Config.options.statusBar
      ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200
    readonly property real sidePadding: isCentered
      ? Math.round((modelData.width - Math.min(centeredWidth, modelData.width - 40 * Appearance.effectiveScale)) / 2)
      : 0

    margins.right: panelWindow.sidePadding
    implicitWidth: Appearance.sizes.quickSettingsWidth
    implicitHeight: Math.round(modelData.height * 0.85)

    Timer { id: closeTimer; interval: 300 }

    onIsOpenChanged: {
      if (isOpen) {
        GlobalFocusGrab.addDismissable(panelWindow);
      } else {
        GlobalFocusGrab.removeDismissable(panelWindow);
        GlobalStates.quickSettingsEditMode = false;
        closeTimer.restart();
      }
    }

    Connections {
      target: GlobalFocusGrab
      function onDismissed() {
        GlobalStates.quickSettingsOpen = false;
        GlobalStates.quickSettingsEditMode = false;
      }
    }

    MouseArea {
      anchors.top: qsContent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      onClicked: if (panelWindow.isOpen) GlobalFocusGrab.dismiss()
    }

    QuickSettingsContent {
      id: qsContent
      height: implicitHeight

      transform: Translate {
        id: qsSlide
        x: panelWindow.isOpen ? 0 : (panelWindow.isCentered ? 0 : qsContent.width + 40 * Appearance.effectiveScale)
        y: panelWindow.isOpen ? 0 : (panelWindow.isCentered ? -qsContent.height - 40 * Appearance.effectiveScale : 0)
        Behavior on x {
          NumberAnimation { duration: 280; easing.bezierCurve: Appearance.animationCurves.standard }
        }
        Behavior on y {
          NumberAnimation { duration: 280; easing.bezierCurve: Appearance.animationCurves.standard }
        }
      }

      opacity: panelWindow.isOpen ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 280 } }

      onClosed: {
        GlobalStates.quickSettingsOpen = false;
        GlobalStates.quickSettingsEditMode = false;
      }
    }
  }
}
