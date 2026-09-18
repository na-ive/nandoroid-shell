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

    property string activeFontName: {
        if (titleCombo.isOpened) return titleCombo.activeFont;
        if (numbersCombo.isOpened) return numbersCombo.activeFont;
        if (monoCombo.isOpened) return monoCombo.activeFont;
        return mainCombo.activeFont;
    }

    property string activeComboLabel: {
        if (titleCombo.isOpened) return I18nService.tr("Title Font");
        if (numbersCombo.isOpened) return I18nService.tr("Numbers Font");
        if (monoCombo.isOpened) return I18nService.tr("Monospace Font");
        return I18nService.tr("Main Font");
    }

    SearchHandler { searchString: "Typography" }

    // ── Typography Section ──

    
            ColumnLayout {
                Layout.fillWidth: true
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
                        text: I18nService.tr("Typography")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: I18nService.tr("Refresh Font")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: maRefreshFont.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                        MouseArea {
                            id: maRefreshFont
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SystemFonts.fetchAndCache()
                        }
                    }
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24 * Appearance.effectiveScale

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale

                        ColumnLayout {
                            id: mainComboContainer
                            Layout.fillWidth: true
                            spacing: 8 * Appearance.effectiveScale
                            z: mainCombo.isOpened ? 10 : 1
                            StyledText { text: I18nService.tr("Main Font"); font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledComboBox {
                                id: mainCombo
                                bgRadius: height / 2
                                Layout.fillWidth: true
                                colBackground: Appearance.m3colors.m3surfaceContainerHigh
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
                            StyledText { text: I18nService.tr("Title Font"); font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledComboBox {
                                id: titleCombo
                                bgRadius: height / 2
                                Layout.fillWidth: true
                                colBackground: Appearance.m3colors.m3surfaceContainerHigh
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
                            StyledText { text: I18nService.tr("Numbers Font"); font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledComboBox {
                                id: numbersCombo
                                bgRadius: height / 2
                                Layout.fillWidth: true
                                colBackground: Appearance.m3colors.m3surfaceContainerHigh
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
                            StyledText { text: I18nService.tr("Monospace Font"); font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledComboBox {
                                id: monoCombo
                                bgRadius: height / 2
                                Layout.fillWidth: true
                                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                                text: Config.options.appearance.fonts.monospace
                                model: SystemFonts.mono
                                onAccepted: (val) => Config.options.appearance.fonts.monospace = val
                            }
                        }
                    }

                    // ── Font Preview ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 320 * Appearance.effectiveScale
                        Layout.maximumWidth: 400 * Appearance.effectiveScale
                        Layout.fillHeight: true
                        radius: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1
                        border.width: Math.max(1, 1 * Appearance.effectiveScale)
                        border.color: Appearance.colors.colOutlineVariant

                        ColumnLayout {
                            id: previewContent
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8 * Appearance.effectiveScale

                                Text {
                                    text: I18nService.tr("Preview")
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.activeComboLabel
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.activeFontName
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.topMargin: 4 * Appearance.effectiveScale
                                Layout.bottomMargin: 4 * Appearance.effectiveScale
                                height: Math.max(1, 1 * Appearance.effectiveScale)
                                color: Appearance.colors.colOutlineVariant
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "The quick brown fox jumps over the lazy dog"
                                font.family: root.activeFontName
                                font.pixelSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnLayer1
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "0123456789"
                                font.family: root.activeFontName
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                font.family: root.activeFontName
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.WrapAnywhere
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "abcdefghijklmnopqrstuvwxyz"
                                font.family: root.activeFontName
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.WrapAnywhere
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "!@#$%^&*()_+-=[]{};':,.<>/?|"
                                font.family: root.activeFontName
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                                wrapMode: Text.WrapAnywhere
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
    

}
