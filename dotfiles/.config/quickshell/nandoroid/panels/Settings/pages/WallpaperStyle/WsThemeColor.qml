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
        searchString: "Theme Color"
        aliases: ["Colors", "Matugen", "Material You", "Accent Color"]
    }

    // ── Theme Section ──

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: themeToggleRow.implicitHeight + 36
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
    
                RowLayout {
                    id: themeToggleRow
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 20
    
                    RowLayout {
                        spacing: 16
                        Layout.preferredWidth: 70
                        MaterialSymbol {
                            text: Config.options.appearance.background.darkmode ? "dark_mode" : "light_mode"
                            iconSize: 24
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: "Dark theme"
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
    
                    Item { Layout.fillWidth: true }

                    AndroidToggle {
                        checked: Config.ready && (Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.darkmode : false)
                        onToggled: Wallpapers.toggleDarkMode()
                    }
                }
            }
    
            // ── Color Settings ──
            ColumnLayout {
                id: colorSettingsCol
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 24
    
                property bool showAllMatugen: false
                property bool showAllBasic: false
    
                // Custom Segmented Style Switcher
                Row {
                    id: colorSwitcherRow
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: 4
                    property string currentTab: Config.ready && Config.options.appearance.background && Config.options.appearance.background.matugen ? "wallpaper" : "basic"
                    
                    SegmentedButton {
                        width: (parent.width - 4) / 2
                        height: parent.height
                        
                        isHighlighted: parent.currentTab === "wallpaper"
                        buttonText: "Wallpaper color"
                        font.pixelSize: 14 // Increased font size
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                        
                        onClicked: parent.currentTab = "wallpaper"
                    }
    
                    SegmentedButton {
                        width: (parent.width - 4) / 2
                        height: parent.height
                        
                        isHighlighted: parent.currentTab === "basic"
                        buttonText: "Basic color"
                        font.pixelSize: 14 // Increased font size
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                        
                        onClicked: parent.currentTab = "basic"
                    }
                }
    
                // Scheme / Color Grid (grid-cols-5 style)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: colorSwitcherRow.currentTab === "wallpaper"
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        rowSpacing: 16
                        columnSpacing: 16
    
                        // Desktop Schemes
                        Repeater {
                            model: root.matugenSchemes
                            delegate: ColorCard {
                                Layout.fillWidth: true
                                label: (Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper) ? "Desktop\n" + modelData.name : modelData.name
                                cardColors: {
                                    const key = "desktop_" + modelData.id;
                                    if (root.matugenPreviews[key]) return root.matugenPreviews[key];
                                    const def = Appearance.m3colors.m3surfaceContainerHigh;
                                    return [def, def, def];
                                }
                                isSelected: Config.ready && (Config.options.appearance && Config.options.appearance.background) && Config.options.appearance.background.matugen && Config.options.appearance.background.matugenScheme === modelData.id && Config.options.appearance.background.matugenSource === "desktop"
                                onClicked: {
                                    Config.options.appearance.background.matugen = true
                                    Config.options.appearance.background.matugenCustomColor = ""
                                    Config.options.appearance.background.matugenThemeFile = ""
                                    Wallpapers.applyScheme(modelData.id, "desktop")
                                }
                            }
                        }
    
                        // Lockscreen Schemes (Only if separate wallpaper is on)
                        Repeater {
                            model: {
                                if (!(Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper)) return 0;
                                if (colorSettingsCol.showAllMatugen) return root.matugenSchemes;
                                return root.matugenSchemes.slice(0, 2); // Show 2 more to reach total of 10
                            }
                            delegate: ColorCard {
                                Layout.fillWidth: true
                                label: "Lockscreen\n" + modelData.name
                                cardColors: {
                                    const key = "lockscreen_" + modelData.id;
                                    if (root.matugenPreviews[key]) return root.matugenPreviews[key];
                                    const def = Appearance.m3colors.m3surfaceContainerHigh;
                                    return [def, def, def];
                                }
                                isSelected: Config.ready && (Config.options.appearance && Config.options.appearance.background) && Config.options.appearance.background.matugen && Config.options.appearance.background.matugenScheme === modelData.id && Config.options.appearance.background.matugenSource === "lockscreen"
                                onClicked: {
                                    Config.options.appearance.background.matugen = true
                                    Config.options.appearance.background.matugenCustomColor = ""
                                    Config.options.appearance.background.matugenThemeFile = ""
                                    Wallpapers.applyScheme(modelData.id, "lockscreen")
                                }
                            }
                        }
                    }
    
                    // Show More Toggle for Matugen (only if separate wallpaper is on)
                    RippleButton {
                        visible: Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        buttonRadius: 16
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: colorSettingsCol.showAllMatugen = !colorSettingsCol.showAllMatugen
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: colorSettingsCol.showAllMatugen ? "expand_less" : "expand_more"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: colorSettingsCol.showAllMatugen ? "Show less" : "Show more colors"
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
    
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    visible: colorSwitcherRow.currentTab === "basic"
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        rowSpacing: 16
                        columnSpacing: 16
    
                        Repeater {
                            model: colorSettingsCol.showAllBasic ? root.basicColors : root.basicColors.slice(0, 10)
                            delegate: ColorCard {
                                Layout.fillWidth: true
                                label: modelData.name
                                cardColors: modelData.colors
                                isSelected: Config.ready && (Config.options.appearance && Config.options.appearance.background) && !Config.options.appearance.background.matugen && Config.options.appearance.background.matugenThemeFile === modelData.file
                                onClicked: {
                                    Config.options.appearance.background.matugen = false
                                    Config.options.appearance.background.matugenScheme = ""
                                    Config.options.appearance.background.matugenSource = ""
                                    Wallpapers.applyTheme(modelData.file)
                                }
                            }
                        }
                    }
    
                    // Show More Toggle for Basic Colors
                    RippleButton {
                        visible: root.basicColors.length > 10
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        buttonRadius: 16
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: colorSettingsCol.showAllBasic = !colorSettingsCol.showAllBasic
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            MaterialSymbol {
                                text: colorSettingsCol.showAllBasic ? "expand_less" : "expand_more"
                                iconSize: 20
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: colorSettingsCol.showAllBasic ? "Show less" : "Show more colors"
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
    

}
