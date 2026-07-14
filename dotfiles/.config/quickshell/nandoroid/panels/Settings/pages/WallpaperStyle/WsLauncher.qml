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
    id: root
    Layout.fillWidth: true
    spacing: 0
    
    SearchHandler { 
        searchString: "Launcher"
        aliases: ["App Launcher", "Search Bar", "Drawer"]
    }

    // ── Launcher Section ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        SearchHandler { 
            searchString: "Icon Shapes"
            aliases: ["Icons", "Shapes", "App Icons"]
        }

        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "rocket_launch"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Launcher"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            // ── App Grouping Toggle ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: groupingRow.implicitHeight + (36 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: groupingRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "category"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Enable App Grouping"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.search ? Config.options.search.enableGrouping : false
                        onToggled: if (Config.ready && Config.options.search)
                            Config.options.search.enableGrouping = !Config.options.search.enableGrouping
                    }
                }
            }

            // ── Launcher Icons Child Section ──────────────
            ColumnLayout {
                id: launcherIconsSection
                Layout.fillWidth: true
                Layout.topMargin: 12 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
                
                property bool showAllShapes: false
                readonly property var allShapes: ["Square", "Circle", "Diamond", "Pill", "Clover4Leaf", "Burst", "Heart", "Flower", "Arch", "Fan", "Gem", "Sunny", "VerySunny", "Slanted", "Arrow", "SemiCircle", "Oval", "ClamShell", "Pentagon", "Ghostish", "Clover8Leaf", "SoftBurst", "Boom", "SoftBoom", "Puffy", "PuffyDiamond", "Bun", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "PixelCircle", "PixelTriangle", "Triangle"]
    
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.leftMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "grid_view"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Icon Shapes"
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
                        model: launcherIconsSection.showAllShapes ? launcherIconsSection.allShapes : launcherIconsSection.allShapes.slice(0, 8)
                        delegate: RippleButton {
                            id: shapeBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84 * Appearance.effectiveScale
                            
                            readonly property bool isSelected: Config.ready && Config.options.search && Config.options.search.iconShape === modelData
                            
                            buttonRadius: isSelected ? 14 * Appearance.effectiveScale : 28 * Appearance.effectiveScale
                            colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                            colRipple: Appearance.m3colors.m3primary
                            
                            onClicked: if (Config.ready && Config.options.search) Config.options.search.iconShape = modelData
                            
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8 * Appearance.effectiveScale
                                MaterialShape {
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.preferredWidth: 32 * Appearance.effectiveScale
                                    Layout.preferredHeight: 32 * Appearance.effectiveScale
                                    shapeString: modelData
                                    color: shapeBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData
                                    font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                                    font.weight: shapeBtn.isSelected ? Font.DemiBold : Font.Normal
                                    color: shapeBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
    
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
    }
}
