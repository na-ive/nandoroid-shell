pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../core"

Item {
    id: root
    anchors.fill: parent

    required property int clockMinute
    property string style: "medium"
    property real handLength: 95
    property real handWidth: style === "bold" ? 20 : style === "medium" ? 12 : 5
    property color color: Appearance.colors.colTertiary

    rotation: -90 + (360 / 60) * root.clockMinute
    Behavior on rotation {
        animation: RotationAnimation {
            direction: RotationAnimation.Clockwise
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasized
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: {
            let position = parent.width / 2 - root.handWidth / 2;
            if (root.style === "classic") position -= 15;
            return position;
        }
        width: root.handLength
        height: root.handWidth
        
        radius: root.style === "classic" ? 2 : root.handWidth / 2
        color: root.color

        Behavior on height {
            NumberAnimation { duration: 300 }
        }

        Behavior on x {
            NumberAnimation { duration: 300 }
        }
    }
}
