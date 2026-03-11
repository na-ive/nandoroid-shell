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
        searchString: "Screen Decor"
        aliases: ["Corners", "Borders", "Rounding"]
    }

    // ── Screen Decor Section ──

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 16
    
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 4
                    MaterialSymbol {
                        text: "desktop_windows"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Screen Decor"
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
                        implicitHeight: screenCornerToggleRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: screenCornerToggleRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "rounded_corner"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Rounded screen corners"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2
                                Repeater {
                                    model: [
                                        { val: 0, label: "Off" },
                                        { val: 1, label: "Adaptive" },
                                        { val: 2, label: "Always" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && (Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.mode : 1) === modelData.val
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.appearance.screenCorners)
                                            Config.options.appearance.screenCorners.mode = modelData.val
                                    }
                                }
                            }
                        }
                    }
    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: screenCornerRadRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && (Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.mode : 1) > 0
                        RowLayout {
                            id: screenCornerRadRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            
                            RowLayout {
                                spacing: 16
                                Layout.preferredWidth: 70
                                MaterialSymbol { text: "straighten"; iconSize: 24; color: Appearance.colors.colPrimary }
                                StyledText { 
                                    text: "Corner radius"
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer1 
                                }
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 100; stepSize: 1
                                value: Config.ready && Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.radius : 20
                                onMoved: if (Config.ready && Config.options.appearance.screenCorners)
                                    Config.options.appearance.screenCorners.radius = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(Config.ready && Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.radius : 20).toString() + "px"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 40
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                }
            }
    

}
