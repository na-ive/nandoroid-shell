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
        searchString: "Media Controls"
        aliases: ["Duplicates", "Plasma Integration", "Browser Players", "Priority", "Hover"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "music_note"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Media Management")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Media Player Priority (whole card focuses the input)
        SegmentedWrapper {
            id: priorityCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, mediaRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: priorityCard.rTopLeft
                topRightRadius: priorityCard.rTopRight
                bottomLeftRadius: priorityCard.rBottomLeft
                bottomRightRadius: priorityCard.rBottomRight
                onClicked: priorityInput.forceActiveFocus()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Prioritize specific players. Put highest priority first (e.g. 'spotify, firefox'). Case-insensitive.")
                }
            }

            RowLayout {
                id: mediaRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "sort"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Media Player Priority")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledTextInput {
                    id: priorityInput
                    Layout.preferredWidth: 200 * Appearance.effectiveScale
                    inputRadius: 24
                    text: (Config.ready && Config.options.media) ? Config.options.media.priority : ""
                    onEditingFinished: { if (Config.ready && Config.options.media) Config.options.media.priority = text; }
                }
            }
        }

        // Filter Duplicate Players (whole card clickable)
        SegmentedWrapper {
            id: dupFilterCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, dupFilterRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: dupFilterCard.rTopLeft
                topRightRadius: dupFilterCard.rTopRight
                bottomLeftRadius: dupFilterCard.rBottomLeft
                bottomRightRadius: dupFilterCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.media) {
                        Config.options.media.filterDuplicatePlayers = !Config.options.media.filterDuplicatePlayers;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Hide native browser players while Plasma browser integration is active, and merge duplicate entries.")
                }
            }

            RowLayout {
                id: dupFilterRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "filter_list"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Filter Duplicate Players")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.media && (Config.options.media.filterDuplicatePlayers ?? true))
                    onToggled: {
                        if (Config.ready && Config.options.media) {
                            Config.options.media.filterDuplicatePlayers = !Config.options.media.filterDuplicatePlayers;
                        }
                    }
                }
            }
        }

        // Dynamic Island Hover (whole card clickable)
        SegmentedWrapper {
            id: islandHoverCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, dynamicIslandHoverRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: islandHoverCard.rTopLeft
                topRightRadius: islandHoverCard.rTopRight
                bottomLeftRadius: islandHoverCard.rBottomLeft
                bottomRightRadius: islandHoverCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.media) {
                        Config.options.media.enableMediaHover = !Config.options.media.enableMediaHover;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Show the media controls popup when hovering over the Dynamic Island.")
                }
            }

            RowLayout {
                id: dynamicIslandHoverRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "touch_app"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Dynamic Island Hover")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.media && Config.options.media.enableMediaHover)
                    onToggled: {
                        if (Config.ready && Config.options.media) {
                            Config.options.media.enableMediaHover = !Config.options.media.enableMediaHover;
                        }
                    }
                }
            }
        }

        // Notch Media Style
        SegmentedWrapper {
            id: notchStyleCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, notchMediaStyleRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            visible: Config.ready && Config.options.media && Config.options.media.enableMediaHover

            MouseArea {
                id: notchStyleHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: notchStyleHoverArea.containsMouse
                    text: I18nService.tr("Choose between a compact mini HUD or a full-featured media card.")
                }
            }

            RowLayout {
                id: notchMediaStyleRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "style"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Notch Media Style")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Repeater {
                        model: [
                            { id: "mini", label: I18nService.tr("Mini HUD") },
                            { id: "full", label: I18nService.tr("Full Card") }
                        ]
                        delegate: SegmentedButton {
                            required property var modelData
                            buttonText: modelData.label
                            isHighlighted: Config.ready && Config.options.media
                                ? (Config.options.media.notchMediaStyle ?? "mini") === modelData.id
                                : modelData.id === "mini"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready && Config.options.media)
                                Config.options.media.notchMediaStyle = modelData.id
                        }
                    }
                }
            }
        }
    }
}
