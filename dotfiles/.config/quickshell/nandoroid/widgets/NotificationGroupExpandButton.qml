import "../core"
import "../core/functions" as Functions
import QtQuick
import QtQuick.Layouts

/**
 * Expand button for Notification Group.
 * 100% Ported from 'ii' source port.
 */
RippleButton { // Expand button
    id: root
    required property int count
    required property bool expanded
    property real fontSize: Appearance.font.pixelSize.smaller
    property real iconSize: Appearance.font.pixelSize.normal
    implicitHeight: fontSize + 4 * 2
    implicitWidth: Math.max(contentContainerItem.implicitWidth + 5 * 2, 30)
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false

    buttonRadius: Appearance.rounding.full
    colBackground: Functions.ColorUtils.mix(Appearance.colors.colLayer2, Appearance.colors.colLayer2Hover, 0.5)
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colRipple: Appearance.colors.colLayer2Active

    contentItem: Item {
        id: contentContainerItem
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 3
            StyledText {
                Layout.leftMargin: 4
                visible: root.count > 1
                text: root.count
                font.pixelSize: root.fontSize
                color: Appearance.colors.colOnLayer2
            }
            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: root.iconSize
                color: Appearance.colors.colOnLayer2
                rotation: expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
