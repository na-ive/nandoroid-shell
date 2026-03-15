import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import "."

/**
 * Overview Popup Container
 * hosts either the Standard Grid or Scrolling Tape overview layout.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: overviewPopup
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: GlobalStates.overviewOpen && isActive

        anchors {
            top: true; bottom: true; left: true; right: true
        }
        color: "transparent"

        WlrLayershell.layer: (GlobalStates.overviewOpen && isActive) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.keyboardFocus: (GlobalStates.overviewOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        exclusionMode: ExclusionMode.Ignore

        mask: Region {
            item: (GlobalStates.overviewOpen && isActive) ? fullMask : emptyMask
        }

        Item {
            id: fullMask; anchors.fill: parent
            TapHandler { onTapped: GlobalStates.closeAllPanels() }
        }

        Item { id: emptyMask; width: 0; height: 0 }

        HyprlandFocusGrab {
            id: focusGrab
            windows: [overviewPopup]
            active: GlobalStates.overviewOpen && isActive
            onCleared: Qt.callLater(() => { if (GlobalStates.overviewOpen && isActive) GlobalStates.closeAllPanels(); })
        }

        // Tonal Scrim
        Rectangle {
            id: backdrop; anchors.fill: parent
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.2)
            opacity: (GlobalStates.overviewOpen && isActive) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            
            // Close when clicking outside (on the backdrop)
            TapHandler {
                onTapped: GlobalStates.closeAllPanels()
            }
        }

        // Main content
        Item {
            id: mainContainer
            anchors.centerIn: parent
            width: overviewLoader.item ? overviewLoader.item.implicitWidth : 400
            height: overviewLoader.item ? overviewLoader.item.implicitHeight : 300

            opacity: (GlobalStates.overviewOpen && isActive) ? 1 : 0
            scale: (GlobalStates.overviewOpen && isActive) ? 1 : 0.9

            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            // Intercept clicks on the card to prevent backdrop from receiving them
            MouseArea {
                anchors.fill: parent
                onClicked: (mouse) => { /* Intercept and do nothing */ }
            }

            Loader {
                id: overviewLoader
                anchors.centerIn: parent
                active: GlobalStates.overviewOpen && isActive
                sourceComponent: OverviewView { currentScreen: overviewPopup.screen }
            }
        }
    }
}
