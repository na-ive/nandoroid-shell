import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"
import "../../../widgets"
import ".."

/**
 * Disk detail page for System Monitor.
 */
Item {
    id: root

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.implicitHeight + 40
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 20

        StyledText {
            text: "Disk Performance"
            font.pixelSize: 24
            font.weight: Font.Bold
        }

        // Real-time Disk I/O Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 140
            color: Appearance.colors.colLayer2
            radius: 16
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        StyledText { text: "Total Throughput"; font.pixelSize: 14; color: Appearance.m3colors.m3onSurfaceVariant }
                        StyledText { 
                            text: ((SystemData.diskReadRate + SystemData.diskWriteRate) / (1024 * 1024)).toFixed(2) + " MB/s"
                            font.pixelSize: 24
                            font.weight: Font.Black
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                    Item { Layout.fillWidth: true }
                    MaterialSymbol {
                        text: "speed"
                        iconSize: 32
                        color: Appearance.m3colors.m3error
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24
                    
                    ColumnLayout {
                        spacing: 2
                        StyledText { text: "READ"; font.pixelSize: 10; font.weight: Font.Bold; color: Appearance.m3colors.m3outline }
                        StyledText { 
                            text: (SystemData.diskReadRate / (1024 * 1024)).toFixed(2) + " MB/s"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                    
                    Rectangle { width: 1; Layout.fillHeight: true; color: Appearance.colors.colLayer3; opacity: 0.5 }
                    
                    ColumnLayout {
                        spacing: 2
                        StyledText { text: "WRITE"; font.pixelSize: 10; font.weight: Font.Bold; color: Appearance.m3colors.m3outline }
                        StyledText { 
                            text: (SystemData.diskWriteRate / (1024 * 1024)).toFixed(2) + " MB/s"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: Appearance.m3colors.m3onSurface
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                }
            }
        }

        StyledText {
            text: "Disk Operations"
            Layout.topMargin: 12
            font.pixelSize: 18
            font.weight: Font.Bold
        }

        // Monitors each disk in the list
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 24

            Repeater {
                model: SystemData.diskStats
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        MaterialSymbol {
                            text: "storage"
                            iconSize: 18
                            color: Appearance.m3colors.m3primary
                        }
                        StyledText {
                            text: modelData.hasAlias ? `${modelData.label.toUpperCase()} DISK USAGE` : `"${modelData.label.toUpperCase()}" DISK USAGE`
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Appearance.m3colors.m3outline
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: `${Math.round(modelData.usage * 100)}%`
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: Appearance.m3colors.m3onSurface
                        }
                    }

                    // Large Disk Bar
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 12
                        radius: 6
                        color: Appearance.colors.colLayer2
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, modelData.usage))
                            height: parent.height
                            radius: 6
                            color: Appearance.m3colors.m3primary
                            visible: modelData.usage > 0

                            Behavior on width {
                                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            text: modelData.path
                            font.pixelSize: 11
                            color: Appearance.colors.colSubtext
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: (modelData.used / (1024*1024*1024)).toFixed(1) + " GB / " + (modelData.total / (1024*1024*1024)).toFixed(1) + " GB"
                            font.pixelSize: 11
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }

        }
    }
}
