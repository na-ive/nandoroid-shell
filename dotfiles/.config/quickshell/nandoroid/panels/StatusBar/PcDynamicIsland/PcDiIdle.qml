import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../../core"
import "../../../services"
import "../../../widgets"

Item {
    id: diIdleRoot
    required property Item di
    anchors.fill: parent
    // NOTE: plain clip on purpose, no layer/OpacityMask around the row —
    // rasterizing the whole row into a layer makes the clock text blurry
    // while the pill width animates. Only the avatar itself is masked.
    clip: true

    readonly property bool systemIconsElsewhere: {
        if (!Config.ready || !Config.options.statusBar) return false
        const left = Config.options.statusBar.leftModules ?? []
        const right = Config.options.statusBar.rightModules ?? []
        return left.includes("statusIconsGroup") || right.includes("statusIconsGroup")
    }

    // Hover state (driven by di.idleExpanded in PcDynamicIsland.qml,
    // same pattern as media / timer controls).
    readonly property bool showExtra: di.idleExpanded ?? false

    readonly property string distroOrUptime: {
        const descMode = Config.ready && Config.options.profile ? (Config.options.profile.descriptionText || "::distro::") : "::distro::"
        if (descMode === "::uptime::") return I18nService.tr("Up ") + DateTime.uptime
        return SystemInfo.distroName || "Linux"
    }
    readonly property string dateText: DateTime.currentDate

    Rectangle {
        id: avatarRect
        width: di.isMaterial ? di.pillHeight : di.pillHeight - 8
        height: di.isMaterial ? di.pillHeight : di.pillHeight - 8
        anchors {
            left: parent.left
            leftMargin: di.isMaterial ? 0 : 4
            verticalCenter: parent.verticalCenter
        }
        radius: width / 2
        color: Appearance.colors.colPrimaryContainer

        Image {
            id: avatarImage
            anchors.fill: parent
            source: Config.ready && Config.options.profile && Config.options.profile.avatarPicture !== ""
                ? "file://" + Config.options.profile.avatarPicture
                : "file:///home/" + (Quickshell.env("USER") ?? "user") + "/.face"
            sourceSize.width: avatarImage.width * 2
            sourceSize.height: avatarImage.height * 2
            fillMode: Image.PreserveAspectCrop
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: avatarRect.width
                    height: avatarRect.height
                    radius: avatarRect.radius
                }
            }
            onStatusChanged: {
                if (status === Image.Error)
                    visible = false
            }
        }
    }

    // Hidden metrics — measure the widest hover line so the pill
    // width stays stable and never shakes on text change.
    StyledText {
        id: dateMetrics
        visible: false
        text: diIdleRoot.dateText
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.weight: Font.DemiBold
    }
    StyledText {
        id: subMetrics
        visible: false
        text: diIdleRoot.distroOrUptime
        font.pixelSize: Appearance.font.pixelSize.smallest
    }

    ColumnLayout {
        id: infoColumn
        anchors {
            left: avatarRect.right
            leftMargin: 8
            verticalCenter: parent.verticalCenter
            right: rightSideRow.left
            rightMargin: 8
        }
        spacing: di.isMaterial ? -2 : -4
        opacity: diIdleRoot.showExtra ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        StyledText {
            Layout.fillWidth: true
            text: diIdleRoot.dateText
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colNotchText
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
        StyledText {
            Layout.fillWidth: true
            text: diIdleRoot.distroOrUptime
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colNotchText
            opacity: 0.7
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }

        readonly property real widestLineWidth: Math.max(dateMetrics.implicitWidth, subMetrics.implicitWidth)
    }

    RowLayout {
        id: rightSideRow
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 8

        RowLayout {
            id: idleIconsRow
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Revealer {
                reveal: !diIdleRoot.systemIconsElsewhere && (Audio.source?.audio?.muted ?? false)
                MaterialSymbol {
                    text: "mic_off"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colNotchText
                }
            }

            Revealer {
                reveal: !diIdleRoot.systemIconsElsewhere && (Audio.sink?.audio?.muted ?? false)
                MaterialSymbol {
                    text: "volume_off"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colNotchText
                }
            }

            Revealer {
                reveal: (Notifications.unread ?? 0) > 0
                Item {
                    implicitWidth: notifRow.implicitWidth
                    implicitHeight: notifRow.implicitHeight

                    RowLayout {
                        id: notifRow
                        spacing: 2
                        MaterialSymbol {
                            text: "notifications"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colNotchText
                        }
                        StyledText {
                            text: `${Notifications.unread}`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.features: { "tnum": 1 }
                            color: Appearance.colors.colNotchText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen
                    }
                }
            }
        }

        StyledText {
            id: nowLabel
            Layout.alignment: Qt.AlignVCenter
            text: DateTime.currentTime
            font.pixelSize: Appearance.font.pixelSize.small
            font.features: { "tnum": 1 }
            color: Appearance.colors.colNotchText
        }
    }

    // Collapsed width: avatar + clock only (previous behavior).
    readonly property real computedCollapsedWidth: avatarRect.width
        + (di.isMaterial ? 0 : 4)
        + 10
        + rightSideRow.implicitWidth
        + 10

    // Expanded width: avatar + hover info + clock.
    readonly property real computedExpandedWidth: avatarRect.width
        + (di.isMaterial ? 8 : 12)
        + infoColumn.widestLineWidth
        + 12
        + rightSideRow.implicitWidth
        + (di.isMaterial ? 0 : 4)
        + 10

    onComputedCollapsedWidthChanged: di.idleTextContentWidth = computedCollapsedWidth
    onComputedExpandedWidthChanged: di.idleExpandedContentWidth = computedExpandedWidth
    Component.onCompleted: {
        di.idleTextContentWidth = computedCollapsedWidth
        di.idleExpandedContentWidth = computedExpandedWidth
    }
}
