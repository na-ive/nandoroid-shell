import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."

/**
 * Network detail page for System Monitor.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        StyledText {
            text: "Network Activity"
            font.pixelSize: 24
            font.weight: Font.Bold
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer2
            radius: 16
            border.width: 0
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0
                
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 20
                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "Network Bandwidth"; font.pixelSize: 18; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                        StyledText { text: "Total Activity: " + ((SystemData.networkTotalRate) / (1024 * 1024)).toFixed(2) + " MB/s"; color: Appearance.colors.colSubtext; font.pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    RowLayout {
                        spacing: 24
                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "DOWNLOAD"; font.pixelSize: 10; font.weight: Font.Bold; color: "#81C995" }
                            StyledText { text: (SystemData.networkRxRate / (1024 * 1024)).toFixed(2) + " MB/s"; font.pixelSize: 16; font.weight: Font.Black; color: Appearance.m3colors.m3onSurface }
                        }
                        ColumnLayout {
                            spacing: 0
                            StyledText { text: "UPLOAD"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FF8A65" }
                            StyledText { text: (SystemData.networkTxRate / (1024 * 1024)).toFixed(2) + " MB/s"; font.pixelSize: 16; font.weight: Font.Black; color: Appearance.m3colors.m3onSurface; horizontalAlignment: Text.AlignRight }
                        }
                    }
                }
                
                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: 1
                    history: SystemData.networkRxHistory
                    lineColor: "#81C995"
                    fillColor: "#81C995"
                    maxValue: 1024 * 5 // 5MB/s scaling
                }

                // Center line
                Rectangle {
                    Layout.fillWidth: true
                    height: 2
                    color: Appearance.m3colors.m3outlineVariant
                    opacity: 0.5
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
