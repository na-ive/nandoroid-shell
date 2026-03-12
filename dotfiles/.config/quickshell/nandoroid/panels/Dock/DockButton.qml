import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../widgets"

/**
 * Base button for dock items.
 * Inherits RippleButton for consistent Material 3 styling.
 */
RippleButton {
    id: root
    Layout.fillHeight: true
    
    // Default size for dock buttons
    implicitHeight: 64
    implicitWidth: Math.max(48, implicitHeight - (dockTopInset + dockBottomInset))
    buttonRadius: Appearance.rounding.normal
    
    // Ensure the background is transparent by default if not toggled
    colBackground: toggled ? Appearance.colors.colPrimary : "transparent"
    
    // Custom inset properties to avoid conflict with FINAL topInset/bottomInset
    property real dockTopInset: 0
    property real dockBottomInset: 0
    
    background: Rectangle {
        id: bgRect
        anchors.fill: parent
        anchors.topMargin: root.dockTopInset
        anchors.bottomMargin: root.dockBottomInset
        radius: root.buttonRadius
        color: root.baseColor
        
        Behavior on color { 
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(bgRect)
        }
    }
}
