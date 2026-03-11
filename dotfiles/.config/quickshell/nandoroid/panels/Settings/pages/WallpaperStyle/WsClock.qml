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
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "Clock Style"
        aliases: ["Clock", "Time", "Watch"]
    }

    // ── Clock Section ──
    ColumnLayout {

                id: clockStyleSection
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 16
                
                property string activeContext: "desktop"
                property bool showAdvanced: false
    
                // Section Header
                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 4
                    MaterialSymbol {
                        text: "watch"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Clock Style"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                    
                    // Reset Position Button (Only for Desktop)
                    RippleButton {
                        visible: !Config.options.appearance.clock.useSameStyle || clockStyleSection.activeContext === "desktop"
                        Layout.preferredHeight: 32
                        implicitWidth: 120
                        buttonText: "Reset Position"
                        onClicked: {
                            Config.options.appearance.clock.offsetX = 0
                            Config.options.appearance.clock.offsetY = -50
                        }
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                    }
                }
    
                // Context Switcher (Only if NOT same style)
                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    spacing: 4
                    visible: Config.ready && !Config.options.appearance.clock.useSameStyle
                    
                    SegmentedButton {
                        width: (parent.width - 4) / 2
                        height: parent.height
                        buttonText: "Desktop"
                        isHighlighted: clockStyleSection.activeContext === "desktop"
                        onClicked: clockStyleSection.activeContext = "desktop"
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary
                    }
                    SegmentedButton {
                        width: (parent.width - 4) / 2
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
                    implicitHeight: 120
                    radius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
    
                        Repeater {
                            model: [
                                { id: "digital", name: "Digital", icon: "numbers" },
                                { id: "analog",  name: "Analog",  icon: "watch" },
                                { id: "stacked", name: "Stacked", icon: "view_day" },
                                { id: "code",    name: "Code",    icon: "code" }
                            ]
                            delegate: RippleButton {
                                id: clockStyleBtn
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                buttonRadius: 16
                                
                                readonly property bool isSelected: {
                                    if (!Config.ready) return false
                                    if (Config.options.appearance.clock.useSameStyle || clockStyleSection.activeContext === "desktop") {
                                        return Config.options.appearance.clock.style === modelData.id
                                    } else {
                                        return Config.options.appearance.clock.styleLocked === modelData.id
                                    }
                                }
                                
                                colBackground: isSelected ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceContainerLow
                                colRipple: Appearance.m3colors.m3primary
                                
                                onClicked: {
                                    if (!Config.ready) return
                                    if (Config.options.appearance.clock.useSameStyle) {
                                        Config.options.appearance.clock.style = modelData.id
                                        Config.options.appearance.clock.styleLocked = modelData.id
                                    } else {
                                        if (clockStyleSection.activeContext === "desktop") {
                                            Config.options.appearance.clock.style = modelData.id
                                        } else {
                                            Config.options.appearance.clock.styleLocked = modelData.id
                                        }
                                    }
                                }
                                
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        iconSize: 24
                                        color: clockStyleBtn.isSelected ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.name
                                        font.pixelSize: 12
                                        font.weight: clockStyleBtn.isSelected ? Font.Bold : Font.Normal
                                        color: clockStyleBtn.isSelected ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurface
                                    }
                                }
                            }
                        }
                    }
                }
    
                // Advanced Settings Toggle
                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    buttonRadius: 16
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    onClicked: clockStyleSection.showAdvanced = !clockStyleSection.showAdvanced
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        MaterialSymbol {
                            text: clockStyleSection.showAdvanced ? "expand_less" : "expand_more"
                            iconSize: 20
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
                    visible: clockStyleSection.showAdvanced
                    spacing: 12
    
                    readonly property string currentStyle: {
                        if (!Config.ready) return "digital"
                        if (Config.options.appearance.clock.useSameStyle || clockStyleSection.activeContext === "desktop") return Config.options.appearance.clock.style;
                        return Config.options.appearance.clock.styleLocked;
                    }
    
                    // Routes read/write to the correct config object based on context
                    readonly property bool isLockCtx: clockStyleSection.activeContext === "lock" && !Config.options.appearance.clock.useSameStyle
                    readonly property var digitalCfg: isLockCtx ? Config.options.appearance.clock.digitalLocked : Config.options.appearance.clock.digital
                    readonly property var analogCfg:  isLockCtx ? Config.options.appearance.clock.analogLocked  : Config.options.appearance.clock.analog
                    readonly property var codeCfg:    isLockCtx ? Config.options.appearance.clock.codeLocked    : Config.options.appearance.clock.code
                    readonly property var stackedCfg: isLockCtx ? Config.options.appearance.clock.stackedLocked : Config.options.appearance.clock.stacked
    
                    // ── Digital Advanced ──
                    ColumnLayout {
                        visible: advancedPanel.currentStyle === "digital"
                        Layout.fillWidth: true
                        spacing: 8
    
                        // Color Style
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            rowSpacing: 12
                            StyledText { text: "Color Style"; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            // Orientation
                            StyledText { text: "Orientation"; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            // Font Size
                            StyledText { 
                                text: "Font Size"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    value: Config.ready ? advancedPanel.digitalCfg.fontSize : 84
                                    from: 48; to: 200
                                    onMoved: advancedPanel.digitalCfg.fontSize = Math.round(value)
                                }
                                StyledText { 
                                    text: Math.round(advancedPanel.digitalCfg.fontSize).toString()
                                    color: Appearance.colors.colOnLayer1 
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
    
    
                            // Time-Date Gap
                            StyledText { 
                                text: "Date Gap"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    from: -40; to: 60; stepSize: 1
                                    value: Config.ready ? (advancedPanel.digitalCfg.dateGap ?? 4) : 4
                                    onMoved: advancedPanel.digitalCfg.dateGap = Math.round(value)
                                }
                                StyledText {
                                    text: Math.round(advancedPanel.digitalCfg.dateGap ?? 4).toString() + "px"
                                    color: Appearance.colors.colOnLayer1
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
    
                    // ── Analog Advanced ──
                    ColumnLayout {
                        visible: advancedPanel.currentStyle === "analog"
                        Layout.fillWidth: true
                        spacing: 16
    
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            rowSpacing: 16
                            columnSpacing: 12
    
                            StyledText { 
                                text: "Clock Size"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    value: Config.ready ? advancedPanel.analogCfg.size : 240
                                    from: 120; to: 480
                                    onMoved: advancedPanel.analogCfg.size = Math.round(value)
                                }
                                StyledText { 
                                    text: Math.round(advancedPanel.analogCfg.size).toString()
                                    color: Appearance.colors.colOnLayer1 
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
    
                            StyledText {
                                text: "Face Shape"
                                Layout.alignment: Qt.AlignTop
                                color: Appearance.colors.colOnLayer1
                                Layout.topMargin: 12
                                Layout.preferredWidth: 110
                                visible: Config.ready && advancedPanel.analogCfg.backgroundStyle === "shape"
                            }
                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: Config.ready && advancedPanel.analogCfg.backgroundStyle === "shape"
                                Repeater {
                                    model: ["Circle", "Square", "Slanted", "Arch", "Fan", "Arrow", "SemiCircle", "Oval", "Pill", "Triangle", "Diamond", "ClamShell", "Pentagon", "Gem", "Sunny", "VerySunny", "Cookie4Sided", "Cookie6Sided", "Cookie9Sided", "Cookie12Sided", "Clover4Leaf", "Burst", "SoftBurst", "Flower", "Puffy", "Heart"]
                                    delegate: RippleButton {
                                        required property string modelData
                                        width: 56; height: 56
                                        buttonRadius: 12
                                        property bool isSelected: Config.ready && advancedPanel.analogCfg.shape === modelData
                                        colBackground: isSelected ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                                        onClicked: advancedPanel.analogCfg.shape = modelData
                                        MaterialShape {
                                            anchors.centerIn: parent
                                            implicitSize: 32
                                            shapeString: modelData
                                            color: parent.isSelected ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                                        }
                                    }
                                }
                            }
                            StyledText { 
                                text: "Background Style"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText {
                                text: "Sides"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1
                                visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine")
                            }
                            RowLayout {
                                visible: Config.ready && (advancedPanel.analogCfg.backgroundStyle === "cookie" || advancedPanel.analogCfg.backgroundStyle === "sine")
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    from: 3
                                    to: 36
                                    stepSize: 1
                                    value: Config.ready ? advancedPanel.analogCfg.sides : 12
                                    onMoved: advancedPanel.analogCfg.sides = Math.round(value)
                                }
                                StyledText {
                                    text: Math.round(advancedPanel.analogCfg.sides).toString()
                                    color: Appearance.colors.colOnLayer1
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
    
                            StyledText { text: "Constantly Rotate"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                Layout.alignment: Qt.AlignRight
                                checked: Config.ready && advancedPanel.analogCfg.constantlyRotate
                                onToggled: advancedPanel.analogCfg.constantlyRotate = !advancedPanel.analogCfg.constantlyRotate
                            }
    
                            StyledText { text: "Time Indicators"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                Layout.alignment: Qt.AlignRight
                                checked: Config.ready && advancedPanel.analogCfg.timeIndicators
                                onToggled: advancedPanel.analogCfg.timeIndicators = !advancedPanel.analogCfg.timeIndicators
                            }
    
                            StyledText { text: "Hour Marks"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                Layout.alignment: Qt.AlignRight
                                checked: Config.ready && advancedPanel.analogCfg.hourMarks
                                onToggled: advancedPanel.analogCfg.hourMarks = !advancedPanel.analogCfg.hourMarks
                            }
    
                            StyledText { text: "Show Marks"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                Layout.alignment: Qt.AlignRight
                                checked: Config.ready && advancedPanel.analogCfg.showMarks
                                onToggled: advancedPanel.analogCfg.showMarks = !advancedPanel.analogCfg.showMarks
                            }
    
                            StyledText {
                                text: "Dial Style"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1
                                visible: Config.ready && advancedPanel.analogCfg.showMarks
                            }
                            Row {
                                visible: Config.ready && advancedPanel.analogCfg.showMarks
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
                                Repeater {
                                    model: ["none", "dots", "full", "numbers"]
                                    delegate: SegmentedButton {
                                        required property string modelData
                                        buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        isHighlighted: Config.ready && advancedPanel.analogCfg.dialStyle === modelData
                                        onClicked: advancedPanel.analogCfg.dialStyle = modelData
                                    }
                                }
                            }
    
                            StyledText { text: "Hour Hand"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
                                Repeater {
                                    model: ["none", "classic", "hollow", "fill"]
                                    delegate: SegmentedButton {
                                        required property string modelData
                                        buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        isHighlighted: Config.ready && advancedPanel.analogCfg.hourHandStyle === modelData
                                        onClicked: advancedPanel.analogCfg.hourHandStyle = modelData
                                    }
                                }
                            }
    
                            StyledText { text: "Minute Hand"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
                                Repeater {
                                    model: ["none", "classic", "thin", "medium", "bold"]
                                    delegate: SegmentedButton {
                                        required property string modelData
                                        buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        isHighlighted: Config.ready && advancedPanel.analogCfg.minuteHandStyle === modelData
                                        onClicked: advancedPanel.analogCfg.minuteHandStyle = modelData
                                    }
                                }
                            }
    
                            StyledText { text: "Second Hand"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
                                Repeater {
                                    model: ["none", "classic", "line", "dot"]
                                    delegate: SegmentedButton {
                                        required property string modelData
                                        buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        isHighlighted: Config.ready && advancedPanel.analogCfg.secondHandStyle === modelData
                                        onClicked: advancedPanel.analogCfg.secondHandStyle = modelData
                                    }
                                }
                            }
    
                            StyledText { text: "Date Style"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
                                Repeater {
                                    model: ["none", "bubble", "border", "rect"]
                                    delegate: SegmentedButton {
                                        required property string modelData
                                        buttonText: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                        isHighlighted: Config.ready && advancedPanel.analogCfg.dateStyle === modelData
                                        onClicked: advancedPanel.analogCfg.dateStyle = modelData
                                    }
                                }
                            }
    
    
    
    
                        }
                    }
    
                    // ── Code Advanced ──
                    ColumnLayout {
                        visible: advancedPanel.currentStyle === "code"
                        Layout.fillWidth: true
                        spacing: 12
    
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            rowSpacing: 16
                            columnSpacing: 12
    
                            StyledText { text: "Value Color"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText { text: "Keyword Color"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText { text: "Block Color"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText {
                                text: "Block Style"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1
                            }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
                                Repeater {
                                    model: [
                                        { id: "js",     label: "JS / while" },
                                        { id: "python", label: "Python" },
                                        { id: "rust",   label: "Rust" },
                                        { id: "c",      label: "C/C++" },
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
    
                            StyledText { 
                                text: "Font Size"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    value: Config.ready ? advancedPanel.codeCfg.fontSize : 18
                                    from: 12; to: 48
                                    onMoved: advancedPanel.codeCfg.fontSize = Math.round(value)
                                }
                                StyledText { 
                                    text: Math.round(advancedPanel.codeCfg.fontSize).toString()
                                    color: Appearance.colors.colOnLayer1 
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
    
                        }
                    }
    
                    // ── Stacked Advanced ──
                    ColumnLayout {
                        visible: advancedPanel.currentStyle === "stacked"
                        Layout.fillWidth: true
                        spacing: 12
    
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            rowSpacing: 16
                            columnSpacing: 12
    
                            StyledText { text: "Main Color"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText { text: "Text Color"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText { text: "Alignment"; Layout.preferredWidth: 160; color: Appearance.colors.colOnLayer1 }
                            Row {
                                Layout.alignment: Qt.AlignRight
                                spacing: 2
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
    
                            StyledText { 
                                text: "Clock Size"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    value: Config.ready ? advancedPanel.stackedCfg.fontSize : 84
                                    from: 32; to: 160
                                    onMoved: advancedPanel.stackedCfg.fontSize = Math.round(value)
                                }
                                StyledText { 
                                    text: Math.round(advancedPanel.stackedCfg.fontSize).toString()
                                    color: Appearance.colors.colOnLayer1 
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
    
                            StyledText { 
                                text: "Label Size"
                                Layout.preferredWidth: 110
                                color: Appearance.colors.colOnLayer1 
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12
                                StyledSlider {
                                    Layout.fillWidth: true
                                    value: Config.ready ? advancedPanel.stackedCfg.labelFontSize : 42
                                    from: 16; to: 84
                                    onMoved: advancedPanel.stackedCfg.labelFontSize = Math.round(value)
                                }
                                StyledText { 
                                    text: Math.round(advancedPanel.stackedCfg.labelFontSize).toString()
                                    color: Appearance.colors.colOnLayer1 
                                    Layout.preferredWidth: 40
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }
                }
    
                // Global Toggles Column
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
    
                    // Use Same Style Toggle (Grouped with main style usually, but here is fine)
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sameStyleRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: sameStyleRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "sync"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Use same style for lockscreen"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.appearance.clock.useSameStyle
                                onToggled: {
                                    if (Config.ready) {
                                        Config.options.appearance.clock.useSameStyle = !Config.options.appearance.clock.useSameStyle
                                        if (Config.options.appearance.clock.useSameStyle) Config.options.appearance.clock.styleLocked = Config.options.appearance.clock.style
                                    }
                                }
                            }
                        }
                    }
    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: showOnDesktopRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showOnDesktopRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "desktop_windows"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show clock on desktop"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.appearance.clock.showOnDesktop
                                onToggled: if(Config.ready) Config.options.appearance.clock.showOnDesktop = !Config.options.appearance.clock.showOnDesktop
                            }
                        }
                    }
                    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: showDateRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: showDateRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "calendar_today"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Show date"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.appearance.clock.showDate
                                onToggled: if(Config.ready) Config.options.appearance.clock.showDate = !Config.options.appearance.clock.showDate
                            }
                        }
                    }
                }
            }
            

}
