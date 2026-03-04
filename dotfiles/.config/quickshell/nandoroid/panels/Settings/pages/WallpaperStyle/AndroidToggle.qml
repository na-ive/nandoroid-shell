import "../../../../core"
import QtQuick

Rectangle {
    property bool checked: false
    signal toggled()
    implicitWidth: 52; implicitHeight: 28; radius: 14
    color: checked ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
    
    Rectangle {
        width: 20; height: 20; radius: 10; anchors.verticalCenter: parent.verticalCenter
        x: parent.checked ? parent.width - width - 4 : 4
        color: parent.checked ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
    
    MouseArea { 
        anchors.fill: parent; 
        cursorShape: Qt.PointingHandCursor; 
        onClicked: parent.toggled() 
    }
}
