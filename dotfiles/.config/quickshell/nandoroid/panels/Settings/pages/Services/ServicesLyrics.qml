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
                text: "Lyrics Configuration"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // 1. Font Family
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: 64 * Appearance.effectiveScale
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16 * Appearance.effectiveScale
                anchors.rightMargin: 16 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
                
                MaterialSymbol { text: "text_fields"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                StyledText { 
                    text: "Lyrics Font Family"
                    Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 
                }
                StyledComboBox {
                    Layout.preferredWidth: 300 * Appearance.effectiveScale
                    model: SystemFonts.all
                    text: {
                        if (!Config.ready) return "Default";
                        const val = Config.options.appearance.lyrics.fontFamily;
                        return (val === "" || val === undefined) ? "Default" : val;
                    }
                    onAccepted: (val) => {
                        if (!Config.ready) return;
                        Config.options.appearance.lyrics.fontFamily = (val === "Default" ? "" : val);
                    }
                }
            }
        }

        // 2. Font Size
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: fontSizeRow.implicitHeight + (36 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh
            
            RowLayout {
                id: fontSizeRow
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                RowLayout {
                    spacing: 16 * Appearance.effectiveScale
                    Layout.preferredWidth: 70 * Appearance.effectiveScale
                    MaterialSymbol { text: "format_size"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { 
                        text: "Base Font Size"
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }

                StyledSlider {
                    Layout.fillWidth: true
                    value: (Config.ready && Config.options.appearance.lyrics) ? Config.options.appearance.lyrics.fontSize : 36
                    from: 16; to: 84; stepSize: 1
                    onMoved: if (Config.ready && Config.options.appearance.lyrics) Config.options.appearance.lyrics.fontSize = Math.round(value)
                }
                StyledText { 
                    text: Math.round(Config.ready && Config.options.appearance.lyrics ? Config.options.appearance.lyrics.fontSize : 36).toString() + "px"
                    color: Appearance.colors.colOnLayer1 
                    Layout.preferredWidth: 40 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        // 3. Context Lines
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: contextLinesRow.implicitHeight + (36 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh
            
            RowLayout {
                id: contextLinesRow
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                RowLayout {
                    spacing: 16 * Appearance.effectiveScale
                    Layout.preferredWidth: 70 * Appearance.effectiveScale
                    MaterialSymbol { text: "subject"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { 
                        text: "Context Lines"
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }

                StyledSlider {
                    Layout.fillWidth: true
                    value: (Config.ready && Config.options.appearance.lyrics) ? Config.options.appearance.lyrics.contextLines : 3
                    from: 1; to: 7; stepSize: 1
                    onMoved: if (Config.ready && Config.options.appearance.lyrics) Config.options.appearance.lyrics.contextLines = Math.round(value)
                }
                StyledText { 
                    text: Math.round(Config.ready && Config.options.appearance.lyrics ? Config.options.appearance.lyrics.contextLines : 3).toString()
                    color: Appearance.colors.colOnLayer1 
                    Layout.preferredWidth: 40 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
