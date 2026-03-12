import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0
    
    SearchHandler { 
        searchString: "Dock"
        aliases: ["Taskbar", "App Dock", "Pinned Apps"]
    }

    // ── Dock Section ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        spacing: 16
        
        // Section Header
        RowLayout {
            spacing: 12
            Layout.bottomMargin: 4
            MaterialSymbol {
                text: "bottom_panel_open"
                iconSize: 24
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Dock"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 // STANDAR GAP 4px

            // ── Enable Dock ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: enableRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                RowLayout {
                    id: enableRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "visibility"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Enable Dock"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.enable : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.enable = !Config.options.dock.enable
                    }
                }
            }

            // ── Show only in Desktop ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: showDesktopRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: showDesktopRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "desktop_windows"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Only in Desktop"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.showOnlyInDesktop : false
                        onToggled: {
                            if (Config.ready && Config.options.dock) {
                                const newState = !Config.options.dock.showOnlyInDesktop;
                                Config.options.dock.showOnlyInDesktop = newState;
                                if (newState && Config.options.dock.autoHide && Config.options.dock.autoHideMode === 0) {
                                    Config.options.dock.autoHideMode = 1;
                                }
                            }
                        }
                    }
                }
            }

            // ── Auto Hide Mode ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: autoHideRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: autoHideRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "visibility_off"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Auto Hide"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2
                        Repeater {
                            model: {
                                const onlyDesktop = Config.ready && Config.options.dock && Config.options.dock.showOnlyInDesktop;
                                if (onlyDesktop) return [{ val: -1, label: "Off" }, { val: 1,  label: "Always" }];
                                return [{ val: -1, label: "Off" }, { val: 0,  label: "Adaptive" }, { val: 1,  label: "Always" }];
                            }
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: {
                                    if (modelData.val === -1) return !Config.options.dock.autoHide;
                                    return Config.options.dock.autoHide && Config.options.dock.autoHideMode === modelData.val;
                                }
                                colActive: Appearance.m3colors.m3primary; colActiveText: Appearance.m3colors.m3onPrimary; colInactive: Appearance.m3colors.m3surfaceContainerLow
                                onClicked: {
                                    if (modelData.val === -1) Config.options.dock.autoHide = false;
                                    else { Config.options.dock.autoHide = true; Config.options.dock.autoHideMode = modelData.val; }
                                }
                            }
                        }
                    }
                }
            }

            // ── Background Style ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: bgStyleRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: bgStyleRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "layers"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Background"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2
                        Repeater {
                            model: [{ val: 0, label: "None" }, { val: 1, label: "Floating" }, { val: 2, label: "Attached" }]
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: Config.options.dock.backgroundStyle === modelData.val
                                colActive: Appearance.m3colors.m3primary; colActiveText: Appearance.m3colors.m3onPrimary; colInactive: Appearance.m3colors.m3surfaceContainerLow
                                onClicked: Config.options.dock.backgroundStyle = modelData.val
                            }
                        }
                    }
                }
            }

            // ── Themed Icons ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: monoRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: monoRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "palette"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Themed Icons"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.monochromeIcons : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.monochromeIcons = !Config.options.dock.monochromeIcons
                    }
                }
            }

            // ── Dock Scale ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: scaleRow.implicitHeight + 32
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: scaleRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 20

                    RowLayout {
                        spacing: 16
                        Layout.preferredWidth: 70
                        MaterialSymbol { text: "open_in_full"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Scale"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; elide: Text.ElideRight }
                    }

                    StyledSlider {
                        Layout.fillWidth: true; from: 0.5; to: 1.5; stepSize: 0.05
                        value: Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0
                        onMoved: if (Config.ready && Config.options.dock) Config.options.dock.scale = value
                    }
                    
                    StyledText {
                        text: Math.round((Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0) * 100).toString() + "%"
                        color: Appearance.colors.colOnLayer1; Layout.preferredWidth: 50; horizontalAlignment: Text.AlignRight
                    }
                }
            }

            // ── Show App Launcher ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: launcherRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: launcherRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "widgets"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show App Launcher"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showLauncher ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showLauncher = !Config.options.dock.showLauncher
                    }
                }
            }

            // ── Show Overview Button ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: overviewRow.implicitHeight + 36
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: overviewRow
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16
                    MaterialSymbol { text: "grid_view"; iconSize: 24; color: Appearance.colors.colPrimary }
                    StyledText { text: "Show Overview Button"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showOverview ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showOverview = !Config.options.dock.showOverview
                    }
                }
            }
        }
    }
}
