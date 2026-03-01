pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../services"
import "../../core"

Item {
    id: root
    property bool isMonth: false
    property real targetSize: 0
    property alias text: bubbleText.text

    text: {
        // Trigger reactivity when date changes
        const _ = DateTime.currentDate;
        return Qt.formatDate(new Date(), root.isMonth ? "MM" : "d");
    }

    MaterialShape {
        id: bubble
        z: 5
        shape: root.isMonth ? MaterialShape.Shape.Pill : MaterialShape.Shape.Pentagon
        anchors.centerIn: parent
        color: root.isMonth ? Appearance.colors.colSecondaryContainer : Appearance.colors.colTertiaryContainer
        implicitSize: targetSize
        width: implicitSize
        height: implicitSize
    }

    Text {
        id: bubbleText
        z: 6
        anchors.centerIn: parent
        // Visually offset for non-symmetrical shapes (like Pentagon)
        anchors.verticalCenterOffset: root.isMonth ? 0 : 3 
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
        color: root.isMonth ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnTertiaryContainer
        font {
            family: Appearance.font.family.expressive
            pixelSize: 30
            weight: Font.Black
            variableAxes: Appearance.font.variableAxes.expressive
        }
    }
}
