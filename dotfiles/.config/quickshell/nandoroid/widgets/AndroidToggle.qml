import "../core"
import QtQuick
import QtQuick.Effects

Item {
    id: root
    property bool checked: false
    signal toggled()

    // 0.75 scale from end4-pC StyledSwitch
    property real scaleMultiplier: 0.75 * Appearance.effectiveScale
    implicitHeight: 30 * scaleMultiplier
    implicitWidth: 52 * scaleMultiplier

    property alias color: bg.color
    property color activeColor: Appearance.colors.colPrimary
    property color inactiveColor: Appearance.colors.colLayer2

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Appearance.rounding.full
        color: root.checked ? root.activeColor : root.inactiveColor

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
        }

        Behavior on color {
            ColorAnimation { duration: 200 }
        }
    }

    Rectangle {
        id: indicator
        readonly property real thumbSize: 22 * root.scaleMultiplier
        readonly property real pad: 4 * root.scaleMultiplier
        readonly property real stretchExtra: 4 * root.scaleMultiplier

        width: mouseArea.pressed ? thumbSize + stretchExtra : thumbSize
        height: thumbSize
        radius: Appearance.rounding.full

        // Keep nandoroid's original thumb colors
        color: root.checked ? Appearance.colors.colOnPrimary : root.activeColor



        anchors.verticalCenter: parent.verticalCenter
        x: root.checked
            ? (mouseArea.pressed
                ? parent.width - width - pad - stretchExtra
                : parent.width - width - pad)
            : pad

        Behavior on x {
            NumberAnimation {
                duration: 320
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.42, 1.5, 0.28, 0.95, 1, 1]
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: 160
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.42, 1.5, 0.28, 0.95, 1, 1]
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggled()
        }
    }
}
