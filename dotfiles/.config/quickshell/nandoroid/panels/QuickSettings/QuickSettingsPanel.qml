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

    // QS selalu floating: inset 4px atas + sisi. Di centered mode bar
    // tidak menyentuh corner layar, jadi sisi tidak perlu inset.
    readonly property real floatGap: 4 * Appearance.effectiveScale
    readonly property real topGap: panelWindow.floatGap

    margins.top: panelWindow.topGap
    margins.right: panelWindow.sidePadding + (panelWindow.isCentered ? 0 : panelWindow.floatGap)
    implicitWidth: Appearance.sizes.quickSettingsWidth
    implicitHeight: modelData.height - panelWindow.topGap

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
        x: 0
        y: panelWindow.isOpen ? 0 : -qsContent.height - 40 * Appearance.effectiveScale
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
