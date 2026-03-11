import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { searchString: "Date & Time" }

    // ── Date & Time Section ──

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 16
                
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 4
                    MaterialSymbol {
                        text: "schedule"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Date & Time"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
    
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
    
                    // Time Format Card
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: timeRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        RowLayout {
                            id: timeRow
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            
                            MaterialSymbol { text: "pace"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText {
                                text: "Time Format"
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
    
                            RowLayout {
                                spacing: 4
                                Layout.preferredHeight: 48
                                
                                Repeater {
                                    model: [
                                        { label: "12H pm", value: "12H_pm" },
                                        { label: "12H PM", value: "12H_PM" },
                                        { label: "24H",    value: "24H" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        isHighlighted: Config.ready && Config.options.time ? Config.options.time.timeStyle === modelData.value : false
                                        Layout.fillHeight: true
                                        
                                        buttonText: modelData.label
                                        leftPadding: 16
                                        rightPadding: 16
                                        
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        
                                        onClicked: if(Config.ready) Config.options.time.timeStyle = modelData.value
                                    }
                                }
                            }
                        }
                    }
    
                    // Date Format Card
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: dateRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        RowLayout {
                            id: dateRow
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            
                            MaterialSymbol { text: "calendar_month"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText {
                                text: "Date Format"
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
    
                            RowLayout {
                                spacing: 4
                                Layout.preferredHeight: 48
                                
                                Repeater {
                                    model: [
                                        { label: "DD/MM/YYYY", value: "DMY" },
                                        { label: "MM/DD/YYYY", value: "MDY" },
                                        { label: "YYYY/MM/DD", value: "YMD" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        isHighlighted: Config.ready && Config.options.time ? Config.options.time.dateStyle === modelData.value : false
                                        Layout.fillHeight: true
                                        
                                        buttonText: modelData.label
                                        leftPadding: 16
                                        rightPadding: 16
                                        
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        
                                        onClicked: if(Config.ready) Config.options.time.dateStyle = modelData.value
                                    }
                                }
                            }
                        }
                    }
                }
            }
    

}
