import "../core"
import "../core/functions" as Functions
import QtQuick

Text {
    id: root
    property bool animateChange: false
    property real animationDistanceX: 0
    property real animationDistanceY: 6

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    property bool shouldUseNumberFont: root.text.match(/^\d+$/) !== null
    property var defaultFont: (Appearance.font && shouldUseNumberFont) ? Appearance.font.family.numbers : (Appearance.font ? Appearance.font.family.main : "sans-serif")
    
    font {
        hintingPreference: Font.PreferDefaultHinting
        family: defaultFont
        pixelSize: Appearance.font ? Appearance.font.pixelSize.small : 15
        // variableAxes: shouldUseNumberFont ? ({}) : Appearance.font.variableAxes.main
    }
    color: Appearance.m3colors ? Appearance.m3colors.m3onBackground : "black"
    linkColor: Appearance.m3colors ? Appearance.m3colors.m3primary : "blue"
}
