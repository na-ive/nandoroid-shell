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
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16 * Appearance.effectiveScale

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: themeToggleRow.implicitHeight + (36 * Appearance.effectiveScale)
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: themeToggleRow
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                RowLayout {
                    spacing: 16 * Appearance.effectiveScale
                    Layout.preferredWidth: 70 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: Config.options.appearance.background.darkmode ? "dark_mode" : "light_mode"
                        iconSize: 24 * Appearance.effectiveScale
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
            Layout.topMargin: 12 * Appearance.effectiveScale
            spacing: 24 * Appearance.effectiveScale
            
            property bool showAllBasic: false

            // Custom Segmented Style Switcher
            Row {
                id: colorSwitcherRow
                Layout.fillWidth: true
                Layout.preferredHeight: 52 * Appearance.effectiveScale
                spacing: 4 * Appearance.effectiveScale
                property string currentTab: "wallpaper"

                Component.onCompleted: {
                    if (Config.ready && Config.options.appearance.background) {
                        const bg = Config.options.appearance.background;
                        if (bg.matugen || (bg.matugenCustomColor !== "" && bg.matugenThemeFile === "")) {
                            currentTab = "wallpaper";
                        } else {
                            currentTab = "basic";
                        }
                    }
                }
                
                SegmentedButton {
                    width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                    height: parent.height
                    isHighlighted: parent.currentTab === "wallpaper"
                    buttonText: "Wallpaper color"
                    onClicked: colorSwitcherRow.currentTab = "wallpaper"
                }

                SegmentedButton {
                    width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                    height: parent.height
                    isHighlighted: parent.currentTab === "basic"
                    buttonText: "Basic colors"
                    onClicked: colorSwitcherRow.currentTab = "basic"
                }
            }

            // --- Wallpaper Colors Grid ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale
                visible: colorSwitcherRow.currentTab === "wallpaper"

                Item {
                    Layout.fillWidth: true
                    implicitHeight: matugenColorGrid.implicitHeight

                    GridLayout {
                        id: matugenColorGrid
                        anchors.fill: parent
                        columns: 5
                        rowSpacing: 4 * Appearance.effectiveScale
                        columnSpacing: 4 * Appearance.effectiveScale

                        opacity: (previewIterateTimer.running || previewMatugen.running) ? 0.3 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        enabled: !(previewIterateTimer.running || previewMatugen.running)

                    Repeater {
                        model: root.matugenSchemes
                        delegate: ColorCard {
                            Layout.fillWidth: true
                            label: modelData.name
                            cardColors: {
                                const key = "desktop_" + modelData.id;
                                if (root.matugenPreviews[key]) return root.matugenPreviews[key];
                                const def = Appearance.m3colors.m3surfaceContainerHigh;
                                return [def, def, def];
                            }
                            isSelected: Config.ready && Config.options.appearance.background.matugen && Config.options.appearance.background.matugenScheme === modelData.id
                            onClicked: {
                                Config.options.appearance.background.matugen = true
                                Config.options.appearance.background.matugenCustomColor = ""
                                Config.options.appearance.background.matugenThemeFile = ""
                                Wallpapers.applyScheme(modelData.id)
                            }
                        }
                    }

                    ColorCard {
                        Layout.fillWidth: true
                        label: "Accent Picker"
                        iconName: "colorize"
                        cardColors: [Appearance.m3colors.m3primary, Appearance.m3colors.m3secondary, Appearance.m3colors.m3tertiary]
                        isSelected: Config.ready && !Config.options.appearance.background.matugen && Config.options.appearance.background.matugenCustomColor !== "" && Config.options.appearance.background.matugenThemeFile === ""
                        onClicked: {
                            GlobalStates.accentPickerTarget = "desktop"
                            GlobalStates.accentPickerOpen = true
                        }
                    }
                    }

                    MaterialSymbol {
                        text: "sync"
                        anchors.centerIn: parent
                        visible: previewIterateTimer.running || previewMatugen.running
                        iconSize: 42 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                        RotationAnimation on rotation {
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                            running: parent.visible
                        }
                    }
                }


            }

            // --- Basic Colors Grid ---
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale
                visible: colorSwitcherRow.currentTab === "basic"
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 5
                    rowSpacing: 4 * Appearance.effectiveScale
                    columnSpacing: 4 * Appearance.effectiveScale

                    Repeater {
                        model: {
                            if (colorSettingsCol.showAllBasic)
                                return root.basicColors
                            const top10 = root.basicColors.slice(0, 10)
                            const selectedFile = Config.ready && Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.matugenThemeFile : null
                            if (selectedFile) {
                                const idx = root.basicColors.findIndex(c => c.file === selectedFile)
                                if (idx >= 10)
                                    return root.basicColors.slice(0, 9).concat([root.basicColors[idx]])
                            }
                            return top10
                        }
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
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: colorSettingsCol.showAllBasic = !colorSettingsCol.showAllBasic
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: colorSettingsCol.showAllBasic ? "expand_less" : "expand_more"
                            iconSize: 20 * Appearance.effectiveScale
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
}
