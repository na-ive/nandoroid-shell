import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"

RippleButton {
    id: root
    property string iconName
    property int iconSize: 24
    property bool isM3Highlighted: false
    property color color: Appearance.colors.colOnLayer1
    
    implicitWidth: 40
    implicitHeight: 40
    buttonRadius: 20
    
    colBackground: isM3Highlighted ? Appearance.m3colors.m3secondaryContainer : "transparent"
    
    property int xOffset: 0
    
    contentItem: Item {
        MaterialSymbol {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.xOffset
            text: root.iconName
            iconSize: root.iconSize
            color: isM3Highlighted ? Appearance.m3colors.m3onSecondaryContainer : root.color
        }
    }
}
