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
            "Performance Stats", "System Monitor", "Banner Image"
        ]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale

            MaterialSymbol {
                text: "layers"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Overlays")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        // ── Notification Center ──
        StyledText {
            text: I18nService.tr("Notification Center")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }

        ColumnLayout {
            id: weatherColumn
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            readonly property bool weatherServiceOn: Config.ready && (Config.options.weather?.enable ?? true)

            SegmentedWrapper {
                id: showNcMediaCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, showNcMediaRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: showNcMediaCard.rTopLeft
                    topRightRadius: showNcMediaCard.rTopRight
                    bottomLeftRadius: showNcMediaCard.rBottomLeft
                    bottomRightRadius: showNcMediaCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.media)
                        Config.options.media.showMediaCard = !Config.options.media.showMediaCard
                }

                RowLayout {
                    id: showNcMediaRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "music_note"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Media Card"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.media && Config.options.media.showMediaCard
                        onToggled: if (Config.ready && Config.options.media)
                            Config.options.media.showMediaCard = !Config.options.media.showMediaCard
                    }
                }
            }

            SegmentedWrapper {
                id: showNcWeatherCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, showNcWeatherRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                opacity: weatherColumn.weatherServiceOn ? 1.0 : 0.5

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: showNcWeatherCard.rTopLeft
                    topRightRadius: showNcWeatherCard.rTopRight
                    bottomLeftRadius: showNcWeatherCard.rBottomLeft
                    bottomRightRadius: showNcWeatherCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.weather && weatherColumn.weatherServiceOn)
                        Config.options.weather.showInNotificationCenter = !Config.options.weather.showInNotificationCenter
                }

                RowLayout {
                    id: showNcWeatherRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: "cloud"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText {
                            text: I18nService.tr("Show Weather Card")
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: I18nService.tr("Enable Weather Service first")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            visible: !weatherColumn.weatherServiceOn
                        }
                    }

                    Item { Layout.fillWidth: true }

                    AndroidToggle {
                        Layout.alignment: Qt.AlignVCenter
                        enabled: weatherColumn.weatherServiceOn
                        checked: Config.ready && Config.options.weather
                            && weatherColumn.weatherServiceOn
                            && Config.options.weather.showInNotificationCenter
                        onToggled: if (Config.ready && Config.options.weather)
                            Config.options.weather.showInNotificationCenter = !Config.options.weather.showInNotificationCenter
                    }
                }
            }
        }

        // ── Quick Settings ──
        StyledText {
            text: I18nService.tr("Quick Settings")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
            Layout.topMargin: 12 * Appearance.effectiveScale
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            SegmentedWrapper {
                id: showQsPerfCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, showQsPerfRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: showQsPerfCard.rTopLeft
                    topRightRadius: showQsPerfCard.rTopRight
                    bottomLeftRadius: showQsPerfCard.rBottomLeft
                    bottomRightRadius: showQsPerfCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.quickSettings)
                        Config.options.quickSettings.showPerformanceStats = !Config.options.quickSettings.showPerformanceStats
                }

                RowLayout {
                    id: showQsPerfRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "monitoring"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Performance Stats"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats
                        onToggled: if (Config.ready && Config.options.quickSettings)
                            Config.options.quickSettings.showPerformanceStats = !Config.options.quickSettings.showPerformanceStats
                    }
                }
            }

            SegmentedWrapper {
                id: showQsBannerCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, showQsBannerRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: showQsBannerCard.rTopLeft
                    topRightRadius: showQsBannerCard.rTopRight
                    bottomLeftRadius: showQsBannerCard.rBottomLeft
                    bottomRightRadius: showQsBannerCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.quickSettings)
                        Config.options.quickSettings.showBanner = !Config.options.quickSettings.showBanner
                }

                RowLayout {
                    id: showQsBannerRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "panorama"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Banner Image"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.quickSettings && Config.options.quickSettings.showBanner
                        onToggled: if (Config.ready && Config.options.quickSettings)
                            Config.options.quickSettings.showBanner = !Config.options.quickSettings.showBanner
                    }
                }
            }
        }
    }
}
