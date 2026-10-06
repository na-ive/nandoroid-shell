import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../core"
import "../../../services"
import "../../../widgets"

Item {
    id: diOsdRoot
    required property Item di
    anchors.fill: parent
    clip: true

    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen ? Brightness.getMonitorForScreen(focusedScreen) : null

    RowLayout {
        id: osdRow
        anchors {
            fill: parent
            leftMargin: 4
            rightMargin: 10
        }
        spacing: 6

        MaterialShapeWrappedMaterialSymbol {
            id: osdIcon
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
            id: osdLabel
            Layout.alignment: Qt.AlignVCenter
            text: di.osdText()
            font.pixelSize: di.isMaterial ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
            font.features: { "tnum": 1 }
            color: Appearance.colors.colNotchText
        }
    }

    // Hidden text metrics for natural width measurement.
    StyledText {
        id: osdMetrics
        visible: false
        text: osdLabel.text
        font.pixelSize: osdLabel.font.pixelSize
        font.features: osdLabel.font.features
    }

    // Natural width: margins + icon + gaps + text.
    readonly property real computedContentWidth: osdRow.anchors.leftMargin + osdIcon.implicitWidth + osdRow.spacing * 2 + osdMetrics.implicitWidth + osdRow.anchors.rightMargin

    onComputedContentWidthChanged: di.reportWidth("osdTextContentWidth", computedContentWidth)
    Component.onCompleted: di.reportWidth("osdTextContentWidth", computedContentWidth)
}
