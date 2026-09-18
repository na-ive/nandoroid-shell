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
        spacing: 4 * Appearance.effectiveScale

        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "widgets"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("At a Glance")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            StyledText {
                text: I18nService.tr("Reset Position")
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

            // Show Greeting (whole card clickable)
            SegmentedWrapper {
                id: greetingCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, greetingRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: greetingCard.rTopLeft
                    topRightRadius: greetingCard.rTopRight
                    bottomLeftRadius: greetingCard.rBottomLeft
                    bottomRightRadius: greetingCard.rBottomRight
                    onClicked: if (Config.ready) Config.options.appearance.atAGlance.showGreeting = !Config.options.appearance.atAGlance.showGreeting
                }

                RowLayout {
                    id: greetingRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "waving_hand"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Greeting"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.atAGlance.showGreeting; onToggled: if(Config.ready) Config.options.appearance.atAGlance.showGreeting = !Config.options.appearance.atAGlance.showGreeting }
                }
            }

            // Show Date (whole card clickable)
            SegmentedWrapper {
                id: dateCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, dateShowRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: dateCard.rTopLeft
                    topRightRadius: dateCard.rTopRight
                    bottomLeftRadius: dateCard.rBottomLeft
                    bottomRightRadius: dateCard.rBottomRight
                    onClicked: if (Config.ready) Config.options.appearance.atAGlance.showDate = !Config.options.appearance.atAGlance.showDate
                }

                RowLayout {
                    id: dateShowRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "calendar_month"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Date"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.atAGlance.showDate; onToggled: if(Config.ready) Config.options.appearance.atAGlance.showDate = !Config.options.appearance.atAGlance.showDate }
                }
            }

            // Show Quotes (whole card clickable)
            SegmentedWrapper {
                id: quoteCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, quoteShowRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: quoteCard.rTopLeft
                    topRightRadius: quoteCard.rTopRight
                    bottomLeftRadius: quoteCard.rBottomLeft
                    bottomRightRadius: quoteCard.rBottomRight
                    onClicked: if (Config.ready) Config.options.appearance.atAGlance.showQuote = !Config.options.appearance.atAGlance.showQuote
                }

                RowLayout {
                    id: quoteShowRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "format_quote"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Quotes"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.atAGlance.showQuote; onToggled: if(Config.ready) Config.options.appearance.atAGlance.showQuote = !Config.options.appearance.atAGlance.showQuote }
                }
            }

            // Alignment
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, alignmentRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: alignmentRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "format_align_left"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Alignment"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }

                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale
                            Layout.fillHeight: true
                            iconName: "format_align_left"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "left"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "left"
                        }
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale
                            Layout.fillHeight: true
                            iconName: "format_align_center"
                            isHighlighted: Config.ready && Config.options.appearance.atAGlance.alignment === "center"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.atAGlance.alignment = "center"
                        }
                        SegmentedButton {
                            width: 64 * Appearance.effectiveScale
                            Layout.fillHeight: true
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

            // Font Family (whole card opens the combo)
            SegmentedWrapper {
                id: fontFamilyCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, fontRow.implicitHeight)
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
                        glanceFontCombo.isOpened = !glanceFontCombo.isOpened;
                    }

                    Connections {
                        target: glanceFontCombo
                        function onIsOpenedChanged() {
                            if (!glanceFontCombo.isOpened) fontFamilyClickArea.comboClosedAt = Date.now();
                        }
                    }
                }

                RowLayout {
                    id: fontRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "text_fields"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Font Family")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    StyledComboBox {
                        id: glanceFontCombo
                        Layout.preferredWidth: 300 * Appearance.effectiveScale
                        bgRadius: height / 2
                        model: SystemFonts.all
                        text: {
                            if (!Config.ready) return I18nService.tr("Default");
                            const val = Config.options.appearance.atAGlance.fontFamily;
                            return (val === "" || val === undefined) ? I18nService.tr("Default") : val;
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
                        text: I18nService.tr("Font Size")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    StyledStepper {
                        value: Config.ready ? Config.options.appearance.atAGlance.fontSize : 24
                        from: 12; to: 72
                        stepSize: 1
                        decimals: 0
                        onValueChanged: if(Config.ready) Config.options.appearance.atAGlance.fontSize = Math.round(value)
                    }
                }
            }

            // Greeting Color
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, greetingColorRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: greetingColorRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Greeting Color")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
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
                implicitHeight: Math.max(64 * Appearance.effectiveScale, dateColorRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: dateColorRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Date Color")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
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
                implicitHeight: Math.max(64 * Appearance.effectiveScale, quoteColorRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: quoteColorRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: I18nService.tr("Quote Color")
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
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
