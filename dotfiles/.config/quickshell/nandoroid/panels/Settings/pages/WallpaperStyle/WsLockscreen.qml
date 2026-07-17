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
                Layout.topMargin: 12 * Appearance.effectiveScale
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
                        text: "Lockscreen"
                        font.pixelSize: Appearance.font.pixelSize.large
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
                        Layout.fillWidth: true
                        implicitHeight: showWeatherRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showWeatherRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "cloud"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show Weather Text"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
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
                        implicitHeight: weatherTextRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: weatherTextRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Weather text color"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "adaptive", label: "Adaptive" },
                                        { id: "light",    label: "Light" },
                                        { id: "dark",     label: "Dark" }
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

                    // ── Show Date ──────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: showLockscreenDateRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showLockscreenDateRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "event"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show date on lockscreen"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.appearance.clock.showLockscreenDate
                                onToggled: if(Config.ready) Config.options.appearance.clock.showLockscreenDate = !Config.options.appearance.clock.showLockscreenDate
                            }
                        }
                    }

                    // ── Show Media Controls ──────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: showMediaRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showMediaRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "movie"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show Media Controls"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
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
            }
}
