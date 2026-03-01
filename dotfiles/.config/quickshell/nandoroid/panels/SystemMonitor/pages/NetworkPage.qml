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
                
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        StyledText { text: "Download: " + (SystemData.networkRxRate / (1024 * 1024)).toFixed(2) + " MB/s"; font.pixelSize: 16; font.weight: Font.Medium; color: "#81C995" }
                        StyledText { text: "Upload: " + (SystemData.networkTxRate / (1024 * 1024)).toFixed(2) + " MB/s"; font.pixelSize: 16; font.weight: Font.Medium; color: "#F28B82" }
                    }
                }
                
                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    history: SystemData.networkRxHistory
                    lineColor: "#81C995"
                    fillColor: "#81C995"
                    maxValue: 10 // Adjust based on common speeds or make it dynamic
                }

                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    history: SystemData.networkTxHistory
                    lineColor: "#F28B82"
                    fillColor: "#F28B82"
                    maxValue: 10
                }
            }
        }
    }
}
