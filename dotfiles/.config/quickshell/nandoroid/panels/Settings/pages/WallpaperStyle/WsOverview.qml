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
    
    SearchHandler { 
        searchString: "Overview"
        aliases: ["Workspaces", "Window Manager", "Expose"]
    }

    // ── Overview Settings Section ──
    ColumnLayout {
                id: overviewSettingsSection
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 4
                
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "grid_view"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Overview"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
    
                // Rows
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: overviewRowsRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        id: overviewRowsRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 20
    
                        RowLayout {
                            spacing: 16
                            Layout.preferredWidth: 70
                            MaterialSymbol { text: "reorder"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { 
                                text: "Rows"
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready && Config.options.overview ? Config.options.overview.rows : 2
                            from: 1; to: 5; stepSize: 1
                            onMoved: if (Config.ready && Config.options.overview) Config.options.overview.rows = Math.round(value)
                        }
                        StyledText { 
                            text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.rows : 2).toString()
                            color: Appearance.colors.colOnLayer1 
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
    
                // Columns
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: overviewColsRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        id: overviewColsRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 20
    
                        RowLayout {
                            spacing: 16
                            Layout.preferredWidth: 70
                            MaterialSymbol { text: "view_week"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { 
                                text: "Columns"
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready && Config.options.overview ? Config.options.overview.columns : 5
                            from: 1; to: 10; stepSize: 1
                            onMoved: if (Config.ready && Config.options.overview) Config.options.overview.columns = Math.round(value)
                        }
                        StyledText { 
                            text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.columns : 5).toString()
                            color: Appearance.colors.colOnLayer1 
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
    
                // Scale
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: overviewScaleRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        id: overviewScaleRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 20
    
                        RowLayout {
                            spacing: 16
                            Layout.preferredWidth: 70
                            MaterialSymbol { text: "zoom_in"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { 
                                text: "Window Scale"
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready && Config.options.overview ? Config.options.overview.scale * 100 : 15
                            from: 5; to: 50; stepSize: 1
                            onMoved: if (Config.ready && Config.options.overview) Config.options.overview.scale = value / 100.0
                        }
                        StyledText { 
                            text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.scale * 100 : 15).toString() + "%"
                            color: Appearance.colors.colOnLayer1 
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
    
                // Workspace Spacing
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: overviewSpacingRow.implicitHeight + 36
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        id: overviewSpacingRow
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 20
    
                        RowLayout {
                            spacing: 16
                            Layout.preferredWidth: 70
                            MaterialSymbol { text: "space_dashboard"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { 
                                text: "Workspace Spacing"
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                        }

                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready && Config.options.overview ? Config.options.overview.workspaceSpacing : 10
                            from: 0; to: 50; stepSize: 1
                            onMoved: if (Config.ready && Config.options.overview) Config.options.overview.workspaceSpacing = Math.round(value)
                        }
                        StyledText { 
                            text: Math.round(Config.ready && Config.options.overview ? Config.options.overview.workspaceSpacing : 10).toString() + "px"
                            color: Appearance.colors.colOnLayer1 
                            Layout.preferredWidth: 40
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
    

}
