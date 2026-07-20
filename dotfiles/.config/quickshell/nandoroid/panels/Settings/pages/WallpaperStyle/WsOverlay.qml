import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Overlays"
        aliases: [
            "Notification Center", "Quick Settings", "Media Card", "Weather Card",
            "Performance Stats", "System Monitor"
        ]
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale

            MaterialSymbol {
                text: "layers"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Overlays"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        // ── Notification Center ──
        StyledText {
            text: "Notification Center"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary
            Layout.bottomMargin: 4 * Appearance.effectiveScale
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: showNcMediaRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: showNcMediaRow
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "music_note"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Media Card"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.media && Config.options.media.showMediaCard
                        onToggled: if (Config.ready && Config.options.media)
                            Config.options.media.showMediaCard = !Config.options.media.showMediaCard
                    }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: showNcWeatherRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: showNcWeatherRow
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "cloud"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Weather Card"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.weather && Config.options.weather.showInNotificationCenter
                        onToggled: if (Config.ready && Config.options.weather)
                            Config.options.weather.showInNotificationCenter = !Config.options.weather.showInNotificationCenter
                    }
                }
            }
        }

        // ── Quick Settings ──
        StyledText {
            text: "Quick Settings"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary
            Layout.topMargin: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: showQsPerfRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: showQsPerfRow
                    anchors.fill: parent
                    anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "monitoring"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Performance Stats"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats
                        onToggled: if (Config.ready && Config.options.quickSettings)
                            Config.options.quickSettings.showPerformanceStats = !Config.options.quickSettings.showPerformanceStats
                    }
                }
            }
        }
    }
}
