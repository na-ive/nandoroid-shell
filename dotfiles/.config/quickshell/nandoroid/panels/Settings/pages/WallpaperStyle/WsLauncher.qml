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

    SearchHandler { 
        searchString: "Icon Shapes"
        aliases: ["Icons", "Shapes", "App Icons"]
    }

    // ── Launcher Section ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16 * Appearance.effectiveScale

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
                text: I18nService.tr("Launcher")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
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
                id: groupingCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, groupingRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: groupingCard.rTopLeft
                    topRightRadius: groupingCard.rTopRight
                    bottomLeftRadius: groupingCard.rBottomLeft
                    bottomRightRadius: groupingCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.search)
                        Config.options.search.enableGrouping = !Config.options.search.enableGrouping
                }

                RowLayout {
                    id: groupingRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "category"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Enable App Grouping"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
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
                readonly property var allShapes: ["None", "Square", "Circle", "Diamond", "Pill", "Clover4Leaf", "Burst", "Heart", "Flower", "Arch", "Fan", "Gem", "Sunny", "VerySunny", "Slanted", "Arrow", "SemiCircle", "Oval", "ClamShell", "Pentagon", "Ghostish", "Clover8Leaf", "SoftBurst", "Boom", "SoftBoom", "Puffy", "PuffyDiamond", "Bun", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "PixelCircle", "PixelTriangle", "Triangle"]
    
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.leftMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "grid_view"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: I18nService.tr("Icon Shapes")
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
    
                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 4 * Appearance.effectiveScale
                    columnSpacing: 4 * Appearance.effectiveScale
    
                    Repeater {
                        model: {
                            if (launcherIconsSection.showAllShapes)
                                return launcherIconsSection.allShapes
                            const top8 = launcherIconsSection.allShapes.slice(0, 8)
                            const selected = Config.ready && Config.options.search ? Config.options.search.iconShape : null
                            if (selected && !top8.includes(selected))
                                return launcherIconsSection.allShapes.slice(0, 7).concat([selected])
                            return top8
                        }
                        delegate: RippleButton {
                            id: shapeBtn
                            Layout.fillWidth: true
                            Layout.preferredHeight: 84 * Appearance.effectiveScale
                            
                            readonly property bool isSelected: Config.ready && Config.options.search && Config.options.search.iconShape === modelData
                            
                            buttonRadius: 20 * Appearance.effectiveScale
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
                                    visible: modelData !== "None"
                                    shapeString: modelData
                                    color: shapeBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignHCenter
                                    visible: modelData === "None"
                                    text: "block"
                                    iconSize: 32 * Appearance.effectiveScale
                                    color: shapeBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData
                                    font.pixelSize: Appearance.font.pixelSize.smaller
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
                    buttonRadius: 24 * Appearance.effectiveScale
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
                            text: launcherIconsSection.showAllShapes ? I18nService.tr("Show less") : I18nService.tr("Show more shapes")
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }
    }
}
