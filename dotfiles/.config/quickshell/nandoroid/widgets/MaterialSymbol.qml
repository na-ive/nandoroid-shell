import "../core"
import QtQuick

/**
 * Material Symbols Rounded icon renderer.
 * Set `text` to the icon name (e.g., "wifi", "battery_full").
 */
StyledText {
    id: root
    property real iconSize: Appearance.font ? Appearance.font.pixelSize.normal : 16
    property real fill: 0
    property real truncatedFill: fill.toFixed(1)

    renderType: Text.NativeRendering
    font {
        hintingPreference: Font.PreferNoHinting
        family: Appearance.font ? Appearance.font.family.iconMaterial : "Material Symbols Rounded"
        pixelSize: iconSize
        weight: Font.Normal + (Font.DemiBold - Font.Normal) * truncatedFill
        variableAxes: {
            "FILL": truncatedFill,
            "opsz": iconSize,
        }
    }

    Behavior on fill {
        NumberAnimation {
            duration: Appearance.animation ? Appearance.animation.elementMoveFast.duration : 200
            easing.type: Appearance.animation ? Appearance.animation.elementMoveFast.type : Easing.BezierSpline
            easing.bezierCurve: Appearance.animation ? Appearance.animation.elementMoveFast.bezierCurve : [0.34, 0.80, 0.34, 1.00, 1, 1]
        }
    }
}
