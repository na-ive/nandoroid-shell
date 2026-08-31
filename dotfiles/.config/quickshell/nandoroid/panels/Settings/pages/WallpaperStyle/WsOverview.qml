import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Overview"
        aliases: ["Workspaces", "Window Manager", "Expose"]
    }

    // ── Overview Settings Section ──
    ColumnLayout {
        id: overviewSettingsSection
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        readonly property bool isNiri: Config.ready && Config.options.overview && Config.options.overview.style === "niri"

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "grid_view"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Overview")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            // Style
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: overviewStyleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                        topMargin: 12 * Appearance.effectiveScale
                        bottomMargin: 12 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "style"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: [{ val: "default", label: I18nService.tr("Default") }, { val: "niri", label: I18nService.tr("Niri") }]
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: Config.ready && Config.options.overview ? Config.options.overview.style === modelData.val : modelData.val === "default"
                                colActive: Appearance.m3colors.m3primary; colActiveText: Appearance.m3colors.m3onPrimary; colInactive: Appearance.m3colors.m3surfaceContainerLow
                                onClicked: if (Config.ready && Config.options.overview) Config.options.overview.style = modelData.val
                            }
                        }
                    }
                }
            }

            // Rows
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewRowsRow.implicitHeight + (24 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: overviewRowsRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                        topMargin: 12 * Appearance.effectiveScale
                        bottomMargin: 12 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "reorder"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Rows")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }

                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        value: Config.ready && Config.options.overview ? Config.options.overview.rows : 2
                        from: 1; to: 5; stepSize: 1
                        decimals: 0
                        onValueChanged: if (Config.ready && Config.options.overview) Config.options.overview.rows = Math.round(value)
                    }
                }
            }

            // Columns
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewColsRow.implicitHeight + (24 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: overviewColsRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                        topMargin: 12 * Appearance.effectiveScale
                        bottomMargin: 12 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "view_week"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Columns")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }

                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        value: Config.ready && Config.options.overview ? Config.options.overview.columns : 5
                        from: 1; to: 10; stepSize: 1
                        decimals: 0
                        onValueChanged: if (Config.ready && Config.options.overview) Config.options.overview.columns = Math.round(value)
                    }
                }
            }

            // Scale
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewScaleRow.implicitHeight + (24 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: overviewScaleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                        topMargin: 12 * Appearance.effectiveScale
                        bottomMargin: 12 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "zoom_in"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Window Scale")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }

                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        value: {
                            if (!Config.ready || !Config.options.overview) return overviewSettingsSection.isNiri ? 50 : 15
                            return (overviewSettingsSection.isNiri ? (Config.options.overview.niriScale ?? 0.5) : Config.options.overview.scale) * 100
                        }
                        from: overviewSettingsSection.isNiri ? 10 : 5
                        to: overviewSettingsSection.isNiri ? 75 : 50
                        stepSize: overviewSettingsSection.isNiri ? 5 : 1
                        decimals: 0
                        suffix: "%"
                        onValueChanged: {
                            if (!Config.ready || !Config.options.overview) return
                            if (overviewSettingsSection.isNiri) Config.options.overview.niriScale = value / 100.0
                            else Config.options.overview.scale = value / 100.0
                        }
                    }
                }
            }

            // Workspace Spacing
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewSpacingRow.implicitHeight + (24 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: overviewSpacingRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                        topMargin: 12 * Appearance.effectiveScale
                        bottomMargin: 12 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "space_dashboard"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Workspace Spacing")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }

                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        value: Config.ready && Config.options.overview ? Config.options.overview.workspaceSpacing : 10
                        from: 0; to: 50; stepSize: 1
                        decimals: 0
                        suffix: "px"
                        onValueChanged: if (Config.ready && Config.options.overview) Config.options.overview.workspaceSpacing = Math.round(value)
                    }
                }
            }
        }
    }
}