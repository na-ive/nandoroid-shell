import QtQuick
import Qt5Compat.GraphicalEffects


DropShadow {
    required property var target
    source: target
    anchors.fill: source
    radius: 12
    samples: 24
    color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.1)
    transparentBorder: true
    cached: true
}
