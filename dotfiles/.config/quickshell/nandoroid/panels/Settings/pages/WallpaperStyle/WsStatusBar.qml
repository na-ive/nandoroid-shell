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
        aliases: ["Bar", "Top Bar", "Panel"]
    }

    // ── Status Bar Section ──

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 16
    
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
                    spacing: 12
                    Layout.bottomMargin: 4
                    MaterialSymbol {
                        text: "view_compact"
                        iconSize: 24
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
                    spacing: 4
    
                    // ── Text color mode (disabled when bg is active) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: statusBarTextRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: parent.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarTextRow
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "palette"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Text color"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2
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
                        Layout.fillWidth: true
                        implicitHeight: statusBarGradientRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: sbSettingsCol.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarGradientRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "gradient"; iconSize: 24; color: Appearance.colors.colPrimary }
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
                        Layout.fillWidth: true
                        implicitHeight: statusBarBgRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: statusBarBgRow
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "rectangle"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Background"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2
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
                        Layout.fillWidth: true
                        implicitHeight: layoutStyleRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: layoutStyleRow
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "center_focus_strong"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Layout Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2
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

                    // ── Autohide Toggle ──────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: autohideRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: autohideRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "visibility_off"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Autohide status bar"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? Config.options.statusBar.autohide : false
                                onToggled: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.autohide = !Config.options.statusBar.autohide
                            }
                        }
                    }

                    // ── Centered Width (only visible when centered is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: centeredWidthRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && Config.options.statusBar.layoutStyle === "centered"
                        RowLayout {
                            id: centeredWidthRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 20

                            RowLayout {
                                spacing: 16
                                Layout.preferredWidth: 70 // Ramped down to give maximum space to slider
                                MaterialSymbol { text: "width_full"; iconSize: 24; color: Appearance.colors.colPrimary }
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
                                Layout.preferredWidth: 50
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }

                    // ── Corner radius (visible when ANY background style is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbCornerRow.implicitHeight + 36
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: sbSettingsCol.parent.sbAnyBgStyle
                        RowLayout {
                            id: sbCornerRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 20

                            RowLayout {
                                spacing: 16
                                Layout.preferredWidth: 70
                                MaterialSymbol { text: "rounded_corner"; iconSize: 24; color: Appearance.colors.colPrimary }
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
                    // ── Workspace count ──────────────────────────────────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbWorkspaceRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: sbWorkspaceRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "grid_view"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Workspace count"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 8
                                M3IconButton {
                                    iconName: "remove"
                                    iconSize: 18
                                    implicitWidth: 32; implicitHeight: 32
                                    buttonRadius: 16
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
                                    Layout.preferredWidth: 30
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                M3IconButton {
                                    iconName: "add"
                                    iconSize: 18
                                    implicitWidth: 32; implicitHeight: 32
                                    buttonRadius: 16
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
                }
            }
    

}
