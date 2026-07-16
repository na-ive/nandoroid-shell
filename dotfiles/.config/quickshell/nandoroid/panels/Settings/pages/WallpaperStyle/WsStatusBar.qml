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
        searchString: "Status Bar"
        aliases: ["Bar", "Top Bar", "Panel", "Statusbar"]
    }

    // ── Status Bar Section ──

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale
    
                readonly property bool isM3Style: Config.ready && Config.options.statusBar && (Config.options.statusBar.moduleStyle === "m3")

    
                // Computed: background is ALWAYS active (style == 1)
                readonly property bool sbAlwaysSolid: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) === 1
                    : false
                // Computed: any background style is selected (style > 0)
                readonly property bool sbAnyBgStyle: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) > 0
                    : false
                // Gradient is active: only when bg is not ALWAYS solid + useGradient = true
                readonly property bool sbGradientActive: !sbAlwaysSolid
                    && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true)
    
                // Section Header
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "view_compact"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Status Bar"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
    
                ColumnLayout {
                    id: sbSettingsCol
                    Layout.fillWidth: true
                    spacing: 16 * Appearance.effectiveScale
    
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52 * Appearance.effectiveScale
                        spacing: 4 * Appearance.effectiveScale
                        
                        SegmentedButton {
                            width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                            height: parent.height
                            isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle !== "m3"
                            buttonText: "Base Style"
                            onClicked: if (Config.ready && Config.options.statusBar) Config.options.statusBar.moduleStyle = "base"
                        }
        
                        SegmentedButton {
                            width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                            height: parent.height
                            isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle === "m3"
                            buttonText: "M3 Style"
                            onClicked: if (Config.ready && Config.options.statusBar) Config.options.statusBar.moduleStyle = "m3"
                        }
                    }

                    // ── Layout & Appearance ─────────────────────────────
                    StyledText {
                        text: "Layout & Appearance"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                        Layout.topMargin: 12 * Appearance.effectiveScale
                        Layout.bottomMargin: 4 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Auto Hide ──────────────────────────────────────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: autoHideRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: autoHideRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "visibility_off"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Auto hide"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.autoHide ?? false) : false
                                onToggled: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.autoHide = !Config.options.statusBar.autoHide
                            }
                        }
                    }

                    // ── Text color mode (disabled when bg is active) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarTextRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: parent.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarTextRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Text color"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "adaptive", label: "Adaptive" },
                                        { id: "light",    label: "Light" },
                                        { id: "dark",     label: "Dark" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        enabled: !sbSettingsCol.parent.sbAlwaysSolid
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.textColorMode === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                            Config.options.statusBar.textColorMode = modelData.id
                                    }
                                }
                            }
                        }
                    }
    
                    // ── Use Gradient (disabled ONLY when background is ALWAYS active) ──────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarGradientRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: sbSettingsCol.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarGradientRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "gradient"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Use gradient"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true
                                onToggled: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                    Config.options.statusBar.useGradient = !Config.options.statusBar.useGradient
                            }
                        }
                    }
    
                    // ── Background Style (None / Always / Adaptive) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarBgRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: statusBarBgRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "rectangle"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Background"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { val: 0, label: "None" },
                                        { val: 1, label: "Always" },
                                        { val: 2, label: "Adaptive" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.backgroundStyle === modelData.val
                                            : modelData.val === 0
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.backgroundStyle = modelData.val
                                    }
                                }
                            }
                        }
                    }

                    // ── Layout Style (Standard / Centered) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: layoutStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: layoutStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "center_focus_strong"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Layout Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "standard", label: "Standard" },
                                        { id: "centered", label: "Centered (HUD)" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.layoutStyle === modelData.id
                                            : modelData.id === "standard"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.layoutStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    } // End Layout & Appearance ColumnLayout

                    // ── Modules Positioning ──────────────────────────────────
                    StyledText {
                        text: "Modules Positioning"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                        Layout.topMargin: 12 * Appearance.effectiveScale
                        Layout.bottomMargin: 4 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Clock Position (Center / Right) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: clockPositionRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: clockPositionRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "schedule"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Clock Position"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "center", label: "Center" },
                                        { id: "right", label: "Right" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.clockPosition ?? "center") === modelData.id
                                            : modelData.id === "center"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.clockPosition = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Notification Position (Left / Right) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: notifPositionRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: notifPositionRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "notifications"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Notification Counter"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "left", label: "Left" },
                                        { id: "right", label: "Right" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.notifications
                                            ? (Config.options.notifications.position ?? "right") === modelData.id
                                            : modelData.id === "right"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.notifications)
                                            Config.options.notifications.position = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Active Window Position ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: activeWindowPositionRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: activeWindowPositionRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "web_asset"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Active Window Name"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "left", label: "Left" },
                                        { id: "right", label: "Right" },
                                        { id: "hidden", label: "Hidden" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.activeWindowPosition ?? "left") === modelData.id
                                            : modelData.id === "left"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.activeWindowPosition = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── System Monitor ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sysMonCol.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        ColumnLayout {
                            id: sysMonCol
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                MaterialSymbol { text: "memory"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: "System Monitor"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                                RowLayout {
                                    spacing: 2 * Appearance.effectiveScale
                                    Repeater {
                                        model: [
                                            { id: "left", label: "Left" },
                                            { id: "right", label: "Right" },
                                            { id: "hidden", label: "Hidden" }
                                        ]
                                        delegate: SegmentedButton {
                                            required property var modelData
                                            buttonText: modelData.label
                                            isHighlighted: Config.ready && Config.options.statusBar
                                                ? (Config.options.statusBar.systemMonitorPosition ?? "hidden") === modelData.id
                                                : modelData.id === "hidden"
                                            colActive: Appearance.m3colors.m3primary
                                            colActiveText: Appearance.m3colors.m3onPrimary
                                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                                            onClicked: if (Config.ready && Config.options.statusBar)
                                                Config.options.statusBar.systemMonitorPosition = modelData.id
                                        }
                                    }
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                visible: Config.ready && Config.options.statusBar && (Config.options.statusBar.systemMonitorPosition ?? "hidden") !== "hidden"
                                spacing: 12 * Appearance.effectiveScale
                                Item { Layout.fillWidth: true } // Spacer
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorCpu ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorCpu = !Config.options.statusBar.showSystemMonitorCpu
                                    }
                                    StyledText { text: "CPU"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorRam ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorRam = !Config.options.statusBar.showSystemMonitorRam
                                    }
                                    StyledText { text: "RAM"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorSwap ?? false) : false
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorSwap = !Config.options.statusBar.showSystemMonitorSwap
                                    }
                                    StyledText { text: "Swap"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorTemp ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorTemp = !Config.options.statusBar.showSystemMonitorTemp
                                    }
                                    StyledText { text: "Temp"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorText ?? false) : false
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorText = !Config.options.statusBar.showSystemMonitorText
                                    }
                                    StyledText { text: "Text"; color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                            }
                        }
                    }

                    // ── System Monitor Style ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sysMonStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && (Config.options.statusBar.systemMonitorPosition ?? "hidden") !== "hidden"
                        RowLayout {
                            id: sysMonStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "style"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "System Monitor Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "outline", label: "Outline" },
                                        { id: "filled", label: "Filled" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.systemMonitorStyle ?? "outline") === modelData.id
                                            : modelData.id === "outline"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.systemMonitorStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Centered Width (only visible when centered is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: centeredWidthRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && Config.options.statusBar.layoutStyle === "centered"
                        RowLayout {
                            id: centeredWidthRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 20 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                Layout.preferredWidth: 70 * Appearance.effectiveScale // Ramped down to give maximum space to slider
                                MaterialSymbol { text: "width_full"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { 
                                    text: "Centered width"
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer1 
                                }
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                from: 800; to: 2000; stepSize: 50
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.centeredWidth ?? 1200) : 1200
                                onMoved: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.centeredWidth = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(Config.ready && Config.options.statusBar
                                    ? (Config.options.statusBar.centeredWidth ?? 1200) : 1200).toString() + "px"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 50 * Appearance.effectiveScale
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // ── Corner radius (visible when ANY background style is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbCornerRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: sbSettingsCol.parent.sbAnyBgStyle
                        RowLayout {
                            id: sbCornerRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 20 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                Layout.preferredWidth: 70 * Appearance.effectiveScale
                                MaterialSymbol { text: "rounded_corner"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { 
                                    text: "Corner radius"
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer1 
                                }
                            }

                            StyledSlider {
                                Layout.fillWidth: true
                                from: 0; to: 20; stepSize: 1
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20
                                onMoved: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.backgroundCornerRadius = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(Config.ready && Config.options.statusBar
                                    ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20).toString() + "px"
                                color: Appearance.colors.colOnLayer1
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    } // End Modules Positioning ColumnLayout

                    // ── Modules Styling ──────────────────────────────────────
                    StyledText {
                        text: "Modules Styling"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colPrimary
                        Layout.topMargin: 12 * Appearance.effectiveScale
                        Layout.bottomMargin: 4 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Workspace Style (Shape) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: wsStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: wsStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "layers"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Indicator Shape"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "pill", label: "Pill" },
                                        { id: "unified", label: "Unified" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.workspaces
                                            ? Config.options.workspaces.indicatorStyle === modelData.id
                                            : modelData.id === "pill"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.workspaces)
                                            Config.options.workspaces.indicatorStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Workspace Style (Label) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: wsLabelRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: wsLabelRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "format_list_numbered"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Indicator Label"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "none", label: "None" },
                                        { id: "numeric", label: "Numeric" },
                                        { id: "japanese", label: "Japanese" },
                                        { id: "roman", label: "Roman" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.workspaces
                                            ? (Config.options.workspaces.indicatorLabel ?? "none") === modelData.id
                                            : modelData.id === "none"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.workspaces)
                                            Config.options.workspaces.indicatorLabel = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Island Style ──
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: islandStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: islandStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "animation"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Island Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "pill", label: "Pill" },
                                        { id: "waterdrop", label: "Waterdrop" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.islandStyle === modelData.id
                                            : modelData.id === "pill"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.islandStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Tray Style ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: trayStyleRow.implicitHeight + (36 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: trayStyleRow
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "apps"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Tray Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "all", label: "All" },
                                        { id: "adaptive", label: "Adaptive" },
                                        { id: "hide", label: "Hide" }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.trayStyle ?? "adaptive") === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.trayStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Volume Indicator ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: volumeIndicatorRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: volumeIndicatorRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "volume_up"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Volume Indicator"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                                onToggled: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.showVolumeIndicator = !Config.options.statusBar.showVolumeIndicator
                            }
                        }
                    }

                    // ── Workspace count ──────────────────────────────────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbWorkspaceRow.implicitHeight + (32 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: sbWorkspaceRow
                            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "grid_view"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: "Workspace count"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 8 * Appearance.effectiveScale
                                M3IconButton {
                                    iconName: "remove"
                                    iconSize: 18 * Appearance.effectiveScale
                                    implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: Appearance.m3colors.m3surfaceContainerLow
                                    color: Appearance.m3colors.m3primary
                                    onClicked: {
                                        if (Config.ready && Config.options.workspaces) {
                                            let val = Config.options.workspaces.max_shown ?? 5
                                            if (val > 1) Config.options.workspaces.max_shown = val - 1
                                        }
                                    }
                                }
                                StyledText {
                                    text: (Config.ready && Config.options.workspaces ? (Config.options.workspaces.max_shown ?? 5) : 5).toString()
                                    color: Appearance.colors.colOnLayer1
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    Layout.preferredWidth: 30 * Appearance.effectiveScale
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                M3IconButton {
                                    iconName: "add"
                                    iconSize: 18 * Appearance.effectiveScale
                                    implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: Appearance.m3colors.m3surfaceContainerLow
                                    color: Appearance.m3colors.m3primary
                                    onClicked: {
                                        if (Config.ready && Config.options.workspaces) {
                                            let val = Config.options.workspaces.max_shown ?? 5
                                            if (val < 20) Config.options.workspaces.max_shown = val + 1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    } // End Modules Styling ColumnLayout
                }
            }
    

}
