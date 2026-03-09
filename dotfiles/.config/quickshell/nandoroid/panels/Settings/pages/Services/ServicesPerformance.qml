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
            spacing: 4
            Layout.topMargin: 16
            
            SearchHandler { searchString: "Performance" }

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "monitoring"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Performance Monitoring"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: perfStatsRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: perfStatsRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Show Performance Stats"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display CPU, RAM, and Disk usage in the Quick Settings panel."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.quickSettings && Config.options.quickSettings.showPerformanceStats)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.quickSettings) {
                                    Config.options.quickSettings.showPerformanceStats = !Config.options.quickSettings.showPerformanceStats;
                                }
                            }
                        }
                    }
                }
            }
        }

