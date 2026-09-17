import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../core"
import "../../../services"
import "../../../widgets"

RowLayout {
    id: diOsdRoot
    required property Item di
    anchors {
        fill: parent
        leftMargin: di.isMaterial ? 0 : 4
        rightMargin: 10
    }
    spacing: 6

    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen ? Brightness.getMonitorForScreen(focusedScreen) : null

    MaterialShapeWrappedMaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        shape: MaterialShape.Shape.Cookie12Sided
        color: Appearance.colors.colPrimary
        colSymbol: Appearance.colors.colOnPrimary
        text: di.iconForProviderId("osd")
        iconSize: di.isMaterial ? 20 : 14
        fill: 1
        padding: 4
    }

    Item { Layout.fillWidth: true }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: di.osdText()
        font.pixelSize: di.isMaterial ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
        font.features: { "tnum": 1 }
        color: Appearance.colors.colNotchText
    }
}
