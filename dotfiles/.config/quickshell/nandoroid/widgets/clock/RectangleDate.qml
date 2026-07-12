import QtQuick
import ".."
import "../../services"
import "../../core"

Rectangle {
    id: rect

    color: "transparent"
    property color textColor: Appearance.colors.colSecondaryHover
    property bool isLockscreen: false

    readonly property string dateFontFamily: isLockscreen ? Appearance.font.family.lockscreenDateFont : Appearance.font.family.desktopDateFont

    Text {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: Text.NativeRendering
        color: rect.textColor
        text: {
            const _ = DateTime.currentDate;
            return Qt.formatDate(new Date(), "dd");
        }
        font {
            family: root.dateFontFamily
            pixelSize: 20 * Appearance.effectiveScale
            weight: Font.Black
            variableAxes: Appearance.font.variableAxes.expressive
        }
    }
}
