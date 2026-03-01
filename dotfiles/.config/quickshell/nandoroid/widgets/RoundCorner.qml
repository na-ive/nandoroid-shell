import QtQuick
import QtQuick.Shapes

/**
 * Decorative concave round corner piece.
 * Draws the "negative space" corner so a rectangular background visually
 * matches the rounded screen edges below it.
 *
 * Usage:
 *   RoundCorner {
 *       implicitSize: 20
 *       color: barBackground.color
 *       corner: RoundCorner.CornerEnum.BottomLeft
 *   }
 */
Item {
    id: root

    enum CornerEnum { TopLeft, TopRight, BottomLeft, BottomRight }
    property var corner: RoundCorner.CornerEnum.BottomLeft
    property int implicitSize: 20
    property color color: "transparent"

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    readonly property bool isTop:    corner === RoundCorner.CornerEnum.TopLeft    || corner === RoundCorner.CornerEnum.TopRight
    readonly property bool isLeft:   corner === RoundCorner.CornerEnum.TopLeft    || corner === RoundCorner.CornerEnum.BottomLeft
    readonly property bool isBottom: corner === RoundCorner.CornerEnum.BottomLeft || corner === RoundCorner.CornerEnum.BottomRight
    readonly property bool isRight:  corner === RoundCorner.CornerEnum.TopRight   || corner === RoundCorner.CornerEnum.BottomRight

    Shape {
        id: shape
        anchors {
            top:    root.isTop    ? parent.top    : undefined
            bottom: root.isBottom ? parent.bottom : undefined
            left:   root.isLeft   ? parent.left   : undefined
            right:  root.isRight  ? parent.right  : undefined
        }
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.smooth: true

        ShapePath {
            id: sp
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color

            readonly property real sz: root.implicitSize
            startX: root.isLeft  ? 0   : sp.sz
            startY: root.isTop   ? 0   : sp.sz

            PathAngleArc {
                moveToStart: false
                centerX: sp.sz - sp.startX
                centerY: sp.sz - sp.startY
                radiusX: sp.sz
                radiusY: sp.sz
                startAngle: {
                    switch (root.corner) {
                        case RoundCorner.CornerEnum.TopLeft:     return 180
                        case RoundCorner.CornerEnum.TopRight:    return -90
                        case RoundCorner.CornerEnum.BottomLeft:  return 90
                        case RoundCorner.CornerEnum.BottomRight: return 0
                    }
                }
                sweepAngle: 90
            }
            PathLine { x: sp.startX; y: sp.startY }
        }
    }
}
