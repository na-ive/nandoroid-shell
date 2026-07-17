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
        searchString: "Performance"
        aliases: ["CPU", "RAM", "Monitoring", "Quick Settings", "Performance Stats", "Interval", "Update", "Refresh"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "monitoring"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Performance Monitoring"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: perfStatsRow.implicitHeight + 40 * Appearance.effectiveScale
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8 * Appearance.effectiveScale
                fullRadius: 20 * Appearance.effectiveScale
                
                RowLayout {
                    id: perfStatsRow
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText {
                            text: "Show Performance Stats"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display CPU, RAM, and Disk usage in the Quick Settings panel."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    AndroidToggle {
                            checked: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats)
                            onToggled: {
                                if (Config.ready && Config.options.quickSettings) {
                                    Config.options.quickSettings.showPerformanceStats = !Config.options.quickSettings.showPerformanceStats;
                    }
                    }
                    }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: intervalRow.implicitHeight + 40 * Appearance.effectiveScale
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8 * Appearance.effectiveScale
                fullRadius: 20 * Appearance.effectiveScale

                RowLayout {
                    id: intervalRow
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText {
                            text: "Update Interval"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "How often to refresh system data (statusbar, quick settings, desktop widget)."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StyledSlider {
                        id: intervalSlider
                        Layout.preferredWidth: 200 * Appearance.effectiveScale
                        value: Config.ready ? Config.options.appearance.systemMonitor.updateInterval : 3000
                        defaultValue: 3000
                        from: 1000; to: 10000; stepSize: 500
                        onMoved: if (Config.ready) Config.options.appearance.systemMonitor.updateInterval = Math.round(value)
                    }

                    StyledText {
                        text: {
                            let ms = Config.ready ? Config.options.appearance.systemMonitor.updateInterval : 3000;
                            if (ms < 2000) return ms + "ms";
                            return (ms / 1000).toFixed(ms % 1000 === 0 ? 0 : 1) + "s";
                        }
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 48 * Appearance.effectiveScale
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        
    }
}

