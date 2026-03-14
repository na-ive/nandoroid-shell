import "../core"
import "."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property string text
    property bool shown: false
    property alias font: tooltipTextObject.font
    
    // Reset to a much tighter, more standard padding
    property real horizontalPadding: 8
    property real verticalPadding: 4
    
    implicitWidth: tooltipTextObject.implicitWidth + 2 * root.horizontalPadding
    implicitHeight: tooltipTextObject.implicitHeight + 2 * root.verticalPadding

    property bool isVisible: shown

    StyledText {
        id: tooltipTextObject
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.hintingPreference: Font.PreferNoHinting
        color: Appearance.m3colors.m3onSurface
        wrapMode: Text.Wrap
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
}
