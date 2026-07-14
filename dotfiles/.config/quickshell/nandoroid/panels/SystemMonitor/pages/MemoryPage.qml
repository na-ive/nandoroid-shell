import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."

/**
 * Memory detail page for System Monitor.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 20 * Appearance.effectiveScale

        StyledText {
            text: "Memory Performance"
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
                        StyledText { text: "Total RAM: " + (SystemData.totalMemoryMB / 1024).toFixed(1) + " GB"; font.pixelSize: Appearance.font.pixelSize.normal; font.weight: Font.Medium }
                        StyledText { text: "Used: " + (SystemData.usedMemoryMB / 1024).toFixed(1) + " GB"; color: Appearance.colors.colSubtext; font.pixelSize: Appearance.font.pixelSize.smaller }
                    }
                    Item { Layout.fillWidth: true }
                    StyledText { 
                        text: Math.round(SystemData.memUsage * 100) + "%"
                        font.pixelSize: Math.round(32 * Appearance.effectiveScale)
                        font.weight: Font.Black
                        color: "#8AB4F8"
                    }
                }
                
                PerformanceGraph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    history: SystemData.memHistory
                    lineColor: "#8AB4F8"
                    fillColor: "#8AB4F8"
                    maxValue: 100
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { text: "Swap Usage: " + Math.round(SystemData.swapUsage * 100) + "%"; font.weight: Font.DemiBold; font.pixelSize: Appearance.font.pixelSize.small }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
