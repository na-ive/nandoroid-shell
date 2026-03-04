import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0
            // ── Lockscreen Section ──
            ColumnLayout {
                id: lockscreenStyleSection
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 16
    
                // Section Header
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 4
    
                    MaterialSymbol {
                        text: "lock"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Lockscreen"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
    
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: showCavaRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showCavaRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "equalizer"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show Cava Visualizer"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.lock.showCava
                                onToggled: if(Config.ready) Config.options.lock.showCava = !Config.options.lock.showCava
                            }
                        }
                    }
    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: showMediaRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showMediaRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "movie"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show Media Controls"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.lock.showMediaCard
                                onToggled: if(Config.ready) Config.options.lock.showMediaCard = !Config.options.lock.showMediaCard
                            }
                        }
                    }
                }
            }
    

}
