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
    property bool hasEvent: false   // show schedule dot

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: Appearance.sizes.calendarCellSize
    implicitHeight: Appearance.sizes.calendarCellSize
    toggled: !isLabel && (isToday == 1)
    buttonRadius: Appearance.rounding.small
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer2Hover

    // Day number (moved up slightly when dot is shown)
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: (hasEvent && !isLabel) ? -3 : 0
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: (bold || isLabel) ? Font.DemiBold : Font.Normal
        color: isLabel ? Appearance.m3colors.m3onSurface :
               (isToday == 1) ? Appearance.m3colors.m3onPrimary :
               (isToday == 0) ? Appearance.m3colors.m3onSurface :
               Appearance.colors.colOutlineVariant
    }

    // Schedule dot indicator
    Rectangle {
        visible: hasEvent && !isLabel && isToday !== 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        width: 4; height: 4; radius: 2
        color: Appearance.colors.colPrimary
        opacity: 0.85
    }

    // Today + event: white dot (primary bg)
    Rectangle {
        visible: hasEvent && !isLabel && isToday === 1
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3
        width: 4; height: 4; radius: 2
        color: Appearance.m3colors.m3onPrimary
        opacity: 0.85
    }
}
