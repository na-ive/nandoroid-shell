import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../core"
import "../services"

Item {
    id: root
    property list<int> points: CavaService.values
    property real maxVisualizerValue: 1000
    property int smoothing: 3
    property color color: Appearance.colors.colPrimary
    property real opacityMultiplier: 0.25
    property string style: "wave" // "wave" | "bars" | "dots" — dots = pC 5-dot island
    // pC dots props (used when style==="dots")
    property int dotsBarCount: 5
    property real dotsDotSize: 3 * Appearance.effectiveScale
    property real dotsDotSpacing: 3 * Appearance.effectiveScale
    property real dotsMaxBarHeight: 32 * Appearance.effectiveScale
    readonly property bool _isPlaying: MprisController.activePlayer?.isPlaying ?? false

    // ── Wave style (original Canvas fill, full width) ──
    Loader {
        anchors.fill: parent
        active: root.visible && root.style === "wave"
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

    // ── Dots style (pC island 5 dots) ──
    Loader {
        anchors.fill: parent
        active: root.visible && root.style === "dots"
        sourceComponent: Item {
            id: dotsRoot
            anchors.fill: parent
            Row {
                anchors.centerIn: parent
                spacing: root.dotsDotSpacing
                Repeater {
                    model: root.dotsBarCount
                    Rectangle {
                        required property int index
                        width: root.dotsDotSize
                        property real pointValue: {
                            if (!root._isPlaying || root.points.length === 0) return root.dotsDotSize
                            const idx = Math.floor(index * root.points.length / root.dotsBarCount)
                            const v = root.points[idx] ?? 0
                            return Math.max(root.dotsDotSize, (v / root.maxVisualizerValue) * root.dotsMaxBarHeight)
                        }
                        height: pointValue
                        radius: width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.color
                        opacity: root._isPlaying ? 0.85 : 0.3
                        Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }
    }

    // ── Bars style (terminal cava, 2× count, QSG rects, no Canvas) ──
    Loader {
        anchors.fill: parent
        active: root.visible && root.style === "bars"
        sourceComponent: Item {
            id: barRoot
            anchors.fill: parent
            clip: true

            readonly property var smoothedPoints: {
                var data = root.points
                var n = data.length
                if (n < 2) return data
                var win = root.smoothing
                var res = []
                for (var i = 0; i < n; ++i) {
                    var sum = 0, cnt = 0
                    for (var j = -win; j <= win; ++j) {
                        var idx = Math.max(0, Math.min(n - 1, i + j))
                        sum += data[idx]
                        cnt++
                    }
                    res.push(sum / cnt)
                }
                return res
            }
            readonly property var displayPoints: {
                var data = smoothedPoints
                var n = data.length
                if (n < 2) return data
                var res = []
                for (var i = 0; i < n * 2; ++i) {
                    var pos = i / 2
                    var lo = Math.floor(pos)
                    var hi = Math.min(n - 1, Math.ceil(pos))
                    var t = pos - lo
                    res.push(data[lo] * (1 - t) + data[hi] * t)
                }
                return res
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height
                spacing: 2 * Appearance.effectiveScale

                Repeater {
                    model: barRoot.displayPoints.length
                    Rectangle {
                        width: Math.max(1.5 * Appearance.effectiveScale, (parent.width - (parent.spacing * (barRoot.displayPoints.length - 1))) / barRoot.displayPoints.length)
                        height: Math.max(2 * Appearance.effectiveScale, (barRoot.displayPoints[index] / root.maxVisualizerValue) * parent.height)
                        anchors.bottom: parent.bottom
                        color: root.color
                        opacity: root.opacityMultiplier
                        topLeftRadius: width / 2
                        topRightRadius: width / 2
                        bottomLeftRadius: 0
                        bottomRightRadius: 0
                    }
                }
            }
        }
    }
}
