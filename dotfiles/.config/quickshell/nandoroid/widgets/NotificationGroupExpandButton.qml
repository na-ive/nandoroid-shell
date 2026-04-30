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
    property bool isRestart: false
    property real fontSize: Appearance.font.pixelSize.smaller
    property real iconSize: Appearance.font.pixelSize.normal
    implicitHeight: fontSize + (4 * 2) * Appearance.effectiveScale
    implicitWidth: Math.max(contentContainerItem.implicitWidth + (5 * 2) * Appearance.effectiveScale, 30 * Appearance.effectiveScale)
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false

    buttonRadius: Appearance.rounding.full
    colBackground: isRestart ? 
        Functions.ColorUtils.applyAlpha(Appearance.colors.colOnWarningContainer, 0.1) :
        Functions.ColorUtils.mix(Appearance.colors.colLayer2, Appearance.colors.colLayer2Hover, 0.5)
    colBackgroundHover: isRestart ? 
        Functions.ColorUtils.applyAlpha(Appearance.colors.colOnWarningContainer, 0.2) :
        Appearance.colors.colLayer2Hover
    colRipple: isRestart ? 
        Functions.ColorUtils.applyAlpha(Appearance.colors.colOnWarningContainer, 0.3) :
        Appearance.colors.colLayer2Active

    contentItem: Item {
        id: contentContainerItem
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth
        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 3 * Appearance.effectiveScale
            StyledText {
                Layout.leftMargin: 4 * Appearance.effectiveScale
                visible: root.count > 1
                text: root.count
                font.pixelSize: root.fontSize
                color: isRestart ? Appearance.colors.colOnWarningContainer : Appearance.colors.colOnLayer2
            }
            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: root.iconSize
                color: isRestart ? Appearance.colors.colOnWarningContainer : Appearance.colors.colOnLayer2
                rotation: expanded ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
