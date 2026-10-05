import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Vertical navigation rail (adapted from end4-pC DashboardGroupRail).
 * Square (1:1) icon + label buttons on a full-height M3 rail card.
 * Active button morphs: corner radius (14 <-> 18) and per-group accent colors.
 * Used by the Dashboard tab strip.
 *
 * Notes:
 * - Corner radii are bound directly (no outer Behavior): RippleButton already
 *   animates its corner props internally, so a second animation stage would
 *   only add lag.
 * - Button content is wrapped so vertical centering can't be disturbed by
 *   the Button's internal contentItem handling.
 *
 * Usage:
 *   DashGroupRail {
 *       groups: [
 *           { name: "Calendar", icon: "calendar_today",
 *             container: ..., onContainer: ..., accent: ..., onAccent: ...,
 *             count: 0 }
 *       ]
 *       current: root.currentTab
 *       onPicked: (index) => root.currentTab = index
 *   }
 */
Item {
    id: root

    property var groups: []
    property int current: 0
    // Square buttons sized to fill the strip top-to-bottom exactly (end4 formula),
    // narrow fixed gaps. No max clamp: the boxes grow/shrink with the panel.
    readonly property real railGap: 12 * Appearance.effectiveScale
    readonly property real boxSize: (height - railGap * Math.max(0, groups.length - 1)) / Math.max(1, groups.length)

    signal picked(int index)

    ColumnLayout {
        id: railCol
        anchors.fill: parent
        spacing: root.railGap

        Repeater {
            model: root.groups

            delegate: Item {
                id: box

                required property int index
                required property var modelData
                readonly property bool on: root.current === index
                readonly property real morphRadius: (box.on ? 18 : 14) * Appearance.effectiveScale

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: root.boxSize
                implicitHeight: root.boxSize

                Item {
                    id: lift
                    anchors.fill: parent

                    StyledRectangularShadow {
                        target: plate
                        opacity: box.on ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                    }

                    Rectangle {
                        id: plate
                        anchors.fill: parent
                        radius: button.topLeftRadius
                        color: "transparent"
                    }

                    RippleButton {
                        id: button
                        anchors.fill: parent
                        toggled: box.on
                        topLeftRadius: box.morphRadius
                        topRightRadius: box.morphRadius
                        bottomLeftRadius: box.morphRadius
                        bottomRightRadius: box.morphRadius
                        colBackground: box.modelData.container
                        colBackgroundHover: Functions.ColorUtils.mix(box.modelData.container, box.modelData.onContainer, 0.9)
                        colRipple: Functions.ColorUtils.mix(box.modelData.container, box.modelData.onContainer, 0.8)
                        colBackgroundToggled: box.modelData.accent
                        colBackgroundToggledHover: Functions.ColorUtils.mix(box.modelData.accent, box.modelData.onAccent, 0.9)
                        onClicked: root.picked(box.index)

                        contentItem: Item {
                            anchors.fill: parent

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 1 * Appearance.effectiveScale

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: box.modelData.icon
                                    iconSize: Appearance.font.pixelSize.huge
                                    fill: box.on ? 1 : 0
                                    color: box.on ? box.modelData.onAccent : box.modelData.onContainer
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: box.modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    font.weight: Font.DemiBold
                                    color: box.on ? box.modelData.onAccent : box.modelData.onContainer
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: (box.modelData.count ?? 0) > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -5 * Appearance.effectiveScale
                        anchors.rightMargin: -5 * Appearance.effectiveScale
                        implicitHeight: 20 * Appearance.effectiveScale
                        implicitWidth: Math.max(20 * Appearance.effectiveScale, badgeText.implicitWidth + 10 * Appearance.effectiveScale)
                        radius: 10 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHighest

                        StyledText {
                            id: badgeText
                            anchors.centerIn: parent
                            text: box.modelData.count ?? 0
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.Bold
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                }
            }
        }
    }
}
