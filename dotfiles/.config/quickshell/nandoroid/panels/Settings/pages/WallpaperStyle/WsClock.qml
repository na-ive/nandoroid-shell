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
    id: rootClock
    Layout.fillWidth: true
    spacing: 0
    
    property bool isDedicatedContext: false
    property bool dedicatedIsLock: false
    property bool isSubSection: false

    // Search handled per-context
    // ── Clock Section ──
    ColumnLayout {
        id: clockStyleSection
        Layout.fillWidth: true
        spacing: 16 * Appearance.effectiveScale
        
        property string activeContext: rootClock.isDedicatedContext ? (rootClock.dedicatedIsLock ? "lock" : "desktop") : "desktop"
        property bool showAdvanced: false

        function mapAlign(align) {
            if (align === "left") return Qt.AlignLeft;
            if (align === "right") return Qt.AlignRight;
            return Qt.AlignHCenter;
        }

        function mapTextAlign(align) {
            if (align === "left") return Text.AlignLeft;
            if (align === "right") return Text.AlignRight;
            return Text.AlignHCenter;
        }

        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: (rootClock.isSubSection ? 0 : 4) * Appearance.effectiveScale
            MaterialSymbol {
                text: "watch"
                iconSize: (rootClock.isSubSection ? 20 : 24) * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Clock")
                font.pixelSize: rootClock.isSubSection ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            
            StyledText {
                visible: !rootClock.dedicatedIsLock
                text: I18nService.tr("Reset Position")
                font.pixelSize: Appearance.font.pixelSize.small
                color: maResetClock.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                MouseArea {
                    id: maResetClock
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!Config.ready) return;
                        Config.options.appearance.clock.desktopX = -1;
                        Config.options.appearance.clock.desktopY = -1;
                        Config.options.appearance.clock.desktopCenterX = -1;
                        Config.options.appearance.clock.desktopCenterY = -1;
                        Config.options.appearance.clock.desktopRightX = -1;
                        Config.options.appearance.clock.offsetX = 0;
                        Config.options.appearance.clock.offsetY = -50;
                    }
                }
            }
            
            AndroidToggle {
                visible: !rootClock.dedicatedIsLock
                checked: Config.ready && Config.options.appearance.clock.showOnDesktop
                onToggled: if (Config.ready) Config.options.appearance.clock.showOnDesktop = !Config.options.appearance.clock.showOnDesktop
            }
        }

        // Context Switcher
        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: 52 * Appearance.effectiveScale
            spacing: 2 * Appearance.effectiveScale
            visible: !rootClock.isDedicatedContext && Config.ready && !Config.options.appearance.clock.useSameStyle

            SegmentedButton {
                width: (parent.width - (2 * Appearance.effectiveScale)) / 2
                height: parent.height
                buttonText: I18nService.tr("Desktop")
                isHighlighted: clockStyleSection.activeContext === "desktop"
                onClicked: clockStyleSection.activeContext = "desktop"
                colActive: Appearance.m3colors.m3primary
                colActiveText: Appearance.m3colors.m3onPrimary
            }
            SegmentedButton {
                width: (parent.width - (2 * Appearance.effectiveScale)) / 2
                height: parent.height
                buttonText: I18nService.tr("Lockscreen")
                isHighlighted: clockStyleSection.activeContext === "lock"
                onClicked: clockStyleSection.activeContext = "lock"
                colActive: Appearance.m3colors.m3primary
                colActiveText: Appearance.m3colors.m3onPrimary
            }
        }

        // Style Picker (single row)
        RowLayout {
            Layout.fillWidth: true
            visible: rootClock.dedicatedIsLock || (Config.ready && !Config.options.appearance.clock.useSameStyle)
            spacing: 4 * Appearance.effectiveScale

            Repeater {
                model: [
                    { id: "digital", name: I18nService.tr("Digital"), icon: "numbers" },
                    { id: "analog",  name: I18nService.tr("Analog"),  icon: "watch" },
                    { id: "stacked", name: I18nService.tr("Stacked"), icon: "view_day" },
                    { id: "text",    name: I18nService.tr("Text"),    icon: "text_fields" },
                    { id: "pill",    name: I18nService.tr("Pill"),    icon: "smart_button" },
                    { id: "code",    name: I18nService.tr("Code"),    icon: "code" },
                    { id: "pixel",   name: I18nService.tr("Pixel"),   icon: "grid_view" }
                ]
                delegate: RippleButton {
                    id: clockStyleBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 68 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    
                    readonly property bool isSelected: {
                        if (!Config.ready) return false
                        if (Config.options.appearance.clock.useSameStyle) return Config.options.appearance.clock.styleLocked === modelData.id
                        if (clockStyleSection.activeContext === "lock") return Config.options.appearance.clock.styleLocked === modelData.id
                        return Config.options.appearance.clock.style === modelData.id
                    }
                    
                    colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                    colRipple: Appearance.m3colors.m3primary
                    
                    onClicked: {
                        if (!Config.ready) return
                        if (Config.options.appearance.clock.useSameStyle) {
                            Config.options.appearance.clock.styleLocked = modelData.id
                        } else {
                            if (clockStyleSection.activeContext === "lock") {
                                Config.options.appearance.clock.styleLocked = modelData.id
                            } else {
                                Config.options.appearance.clock.style = modelData.id
                            }
                        }
                    }
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4 * Appearance.effectiveScale
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.icon
                            iconSize: 22 * Appearance.effectiveScale
                            color: clockStyleBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.name
                            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            font.weight: clockStyleBtn.isSelected ? Font.DemiBold : Font.Normal
                            color: clockStyleBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        // Advanced Settings Toggle
        RippleButton {
            Layout.fillWidth: true
            visible: rootClock.dedicatedIsLock || (Config.ready && !Config.options.appearance.clock.useSameStyle)
            Layout.preferredHeight: 48 * Appearance.effectiveScale
            buttonRadius: 24 * Appearance.effectiveScale
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            onClicked: clockStyleSection.showAdvanced = !clockStyleSection.showAdvanced
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: clockStyleSection.showAdvanced ? "expand_less" : "expand_more"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Advanced Settings")
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Advanced Panel
        ColumnLayout {
            id: advancedPanel
            Layout.fillWidth: true
            visible: clockStyleSection.showAdvanced && (rootClock.dedicatedIsLock || (Config.ready && !Config.options.appearance.clock.useSameStyle))
            spacing: 12 * Appearance.effectiveScale

            readonly property string currentStyle: {
                if (!Config.ready) return "digital"
                if (Config.options.appearance.clock.useSameStyle) return Config.options.appearance.clock.styleLocked;
                return (clockStyleSection.activeContext === "lock") ? Config.options.appearance.clock.styleLocked : Config.options.appearance.clock.style;
            }

            readonly property bool isLockCtx: clockStyleSection.activeContext === "lock" || Config.options.appearance.clock.useSameStyle
            readonly property var digitalCfg: isLockCtx ? Config.options.appearance.clock.digitalLocked : Config.options.appearance.clock.digital
            readonly property var analogCfg:  isLockCtx ? Config.options.appearance.clock.analogLocked  : Config.options.appearance.clock.analog
            readonly property var codeCfg:    isLockCtx ? Config.options.appearance.clock.codeLocked    : Config.options.appearance.clock.code
            readonly property var stackedCfg: isLockCtx ? Config.options.appearance.clock.stackedLocked : Config.options.appearance.clock.stacked
            readonly property var textCfg: isLockCtx ? Config.options.appearance.clock.textLocked : Config.options.appearance.clock.text
            readonly property var pillCfg: isLockCtx ? Config.options.appearance.clock.pillLocked : Config.options.appearance.clock.pill
            readonly property var pixelCfg: isLockCtx ? Config.options.appearance.clock.pixelLocked : Config.options.appearance.clock.pixel

            // ── Digital Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "digital"
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.digitalCfg.colorStyle === modelData
                                onClicked: advancedPanel.digitalCfg.colorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Orientation"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            buttonText: I18nService.tr("Horizontal")
                            isHighlighted: Config.ready && !advancedPanel.digitalCfg.isVertical
                            onClicked: advancedPanel.digitalCfg.isVertical = false
                        }
                        SegmentedButton {
                            buttonText: I18nService.tr("Vertical")
                            isHighlighted: Config.ready && advancedPanel.digitalCfg.isVertical
                            onClicked: advancedPanel.digitalCfg.isVertical = true
                        }
                    }
                    StyledText { text: I18nService.tr("Font Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? advancedPanel.digitalCfg.fontSize : 84; from: 48; to: 200; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.digitalCfg.fontSize = Math.round(value)
                        }
                    }
                    StyledText { text: I18nService.tr("Date Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? (advancedPanel.digitalCfg.dateFontSize || 24) : 24; from: 12; to: 80; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.digitalCfg.dateFontSize = Math.round(value)
                        }
                    }
                    StyledText { text: I18nService.tr("Date Gap"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            from: -40; to: 60; stepSize: 1
                            value: Config.ready ? (advancedPanel.digitalCfg.dateGap ?? 4) : 4
                            decimals: 0
                            suffix: "px"
                            onValueChanged: advancedPanel.digitalCfg.dateGap = Math.round(value)
                        }
                    }
                    StyledText { text: I18nService.tr("Alignment"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["left", "center", "right"]
                            delegate: SegmentedButton {
                                required property string modelData
                                iconName: "format_align_" + modelData
                                isHighlighted: Config.ready && advancedPanel.digitalCfg.alignment === modelData
                                onClicked: advancedPanel.digitalCfg.alignment = modelData
                            }
                        }
                    }
                }
            }

            // ── Analog Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "analog"
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 16 * Appearance.effectiveScale; columnSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Clock Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? advancedPanel.analogCfg.size : 240; from: 120; to: 480; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.analogCfg.size = Math.round(value)
                        }
                    }
                    StyledText {
                        text: I18nService.tr("Face Shape")
                        Layout.alignment: Qt.AlignTop
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                        Layout.preferredWidth: 110 * Appearance.effectiveScale
                        visible: Config.ready && advancedPanel.analogCfg.backgroundStyle === "shape"
                    }
                    Flow {
                        Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale; visible: Config.ready && advancedPanel.analogCfg.backgroundStyle === "shape"
                        Repeater {
                            model: ["Circle", "Square", "Slanted", "Oval", "Pill", "Triangle", "Diamond", "PuffyDiamond", "Pentagon", "Gem", "ClamShell", "Flower", "Ghostish", "Bun", "Heart", "Clover4Leaf", "Clover8Leaf", "Sunny", "VerySunny", "Burst", "SoftBurst", "Boom", "SoftBoom", "Cookie4Sided", "Cookie6Sided", "Cookie7Sided", "Cookie9Sided", "Cookie12Sided", "PixelCircle", "PixelTriangle"]
                            delegate: RippleButton {
                                required property string modelData
                                width: 56 * Appearance.effectiveScale; height: 56 * Appearance.effectiveScale; buttonRadius: 12 * Appearance.effectiveScale
                                property bool isSelected: Config.ready && advancedPanel.analogCfg.shape === modelData
                                colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                                onClicked: advancedPanel.analogCfg.shape = modelData
                                MaterialShape { anchors.centerIn: parent; implicitSize: 32 * Appearance.effectiveScale; shapeString: modelData; color: parent.isSelected ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1 }
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Background Style"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["none", "shape", "cookie", "sine"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.analogCfg.backgroundStyle === modelData
                                onClicked: advancedPanel.analogCfg.backgroundStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Sides"); color: Appearance.colors.colOnLayer1; visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine") }
                    RowLayout {
                        visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine")
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            from: 3; to: 36; stepSize: 1; value: Config.ready ? advancedPanel.analogCfg.sides : 12
                            decimals: 0
                            onValueChanged: advancedPanel.analogCfg.sides = Math.round(value)
                        }
                    }
                    StyledText {
                        text: I18nService.tr("Constantly Rotate"); color: Appearance.colors.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: advancedPanel.analogCfg.constantlyRotate = !advancedPanel.analogCfg.constantlyRotate }
                    }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.constantlyRotate; onToggled: advancedPanel.analogCfg.constantlyRotate = !advancedPanel.analogCfg.constantlyRotate }
                    StyledText {
                        text: I18nService.tr("Time Indicators"); color: Appearance.colors.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: advancedPanel.analogCfg.timeIndicators = !advancedPanel.analogCfg.timeIndicators }
                    }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.timeIndicators; onToggled: advancedPanel.analogCfg.timeIndicators = !advancedPanel.analogCfg.timeIndicators }
                    StyledText {
                        text: I18nService.tr("Hour Marks"); color: Appearance.colors.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: advancedPanel.analogCfg.hourMarks = !advancedPanel.analogCfg.hourMarks }
                    }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.hourMarks; onToggled: advancedPanel.analogCfg.hourMarks = !advancedPanel.analogCfg.hourMarks }
                    StyledText {
                        text: I18nService.tr("Show Marks"); color: Appearance.colors.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: advancedPanel.analogCfg.showMarks = !advancedPanel.analogCfg.showMarks }
                    }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.showMarks; onToggled: advancedPanel.analogCfg.showMarks = !advancedPanel.analogCfg.showMarks }
                    StyledText { text: I18nService.tr("Dial Style"); color: Appearance.colors.colOnLayer1; visible: Config.ready && advancedPanel.analogCfg.showMarks }
                    Row {
                        visible: Config.ready && advancedPanel.analogCfg.showMarks; Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["none", "dots", "full", "numbers"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1); isHighlighted: Config.ready && advancedPanel.analogCfg.dialStyle === modelData; onClicked: advancedPanel.analogCfg.dialStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Hour Hand"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["none", "classic", "hollow", "fill"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1); isHighlighted: Config.ready && advancedPanel.analogCfg.hourHandStyle === modelData; onClicked: advancedPanel.analogCfg.hourHandStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Minute Hand"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["none", "classic", "thin", "medium", "bold"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1); isHighlighted: Config.ready && advancedPanel.analogCfg.minuteHandStyle === modelData; onClicked: advancedPanel.analogCfg.minuteHandStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Second Hand"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["none", "classic", "line", "dot"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1); isHighlighted: Config.ready && advancedPanel.analogCfg.secondHandStyle === modelData; onClicked: advancedPanel.analogCfg.secondHandStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Date Style"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["none", "bubble", "border", "rect"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1); isHighlighted: Config.ready && advancedPanel.analogCfg.dateStyle === modelData; onClicked: advancedPanel.analogCfg.dateStyle = modelData
                            }
                        }
                    }
                }
            }

            // ── Code Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "code"
                Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 16 * Appearance.effectiveScale; columnSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Value Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.codeCfg.valueColorStyle === modelData
                                onClicked: advancedPanel.codeCfg.valueColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Keyword Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.codeCfg.keywordColorStyle === modelData
                                onClicked: advancedPanel.codeCfg.keywordColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Block Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.codeCfg.blockColorStyle === modelData
                                onClicked: advancedPanel.codeCfg.blockColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Block Style"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: [
                                { id: "js", label: I18nService.tr("JS / while") },
                                { id: "python", label: I18nService.tr("Python") },
                                { id: "rust", label: I18nService.tr("Rust") },
                                { id: "c", label: I18nService.tr("C/C++") },
                                { id: "kotlin", label: I18nService.tr("Kotlin") }
                            ]
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: Config.ready && advancedPanel.codeCfg.blockType === modelData.id
                                onClicked: advancedPanel.codeCfg.blockType = modelData.id
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Font Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? advancedPanel.codeCfg.fontSize : 18
                            from: 12; to: 48; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.codeCfg.fontSize = Math.round(value)
                        }
                    }
                }
            }

            // ── Stacked Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "stacked"
                Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 16 * Appearance.effectiveScale; columnSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Main Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.stackedCfg.colorStyle === modelData
                                onClicked: advancedPanel.stackedCfg.colorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Text Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.stackedCfg.textColorStyle === modelData
                                onClicked: advancedPanel.stackedCfg.textColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Alignment"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["left", "center", "right"]
                            delegate: SegmentedButton {
                                required property string modelData
                                iconName: "format_align_" + modelData
                                isHighlighted: Config.ready && advancedPanel.stackedCfg.alignment === modelData
                                onClicked: advancedPanel.stackedCfg.alignment = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Clock Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? advancedPanel.stackedCfg.fontSize : 84
                            from: 32; to: 160; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.stackedCfg.fontSize = Math.round(value)
                        }
                    }
                    StyledText { text: I18nService.tr("Label Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? advancedPanel.stackedCfg.labelFontSize : 42
                            from: 16; to: 84; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.stackedCfg.labelFontSize = Math.round(value)
                        }
                    }
                }
            }

            // ── Text Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "text"
                Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Time Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.textCfg.timeColorStyle === modelData
                                onClicked: advancedPanel.textCfg.timeColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Date Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.textCfg.dateColorStyle === modelData
                                onClicked: advancedPanel.textCfg.dateColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Alignment"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["left", "center", "right"]
                            delegate: SegmentedButton {
                                required property string modelData
                                iconName: "format_align_" + modelData
                                isHighlighted: Config.ready && advancedPanel.textCfg.alignment === modelData
                                onClicked: advancedPanel.textCfg.alignment = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Font Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? (advancedPanel.textCfg.fontSize || 42) : 42
                            from: 14; to: 120; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.textCfg.fontSize = Math.round(value)
                        }
                    }
                    StyledText { text: I18nService.tr("Date Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? (advancedPanel.textCfg.dateFontSize || 18) : 18
                            from: 8; to: 60; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.textCfg.dateFontSize = Math.round(value)
                        }
                    }
                }
            }

            // ── Pill Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "pill"
                Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Time Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "surface", "onSurface", "onLayer1"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.pillCfg.timeColorStyle === modelData
                                onClicked: advancedPanel.pillCfg.timeColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Pill Color"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primaryContainer", "secondaryContainer", "tertiaryContainer", "surfaceContainerHigh", "surfaceContainerLowest"]
                            delegate: ColorPickerButton {
                                required property string modelData
                                colorString: modelData
                                useLockColors: rootClock.dedicatedIsLock
                                isHighlighted: Config.ready && advancedPanel.pillCfg.pillColorStyle === modelData
                                onClicked: advancedPanel.pillCfg.pillColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: I18nService.tr("Orientation"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        SegmentedButton { buttonText: I18nService.tr("Horizontal"); isHighlighted: Config.ready && !advancedPanel.pillCfg.isVertical; onClicked: advancedPanel.pillCfg.isVertical = false }
                        SegmentedButton { buttonText: I18nService.tr("Vertical"); isHighlighted: Config.ready && advancedPanel.pillCfg.isVertical; onClicked: advancedPanel.pillCfg.isVertical = true }
                    }
                    StyledText {
                        text: I18nService.tr("Show Background"); color: Appearance.colors.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: advancedPanel.pillCfg.showBackground = !advancedPanel.pillCfg.showBackground }
                    }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.pillCfg.showBackground; onToggled: advancedPanel.pillCfg.showBackground = !advancedPanel.pillCfg.showBackground }
                    StyledText { text: I18nService.tr("Clock Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? (advancedPanel.pillCfg.size || 120) : 120
                            from: 60; to: 300; stepSize: 1
                            decimals: 0
                            onValueChanged: advancedPanel.pillCfg.size = Math.round(value)
                        }
                    }
                }
            }

            // ── Pixel Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "pixel"
                Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Orientation"); color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        SegmentedButton { buttonText: I18nService.tr("Horizontal"); isHighlighted: Config.ready && !(advancedPanel.pixelCfg.isVertical ?? true); onClicked: advancedPanel.pixelCfg.isVertical = false }
                        SegmentedButton { buttonText: I18nService.tr("Vertical"); isHighlighted: Config.ready && (advancedPanel.pixelCfg.isVertical ?? true); onClicked: advancedPanel.pixelCfg.isVertical = true }
                    }
                    StyledText { text: I18nService.tr("Clock Size"); color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        Item { Layout.fillWidth: true }
                        StyledStepper {
                            Layout.alignment: Qt.AlignVCenter
                            value: Config.ready ? (advancedPanel.pixelCfg.size || 100) : 100
                            from: 50; to: 200; stepSize: 5
                            decimals: 0
                            suffix: "%"
                            onValueChanged: advancedPanel.pixelCfg.size = Math.round(value)
                        }
                    }
                }
            }
        }

        // Clock Fonts & Date Settings
        ColumnLayout {
            id: fontsCol

            Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
            z: 10 // Ensure dropdowns overlap below elements
            visible: rootClock.dedicatedIsLock || (Config.ready && !Config.options.appearance.clock.useSameStyle)
            // Pixel clock hardcodes its display font; the picker is locked while it is active
            readonly property bool pixelFontLocked: Config.ready && advancedPanel.currentStyle === "pixel"

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: 20 * Appearance.effectiveScale
                topRightRadius: 20 * Appearance.effectiveScale
                bottomLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                z: 2 // Make sure top combo overlaps bottom combo
                opacity: fontsCol.pixelFontLocked ? 0.45 : 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "text_fields"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { 
                        text: Config.options.appearance.clock.useSameStyle ? I18nService.tr("Time Font") : (clockStyleSection.activeContext === "desktop" ? I18nService.tr("Desktop Time Font") : I18nService.tr("Lockscreen Time Font"))
                        Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 
                    }
                    StyledComboBox {
                        bgRadius: height / 2
                        Layout.preferredWidth: 300 * Appearance.effectiveScale
                        enabled: !fontsCol.pixelFontLocked
                        model: SystemFonts.all
                        text: {
                            if (fontsCol.pixelFontLocked) return "Google Sans Flex";
                            if (!Config.ready) return "Default";
                            const val = clockStyleSection.activeContext === "desktop" ? Config.options.appearance.clockFonts.desktopTimeFont : Config.options.appearance.clockFonts.lockscreenTimeFont;
                            return (val === "" || val === undefined) ? "Default" : val;
                        }
                        onAccepted: (val) => {
                            if (!Config.ready) return;
                            if (clockStyleSection.activeContext === "desktop") Config.options.appearance.clockFonts.desktopTimeFont = (val === "Default" ? "" : val);
                            else Config.options.appearance.clockFonts.lockscreenTimeFont = (val === "Default" ? "" : val);
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: fontsCol.pixelFontLocked
                    hoverEnabled: true
                    property bool hovered: containsMouse
                    StyledToolTip {
                        text: I18nService.tr("Pixel clock is optimized for Google Sans Flex")
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                topRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                z: 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "calendar_month"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText {
                        text: Config.options.appearance.clock.useSameStyle ? I18nService.tr("Date Font") : (clockStyleSection.activeContext === "desktop" ? I18nService.tr("Desktop Date Font") : I18nService.tr("Lockscreen Date Font"))
                        Layout.fillWidth: true; color: Appearance.colors.colOnLayer1
                    }
                    StyledComboBox {
                        bgRadius: height / 2
                        Layout.preferredWidth: 300 * Appearance.effectiveScale
                        model: SystemFonts.all
                        text: {
                            if (!Config.ready) return "Default";
                            const val = clockStyleSection.activeContext === "desktop" ? Config.options.appearance.clockFonts.desktopDateFont : Config.options.appearance.clockFonts.lockscreenDateFont;
                            return (val === "" || val === undefined) ? "Default" : val;
                        }
                        onAccepted: (val) => {
                            if (!Config.ready) return;
                            if (clockStyleSection.activeContext === "desktop") Config.options.appearance.clockFonts.desktopDateFont = (val === "Default" ? "" : val);
                            else Config.options.appearance.clockFonts.lockscreenDateFont = (val === "Default" ? "" : val);
                        }
                    }
                }
            }

            Rectangle {
                visible: rootClock.dedicatedIsLock
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                topRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomLeftRadius: rootClock.dedicatedIsLock ? 20 * Appearance.effectiveScale : (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomRightRadius: rootClock.dedicatedIsLock ? 20 * Appearance.effectiveScale : (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                z: 0

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius
                    onClicked: if(Config.ready) Config.options.appearance.clock.showLockscreenDate = !Config.options.appearance.clock.showLockscreenDate
                }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "event"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show date on lockscreen"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.clock.showLockscreenDate; onToggled: if(Config.ready) Config.options.appearance.clock.showLockscreenDate = !Config.options.appearance.clock.showLockscreenDate }
                }
            }

            Rectangle {
                visible: !rootClock.dedicatedIsLock
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                topRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomLeftRadius: 20 * Appearance.effectiveScale
                bottomRightRadius: 20 * Appearance.effectiveScale
                z: 0

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: parent.topLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    bottomRightRadius: parent.bottomRightRadius
                    onClicked: if(Config.ready) Config.options.appearance.clock.showDesktopDate = !Config.options.appearance.clock.showDesktopDate
                }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "calendar_today"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show date on desktop"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.clock.showDesktopDate; onToggled: if(Config.ready) Config.options.appearance.clock.showDesktopDate = !Config.options.appearance.clock.showDesktopDate }
                }
            }
        }

        // Global Toggles
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale
            visible: !rootClock.dedicatedIsLock
            SegmentedWrapper {
                id: syncStylesCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, syncStylesRow.implicitHeight)
                color: Appearance.m3colors.m3surfaceContainerHigh
                orientation: Qt.Vertical

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: syncStylesCard.rTopLeft
                    topRightRadius: syncStylesCard.rTopRight
                    bottomLeftRadius: syncStylesCard.rBottomLeft
                    bottomRightRadius: syncStylesCard.rBottomRight
                    onClicked: if (Config.ready)
                        Config.options.appearance.clock.useSameStyle = !Config.options.appearance.clock.useSameStyle
                }

                RowLayout {
                    id: syncStylesRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "sync"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Sync desktop with lockscreen"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.appearance.clock.useSameStyle
                        onToggled: {
                            if (Config.ready) {
                                Config.options.appearance.clock.useSameStyle = !Config.options.appearance.clock.useSameStyle
                            }
                        }
                    }
                }
            }

        }
    }
}
