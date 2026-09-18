import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Lyrics"
        aliases: ["Text", "Karaoke", "Song"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "lyrics"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Lyrics Configuration")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Font Family (whole card opens the combo)
        SegmentedWrapper {
            id: fontFamilyCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, fontFamilyRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                id: fontFamilyClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: fontFamilyCard.rTopLeft
                topRightRadius: fontFamilyCard.rTopRight
                bottomLeftRadius: fontFamilyCard.rBottomLeft
                bottomRightRadius: fontFamilyCard.rBottomRight

                property real comboClosedAt: 0

                onClicked: {
                    if (Date.now() - comboClosedAt < 250) return;
                    lyricsFontCombo.isOpened = !lyricsFontCombo.isOpened;
                }

                Connections {
                    target: lyricsFontCombo
                    function onIsOpenedChanged() {
                        if (!lyricsFontCombo.isOpened) fontFamilyClickArea.comboClosedAt = Date.now();
                    }
                }
            }

            RowLayout {
                id: fontFamilyRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol { text: "text_fields"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                StyledText {
                    text: I18nService.tr("Lyrics Font Family")
                    Layout.fillWidth: true; color: Appearance.colors.colOnLayer1
                }
                StyledComboBox {
                    id: lyricsFontCombo
                    Layout.preferredWidth: 300 * Appearance.effectiveScale
                    bgRadius: height / 2
                    model: SystemFonts.all
                    text: {
                        if (!Config.ready) return I18nService.tr("Default");
                        const val = Config.options.appearance.lyrics.fontFamily;
                        return (val === "" || val === undefined) ? I18nService.tr("Default") : val;
                    }
                    onAccepted: (val) => {
                        if (!Config.ready) return;
                        Config.options.appearance.lyrics.fontFamily = (val === "Default" ? "" : val);
                    }
                }
            }
        }

        // Base Font Size
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, fontSizeRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: fontSizeRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol { text: "format_size"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                StyledText {
                    text: I18nService.tr("Base Font Size")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledStepper {
                    value: (Config.ready && Config.options.appearance.lyrics) ? Config.options.appearance.lyrics.fontSize : 36
                    from: 16; to: 84; stepSize: 1
                    decimals: 0
                    suffix: "px"
                    onValueChanged: if (Config.ready && Config.options.appearance.lyrics) Config.options.appearance.lyrics.fontSize = Math.round(value)
                }
            }
        }

        // Context Lines
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, contextLinesRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RowLayout {
                id: contextLinesRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol { text: "subject"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                StyledText {
                    text: I18nService.tr("Context Lines")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledStepper {
                    value: (Config.ready && Config.options.appearance.lyrics) ? Config.options.appearance.lyrics.contextLines : 3
                    from: 1; to: 7; stepSize: 1
                    decimals: 0
                    onValueChanged: if (Config.ready && Config.options.appearance.lyrics) Config.options.appearance.lyrics.contextLines = Math.round(value)
                }
            }
        }
    }
}
