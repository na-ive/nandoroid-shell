import QtQuick
import QtQuick.Layouts
import "../core"

MouseArea {
    id: root

    property string colorString: ""
    property color buttonColor: {
        if (colorString === "primary") return Appearance.colors.colPrimary
        if (colorString === "secondary") return Appearance.colors.colSecondary
        if (colorString === "tertiary") return Appearance.m3colors.m3tertiary
        if (colorString === "onSurface") return Appearance.m3colors.m3onSurface
        if (colorString === "onLayer1") return Appearance.colors.colOnLayer1
        if (colorString === "surface") return Appearance.m3colors.m3surface
        if (colorString === "error") return Appearance.colors.colError
        if (colorString === "surfaceContainerHigh") return Appearance.m3colors.m3surfaceContainerHigh
        if (colorString === "primaryContainer") return Appearance.m3colors.m3primaryContainer
        if (colorString === "secondaryContainer") return Appearance.m3colors.m3secondaryContainer
        if (colorString === "surfaceContainerLowest") return Appearance.m3colors.m3surfaceContainerLowest
        return "transparent"
    }
    property bool isHighlighted: false

    implicitWidth: 44 * Appearance.effectiveScale
    implicitHeight: 44 * Appearance.effectiveScale

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        id: selectionRing
        anchors.centerIn: parent
        width: 40 * Appearance.effectiveScale
        height: 40 * Appearance.effectiveScale
        // Morph into a squircle when highlighted
        radius: root.isHighlighted ? (14 * Appearance.effectiveScale) : (width / 2)
        color: "transparent"
        // Thin border, colored dynamically or white/onSurface
        border.color: Appearance.m3colors.m3onSurface
        border.width: root.isHighlighted ? Math.max(1, 2 * Appearance.effectiveScale) : 0
        opacity: root.isHighlighted ? 1 : 0
        scale: root.isHighlighted ? 1 : 0.8

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on border.width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: innerCircle
        anchors.centerIn: parent
        // Size stays exactly the same! 32px
        width: 32 * Appearance.effectiveScale
        height: 32 * Appearance.effectiveScale
        // Morph into a squircle when highlighted (radius 10 vs radius 16)
        radius: root.isHighlighted ? (10 * Appearance.effectiveScale) : (width / 2)
        color: root.buttonColor
        // Subtle border for colors that might blend into the background (only when unselected)
        border.color: root.isHighlighted ? "transparent" : Appearance.colors.colOutlineVariant
        border.width: root.isHighlighted ? 0 : Math.max(1, 1 * Appearance.effectiveScale)

        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    }
}
