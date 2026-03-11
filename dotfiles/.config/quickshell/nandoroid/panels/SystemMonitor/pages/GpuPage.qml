import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."

/**
 * GPU detail page for System Monitor.
 */
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        StyledText {
            text: "GPU Performance"
            font.pixelSize: 24
            font.weight: Font.Bold
        }

        Repeater {
            model: SystemData.hasValidGpuData ? SystemData.availableGpus : []
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 180
                color: Appearance.colors.colLayer2
                radius: 16
                border.width: 0
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            StyledText { text: modelData.name; font.pixelSize: 18; font.weight: Font.Bold; color: Appearance.m3colors.m3primaryContainer }
                            StyledText { text: modelData.vendor; color: Appearance.m3colors.m3onSurfaceVariant }
                        }
                        Item { Layout.fillWidth: true }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight
                            StyledText { 
                                text: modelData.temp > 0 ? modelData.temp + "°C" : "--°C"
                                font.pixelSize: 24
                                font.weight: Font.Black
                                color: modelData.temp > 80 ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurface
                            }
                            StyledText { text: "Temperature"; font.pixelSize: 10; color: Appearance.m3colors.m3onSurfaceVariant; horizontalAlignment: Text.AlignRight }
                        }
                    }
                    
                    StyledText {
                        text: "PCI ID: " + modelData.pciId
                        font.pixelSize: 10
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    StyledText {
                        text: (modelData.driver && modelData.driver !== "undefined") ? "System is using " + modelData.driver + " driver." : "System GPU driver loaded."
                        font.pixelSize: 12
                        color: Appearance.m3colors.m3onSurface
                        font.italic: true
                    }
                }
            }
        }
        
        // Proper Fallback Card for layout consistency
        Rectangle {
            visible: !SystemData.hasValidGpuData
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer2
            radius: 16
            border.width: 0

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width * 0.8
                spacing: 12
                MaterialSymbol {
                    text: "videogame_asset_off"
                    iconSize: 48
                    color: Appearance.m3colors.m3outline
                    Layout.alignment: Qt.AlignCenter
                }
                StyledText {
                    text: "GPU performance data not available"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: Appearance.m3colors.m3onSurface
                    Layout.alignment: Qt.AlignCenter
                }
                StyledText {
                    text: "Your GPU (likely integrated) does not report usage or temperature data to the system sensors."
                    font.pixelSize: 12
                    color: Appearance.m3colors.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
