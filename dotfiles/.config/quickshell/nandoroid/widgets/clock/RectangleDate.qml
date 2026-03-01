import QtQuick
import ".."
import "../../services"
import "../../core"

Rectangle {
    id: rect

    color: "transparent"
    property color textColor: Appearance.colors.colSecondaryHover

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
            family: Appearance.font.family.expressive
            pixelSize: 20
            weight: Font.Black
            variableAxes: Appearance.font.variableAxes.expressive
        }
    }
}
