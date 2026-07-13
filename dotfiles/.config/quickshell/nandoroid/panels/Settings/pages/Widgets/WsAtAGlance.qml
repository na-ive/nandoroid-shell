import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: rootAtAGlance
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "At a Glance"
        aliases: ["Widget", "Glance", "Greeting", "Date", "Quote"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "widgets"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "At a Glance"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            AndroidToggle {
                checked: Config.ready && Config.options.appearance.atAGlance.show
                onToggled: if (Config.ready) Config.options.appearance.atAGlance.show = !Config.options.appearance.atAGlance.show
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale
            visible: Config.ready && Config.options.appearance.atAGlance.show

            SegmentedWrapper {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "waving_hand"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Greeting"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.atAGlance.showGreeting; onToggled: if(Config.ready) Config.options.appearance.atAGlance.showGreeting = !Config.options.appearance.atAGlance.showGreeting }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "calendar_month"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Date"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.atAGlance.showDate; onToggled: if(Config.ready) Config.options.appearance.atAGlance.showDate = !Config.options.appearance.atAGlance.showDate }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "format_quote"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Quotes"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.atAGlance.showQuote; onToggled: if(Config.ready) Config.options.appearance.atAGlance.showQuote = !Config.options.appearance.atAGlance.showQuote }
                }
            }


            // Alignment
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: alignmentRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: alignmentRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "format_align_left"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Alignment"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    
                    Row {
                        spacing: 4 * Appearance.effectiveScale
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale
                            iconName: "format_align_left"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "left"
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "left"
                        }
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale
                            iconName: "format_align_center"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "center"
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "center"
                        }
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale
                            iconName: "format_align_right"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "right"
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "right"
                        }
                    }
                }
            }
        }
    }
}
