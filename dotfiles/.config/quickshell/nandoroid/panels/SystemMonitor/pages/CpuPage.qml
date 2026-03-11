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
                        spacing: 0
                        StyledText { text: SystemData.cpuModel; font.pixelSize: 16; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                        StyledText { 
                            text: `${SystemData.physicalCores} Cores / ${SystemData.cpuThreads} Threads`; 
                            color: Appearance.colors.colSubtext; 
                            font.pixelSize: 12 
                        }
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
                    spacing: 20
                    
                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "TEMPERATURE"; font.pixelSize: 10; font.weight: Font.Bold; color: Appearance.m3colors.m3outline }
                        StyledText { text: Math.round(SystemData.cpuTemperature) + "°C"; font.weight: Font.Medium; font.pixelSize: 14 }
                    }

                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "LOAD AVERAGE"; font.pixelSize: 10; font.weight: Font.Bold; color: Appearance.m3colors.m3outline }
                        StyledText { text: SystemData.loadAverage; font.weight: Font.Medium; font.pixelSize: 14 }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "UPTIME"; font.pixelSize: 10; font.weight: Font.Bold; color: Appearance.m3colors.m3outline }
                        StyledText { text: SystemData.uptime; font.weight: Font.Medium; font.pixelSize: 14; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }
    }
}
