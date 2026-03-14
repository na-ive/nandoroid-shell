pragma ComponentBehavior: Bound
import "../../widgets"
import "../../core"
import "../../core/functions" as Functions
import QtQuick
import Quickshell

/**
 * Animated material-shape characters used as password dots.
 * Each character shows a stable random material shape with a pop-in animation.
 * Uses ListModel to prevent re-creation of existing dots during typing (fixes blinking).
 */
StyledFlickable {
    id: root

    required property int length
    property int selectionStart: 0
    property int selectionEnd: 0


    property int cursorPosition: length

    property color shapeColor: Appearance.colors.colPrimary
    property color selectedTextColor: Appearance.m3colors.m3onSecondaryContainer
    property color selectionColor:    Appearance.m3colors.m3secondaryContainer

    property int charSize: 22

    // shapes pool
    readonly property list<int> charShapes: [
        MaterialShape.Shape.Arrow,
        MaterialShape.Shape.Pill,
        MaterialShape.Shape.Diamond,
        MaterialShape.Shape.ClamShell,
        MaterialShape.Shape.Pentagon,
        MaterialShape.Shape.Cookie4Sided,
        MaterialShape.Shape.SoftBurst,
    ]

    // Model management to prevent re-creation of items
    ListModel { id: charModel }

    function updateModel() {
        while (charModel.count > root.length) {
            charModel.remove(charModel.count - 1)
        }
        while (charModel.count < root.length) {
            // Append with random shape index (0-6)
            charModel.append({ "shapeIdx": Math.floor(Math.random() * 7) })
        }
    }
    
    onLengthChanged: updateModel()
    Component.onCompleted: updateModel()

    property int spacing: 4
    property int leftPadding: 12

    contentWidth: dotsRow.implicitWidth + leftPadding * 2
    contentX: Math.max(contentWidth - width, 0)
    Behavior on contentX {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    property bool active: true

    // Blinking cursor (Softer animation)
    Rectangle {
        id: cursor
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            // Updated formula: (charSize + spacing) * index + padding
            leftMargin: (root.charSize + root.spacing) * root.cursorPosition + root.leftPadding
        }
        color: root.shapeColor
        implicitWidth: 2
        implicitHeight: root.charSize
        opacity: root.active ? 1 : 0

        Behavior on anchors.leftMargin {
            animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(cursor)
        }
    }



    Row {
        id: dotsRow
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            // Correct margin accounting for padding
            leftMargin: root.leftPadding
        }
        spacing: root.spacing

        Repeater {
            model: charModel

            delegate: Rectangle {
                id: charItem
                required property int index
                required property int shapeIdx // From model
                
                implicitWidth: root.charSize
                implicitHeight: root.charSize
                
                property bool selected: index >= root.selectionStart && index < root.selectionEnd
                color: Functions.ColorUtils?.transparentize(root.selectionColor, selected ? 0 : 1)
                    ?? (selected ? root.selectionColor : "transparent")

                MaterialShape {
                    id: shape
                    anchors.centerIn: parent
                    shape: root.charShapes[charItem.shapeIdx]
                    // No color binding here — set imperatively so ColorAnimation has full control
                    // implicitSize/opacity/scale start at 0 for pop-in animation
                    implicitSize: 0
                    opacity: 0
                    scale: 0.5

                    // Watch selection changes manually (binding would conflict with animation)
                    property bool selected: charItem.selected
                    onSelectedChanged: color = selected ? root.selectedTextColor : Appearance.colors.colOnLayer1

                    Component.onCompleted: {
                        color = root.shapeColor  // imperative set — no binding overhead
                        appearAnim.start()
                    }

                    ParallelAnimation {
                        id: appearAnim
                        NumberAnimation {
                            target: shape
                            properties: "opacity"
                            to: 1
                            duration: 50
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                        NumberAnimation {
                            target: shape
                            properties: "scale"
                            to: 1
                            duration: 250
                            easing.type: Easing.OutBack
                            easing.overshoot: 3.0
                        }
                        NumberAnimation {
                            target: shape
                            properties: "implicitSize"
                            to: 18
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                        }
                        ColorAnimation {
                            target: shape
                            properties: "color"
                            from: Appearance.colors.colPrimary
                            to: Appearance.colors.colOnLayer1
                            duration: 1500 // Snappy yet smooth transition
                            easing.type: Easing.InOutCubic
                        }
                    }
                }
            }
        }
    }
}
