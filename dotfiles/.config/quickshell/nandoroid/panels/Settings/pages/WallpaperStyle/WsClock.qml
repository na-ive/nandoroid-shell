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

    SearchHandler { 
        searchString: "Clock Style"
        aliases: ["Clock", "Time", "Watch"]
    }

    // ── Clock Section ──
    ColumnLayout {
        id: clockStyleSection
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
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
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "watch"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Clock Style"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            
            RippleButton {
                visible: !rootClock.dedicatedIsLock
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                implicitWidth: 120 * Appearance.effectiveScale
                buttonText: "Reset Position"
                onClicked: {
                    Config.options.appearance.clock.offsetX = 0
                    Config.options.appearance.clock.offsetY = -50
                }
                colBackground: Appearance.m3colors.m3surfaceContainerHighest
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
            spacing: 4 * Appearance.effectiveScale
            visible: !rootClock.isDedicatedContext && Config.ready && !Config.options.appearance.clock.useSameStyle
            
            SegmentedButton {
                width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                height: parent.height
                buttonText: "Desktop"
                isHighlighted: clockStyleSection.activeContext === "desktop"
                onClicked: clockStyleSection.activeContext = "desktop"
                colActive: Appearance.m3colors.m3primary
                colActiveText: Appearance.m3colors.m3onPrimary
            }
            SegmentedButton {
                width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                height: parent.height
                buttonText: "Lockscreen"
                isHighlighted: clockStyleSection.activeContext === "lock"
                onClicked: clockStyleSection.activeContext = "lock"
                colActive: Appearance.m3colors.m3primary
                colActiveText: Appearance.m3colors.m3onPrimary
            }
        }

        // Style Picker
        Rectangle {
            Layout.fillWidth: true
            visible: rootClock.dedicatedIsLock || (Config.ready && !Config.options.appearance.clock.useSameStyle)
            implicitHeight: 120 * Appearance.effectiveScale
            radius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { id: "digital", name: "Digital", icon: "numbers" },
                        { id: "analog",  name: "Analog",  icon: "watch" },
                        { id: "stacked", name: "Stacked", icon: "view_day" },
                        { id: "text",    name: "Text",    icon: "text_fields" },
                        { id: "pill",    name: "Pill",    icon: "smart_button" },
                        { id: "code",    name: "Code",    icon: "code" }
                    ]
                    delegate: RippleButton {
                        id: clockStyleBtn
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        buttonRadius: 16 * Appearance.effectiveScale
                        
                        readonly property bool isSelected: {
                            if (!Config.ready) return false
                            if (Config.options.appearance.clock.useSameStyle) return Config.options.appearance.clock.styleLocked === modelData.id
                            if (clockStyleSection.activeContext === "lock") return Config.options.appearance.clock.styleLocked === modelData.id
                            return Config.options.appearance.clock.style === modelData.id
                        }
                        
                        colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerLow
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
                            spacing: 8 * Appearance.effectiveScale
                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                iconSize: 24 * Appearance.effectiveScale
                                color: clockStyleBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurfaceVariant
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                font.pixelSize: 12 * Appearance.effectiveScale
                                font.weight: clockStyleBtn.isSelected ? Font.DemiBold : Font.Normal
                                color: clockStyleBtn.isSelected ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface
                            }
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
            buttonRadius: 16 * Appearance.effectiveScale
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
                    text: "Advanced Settings"
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

            // ── Digital Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "digital"
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: "Color Style"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "onSurface", "surface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.digitalCfg.colorStyle === modelData
                                onClicked: advancedPanel.digitalCfg.colorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Orientation"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        SegmentedButton {
                            buttonText: "Horizontal"
                            isHighlighted: Config.ready && !advancedPanel.digitalCfg.isVertical
                            onClicked: advancedPanel.digitalCfg.isVertical = false
                        }
                        SegmentedButton {
                            buttonText: "Vertical"
                            isHighlighted: Config.ready && advancedPanel.digitalCfg.isVertical
                            onClicked: advancedPanel.digitalCfg.isVertical = true
                        }
                    }
                    StyledText { text: "Font Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true; value: Config.ready ? advancedPanel.digitalCfg.fontSize : 84; from: 48; to: 200
                            defaultValue: 84
                            onMoved: advancedPanel.digitalCfg.fontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.digitalCfg.fontSize).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText { text: "Date Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true; value: Config.ready ? (advancedPanel.digitalCfg.dateFontSize || 24) : 24; from: 12; to: 80
                            defaultValue: 24
                            onMoved: advancedPanel.digitalCfg.dateFontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.digitalCfg.dateFontSize || 24).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText { text: "Date Gap"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true; from: -40; to: 60; stepSize: 1
                            value: Config.ready ? (advancedPanel.digitalCfg.dateGap ?? 4) : 4
                            defaultValue: 4
                            onMoved: advancedPanel.digitalCfg.dateGap = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.digitalCfg.dateGap ?? 4).toString() + "px"; color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText { text: "Alignment"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["left", "center", "right"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
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
                    StyledText { text: "Clock Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true; value: Config.ready ? advancedPanel.analogCfg.size : 240; from: 120; to: 480
                            defaultValue: 240
                            onMoved: advancedPanel.analogCfg.size = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.analogCfg.size).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText {
                        text: "Face Shape"
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
                    StyledText { text: "Background Style"; color: Appearance.colors.colOnLayer1 }
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
                    StyledText { text: "Sides"; color: Appearance.colors.colOnLayer1; visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine") }
                    RowLayout {
                        visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine")
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true; from: 3; to: 36; stepSize: 1; value: Config.ready ? advancedPanel.analogCfg.sides : 12; defaultValue: 12
                            onMoved: advancedPanel.analogCfg.sides = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.analogCfg.sides).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText { text: "Constantly Rotate"; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.constantlyRotate; onToggled: advancedPanel.analogCfg.constantlyRotate = !advancedPanel.analogCfg.constantlyRotate }
                    StyledText { text: "Time Indicators"; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.timeIndicators; onToggled: advancedPanel.analogCfg.timeIndicators = !advancedPanel.analogCfg.timeIndicators }
                    StyledText { text: "Hour Marks"; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.hourMarks; onToggled: advancedPanel.analogCfg.hourMarks = !advancedPanel.analogCfg.hourMarks }
                    StyledText { text: "Show Marks"; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.analogCfg.showMarks; onToggled: advancedPanel.analogCfg.showMarks = !advancedPanel.analogCfg.showMarks }
                    StyledText { text: "Dial Style"; color: Appearance.colors.colOnLayer1; visible: Config.ready && advancedPanel.analogCfg.showMarks }
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
                    StyledText { text: "Hour Hand"; color: Appearance.colors.colOnLayer1 }
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
                    StyledText { text: "Minute Hand"; color: Appearance.colors.colOnLayer1 }
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
                    StyledText { text: "Second Hand"; color: Appearance.colors.colOnLayer1 }
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
                    StyledText { text: "Date Style"; color: Appearance.colors.colOnLayer1 }
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
                    StyledText { text: "Value Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.codeCfg.valueColorStyle === modelData
                                onClicked: advancedPanel.codeCfg.valueColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Keyword Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.codeCfg.keywordColorStyle === modelData
                                onClicked: advancedPanel.codeCfg.keywordColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Block Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.codeCfg.blockColorStyle === modelData
                                onClicked: advancedPanel.codeCfg.blockColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Block Style"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: [
                                { id: "js", label: "JS / while" },
                                { id: "python", label: "Python" },
                                { id: "rust", label: "Rust" },
                                { id: "c", label: "C/C++" },
                                { id: "kotlin", label: "Kotlin" }
                            ]
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: Config.ready && advancedPanel.codeCfg.blockType === modelData.id
                                onClicked: advancedPanel.codeCfg.blockType = modelData.id
                            }
                        }
                    }
                    StyledText { text: "Font Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready ? advancedPanel.codeCfg.fontSize : 18
                            defaultValue: 18
                            from: 12; to: 48
                            onMoved: advancedPanel.codeCfg.fontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.codeCfg.fontSize).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                }
            }

            // ── Stacked Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "stacked"
                Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 16 * Appearance.effectiveScale; columnSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: "Main Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "error", "onSurface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.stackedCfg.colorStyle === modelData
                                onClicked: advancedPanel.stackedCfg.colorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Text Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "tertiary", "onSurface", "surface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.stackedCfg.textColorStyle === modelData
                                onClicked: advancedPanel.stackedCfg.textColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Alignment"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["left", "center", "right"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.stackedCfg.alignment === modelData
                                onClicked: advancedPanel.stackedCfg.alignment = modelData
                            }
                        }
                    }
                    StyledText { text: "Clock Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready ? advancedPanel.stackedCfg.fontSize : 84
                            defaultValue: 84
                            from: 32; to: 160
                            onMoved: advancedPanel.stackedCfg.fontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.stackedCfg.fontSize).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText { text: "Label Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready ? advancedPanel.stackedCfg.labelFontSize : 42
                            defaultValue: 42
                            from: 16; to: 84
                            onMoved: advancedPanel.stackedCfg.labelFontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.stackedCfg.labelFontSize).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                }
            }

            // ── Text Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "text"
                Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: "Time Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "onSurface", "surface", "error"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.textCfg.timeColorStyle === modelData
                                onClicked: advancedPanel.textCfg.timeColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Date Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "onSurface", "surface", "error"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.textCfg.dateColorStyle === modelData
                                onClicked: advancedPanel.textCfg.dateColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Alignment"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["left", "center", "right"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.textCfg.alignment === modelData
                                onClicked: advancedPanel.textCfg.alignment = modelData
                            }
                        }
                    }
                    StyledText { text: "Font Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready ? (advancedPanel.textCfg.fontSize || 42) : 42
                            defaultValue: 42
                            from: 14; to: 120
                            onMoved: advancedPanel.textCfg.fontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.textCfg.fontSize || 42).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                    StyledText { text: "Date Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready ? (advancedPanel.textCfg.dateFontSize || 18) : 18
                            defaultValue: 18
                            from: 8; to: 60
                            onMoved: advancedPanel.textCfg.dateFontSize = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.textCfg.dateFontSize || 18).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                }
            }

            // ── Pill Advanced ──
            ColumnLayout {
                visible: advancedPanel.currentStyle === "pill"
                Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                GridLayout {
                    columns: 2; Layout.fillWidth: true; rowSpacing: 12 * Appearance.effectiveScale
                    StyledText { text: "Time Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primary", "secondary", "onSurface", "surface"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                isHighlighted: Config.ready && advancedPanel.pillCfg.timeColorStyle === modelData
                                onClicked: advancedPanel.pillCfg.timeColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Pill Color"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: ["primaryContainer", "secondaryContainer", "surfaceContainerHigh", "surfaceContainerLowest"]
                            delegate: SegmentedButton {
                                required property string modelData
                                buttonText: {
                                    if (modelData === "surfaceContainerHigh") return "Surface";
                                    if (modelData === "primaryContainer") return "Primary";
                                    if (modelData === "secondaryContainer") return "Secondary";
                                    return "Glass";
                                }
                                isHighlighted: Config.ready && advancedPanel.pillCfg.pillColorStyle === modelData
                                onClicked: advancedPanel.pillCfg.pillColorStyle = modelData
                            }
                        }
                    }
                    StyledText { text: "Orientation"; color: Appearance.colors.colOnLayer1 }
                    Row {
                        Layout.alignment: Qt.AlignRight; spacing: 2 * Appearance.effectiveScale
                        SegmentedButton { buttonText: "Horizontal"; isHighlighted: Config.ready && !advancedPanel.pillCfg.isVertical; onClicked: advancedPanel.pillCfg.isVertical = false }
                        SegmentedButton { buttonText: "Vertical"; isHighlighted: Config.ready && advancedPanel.pillCfg.isVertical; onClicked: advancedPanel.pillCfg.isVertical = true }
                    }
                    StyledText { text: "Show Background"; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { Layout.alignment: Qt.AlignRight; checked: Config.ready && advancedPanel.pillCfg.showBackground; onToggled: advancedPanel.pillCfg.showBackground = !advancedPanel.pillCfg.showBackground }
                    StyledText { text: "Clock Size"; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12 * Appearance.effectiveScale
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Config.ready ? (advancedPanel.pillCfg.size || 120) : 120
                            defaultValue: 120
                            from: 60; to: 300
                            onMoved: advancedPanel.pillCfg.size = Math.round(value)
                        }
                        StyledText { text: Math.round(advancedPanel.pillCfg.size || 120).toString(); color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 40 * Appearance.effectiveScale; horizontalAlignment: Text.AlignRight }
                    }
                }
            }
        }

        // Clock Fonts & Date Settings
        ColumnLayout {
            Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
            z: 10 // Ensure dropdowns overlap below elements
            visible: rootClock.dedicatedIsLock || (Config.ready && !Config.options.appearance.clock.useSameStyle)

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: 20 * Appearance.effectiveScale
                topRightRadius: 20 * Appearance.effectiveScale
                bottomLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                z: 2 // Make sure top combo overlaps bottom combo
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "text_fields"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { 
                        text: Config.options.appearance.clock.useSameStyle ? "Time Font" : (clockStyleSection.activeContext === "desktop" ? "Desktop Time Font" : "Lockscreen Time Font")
                        Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 
                    }
                    StyledComboBox {
                        Layout.preferredWidth: 300 * Appearance.effectiveScale
                        model: SystemFonts.all
                        text: {
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
            }

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                topRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomLeftRadius: rootClock.dedicatedIsLock ? 20 * Appearance.effectiveScale : (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomRightRadius: rootClock.dedicatedIsLock ? 20 * Appearance.effectiveScale : (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                z: 1
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "calendar_month"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { 
                        text: Config.options.appearance.clock.useSameStyle ? "Date Font" : (clockStyleSection.activeContext === "desktop" ? "Desktop Date Font" : "Lockscreen Date Font")
                        Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 
                    }
                    StyledComboBox {
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
                visible: !rootClock.dedicatedIsLock
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                topLeftRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                topRightRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
                bottomLeftRadius: 20 * Appearance.effectiveScale
                bottomRightRadius: 20 * Appearance.effectiveScale
                z: 0
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 16 * Appearance.effectiveScale; anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "calendar_today"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show date on desktop"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle { checked: Config.ready && Config.options.appearance.clock.showDesktopDate; onToggled: if(Config.ready) Config.options.appearance.clock.showDesktopDate = !Config.options.appearance.clock.showDesktopDate }
                }
            }
        }

        // Global Toggles
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale
            SegmentedWrapper {
                Layout.fillWidth: true; implicitHeight: 64 * Appearance.effectiveScale; color: Appearance.m3colors.m3surfaceContainerHigh
                orientation: Qt.Vertical
                maxRadius: 20 * Appearance.effectiveScale
                visible: !rootClock.dedicatedIsLock
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "sync"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Sync desktop with lockscreen"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
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
