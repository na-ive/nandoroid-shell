import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "System Interface"
        aliases: ["Privacy Indicators", "Window Snapping", "Region Selector", "Desktop Gestures", "Desktop Interactions", "Notifications", "Notification Duration"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "settings_suggest"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("System Interface")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Privacy Indicators (whole card clickable)
        SegmentedWrapper {
            id: privacyCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, privRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: privacyCard.rTopLeft
                topRightRadius: privacyCard.rTopRight
                bottomLeftRadius: privacyCard.rBottomLeft
                bottomRightRadius: privacyCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.privacy) {
                        Config.options.privacy.enable = !Config.options.privacy.enable;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Show Android-style green pill when microphone or camera is active.")
                }
            }

            RowLayout {
                id: privRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "visibility"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Privacy Indicators")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.privacy && Config.options.privacy.enable)
                    onToggled: {
                        if (Config.ready && Config.options.privacy) {
                            Config.options.privacy.enable = !Config.options.privacy.enable;
                        }
                    }
                }
            }
        }

        // Region Selector: Window Snapping (whole card clickable)
        SegmentedWrapper {
            id: snappingCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, snapRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: snappingCard.rTopLeft
                topRightRadius: snappingCard.rTopRight
                bottomLeftRadius: snappingCard.rBottomLeft
                bottomRightRadius: snappingCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.regionSelector) {
                        Config.options.regionSelector.targetRegions.windows = !Config.options.regionSelector.targetRegions.windows;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Enable automatic window detection and snapping when selecting a region.")
                }
            }

            RowLayout {
                id: snapRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "grid_view"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Region Selector: Window Snapping")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows)
                    onToggled: {
                        if (Config.ready && Config.options.regionSelector) {
                            Config.options.regionSelector.targetRegions.windows = !Config.options.regionSelector.targetRegions.windows;
                        }
                    }
                }
            }
        }

        // Desktop Interactions (whole card clickable)
        SegmentedWrapper {
            id: interactionsCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: interactionsCard.rTopLeft
                topRightRadius: interactionsCard.rTopRight
                bottomLeftRadius: interactionsCard.rBottomLeft
                bottomRightRadius: interactionsCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.interactions && Config.options.interactions.desktop) {
                        Config.options.interactions.desktop.blockWhenWindowsOpen = !Config.options.interactions.desktop.blockWhenWindowsOpen;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Block right-click, swipe-up, and widget input when windows are open.")
                }
            }

            RowLayout {
                id: desktopRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "ads_click"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Block Desktop Interactions When Windows Open")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.interactions && Config.options.interactions.desktop)
                        ? Config.options.interactions.desktop.blockWhenWindowsOpen : true
                    onToggled: {
                        if (Config.ready && Config.options.interactions && Config.options.interactions.desktop) {
                            Config.options.interactions.desktop.blockWhenWindowsOpen = !Config.options.interactions.desktop.blockWhenWindowsOpen;
                        }
                    }
                }
            }
        }

        // Notification Popup Duration
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, notifRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: notifRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "notifications"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Notification Duration")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledStepper {
                    Layout.alignment: Qt.AlignVCenter
                    from: 1; to: 10; stepSize: 1
                    decimals: 0
                    suffix: "s"
                    value: Config.ready ? Config.options.notifications.timeout_ms / 1000 : 2
                    onValueChanged: if (Config.ready) Config.options.notifications.timeout_ms = value * 1000
                }
            }
        }
    }
}
