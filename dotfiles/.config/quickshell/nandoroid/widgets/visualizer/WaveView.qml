import QtQuick
import QtQuick.Effects
import Quickshell
import "../../core"
import "../../services"

Canvas {
    id: root

    property list<real> points: GlobalStates.visualizerPoints
    property bool live: MprisController.isPlaying
    property color color: Appearance.m3colors.m3primary
    property real alpha: 0.15
    property int smoothing: 2
    property real maxValue: 1000
    property bool blur: true

    onPointsChanged: if (visible) requestPaint()
    onLiveChanged: if (visible) requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var data = points;
        var maxVal = root.maxValue || 1;
        var h = height;
        var w = width;
        var n = data.length;
        if (n < 2) return;

        var target = Math.max(n, Math.min(256, Math.floor(w / 4)));
        var resampled = [];
        for (var i = 0; i < target; ++i) {
            var pos = i / (target - 1) * (n - 1);
            var lo = Math.floor(pos);
            var hi = Math.ceil(pos);
            var t = pos - lo;
            resampled.push(data[lo] * (1 - t) + data[hi] * t);
        }

        var s = [];
        var window = root.smoothing;
        for (var i = 0; i < target; ++i) {
            var sum = 0, count = 0;
            for (var j = -window; j <= window; ++j) {
                var idx = Math.max(0, Math.min(target - 1, i + j));
                sum += resampled[idx];
                count++;
            }
            s.push(sum / count);
        }
        if (!root.live) s.fill(0);

        ctx.beginPath();
        ctx.moveTo(0, h);
        var px = 0;
        var py = h - (s[0] / maxVal) * h;
        ctx.lineTo(px, py);
        for (var i = 1; i < target; ++i) {
            var x = (i * w) / (target - 1);
            var y = h - (s[i] / maxVal) * h;
            ctx.quadraticCurveTo(px, py, (px + x) / 2, (py + y) / 2);
            px = x;
            py = y;
        }
        ctx.lineTo(px, py);
        ctx.lineTo(w, h);
        ctx.closePath();

        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, root.alpha);
        ctx.fill();
    }

    layer.enabled: root.blur
    layer.effect: MultiEffect {
        saturation: 0.2
        blurEnabled: true
        blurMax: 7
        blur: 1
    }
}
