import QtQuick
import QtQuick.Controls
import "../core"

ScrollBar {
    id: root

    policy: ScrollBar.AsNeeded
    topPadding: Appearance.rounding.small
    bottomPadding: Appearance.rounding.small
    active: hovered || pressed

    contentItem: Rectangle {
        implicitWidth: 4
        implicitHeight: root.visualSize
        radius: width / 2
        color: Appearance.m3colors.m3onSurfaceVariant // Adapted color
        
        opacity: root.policy === ScrollBar.AlwaysOn || (root.active && root.size < 1.0) ? 0.5 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 350
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }
    }
}
