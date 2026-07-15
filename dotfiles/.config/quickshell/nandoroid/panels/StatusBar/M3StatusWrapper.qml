import QtQuick
import QtQuick.Layouts
import "../../core"

Item {
    id: root
    default property alias content: row.data
    
    property color m3Color: Appearance.m3colors.m3surfaceContainerHigh
    property color m3ContentColor: Appearance.m3colors.m3onSurface
    
    // Exported colors for children to use
    readonly property color contentColor: m3ContentColor
    readonly property color subtextColor: Qt.rgba(m3ContentColor.r, m3ContentColor.g, m3ContentColor.b, 0.7)
    
    implicitWidth: row.implicitWidth + (24 * Appearance.effectiveScale)
    implicitHeight: Math.max(32 * Appearance.effectiveScale, row.implicitHeight + (8 * Appearance.effectiveScale))
    
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    
    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        color: root.m3Color
        radius: height / 2
        Behavior on color { ColorAnimation { duration: 250 } }
    }
    
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - (24 * Appearance.effectiveScale)
        spacing: 8 * Appearance.effectiveScale
    }
}
