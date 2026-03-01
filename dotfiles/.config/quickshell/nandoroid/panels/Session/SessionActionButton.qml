import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: root
    
    property string iconName
    property string actionText
    
    implicitWidth: 120
    implicitHeight: 120
    
    // Steal keyboard focus on hover so only one button appears active at a time
    onHoveredChanged: if (root.hovered) root.forceActiveFocus()

    buttonRadius: (root.activeFocus || root.down) ? 60 : Appearance.rounding.large

    colBackground: root.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3secondaryContainer
    colBackgroundHover: Appearance.m3colors.m3primary
    colRipple: Appearance.m3colors.m3onPrimary

    property color contentColor: (root.down || root.activeFocus) ?
                                Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.iconName
        iconSize: 48
        color: root.contentColor
    }
    
    StyledToolTip {
        text: root.actionText
    }
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked()
            event.accepted = true
        }
    }

    Behavior on buttonRadius {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuart }
    }
}
