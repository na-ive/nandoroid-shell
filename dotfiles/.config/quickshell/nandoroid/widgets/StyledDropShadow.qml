import QtQuick
import Qt5Compat.GraphicalEffects


DropShadow {
    required property var target
    source: target
    anchors.fill: source
    radius: 8
    samples: radius * 2 + 1
    color: Appearance.colors.colShadow
    transparentBorder: true
}
