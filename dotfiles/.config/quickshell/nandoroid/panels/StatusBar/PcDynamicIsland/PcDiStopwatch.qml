import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"

RowLayout {
    id: root
    required property Item di
    anchors {
        fill: parent
        leftMargin: di.isMaterial ? 0 : 4
        rightMargin: 10
    }
    spacing: 6

    MaterialShapeWrappedMaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        shape: MaterialShape.Shape.Cookie12Sided
        color: Appearance.colors.colPrimary
        colSymbol: Appearance.colors.colOnPrimary
        text: "timer"
        iconSize: di.isMaterial ? 20 : 16
        fill: 1
        padding: 4
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { GlobalStates.dashClockTab = 1; GlobalStates.dashboardOpen = true }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        visible: StopwatchService.laps.length > 0
        text: I18nService.tr("Lap %1").arg(StopwatchService.laps.length)
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.colors.colNotchText
        opacity: 0.8
    }

    Item { Layout.fillWidth: true }

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: -2
        StyledText {
            Layout.alignment: Qt.AlignRight
            text: StopwatchService.timeString.split(".")[0]
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            font.features: { "tnum": 1 }
            color: Appearance.colors.colNotchText
        }
        StyledText {
            Layout.alignment: Qt.AlignRight
            visible: StopwatchService.laps.length > 0
            text: StopwatchService.lapTimeString
            font.pixelSize: 9 * Appearance.effectiveScale
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colNotchText
            opacity: 0.6
        }
    }

    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: "flag"
        iconSize: 14
        color: Appearance.colors.colNotchText
        opacity: StopwatchService.active ? 1 : 0.4
        MouseArea {
            anchors.fill: parent
            enabled: StopwatchService.active
            cursorShape: Qt.PointingHandCursor
            onClicked: StopwatchService.lap()
        }
    }
    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: StopwatchService.active ? "pause" : "play_arrow"
        fill: 1
        iconSize: 16
        color: Appearance.colors.colNotchText
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: StopwatchService.active ? StopwatchService.pause() : StopwatchService.start()
        }
    }
    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: "stop_circle"
        fill: 1
        iconSize: 16
        color: Appearance.colors.colNotchText
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: StopwatchService.reset()
        }
    }
}
