import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."

/**
 * CPU detail page for System Monitor.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        StyledText {
            text: "CPU Performance"
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
                        StyledText { text: SystemData.cpuModel; font.pixelSize: 16; font.weight: Font.Medium }
                        StyledText { text: SystemData.cpuCores + " Cores / Threads"; color: Appearance.colors.colSubtext }
                    }
                    Item { Layout.fillWidth: true }
                    StyledText { 
                        text: Math.round(SystemData.cpuUsage * 100) + "%"
                        font.pixelSize: 32
                        font.weight: Font.Black
                        color: Appearance.m3colors.m3primary
                    }
                }
                
                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    history: SystemData.cpuHistory
                    lineColor: Appearance.m3colors.m3primary
                    fillColor: Appearance.m3colors.m3primary
                    maxValue: 100
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: "Temperature: " + Math.round(SystemData.cpuTemperature) + "°C"; font.weight: Font.Bold }
                    Item { Layout.fillWidth: true }
                    StyledText { text: "Load Average: " + SystemData.loadAverage; color: Appearance.colors.colSubtext }
                }
            }
        }
    }
}
