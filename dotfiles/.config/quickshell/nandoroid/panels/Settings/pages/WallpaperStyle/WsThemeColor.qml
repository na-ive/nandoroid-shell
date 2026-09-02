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
            id: darkModeCard
            Layout.fillWidth: true
            implicitHeight: themeToggleRow.implicitHeight + (24 * Appearance.effectiveScale)
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: darkModeCard.rTopLeft
                topRightRadius: darkModeCard.rTopRight
                bottomLeftRadius: darkModeCard.rBottomLeft
                bottomRightRadius: darkModeCard.rBottomRight
                onClicked: Wallpapers.toggleDarkMode()
            }

            RowLayout {
                id: themeToggleRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: Config.options.appearance.background.darkmode ? "dark_mode" : "light_mode"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Dark theme")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

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
            spacing: 24 * Appearance.effectiveScale
            
            property bool showAllBasic: false

            // Custom Segmented Style Switcher
            Row {
                id: colorSwitcherRow
                Layout.fillWidth: true
                Layout.preferredHeight: 52 * Appearance.effectiveScale
                spacing: 2 * Appearance.effectiveScale
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
                    buttonText: I18nService.tr("Wallpaper color")
                    onClicked: colorSwitcherRow.currentTab = "wallpaper"
                }

                SegmentedButton {
                    width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                    height: parent.height
                    isHighlighted: parent.currentTab === "basic"
                    buttonText: I18nService.tr("Basic colors")
                    onClicked: colorSwitcherRow.currentTab = "basic"
                }
            }

            // --- Wallpaper Colors Grid ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? -1 : 0
                spacing: 16 * Appearance.effectiveScale
                visible: colorSwitcherRow.currentTab === "wallpaper"

                Item {
                    Layout.fillWidth: true
                    implicitHeight: matugenColorGrid.implicitHeight
                    Layout.preferredHeight: implicitHeight

                    GridLayout {
                        id: matugenColorGrid
                        anchors.fill: parent
                        columns: 5
                        rowSpacing: 4 * Appearance.effectiveScale
                        columnSpacing: 4 * Appearance.effectiveScale

                        opacity: MatugenPreviewService.loading ? 0.3 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                        enabled: !MatugenPreviewService.loading

                    Repeater {
                        model: MatugenPreviewService.matugenSchemes
                        delegate: ColorCard {
                            Layout.fillWidth: true
                            label: modelData.name
                            cardColors: {
                                const key = "desktop_" + modelData.id;
                                if (MatugenPreviewService.previews[key]) return MatugenPreviewService.previews[key];
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
                        label: I18nService.tr("Accent Picker")
                        iconName: "colorize"
                        cardColors: [Appearance.m3colors.m3primary, Appearance.m3colors.m3secondary, Appearance.m3colors.m3tertiary]
                        isSelected: Config.ready && !Config.options.appearance.background.matugen && Config.options.appearance.background.matugenCustomColor !== "" && Config.options.appearance.background.matugenThemeFile === ""
                        onClicked: {
                            GlobalStates.accentPickerTarget = "desktop"
                            GlobalStates.accentPickerOpen = true
                        }
                    }
                    }

                    MaterialLoadingIndicator {
                        id: syncIcon
                        anchors.centerIn: parent
                        visible: MatugenPreviewService.loading
                        implicitSize: 60 * Appearance.effectiveScale
                        loading: visible
                    }
                }


            }

            // --- Basic Colors Grid ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? -1 : 0
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
                                return MatugenPreviewService.basicColors
                            const top10 = MatugenPreviewService.basicColors.slice(0, 10)
                            const selectedFile = Config.ready && Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.matugenThemeFile : null
                            if (selectedFile) {
                                const idx = MatugenPreviewService.basicColors.findIndex(c => c.file === selectedFile)
                                if (idx >= 10)
                                    return MatugenPreviewService.basicColors.slice(0, 9).concat([MatugenPreviewService.basicColors[idx]])
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
                            text: colorSettingsCol.showAllBasic ? I18nService.tr("Show less") : I18nService.tr("Show more colors")
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }
    }
}
