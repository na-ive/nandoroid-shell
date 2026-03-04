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
            // ── Launcher Icons Section ──
            ColumnLayout {
                id: launcherIconsSection
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 16
                
                property bool showAllShapes: false
                readonly property var allShapes: ["Square", "Circle", "Diamond", "Pill", "Clover4Leaf", "Burst", "Heart", "Flower", "Arch", "Fan", "Gem", "Sunny", "VerySunny", "Slanted", "Arrow", "SemiCircle", "Oval", "ClamShell", "Pentagon", "Ghostish", "Clover8Leaf", "SoftBurst", "Boom", "SoftBoom", "Puffy", "PuffyDiamond", "Bun", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "PixelCircle", "PixelTriangle", "Triangle"]
    
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 4
                    MaterialSymbol {
                        text: "apps"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Launcher Icons"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
    
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 12
                    columnSpacing: 12
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
    
                    Repeater {
                        model: parent.parent.showAllShapes ? parent.parent.allShapes : parent.parent.allShapes.slice(0, 8)
                        delegate: RippleButton {
                            id: shapeBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84
                            
                            readonly property bool isSelected: Config.ready && Config.options.search.iconShape === modelData
                            
                            buttonRadius: isSelected ? 14 : 28
                            colBackground: isSelected ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceContainerHigh
                            colRipple: Appearance.m3colors.m3primary
                            
                            onClicked: if (Config.ready) Config.options.search.iconShape = modelData
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                MaterialShape {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    shapeString: modelData
                                    color: shapeBtn.isSelected ? Appearance.colors.colNotchText : Appearance.m3colors.m3onSurfaceVariant
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData
                                    font.pixelSize: 10
                                    font.weight: shapeBtn.isSelected ? Font.Bold : Font.Normal
                                    color: shapeBtn.isSelected ? Appearance.colors.colNotchText : Appearance.m3colors.m3onSurface
                                }
                            }
                        }
                    }
                }
    
                // More / Less Toggle Button (Bluetooth Style)
                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    buttonRadius: 16
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: launcherIconsSection.showAllShapes = !launcherIconsSection.showAllShapes
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: launcherIconsSection.showAllShapes ? "expand_less" : "expand_more"
                            iconSize: 20
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: launcherIconsSection.showAllShapes ? "Show less" : "Show more shapes"
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
    

}
