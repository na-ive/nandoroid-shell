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
        searchString: "Launcher Icon Shapes"
        aliases: ["Icon Style", "Icon Shape", "Shape Selection", "Adaptive Icons"]
    }

            // ── Launcher Icons Section ──
            ColumnLayout {
                id: launcherIconsSection
                Layout.fillWidth: true
                Layout.topMargin: 12 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
                
                property bool showAllShapes: false
                readonly property var allShapes: ["Square", "Circle", "Diamond", "Pill", "Clover4Leaf", "Burst", "Heart", "Flower", "Arch", "Fan", "Gem", "Sunny", "VerySunny", "Slanted", "Arrow", "SemiCircle", "Oval", "ClamShell", "Pentagon", "Ghostish", "Clover8Leaf", "SoftBurst", "Boom", "SoftBoom", "Puffy", "PuffyDiamond", "Bun", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "PixelCircle", "PixelTriangle", "Triangle"]
    
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "apps"
                        iconSize: 24 * Appearance.effectiveScale
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
                    rowSpacing: 12 * Appearance.effectiveScale
                    columnSpacing: 12 * Appearance.effectiveScale
                    Layout.leftMargin: 4 * Appearance.effectiveScale
                    Layout.rightMargin: 4 * Appearance.effectiveScale
    
                    Repeater {
                        model: {
                            if (parent.parent.showAllShapes)
                                return parent.parent.allShapes
                            const top8 = parent.parent.allShapes.slice(0, 8)
                            const selected = Config.ready && Config.options.search ? Config.options.search.iconShape : null
                            if (selected && !top8.includes(selected))
                                return parent.parent.allShapes.slice(0, 7).concat([selected])
                            return top8
                        }
                        delegate: RippleButton {
                            id: shapeBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84 * Appearance.effectiveScale
                            
                            readonly property bool isSelected: Config.ready && Config.options.search.iconShape === modelData
                            
                            buttonRadius: (isSelected ? 14 : 28) * Appearance.effectiveScale
                            colBackground: isSelected ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceContainerHigh
                            colRipple: Appearance.m3colors.m3primary
                            
                            onClicked: if (Config.ready) Config.options.search.iconShape = modelData
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8 * Appearance.effectiveScale
                                MaterialShape {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 32 * Appearance.effectiveScale
                                    Layout.preferredHeight: 32 * Appearance.effectiveScale
                                    shapeString: modelData
                                    color: shapeBtn.isSelected ? Appearance.colors.colNotchText : Appearance.m3colors.m3onSurfaceVariant
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData
                                    font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                                    font.weight: shapeBtn.isSelected ? Font.DemiBold : Font.Normal
                                    color: shapeBtn.isSelected ? Appearance.colors.colNotchText : Appearance.m3colors.m3onSurface
                                }
                            }
                        }
                    }
                }
    
                // More / Less Toggle Button (Bluetooth Style)
                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: launcherIconsSection.showAllShapes = !launcherIconsSection.showAllShapes
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: launcherIconsSection.showAllShapes ? "expand_less" : "expand_more"
                            iconSize: 20 * Appearance.effectiveScale
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
