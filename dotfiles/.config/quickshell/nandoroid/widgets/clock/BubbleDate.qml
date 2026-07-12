pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../services"
import "../../core"

Item {
    id: root
    property bool isMonth: false
    property alias text: bubbleText.text
    property bool isLockscreen: false
    readonly property string dateFontFamily: isLockscreen ? Appearance.font.family.lockscreenDateFont : Appearance.font.family.desktopDateFont
    property real targetSize: 0

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
        anchors.verticalCenterOffset: root.isMonth ? 0 : 3 * Appearance.effectiveScale
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
        color: root.isMonth ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnTertiaryContainer
        font {
            family: root.dateFontFamily
            pixelSize: 30 * Appearance.effectiveScale
            weight: Font.Black
            variableAxes: Appearance.font.variableAxes.expressive
        }
    }
}
