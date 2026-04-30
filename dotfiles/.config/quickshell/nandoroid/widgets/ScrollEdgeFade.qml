import QtQuick
import "../core"
import "../core/functions" as Functions

Item {
    id: root
    z: 99
    required property Item target
    property real fadeSize: Appearance.m3colors.darkmode ? 40 * Appearance.effectiveScale : 20 * Appearance.effectiveScale
    property color color: "black" // Should be passed from parent to match background
    property bool vertical: true

    anchors.fill: target

    component EndGradient: Rectangle {
        required property bool shown
        height: vertical ? root.fadeSize : parent.height
        width: vertical ? parent.width : root.fadeSize

        opacity: shown ? 1 : 0
        visible: opacity > 0
        
        gradient: Gradient {
            orientation: root.vertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: root.color
            }
            GradientStop {
                position: 1.0
                color: "transparent"
            }
        }
        
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    EndGradient {
        anchors {
            top: parent.top
            left: parent.left
            right: vertical ? parent.right : undefined
            bottom: vertical ? undefined : parent.bottom
        }
        shown: (root.vertical ? (root.target.contentHeight > root.target.height) : (root.target.contentWidth > root.target.width)) && !(root.vertical ? root.target.atYBeginning : root.target.atXBeginning)
    }

    EndGradient {
        anchors {
            bottom: parent.bottom
            right: parent.right
            left: vertical ? parent.left : undefined
            top: vertical ? undefined : parent.top
        }
        shown: (root.vertical ? (root.target.contentHeight > root.target.height) : (root.target.contentWidth > root.target.width)) && !(root.vertical ? root.target.atYEnd : root.target.atXEnd)
        rotation: 180
    }
}
