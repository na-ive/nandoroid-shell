import "../core"
import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ToolTip {
    id: root
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false

    readonly property bool internalVisibleCondition: (extraVisibleCondition && (parent && (parent.hovered || parent.realHovered))) || alternativeVisibleCondition
    
    // Minimal padding to match ToggleDelegate
    padding: 0
    verticalPadding: 0
    horizontalPadding: 0
    
    background: Rectangle {
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: 8
        border.color: Appearance.m3colors.m3outlineVariant
        border.width: 1
    }
    
    font {
        family: Appearance.font.family.main
        variableAxes: Appearance.font.variableAxes.main
        pixelSize: Appearance.font.pixelSize.smaller
        hintingPreference: Font.PreferNoHinting
    }

    delay: 300
    visible: internalVisibleCondition
    
    contentItem: StyledToolTipContent {
        id: contentItem
        text: root.text
        shown: root.internalVisibleCondition
    }
}
