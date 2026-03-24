import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale
            Layout.topMargin: 16 * Appearance.effectiveScale
            
            SearchHandler { 
                searchString: "Network Status"
                aliases: ["Speed Meter", "Bandwidth", "Internet", "Ethernet"]
            }

            RowLayout {
                spacing: 12 * Appearance.effectiveScale
                Layout.bottomMargin: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "network_check"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Network Status"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: netSpeedRow.implicitHeight + 40 * Appearance.effectiveScale
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8 * Appearance.effectiveScale
                fullRadius: 20 * Appearance.effectiveScale
                
                RowLayout {
                    id: netSpeedRow
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText {
                            text: "Show Network Speed"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display real-time upload and download speeds in the status bar."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52 * Appearance.effectiveScale
                        implicitHeight: 28 * Appearance.effectiveScale
                        radius: 14 * Appearance.effectiveScale
                        color: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20 * Appearance.effectiveScale
                            height: 20 * Appearance.effectiveScale
                            radius: 10 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? parent.width - width - 4 * Appearance.effectiveScale : 4 * Appearance.effectiveScale
                            color: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.bar) {
                                    Config.options.bar.show_network_speed = !Config.options.bar.show_network_speed;
                                }
                            }
                        }
                    }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: netUnitRow.implicitHeight + 40 * Appearance.effectiveScale
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8 * Appearance.effectiveScale
                fullRadius: 20 * Appearance.effectiveScale
                
                opacity: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? 1.0 : 0.4
                enabled: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    id: netUnitRow
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText {
                            text: "Starting Unit"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Select the default unit for speed measurements."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4 * Appearance.effectiveScale
                        Layout.preferredHeight: 40 * Appearance.effectiveScale
                        
                        Repeater {
                            model: ["B", "KB", "MB"]
                            delegate: SegmentedButton {
                                isHighlighted: (Config.ready && Config.options.bar) ? Config.options.bar.network_speed_unit === modelData : false
                                Layout.fillHeight: true
                                
                                buttonText: modelData
                                leftPadding: 32 * Appearance.effectiveScale
                                rightPadding: 32 * Appearance.effectiveScale
                                
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerLow
                                
                                onClicked: {
                                    if (Config.ready && Config.options.bar) {
                                        Config.options.bar.network_speed_unit = modelData;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

