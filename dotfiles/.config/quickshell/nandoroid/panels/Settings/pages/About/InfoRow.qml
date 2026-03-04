import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts

SegmentedWrapper {
    property string label
    property string value
    Layout.fillWidth: true
    Layout.preferredHeight: 52
    orientation: Qt.Vertical
    maxRadius: 20
    color: Appearance.m3colors.m3surfaceContainerHigh
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 20

        StyledText {
            text: label
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer0
            Layout.fillWidth: true
        }
        StyledText {
            text: value
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            Layout.alignment: Qt.AlignRight
            elide: Text.ElideRight
        }
    }
}
