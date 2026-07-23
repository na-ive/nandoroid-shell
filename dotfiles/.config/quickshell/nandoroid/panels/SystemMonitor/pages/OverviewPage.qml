import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../.."
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"
import ".."

/**
 * Overview page for the System Monitor.
 * Displays a summary of all key metrics.
 */
Item {
    id: root

    Flickable {
        anchors.fill: parent
        contentHeight: mainLayout.implicitHeight + (40 * Appearance.effectiveScale)
        clip: true
        
        ScrollBar.vertical: StyledScrollBar {}

        ColumnLayout {
            id: mainLayout
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 20 * Appearance.effectiveScale
            }
            spacing: 24 * Appearance.effectiveScale

            StyledText {
                text: "System Overview"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            // --- System Information Header ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 24 * Appearance.effectiveScale
                
                ColumnLayout {
                    spacing: 0
                        StyledText { text: "UPTIME"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext }
                    StyledText { text: SystemData.uptime || "--"; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                }
                
                ColumnLayout {
                    spacing: 0
                        StyledText { text: "LOAD AVG"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext }
                    StyledText { text: SystemData.loadAverage || "--"; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                }
                
                ColumnLayout {
                    spacing: 0
                        StyledText { text: "PROCESSES"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext }
                    StyledText { text: `${SystemData.processCount} (${SystemData.threadCount} threads)`; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                }
                
                Item { Layout.fillWidth: true }
            }

            // Top Row: Performance Graphs
            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 16 * Appearance.effectiveScale
                rowSpacing: 16 * Appearance.effectiveScale

                GraphCard {
                    title: "CPU Usage"
                    value: Math.round(SystemData.cpuUsage * 100) + "%"
                    subValue: `${SystemData.cpuTemperature}°C`
                    history: SystemData.cpuHistory
                    accentColor: Appearance.colors.colPrimary
                    Layout.fillWidth: true
                }

                // GPU card — always visible; shows a placeholder when no data
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 180 * Appearance.effectiveScale
                    radius: 16 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    border.color: Functions.ColorUtils.applyAlpha(
                        SystemData.availableGpus.length > 0
                            ? Appearance.m3colors.m3primary
                            : Appearance.colors.colSubtext,
                        Appearance.m3colors.darkmode ? 0.35 : 0.55
                    )
                    border.width: 2 * Appearance.effectiveScale

                    // ── Real GPU content ──────────────────────────────────
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale
                        visible: SystemData.hasValidGpuData

                        RowLayout {
                            Layout.fillWidth: true

                            StyledText {
                                text: "GPU"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.m3colors.m3onSurfaceVariant
                            }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: SystemData.availableGpus.length > 0
                                    ? (SystemData.availableGpus[0].temp > 0
                                        ? SystemData.availableGpus[0].temp + "°C"
                                        : "Ready")
                                    : "--"
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Black
                                color: Appearance.m3colors.m3onSurface
                            }
                        }

                        PerformanceGraph {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            history: []
                            lineColor: Appearance.m3colors.m3primary
                            fillColor: Appearance.m3colors.m3primary
                            maxValue: 100
                        }
                    }

                    // ── Fallback placeholder ──────────────────────────────
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8 * Appearance.effectiveScale
                        visible: !SystemData.hasValidGpuData

                        MaterialSymbol {

                            Layout.alignment: Qt.AlignHCenter
                            text: "videogame_asset_off"
                            iconSize: 28 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "GPU"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No GPU data found"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }


                GraphCard {
                    title: "Memory"
                    value: Math.round(SystemData.memUsage * 100) + "%"
                    subValue: `${SystemData.usedMemoryMB}MB / ${SystemData.totalMemoryMB}MB`
                    history: SystemData.memHistory
                    accentColor: "#8AB4F8"
                    Layout.fillWidth: true
                }

                GraphCard {
                    title: "Network"
                    value: (SystemData.networkRxRate / (1024 * 1024)).toFixed(2) + " MB/s"
                    subValue: `↓${(SystemData.networkRxRate / 1024).toFixed(0)}KB/s ↑${(SystemData.networkTxRate / 1024).toFixed(0)}KB/s`
                    accentColor: "#81C995"
                    Layout.fillWidth: true
                    
                    // Mirrored graph
                    customGraph: Component {
                        Item {
                            anchors.fill: parent
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                PerformanceGraph {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredHeight: 1
                                    history: SystemData.networkRxHistory
                                    lineColor: "#81C995"
                                    fillColor: "#81C995"
                                    maxValue: 1024 * 5
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 2 * Appearance.effectiveScale
                                    color: Appearance.m3colors.m3primary
                                    opacity: 0.5
                                    z: 10
                                }

                                PerformanceGraph {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.preferredHeight: 1
                                    history: SystemData.networkTxHistory
                                    lineColor: "#FF8A65"
                                    fillColor: "#FF8A65"
                                    inverted: true
                                    maxValue: 1024 * 5
                                }
                            }
                        }
                    }
                }

                GraphCard {
                    title: "Disk I/O"
                    value: (SystemData.diskTotalRate / (1024 * 1024)).toFixed(2) + " MB/s"
                    subValue: `R:${(SystemData.diskReadRate / (1024 * 1024)).toFixed(1)}MB/s W:${(SystemData.diskWriteRate / (1024 * 1024)).toFixed(1)}MB/s`
                    history: SystemData.diskReadHistory
                    accentColor: Appearance.m3colors.m3error
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    Layout.preferredHeight: 140 * Appearance.effectiveScale
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }

    // Helper Card Component
    component GraphCard: Rectangle {
        id: card
        property string title
        property string value
        property string subValue: ""
        property var history
        property color accentColor
        property Component customGraph: null
        
        Layout.preferredHeight: 180 * Appearance.effectiveScale
        radius: 16 * Appearance.effectiveScale
        color: Appearance.colors.colLayer2
        border.color: Functions.ColorUtils.applyAlpha(card.accentColor, Appearance.m3colors.darkmode ? 0.45 : 0.75)
        border.width: 2 * Appearance.effectiveScale
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 0
            
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 12 * Appearance.effectiveScale
                ColumnLayout {
                    spacing: -2 * Appearance.effectiveScale
                    StyledText {
                        text: card.title
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    StyledText {
                        visible: card.subValue !== ""
                        text: card.subValue
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colSubtext
                    }
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: card.value
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Black
                    color: Appearance.m3colors.m3onSurface
                }
            }
            
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: card.customGraph ? card.customGraph : defaultGraph
                
                Component {
                    id: defaultGraph
                    PerformanceGraph {
                        anchors.fill: parent
                        history: card.history
                        lineColor: card.accentColor
                        fillColor: card.accentColor
                        maxValue: 100
                    }
                }
            }
        }
    }
}
