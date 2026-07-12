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

    SearchHandler { searchString: "Typography" }

    // ── Typography Section ──

    
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
                
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "font_download"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Typography"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
                
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 24 * Appearance.effectiveScale
                    columnSpacing: 24 * Appearance.effectiveScale
                    
                    // We use SystemFonts for dynamically fetching font models
    
                    ColumnLayout {
                        id: mainComboContainer
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale
                        z: mainCombo.isOpened ? 10 : 1
                        StyledText { text: "Main Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: mainCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.main
                            model: SystemFonts.all
                            onAccepted: (val) => Config.options.appearance.fonts.main = val
                        }
                    }
                    
                    ColumnLayout {
                        id: titleComboContainer
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale
                        z: titleCombo.isOpened ? 10 : 1
                        StyledText { text: "Title Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: titleCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.title
                            model: SystemFonts.all
                            onAccepted: (val) => Config.options.appearance.fonts.title = val
                        }
                    }
                    
                    ColumnLayout {
                        id: numbersComboContainer
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale
                        z: numbersCombo.isOpened ? 10 : 1
                        StyledText { text: "Numbers Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: numbersCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.numbers
                            model: SystemFonts.all
                            onAccepted: (val) => Config.options.appearance.fonts.numbers = val
                        }
                    }
                    
                    ColumnLayout {
                        id: monoComboContainer
                        Layout.fillWidth: true
                        spacing: 8 * Appearance.effectiveScale
                        z: monoCombo.isOpened ? 10 : 1
                        StyledText { text: "Monospace Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: monoCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.monospace
                            model: SystemFonts.mono
                            onAccepted: (val) => Config.options.appearance.fonts.monospace = val
                        }
                    }
                }
            }
    

}
