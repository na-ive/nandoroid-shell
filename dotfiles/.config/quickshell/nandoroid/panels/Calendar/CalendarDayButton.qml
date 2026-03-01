import "../../widgets"
import "../../core"
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button
    property string day
    property int isToday
    property bool bold: false
    property bool isLabel: false
    
    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: Appearance.sizes.calendarCellSize
    implicitHeight: Appearance.sizes.calendarCellSize
    toggled: !isLabel && (isToday == 1)
    buttonRadius: Appearance.rounding.small
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer2Hover
    
    StyledText {
        anchors.centerIn: parent
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: (bold || isLabel) ? Font.DemiBold : Font.Normal
        color: isLabel ? Appearance.m3colors.m3onSurface : 
               (isToday == 1) ? Appearance.m3colors.m3onPrimary : 
               (isToday == 0) ? Appearance.m3colors.m3onSurface : 
               Appearance.colors.colOutlineVariant
    }
}
