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
    // ── Lockscreen Section ──
    ColumnLayout {
        id: lockscreenStyleSection
        Layout.fillWidth: true
        Layout.bottomMargin: 16 * Appearance.effectiveScale
        spacing: 4 * Appearance.effectiveScale
                
                SearchHandler { 
                    visible: false
                    searchString: "Lockscreen"
                    aliases: ["Lock", "Lock Screen"]
                }
                
                SearchHandler {
                    visible: false
                    searchString: "Lockscreen Clock"
                    aliases: ["Clock", "Time", "Watch", "Clock Style"]
                }
    
                // Section Header
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
    
                    MaterialSymbol {
                        text: "lock"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: I18nService.tr("Lockscreen")
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
    
                    // ── Show Weather ──────────────
                    SegmentedWrapper {
                        id: showWeatherCard
                        Layout.fillWidth: true
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, showWeatherRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: Appearance.m3colors.m3surfaceContainerHigh
                            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                            buttonRadius: 0
                            topLeftRadius: showWeatherCard.rTopLeft
                            topRightRadius: showWeatherCard.rTopRight
                            bottomLeftRadius: showWeatherCard.rBottomLeft
                            bottomRightRadius: showWeatherCard.rBottomRight
                            onClicked: if(Config.ready) Config.options.lock.showWeather = !Config.options.lock.showWeather
                        }

                        RowLayout {
                            id: showWeatherRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "cloud"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Show Weather Text"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.lock.showWeather
                                onToggled: if(Config.ready) Config.options.lock.showWeather = !Config.options.lock.showWeather
                            }
                        }
                    }

                    // ── Weather text color mode (Adaptive) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        visible: Config.ready && (Config.options.lock?.showWeather ?? true)
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, weatherTextRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: weatherTextRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Weather text color"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "adaptive", label: I18nService.tr("Adaptive") },
                                        { id: "light",    label: I18nService.tr("Light") },
                                        { id: "dark",     label: I18nService.tr("Dark") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.lock && Config.options.lock.weather
                                            ? Config.options.lock.weather.textColorMode === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.lock && Config.options.lock.weather)
                                            Config.options.lock.weather.textColorMode = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Show Media Controls ──────────────
                    SegmentedWrapper {
                        id: showMediaCard
                        Layout.fillWidth: true
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, showMediaRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: Appearance.m3colors.m3surfaceContainerHigh
                            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                            buttonRadius: 0
                            topLeftRadius: showMediaCard.rTopLeft
                            topRightRadius: showMediaCard.rTopRight
                            bottomLeftRadius: showMediaCard.rBottomLeft
                            bottomRightRadius: showMediaCard.rBottomRight
                            onClicked: if(Config.ready) Config.options.lock.showMediaCard = !Config.options.lock.showMediaCard
                        }

                        RowLayout {
                            id: showMediaRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "movie"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Show Media Controls"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.lock.showMediaCard
                                onToggled: if(Config.ready) Config.options.lock.showMediaCard = !Config.options.lock.showMediaCard
                            }
                        }
                    }
                    }
                }
    
            // ── Lockscreen Clock Section ──
            WsClock { 
                Layout.fillWidth: true
                isDedicatedContext: true
                dedicatedIsLock: true 
                isSubSection: true
            }
}
