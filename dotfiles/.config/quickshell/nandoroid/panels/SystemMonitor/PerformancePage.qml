import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

import "pages"

/**
 * PerformancePage manages sub-navigation for system metrics.
 */
Item {
    id: root
    property int subIndex: 0


    // Reset to Overview (0) when System Monitor closes
    Connections {
        target: GlobalStates
        function onSystemMonitorOpenChanged() {
            if (!GlobalStates.systemMonitorOpen) {
                root.subIndex = 0;
                GlobalStates.performanceSubIndex = 0;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        
        // Horizontal Tab Bar
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 60
            color: "transparent"
            
            RowLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                
                Repeater {
                    model: [
                        { name: "Overview", icon: "dashboard" },
                        { name: "CPU", icon: "monitoring" },
                        { name: "GPU", icon: "videogame_asset" },
                        { name: "Memory", icon: "memory" },
                        { name: "Network", icon: "public" },
                        { name: "Disk", icon: "storage" }
                    ]
                    
                    delegate: RippleButton {
                        implicitWidth: 120
                        implicitHeight: 40
                        buttonRadius: 20
                        colBackground: GlobalStates.performanceSubIndex === index 
                            ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.8) 
                            : "transparent"
                        colBackgroundHover: GlobalStates.performanceSubIndex === index 
                            ? colBackground 
                            : Appearance.colors.colLayer2
                        
                        onClicked: GlobalStates.performanceSubIndex = index
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: modelData.icon
                                iconSize: 18
                                color: GlobalStates.performanceSubIndex === index ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }
                            StyledText {
                                text: modelData.name
                                font.pixelSize: 13
                                font.weight: GlobalStates.performanceSubIndex === index ? Font.Bold : Font.Medium
                                color: GlobalStates.performanceSubIndex === index ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
            
            // Underline for the whole tab bar or active tab
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Appearance.colors.colLayer2
            }
        }
        
        // Content Area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: GlobalStates.performanceSubIndex
            
            OverviewPage {}
            CpuPage {}
            GpuPage {}
            MemoryPage {}
            NetworkPage {}
            DiskPage {}
        }
    }
}
