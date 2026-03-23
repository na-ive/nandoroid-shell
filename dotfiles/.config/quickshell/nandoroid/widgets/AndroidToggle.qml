import QtQuick
import "../core"
import "."

Rectangle {
    id: root
    property bool checked: false
    signal toggled()

    implicitWidth: 52 * Appearance.effectiveScale
    implicitHeight: 28 * Appearance.effectiveScale
    radius: 14 * Appearance.effectiveScale
    color: checked ? Appearance.colors.colPrimary : Appearance.colors.colLayer2

    Behavior on color { ColorAnimation { duration: 200 } }

    Rectangle {
        width: 20 * Appearance.effectiveScale
        height: 20 * Appearance.effectiveScale
        radius: 10 * Appearance.effectiveScale
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 4 * Appearance.effectiveScale : 4 * Appearance.effectiveScale
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
