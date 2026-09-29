import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Io

ColumnLayout {
    id: creditsRoot
    spacing: 24 * Appearance.effectiveScale

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8 * Appearance.effectiveScale
        
        StyledText {
            Layout.fillWidth: true
            text: I18nService.tr("This project is a port and personal creation, built with love and inspired by these amazing developers and projects.")
            wrapMode: Text.WordWrap
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }
    }

    // --- Inspiration Cards ---
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12 * Appearance.effectiveScale

        ProjectCard {
            title: "illogical-impulse"
            description: I18nService.tr("End-4's Hyprland dotfiles. A lot of the architecture and shell logic here traces back to this.")
            iconSource: "../../../../assets/icons/illogical-impulse.svg"
            url: "https://github.com/end-4/dots-hyprland"
            accentColor: "#89b4fa"
        }

        ProjectCard {
            title: "ii-vynx"
            description: I18nService.tr("Vynx's fork of illogical-impulse. Helped a lot with the Quickshell port and various other bits throughout the config.")
            iconSource: "../../../../assets/icons/illogical-impulse.svg"
            url: "https://github.com/vaguesyntax/ii-vynx"
            accentColor: "#cba6f7"
        }

        ProjectCard {
            title: "end4-pC"
            description: I18nService.tr("pC's fork of illogical-impulse. Provided valuable references for design layout, widgets, and logic architecture.")
            iconSource: "../../../../assets/icons/illogical-impulse.svg"
            url: "https://github.com/pctrade/end4-pC"
            accentColor: "#f9e2af"
        }

        ProjectCard {
            title: "ii-p3drovfx"
            description: I18nService.tr("P3DROVFX's fork of illogical-impulse. Design and interaction references for various parts throughout the config.")
            iconSource: "../../../../assets/icons/illogical-impulse.svg"
            url: "https://github.com/P3DROVFX/ii-p3drovfx"
            accentColor: "#a6e3a1"
        }

        ProjectCard {
            title: "Dank Material Shell"
            description: I18nService.tr("AvengeMedia's DMS. Helped a ton with a lot of the harder parts of the config, and dgop was super useful for system monitoring stuff.")
            iconSource: "../../../../assets/icons/danklogo.svg"
            url: "https://github.com/AvengeMedia/DankMaterialShell"
            accentColor: "#f38ba8"
        }

        ProjectCard {
            title: "Ambxst"
            description: I18nService.tr("Axenide's Ambxst. Where the notch idea came from, and probably a few other things down the line.")
            iconSource: "../../../../assets/icons/ambxst-logo-color.svg"
            url: "https://github.com/Axenide/Ambxst"
            accentColor: "#89dceb"
        }
    }

    component ProjectCard: Rectangle {
        id: projRoot
        property string title
        property string description
        property string iconSource
        property string url
        property color accentColor

        Layout.fillWidth: true
        Layout.preferredHeight: layoutCol.implicitHeight + (24 * Appearance.effectiveScale)
        radius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh

        RippleButton {
            anchors.fill: parent
            buttonRadius: parent.radius
            colBackground: "transparent"
            onClicked: Qt.openUrlExternally(projRoot.url)
        }

        ColumnLayout {
            id: layoutCol
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
                topMargin: 12 * Appearance.effectiveScale
                bottomMargin: 12 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                Image {
                    source: projRoot.iconSource
                    sourceSize: Qt.size(64 * Appearance.effectiveScale, 64 * Appearance.effectiveScale)
                    Layout.preferredWidth: 64 * Appearance.effectiveScale
                    Layout.preferredHeight: 64 * Appearance.effectiveScale
                    fillMode: Image.PreserveAspectFit
                }

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: projRoot.title
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: projRoot.url
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: projRoot.accentColor
                        opacity: 0.8
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: projRoot.description
                wrapMode: Text.WordWrap
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                lineHeight: 1.2
            }
        }
    }
}
