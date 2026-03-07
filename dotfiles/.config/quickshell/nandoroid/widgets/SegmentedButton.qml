import "../core"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Reusable M3-style Segmented Button.
 * Now powered by SegmentedWrapper.
 * Fixed: Removed binding loop between active state and toggled property.
 */
SegmentedWrapper {
    id: root
    
    // ── Input Properties ──
    property bool checked: false // Use a dedicated property instead of aliasing to internal button.toggled
    property string iconName: ""
    property int iconSize: 24
    property string buttonText: ""
    property bool isHighlighted: false
    property real leftPadding: 16
    property real rightPadding: 16
    property real spacing: 8
    readonly property bool hovered: button.realHovered
    
    property color colActive: Appearance.m3colors.m3primary
    property color colInactive: Appearance.m3colors.m3surfaceContainerHigh
    property color colActiveText: Appearance.m3colors.m3onPrimary
    property color colInactiveText: Appearance.m3colors.m3onSurface

    signal clicked()
    
    // The active state is derived purely from external inputs
    active: isHighlighted || checked
    
    implicitWidth: contentRow.implicitWidth + leftPadding + rightPadding
    implicitHeight: 40

    M3IconButton {
        id: button
        anchors.fill: parent
        iconName: ""
        buttonRadius: root.fullRadius
        
        // Pass radii through from wrapper
        topLeftRadius: root.rTopLeft
        topRightRadius: root.rTopRight
        bottomLeftRadius: root.rBottomLeft
        bottomRightRadius: root.rBottomRight
        
        onClicked: root.clicked()
        
        // Color logic
        toggled: root.active
        colBackground: root.colInactive
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colBackgroundToggled: root.colActive
        colBackgroundToggledHover: root.colActive
        
        colText: root.colInactiveText
        colTextToggled: root.colActiveText
        
        // Content
        contentItem: Item {
            anchors.fill: parent
            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: root.spacing
                
                MaterialSymbol {
                    visible: root.iconName !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.iconName
                    iconSize: root.iconSize
                    color: root.active ? root.colActiveText : root.colInactiveText
                }
                
                StyledText {
                    id: label
                    visible: root.buttonText !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.buttonText
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: root.active ? root.colActiveText : root.colInactiveText
                }
            }
        }
    }

    property alias font: label.font
    property alias label: label
}
