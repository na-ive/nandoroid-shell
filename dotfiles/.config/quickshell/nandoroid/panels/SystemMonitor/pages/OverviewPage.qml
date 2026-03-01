import QtQuick
import QtQuick.Layouts
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24

        StyledText {
            text: "System Overview"
            font.pixelSize: 24
            font.weight: Font.Bold
            color: Appearance.m3colors.m3onSurface
        }

        // Top Row: Performance Graphs
        GridLayout {
            columns: 2
            Layout.fillWidth: true
            columnSpacing: 16
            rowSpacing: 16

            GraphCard {
                title: "CPU Usage"
                value: Math.round(SystemData.cpuUsage * 100) + "%"
                history: SystemData.cpuHistory
                accentColor: Appearance.colors.colPrimary
                Layout.fillWidth: true
            }

            // GPU card — always visible; shows a placeholder when no data
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 180
                radius: 16
                color: Appearance.colors.colLayer2
                border.color: Functions.ColorUtils.applyAlpha(
                    SystemData.availableGpus.length > 0
                        ? Appearance.m3colors.m3primary
                        : Appearance.colors.colSubtext,
                    Appearance.m3colors.darkmode ? 0.35 : 0.55
                )
                border.width: 2

                // ── Real GPU content ──────────────────────────────────
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8
                    visible: SystemData.availableGpus.length > 0

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: "GPU"
                            font.pixelSize: 14
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
                            font.pixelSize: 18
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
                    spacing: 8
                    visible: SystemData.availableGpus.length === 0

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "videogame_asset_off"
                        iconSize: 28
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "GPU"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No GPU data found"
                        font.pixelSize: 12
                        color: Appearance.colors.colSubtext
                    }
                }
            }


            GraphCard {
                title: "Memory"
                value: Math.round(SystemData.memUsage * 100) + "%"
                history: SystemData.memHistory
                accentColor: "#8AB4F8"
                Layout.fillWidth: true
            }

            GraphCard {
                title: "Network"
                value: (SystemData.networkRxRate / (1024 * 1024)).toFixed(2) + " MB/s"
                history: SystemData.networkRxHistory
                accentColor: "#81C995"
                Layout.fillWidth: true
            }

            GraphCard {
                title: "Disk I/O"
                value: (SystemData.diskReadRate / (1024 * 1024)).toFixed(2) + " MB/s"
                history: SystemData.diskReadHistory
                accentColor: Appearance.m3colors.m3error
                Layout.fillWidth: true
                Layout.columnSpan: 2
                implicitHeight: 140
            }
        }
        
        Item { Layout.fillHeight: true }
    }

    // Helper Card Component
    component GraphCard: Rectangle {
        id: card
        property string title
        property string value
        property var history
        property color accentColor
        
        implicitHeight: 180
        radius: 16
        // Reverting to stable flat color as requested
        color: Appearance.colors.colLayer2
        border.color: Functions.ColorUtils.applyAlpha(card.accentColor, Appearance.m3colors.darkmode ? 0.45 : 0.75)
        border.width: 2
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: card.title
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Appearance.m3colors.m3onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: card.value
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: Appearance.m3colors.m3onSurface
                }
            }
            
            PerformanceGraph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                history: card.history
                lineColor: card.accentColor
                fillColor: card.accentColor
                maxValue: 100
            }
        }
    }
}
