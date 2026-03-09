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
    
                // Computed: background is active (style > 0)
                readonly property bool sbBgActive: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) > 0
                    : false
                // Gradient is active: only when bg is None + useGradient = true
                readonly property bool sbGradientActive: !sbBgActive
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
                        opacity: parent.parent.sbBgActive ? 0.4 : 1.0
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
                                        enabled: !sbSettingsCol.parent.sbBgActive
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.textColorMode === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbBgActive)
                                            Config.options.statusBar.textColorMode = modelData.id
                                    }
                                }
                            }
                        }
                    }
    
                    // ── Use Gradient (disabled when bg is active) ──────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: statusBarGradientRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: sbSettingsCol.parent.sbBgActive ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarGradientRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "gradient"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Use gradient"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true
                                onToggled: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbBgActive)
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
    
                    // ── Corner Radius (only visible when background is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbCornerRow.implicitHeight + 32
                        orientation: Qt.Vertical
                        maxRadius: 20
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: sbSettingsCol.parent.sbBgActive
                        RowLayout {
                            id: sbCornerRow
                            anchors.fill: parent; anchors.margins: 16
                            spacing: 16
                            MaterialSymbol { text: "rounded_corner"; iconSize: 24; color: Appearance.colors.colPrimary }
                            StyledText { text: "Corner radius"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            StyledSlider {
                                Layout.preferredWidth: 160
                                from: 0; to: 40; stepSize: 1
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20
                                onMoved: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.backgroundCornerRadius = Math.round(value)
                            }
                            StyledText {
                                text: Math.round(Config.ready && Config.options.statusBar
                                    ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20).toString() + "px"
                                color: Appearance.colors.colOnLayer1
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
