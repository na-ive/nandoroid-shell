import "../../../../core"
import "../../../../widgets"
import "../../../../services"
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
            StyledText {
                text: "Reset Position"
                font.pixelSize: Appearance.font.pixelSize.small
                color: maResetAag.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                MouseArea {
                    id: maResetAag
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!Config.ready) return;
                        Config.options.appearance.atAGlance.desktopX = 64;
                        Config.options.appearance.atAGlance.desktopY = 64;
                    }
                }
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
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "left"
                        }
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale
                            iconName: "format_align_center"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "center"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "center"
                        }
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale
                            iconName: "format_align_right"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "right"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "right"
                        }
                    }
                }
            }
            // Font Family
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: fontRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: fontRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    
                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 70 * Appearance.effectiveScale
                        MaterialSymbol { text: "text_fields"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: "Font Family"
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                    Item { Layout.fillWidth: true }
                    StyledComboBox {
                        Layout.preferredWidth: 300 * Appearance.effectiveScale
                        model: SystemFonts.all
                        text: {
                            if (!Config.ready) return "Default";
                            const val = Config.options.appearance.atAGlance.fontFamily;
                            return (val === "" || val === undefined) ? "Default" : val;
                        }
                        onAccepted: (val) => {
                            if (!Config.ready) return;
                            Config.options.appearance.atAGlance.fontFamily = (val === "Default" ? "" : val);
                        }
                    }
                }
            }

            // Font Size
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: fontSizeRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: fontSizeRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    
                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 70 * Appearance.effectiveScale
                        MaterialSymbol { text: "format_size"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: "Font Size"
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        value: Config.ready ? Config.options.appearance.atAGlance.fontSize : 24
                        defaultValue: 24
                        from: 12; to: 72
                        onMoved: if(Config.ready) Config.options.appearance.atAGlance.fontSize = Math.round(value)
                    }
                    StyledText {
                        text: Math.round(Config.ready ? Config.options.appearance.atAGlance.fontSize : 24).toString()
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 40 * Appearance.effectiveScale
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // Greeting Color
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: greetingColorRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: greetingColorRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    
                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 70 * Appearance.effectiveScale
                        MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: "Greeting Color"
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                isHighlighted: Config.ready && Config.options.appearance.atAGlance.greetingColorStyle === modelData
                                onClicked: Config.options.appearance.atAGlance.greetingColorStyle = modelData
                            }
                        }
                    }
                }
            }

            // Date Color
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: dateColorRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: dateColorRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    
                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 70 * Appearance.effectiveScale
                        MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: "Date Color"
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                isHighlighted: Config.ready && Config.options.appearance.atAGlance.dateColorStyle === modelData
                                onClicked: Config.options.appearance.atAGlance.dateColorStyle = modelData
                            }
                        }
                    }
                }
            }

            // Quote Color
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: quoteColorRow.implicitHeight + (32 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: quoteColorRow
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    
                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        Layout.preferredWidth: 70 * Appearance.effectiveScale
                        MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                        StyledText {
                            text: "Quote Color"
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                isHighlighted: Config.ready && Config.options.appearance.atAGlance.quoteColorStyle === modelData
                                onClicked: Config.options.appearance.atAGlance.quoteColorStyle = modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
