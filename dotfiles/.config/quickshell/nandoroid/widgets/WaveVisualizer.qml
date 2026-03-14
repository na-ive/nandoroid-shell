import QtQuick
import QtQuick.Effects
import "../core"
import "../services"

/**
 * WaveVisualizer.qml (v1.2)
 * Ported from Illogical Impulse — renders smooth blurred waveforms.
 * Uses data from CavaService.
 */
Canvas {
    id: root
    
    // Config
    property list<int> points: CavaService.values
    property real maxVisualizerValue: 1000 // Match Cava output scale
    property int smoothing: 3
    property color color: Appearance.colors.colPrimary
    property real opacityMultiplier: 0.25

    onPointsChanged: root.requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var data = root.points;
        var maxVal = root.maxVisualizerValue || 1;
        var h = height;
        var w = width;
        var n = data.length;
        if (n < 2) return;

        // --- Smoothing Logic (Simple Moving Average) ---
        var smoothPoints = [];
        var window = root.smoothing;
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -window; j <= window; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += data[idx];
                count++;
            }
            smoothPoints.push(sum / count);
        }

        // --- Drawing Wave ---
        ctx.beginPath();
        ctx.moveTo(0, h);
        
        // Use quadratic curves for even smoother look if desired, 
        // but lineTo is often enough when points are high density (128 bars)
        for (var i = 0; i < n; ++i) {
            var x = (i * w) / (n - 1);
            var y = h - (smoothPoints[i] / maxVal) * h;
            ctx.lineTo(x, y);
        }
        
        ctx.lineTo(w, h);
        ctx.closePath();

        ctx.fillStyle = Qt.rgba(
            root.color.r,
            root.color.g,
            root.color.b,
            root.opacityMultiplier
        );
        ctx.fill();
    }

    // Gaussian Blur Effect (The "Organic" Look)
    layer.enabled: true
    layer.effect: MultiEffect {
        source: root
        blurEnabled: true
        blurMax: 8
        blur: 0.6
        saturation: 0.1
    }
}
