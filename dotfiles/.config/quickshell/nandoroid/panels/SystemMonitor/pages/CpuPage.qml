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
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 20 * Appearance.effectiveScale

        StyledText {
            text: "CPU Performance"
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.DemiBold
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer2
            radius: 16 * Appearance.effectiveScale
            border.width: 0
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 0
                        StyledText { text: SystemData.cpuModel; font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.Medium; color: Appearance.m3colors.m3onSurface }
                        StyledText { 
                            text: `${SystemData.physicalCores} Cores / ${SystemData.cpuThreads} Threads`; 
                            color: Appearance.colors.colSubtext; 
                            font.pixelSize: Appearance.font.pixelSize.smaller
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledText { 
                        text: Math.round(SystemData.cpuUsage * 100) + "%"
                        font.pixelSize: Math.round(32 * Appearance.effectiveScale)
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
                    spacing: 20 * Appearance.effectiveScale
                    
                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "TEMPERATURE"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext }
                        StyledText { text: Math.round(SystemData.cpuTemperature) + "°C"; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small }
                    }

                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "LOAD AVERAGE"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext }
                        StyledText { text: SystemData.loadAverage; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 0
                        StyledText { text: "UPTIME"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: Appearance.colors.colSubtext }
                        StyledText { text: SystemData.uptime; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }
    }
}
