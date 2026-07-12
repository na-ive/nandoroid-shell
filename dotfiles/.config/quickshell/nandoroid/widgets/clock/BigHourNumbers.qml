pragma ComponentBehavior: Bound

import QtQuick
import "../../core"
import ".."

Item {
    id: root
    property real numberSize: 80 * Appearance.effectiveScale
    property real margins: 10 * Appearance.effectiveScale
    property color color: Appearance.colors.colOnSecondaryContainer || "#FFFFFF"

    property int hours: 12
    property bool isLockscreen: false
    readonly property string timeFontFamily: isLockscreen ? Appearance.font.family.lockscreenTimeFont : Appearance.font.family.desktopTimeFont
    property int numbers: 4
    property int fontSize: 80 * Appearance.effectiveScale

    Repeater {
        model: root.numbers

        Item {
            id: numberItem
            required property int index
            rotation: 360 / root.numbers * (index + 1)
            anchors.fill: parent
            
            Item {
                implicitWidth: root.numberSize
                implicitHeight: implicitWidth
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: root.margins
                }
                StyledText {
                    color: root.color
                    anchors.centerIn: parent
                    text: root.hours / root.numbers * (numberItem.index + 1)
                    rotation: -numberItem.rotation

                    font {
                        family: root.timeFontFamily
                        pixelSize: root.fontSize
                        weight: Font.Black
                    }
                }
            }
        }
    }
}
