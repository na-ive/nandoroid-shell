import "../../../../core"
import QtQuick

Rectangle {
    property bool checked: false
    signal toggled()
    implicitWidth: 52 * Appearance.effectiveScale; implicitHeight: 28 * Appearance.effectiveScale; radius: 14 * Appearance.effectiveScale
    color: checked ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
    
    Rectangle {
        width: 20 * Appearance.effectiveScale; height: 20 * Appearance.effectiveScale; radius: 10 * Appearance.effectiveScale; anchors.verticalCenter: parent.verticalCenter
        x: parent.checked ? parent.width - width - (4 * Appearance.effectiveScale) : 4 * Appearance.effectiveScale
        color: parent.checked ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    
    MouseArea { 
        anchors.fill: parent; 
        cursorShape: Qt.PointingHandCursor; 
        onClicked: parent.toggled() 
    }
}
