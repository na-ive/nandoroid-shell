import QtQuick
import "../core"
import "../services"

Loader {
    id: root
    active: visible

    property list<int> points: CavaService.values
    property real maxVisualizerValue: 1000
    property int smoothing: 3
    property color color: Appearance.colors.colPrimary
    property real opacityMultiplier: 0.25

    sourceComponent: Canvas {
        anchors.fill: parent

        readonly property list<int> points: root.points
        readonly property real maxVisualizerValue: root.maxVisualizerValue
        readonly property int smoothing: root.smoothing
        readonly property color color: root.color
        readonly property real opacityMultiplier: root.opacityMultiplier

        onPointsChanged: if (visible) requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var data = points
            var maxVal = maxVisualizerValue || 1
            var h = height
            var w = width
            var n = data.length
            if (n < 2) return

            var smoothPoints = []
            var window = smoothing
            for (var i = 0; i < n; ++i) {
                var sum = 0, count = 0
                for (var j = -window; j <= window; ++j) {
                    var idx = Math.max(0, Math.min(n - 1, i + j))
                    sum += data[idx]
                    count++
                }
                smoothPoints.push(sum / count)
            }

            ctx.beginPath()
            ctx.moveTo(0, h)

            for (var i = 0; i < n; ++i) {
                var x = (i * w) / (n - 1)
                var y = h - (smoothPoints[i] / maxVal) * h
                ctx.lineTo(x, y)
            }

            ctx.lineTo(w, h)
            ctx.closePath()

            ctx.fillStyle = Qt.rgba(color.r, color.g, color.b, opacityMultiplier)
            ctx.fill()
        }
    }
}
