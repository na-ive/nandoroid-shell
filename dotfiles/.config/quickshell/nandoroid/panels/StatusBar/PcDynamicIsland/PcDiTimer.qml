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
        text: "hourglass_top"
        iconSize: di.isMaterial ? 20 : 16
        fill: 1
        padding: 4
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { GlobalStates.dashClockTab = 2; GlobalStates.dashboardOpen = true }
        }
    }

    Item { Layout.fillWidth: true }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        text: TimerService.timeString
        font.pixelSize: Appearance.font.pixelSize.small
        font.features: { "tnum": 1 }
        color: TimerService.isNegative ? Appearance.m3colors.m3error : Appearance.colors.colNotchText
    }

    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: "add"
        iconSize: 14
        color: Appearance.colors.colNotchText
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: TimerService.addMinute()
        }
    }
    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: TimerService.active ? "pause" : "play_arrow"
        fill: 1
        iconSize: 16
        color: Appearance.colors.colNotchText
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: TimerService.active ? TimerService.pause() : TimerService.start()
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
            onClicked: TimerService.reset()
        }
    }
}
