pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../core"

Item {
    id: root
    anchors.fill: parent

    required property int clockSecond
    property real handWidth: 2
    property real handLength: 95
    property real dotSize: 14
    property string style: "dot"
    property color color: Appearance.colors.colSecondary

    rotation: -90 + (360 / 60 * clockSecond)

    Behavior on rotation {
        enabled: Config.options.appearance.clock.analog.constantlyRotate
        animation: RotationAnimation {
            direction: RotationAnimation.Clockwise
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    // "line" style: thin line hand
    Rectangle {
        visible: root.style === "line" || root.style === "classic"
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width / 2 - (root.style === "classic" ? 20 : 0)
        width: root.handLength
        height: root.style === "classic" ? 3 : root.handWidth
        radius: height / 2
        color: root.color
    }

    // "classic" style: short tail going backwards
    Rectangle {
        visible: root.style === "classic"
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width / 2 - 24
        width: 20
        height: 3
        radius: 1.5
        color: root.color
    }

    // "dot" style: circle at tip
    Rectangle {
        visible: root.style === "dot"
        width: root.dotSize
        height: root.dotSize
        radius: root.dotSize / 2
        color: root.color
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.horizontalCenter
            leftMargin: root.handLength - root.dotSize / 2
        }
    }
}
