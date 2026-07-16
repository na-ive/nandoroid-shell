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
    
    SearchHandler { searchString: "Media Controls" }

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
                text: "Media Management"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: mediaRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: mediaRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.maximumWidth: 400 * Appearance.effectiveScale
                    StyledText {
                        text: "Media Player Priority"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Prioritize specific players. Put highest priority first (e.g. 'spotify, firefox'). Case-insensitive."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    Layout.preferredWidth: 200 * Appearance.effectiveScale
                    height: 48 * Appearance.effectiveScale
                    radius: 12 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerLow
                    border.width: priorityInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                    border.color: Appearance.colors.colPrimary

                    TextInput {
                        id: priorityInput
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        text: (Config.ready && Config.options.media) ? Config.options.media.priority : ""
                        onEditingFinished: { if (Config.ready && Config.options.media) Config.options.media.priority = text; }
                    }
                }
            }
        }

        // --- Show Media Card Toggle (Notification Center) ---
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: showMediaCardRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: showMediaCardRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.maximumWidth: 400 * Appearance.effectiveScale
                    StyledText {
                        text: "Show Media Card"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Show the media player card in the Notification Center."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                Item { Layout.fillWidth: true }

                // Custom Switch
                AndroidToggle {
                        checked: (Config.ready && Config.options.media && Config.options.media.showMediaCard)
                        onToggled: {
                            if (Config.ready && Config.options.media) {
                                Config.options.media.showMediaCard = !Config.options.media.showMediaCard;
                    }
                    }
                }
            }
        }

        // --- Dynamic Island Hover Toggle ---
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: dynamicIslandHoverRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: dynamicIslandHoverRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.maximumWidth: 400 * Appearance.effectiveScale
                    StyledText {
                        text: "Dynamic Island Hover"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Show the media controls popup when hovering over the Dynamic Island."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
                Item { Layout.fillWidth: true }

                // Custom Switch
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

        // --- Notch Media Style (Only visible if Hover is enabled) ---
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: notchMediaStyleRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh
            visible: Config.ready && Config.options.media && Config.options.media.enableMediaHover

            RowLayout {
                id: notchMediaStyleRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Layout.fillWidth: true
                    StyledText {
                        text: "Notch Media Style"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Choose between a compact mini HUD or a full-featured media card."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale
                    Repeater {
                        model: [
                            { id: "mini", label: "Mini HUD" },
                            { id: "full", label: "Full Card" }
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
