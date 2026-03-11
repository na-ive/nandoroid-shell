import QtQuick
import "../core"
import "."

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 52
    implicitHeight: 28
    radius: 14
    color: checked ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        width: 20
        height: 20
        radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 : 4
        color: root.checked ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext

        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
