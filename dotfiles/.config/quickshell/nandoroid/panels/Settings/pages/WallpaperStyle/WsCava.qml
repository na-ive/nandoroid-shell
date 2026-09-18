import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "Visualizer"
        aliases: ["Cava", "Audio", "Desktop Cava", "Lockscreen Cava"]
    }

    // ── Visualizer Section ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale

            MaterialSymbol {
                text: "equalizer"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Audio Visualizer")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            // --- Desktop Visualizer Toggle ---
            SegmentedWrapper {
                id: desktopCavaCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopCavaRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: desktopCavaCard.rTopLeft
                    topRightRadius: desktopCavaCard.rTopRight
                    bottomLeftRadius: desktopCavaCard.rBottomLeft
                    bottomRightRadius: desktopCavaCard.rBottomRight
                    onClicked: if(Config.ready) Config.options.appearance.background.showCava = !Config.options.appearance.background.showCava
                }

                RowLayout {
                    id: desktopCavaRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "desktop_windows"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show on desktop"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.appearance.background.showCava
                        onToggled: if(Config.ready) Config.options.appearance.background.showCava = !checked
                    }
                }
            }

            // --- Desktop Opacity Slider ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.appearance.background.showCava
                implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopOpacityRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: desktopOpacityRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "opacity"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Desktop opacity"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 0.05; to: 0.5; stepSize: 0.01
                        displayFactor: 100
                        decimals: 0
                        suffix: "%"
                        value: Config.options.appearance.background.cavaOpacity
                        onValueChanged: Config.options.appearance.background.cavaOpacity = value
                    }
                }
            }

            // --- Desktop Style Picker — like WsStatusBar Text Color ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.appearance.background.showCava
                implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopStyleRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: desktopStyleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "auto_awesome_mosaic"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Desktop style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            buttonText: I18nService.tr("Wave")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaStyle ?? "wave") === "wave"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaStyle = "wave"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Bars")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaStyle ?? "wave") === "bars"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaStyle = "bars"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Mirror")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaStyle ?? "wave") === "mirror"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaStyle = "mirror"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Aurora")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaStyle ?? "wave") === "aurora"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaStyle = "aurora"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Dots")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaStyle ?? "wave") === "dots"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaStyle = "dots"
                        }
                    }
                }
            }

            // --- Desktop Colors (shader styles only) ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.appearance.background.showCava && ["mirror", "aurora", "dots"].includes(Config.options.appearance.background.cavaStyle ?? "wave")
                implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopColorsRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: desktopColorsRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Desktop colors"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            buttonText: I18nService.tr("Theme")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaColorSource ?? "theme") === "theme"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaColorSource = "theme"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Cover")
                            isHighlighted: Config.ready && (Config.options.appearance.background.cavaColorSource ?? "theme") === "cover"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.appearance.background.cavaColorSource = "cover"
                        }
                    }
                }
            }

            // --- Desktop Sensitivity (shader styles only) ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.appearance.background.showCava && ["mirror", "aurora", "dots"].includes(Config.options.appearance.background.cavaStyle ?? "wave")
                implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopSensRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: desktopSensRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "tune"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Desktop sensitivity"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 0.5; to: 3.0; stepSize: 0.05
                        displayFactor: 100
                        decimals: 0
                        suffix: "%"
                        value: Config.options.appearance.background.cavaSensitivity ?? 1
                        onValueChanged: Config.options.appearance.background.cavaSensitivity = value
                    }
                }
            }

            // --- Desktop Height (shader styles only) ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.appearance.background.showCava && ["mirror", "aurora", "dots"].includes(Config.options.appearance.background.cavaStyle ?? "wave")
                implicitHeight: Math.max(64 * Appearance.effectiveScale, desktopHeightRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: desktopHeightRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "height"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Desktop height"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 120; to: 600; stepSize: 10
                        displayFactor: 1
                        decimals: 0
                        suffix: "px"
                        value: Config.options.appearance.background.cavaHeight ?? 260
                        onValueChanged: Config.options.appearance.background.cavaHeight = value
                    }
                }
            }

            // --- Lockscreen Visualizer Toggle ---
            SegmentedWrapper {
                id: lockCavaCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, lockCavaRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: lockCavaCard.rTopLeft
                    topRightRadius: lockCavaCard.rTopRight
                    bottomLeftRadius: lockCavaCard.rBottomLeft
                    bottomRightRadius: lockCavaCard.rBottomRight
                    onClicked: if(Config.ready) Config.options.lock.showCava = !Config.options.lock.showCava
                }

                RowLayout {
                    id: lockCavaRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "lock"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show on lock screen"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.lock.showCava
                        onToggled: if(Config.ready) Config.options.lock.showCava = !checked
                    }
                }
            }

            // --- Lockscreen Opacity Slider ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.lock.showCava
                implicitHeight: Math.max(64 * Appearance.effectiveScale, lockOpacityRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: lockOpacityRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "opacity"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Lock screen opacity"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 0.05; to: 0.5; stepSize: 0.01
                        displayFactor: 100
                        decimals: 0
                        suffix: "%"
                        value: Config.options.lock.cavaOpacity
                        onValueChanged: Config.options.lock.cavaOpacity = value
                    }
                }
            }

            // --- Lockscreen Style Picker — like WsStatusBar Text Color ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.lock.showCava
                implicitHeight: Math.max(64 * Appearance.effectiveScale, lockStyleRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: lockStyleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "auto_awesome_mosaic"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Lock screen style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            buttonText: I18nService.tr("Wave")
                            isHighlighted: Config.ready && (Config.options.lock.cavaStyle ?? "wave") === "wave"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaStyle = "wave"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Bars")
                            isHighlighted: Config.ready && (Config.options.lock.cavaStyle ?? "wave") === "bars"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaStyle = "bars"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Mirror")
                            isHighlighted: Config.ready && (Config.options.lock.cavaStyle ?? "wave") === "mirror"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaStyle = "mirror"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Aurora")
                            isHighlighted: Config.ready && (Config.options.lock.cavaStyle ?? "wave") === "aurora"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaStyle = "aurora"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Dots")
                            isHighlighted: Config.ready && (Config.options.lock.cavaStyle ?? "wave") === "dots"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaStyle = "dots"
                        }
                    }
                }
            }

            // --- Lockscreen Colors (shader styles only) ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.lock.showCava && ["mirror", "aurora", "dots"].includes(Config.options.lock.cavaStyle ?? "wave")
                implicitHeight: Math.max(64 * Appearance.effectiveScale, lockColorsRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: lockColorsRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Lock screen colors"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    Row {
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            buttonText: I18nService.tr("Theme")
                            isHighlighted: Config.ready && (Config.options.lock.cavaColorSource ?? "theme") === "theme"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaColorSource = "theme"
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Cover")
                            isHighlighted: Config.ready && (Config.options.lock.cavaColorSource ?? "theme") === "cover"
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: if (Config.ready) Config.options.lock.cavaColorSource = "cover"
                        }
                    }
                }
            }

            // --- Lockscreen Sensitivity (shader styles only) ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.lock.showCava && ["mirror", "aurora", "dots"].includes(Config.options.lock.cavaStyle ?? "wave")
                implicitHeight: Math.max(64 * Appearance.effectiveScale, lockSensRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: lockSensRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "tune"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Lock screen sensitivity"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 0.5; to: 3.0; stepSize: 0.05
                        displayFactor: 100
                        decimals: 0
                        suffix: "%"
                        value: Config.options.lock.cavaSensitivity ?? 1
                        onValueChanged: Config.options.lock.cavaSensitivity = value
                    }
                }
            }

            // --- Lockscreen Height (shader styles only) ---
            SegmentedWrapper {
                Layout.fillWidth: true
                visible: Config.ready && Config.options.lock.showCava && ["mirror", "aurora", "dots"].includes(Config.options.lock.cavaStyle ?? "wave")
                implicitHeight: Math.max(64 * Appearance.effectiveScale, lockHeightRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: lockHeightRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "height"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Lock screen height"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 120; to: 600; stepSize: 10
                        displayFactor: 1
                        decimals: 0
                        suffix: "px"
                        value: Config.options.lock.cavaHeight ?? 260
                        onValueChanged: Config.options.lock.cavaHeight = value
                    }
                }
            }
        }
    }
}
