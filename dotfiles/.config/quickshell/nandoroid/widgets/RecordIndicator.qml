import "../core"
import "../core/functions" as Functions
import "../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Android-style indicator for screen recording.
 * Shows a primary-colored pill with a timer when active.
 */
Item {
    id: root
    visible: ScreenRecord.active
    implicitWidth: mainContainer.width
    implicitHeight: 24

    Rectangle {
        id: mainContainer
        anchors.verticalCenter: parent.verticalCenter
        height: 20
        width: contentLayout.implicitWidth + 12
        radius: height / 2
        color: Appearance.m3colors.m3primary
        clip: true

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                id: recordIcon
                text: "videocam"
                iconSize: 14
                color: Appearance.m3colors.m3onPrimary
                fill: 1
            }

            StyledText {
                text: Functions.General.formatDuration(ScreenRecord.seconds)
                font.pixelSize: 12
                font.weight: Font.Bold
                color: Appearance.m3colors.m3onPrimary
            }
        }
    }

    opacity: visible ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }
}
