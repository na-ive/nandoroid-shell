import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../widgets"

Rectangle {
    id: root
    required property var clientDimensions

    property color colBackground: Qt.rgba(0.06, 0.06, 0.06, 0.9)
    property color colForeground: "#ddffffff"
    property bool showLabel: Config.ready ? (Config.options.regionSelector.targetRegions.showLabel ?? false) : false
    property bool showIcon: false
    property bool targeted: false
    property color borderColor
    property color fillColor: "transparent"
    property string text: ""
    property real textPadding: 10
    z: 2
    color: fillColor
    border.color: borderColor
    border.width: targeted ? 4 : 2
    radius: 4

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    visible: opacity > 0
    Behavior on opacity {
        NumberAnimation { duration: 100 }
    }
    
    x: clientDimensions ? clientDimensions.at[0] : 0
    y: clientDimensions ? clientDimensions.at[1] : 0
    width: clientDimensions ? clientDimensions.size[0] : 0
    height: clientDimensions ? clientDimensions.size[1] : 0

    Loader {
        anchors {
            top: parent.top
            left: parent.left
            topMargin: root.textPadding
            leftMargin: root.textPadding
        }
        
        active: root.showLabel
        sourceComponent: Rectangle {
            property real verticalPadding: 5
            property real horizontalPadding: 10
            radius: 10
            color: root.colBackground
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            implicitWidth: regionInfoRow.implicitWidth + horizontalPadding * 2
            implicitHeight: regionInfoRow.implicitHeight + verticalPadding * 2

            Row {
                id: regionInfoRow
                anchors.centerIn: parent
                spacing: 4

                Text {
                    id: regionText
                    text: root.text
                    color: root.colForeground
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }
    }
}
