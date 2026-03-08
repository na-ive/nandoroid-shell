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
                Layout.topMargin: 12
                spacing: 16
                
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 4
                    MaterialSymbol {
                        text: "font_download"
                        iconSize: 24
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
                    rowSpacing: 24
                    columnSpacing: 24
                    
                    property var fontOptions: ["Google Sans Flex", "Google Sans Mono", "Cantarell", "JetBrainsMono Nerd Font", "FantasqueSansM Nerd Font", "Inter", "Roboto", "Outfit", "Lexend", "Cascadia Code", "Iosevka", "Public Sans"]
    
                    ColumnLayout {
                        id: mainComboContainer
                        Layout.fillWidth: true
                        spacing: 8
                        z: mainCombo.isOpened ? 10 : 1
                        StyledText { text: "Main Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: mainCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.main
                            model: parent.parent.fontOptions
                            onAccepted: (val) => Config.options.appearance.fonts.main = val
                        }
                    }
                    
                    ColumnLayout {
                        id: titleComboContainer
                        Layout.fillWidth: true
                        spacing: 8
                        z: titleCombo.isOpened ? 10 : 1
                        StyledText { text: "Title Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: titleCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.title
                            model: parent.parent.fontOptions
                            onAccepted: (val) => Config.options.appearance.fonts.title = val
                        }
                    }
                    
                    ColumnLayout {
                        id: numbersComboContainer
                        Layout.fillWidth: true
                        spacing: 8
                        z: numbersCombo.isOpened ? 10 : 1
                        StyledText { text: "Numbers Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: numbersCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.numbers
                            model: parent.parent.fontOptions
                            onAccepted: (val) => Config.options.appearance.fonts.numbers = val
                        }
                    }
                    
                    ColumnLayout {
                        id: monoComboContainer
                        Layout.fillWidth: true
                        spacing: 8
                        z: monoCombo.isOpened ? 10 : 1
                        StyledText { text: "Monospace Font"; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        StyledComboBox {
                            id: monoCombo
                            Layout.fillWidth: true
                            text: Config.options.appearance.fonts.monospace
                            model: parent.parent.fontOptions
                            onAccepted: (val) => Config.options.appearance.fonts.monospace = val
                        }
                    }
                }
            }
    

}
