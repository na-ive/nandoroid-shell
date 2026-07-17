import QtQuick
import "../core"
import "../services"

Canvas {
    id: root

    property list<int> points: CavaService.values
    property real maxVisualizerValue: 1000
    property int smoothing: 3
    property color color: Appearance.colors.colPrimary
    property real opacityMultiplier: 0.25

    onPointsChanged: if (root.visible) root.requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var data = root.points
        var maxVal = root.maxVisualizerValue || 1
        var h = height
        var w = width
        var n = data.length
        if (n < 2) return

        var smoothPoints = []
        var window = root.smoothing
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

        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, root.opacityMultiplier)
        ctx.fill()
    }
}
