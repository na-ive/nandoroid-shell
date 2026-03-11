import QtQuick
import "../../core"
import "../../core/functions" as Functions

/**
 * A real-time line graph component for performance metrics.
 * Uses Canvas for smooth drawing of history data.
 */
Item {
    id: root
    
    property var history: []
    property real maxValue: 100
    property string lineColor: Appearance.colors.colPrimary
    property string fillColor: Appearance.colors.colPrimary
    
    implicitWidth: 200
    implicitHeight: 60
    property real fillOpacity: 0.1
    property real lineWidth: 2
    property bool inverted: false
    
    onHistoryChanged: canvas.requestPaint()
    
    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            if (!history || history.length < 2) return;
            
            var w = width;
            var h = height;
            var step = w / (history.length - 1);
            
            ctx.beginPath();
            ctx.strokeStyle = lineColor;
            ctx.lineWidth = lineWidth;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            
            for (var i = 0; i < history.length; i++) {
                var x = i * step;
                var val = Math.min(maxValue, history[i]);
                var y = root.inverted ? (val / maxValue * h) : h - (val / maxValue * h);
                
                if (i === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            
            ctx.stroke();
            
            // Fill area
            if (root.inverted) {
                ctx.lineTo(w, 0);
                ctx.lineTo(0, 0);
            } else {
                ctx.lineTo(w, h);
                ctx.lineTo(0, h);
            }
            ctx.closePath();
            ctx.fillStyle = Functions.ColorUtils.transparentize(fillColor, 1 - fillOpacity);
            ctx.fill();
        }
    }
}
