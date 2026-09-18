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
        spacing: 4 * Appearance.effectiveScale

        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "bottom_panel_open"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Dock")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale // STANDAR GAP 4px

            // ── Enable Dock ──────────────
            SegmentedWrapper {
                id: enableCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, enableRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: enableCard.rTopLeft
                    topRightRadius: enableCard.rTopRight
                    bottomLeftRadius: enableCard.rBottomLeft
                    bottomRightRadius: enableCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.dock)
                        Config.options.dock.enable = !Config.options.dock.enable
                }

                RowLayout {
                    id: enableRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "visibility"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Enable Dock"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.enable : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.enable = !Config.options.dock.enable
                    }
                }
            }

            // ── Show only in Desktop ──────────────
            SegmentedWrapper {
                id: showDesktopCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, showDesktopRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: showDesktopCard.rTopLeft
                    topRightRadius: showDesktopCard.rTopRight
                    bottomLeftRadius: showDesktopCard.rBottomLeft
                    bottomRightRadius: showDesktopCard.rBottomRight
                    onClicked: showDesktopToggle.toggled()
                }

                RowLayout {
                    id: showDesktopRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "desktop_windows"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Only in Desktop"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        id: showDesktopToggle
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
                implicitHeight: Math.max(64 * Appearance.effectiveScale, autoHideRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: autoHideRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "visibility_off"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Auto Hide"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: {
                                const onlyDesktop = Config.ready && Config.options.dock && Config.options.dock.showOnlyInDesktop;
                                if (onlyDesktop) return [{ val: -1, label: I18nService.tr("Off") }, { val: 1,  label: I18nService.tr("Always") }];
                                return [{ val: -1, label: I18nService.tr("Off") }, { val: 0,  label: I18nService.tr("Adaptive") }, { val: 1,  label: I18nService.tr("Always") }];
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
                implicitHeight: Math.max(64 * Appearance.effectiveScale, bgStyleRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: bgStyleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "layers"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Background"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: [{ val: 0, label: I18nService.tr("None") }, { val: 1, label: I18nService.tr("Floating") }, { val: 2, label: I18nService.tr("Attached") }]
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
                id: monoCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, monoRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: monoCard.rTopLeft
                    topRightRadius: monoCard.rTopRight
                    bottomLeftRadius: monoCard.rBottomLeft
                    bottomRightRadius: monoCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.dock)
                        Config.options.dock.monochromeIcons = !Config.options.dock.monochromeIcons
                }

                RowLayout {
                    id: monoRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Themed Icons"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
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
                implicitHeight: Math.max(64 * Appearance.effectiveScale, scaleRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: scaleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "open_in_full"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Scale"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; elide: Text.ElideRight }

                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 0.5; to: 1.5; stepSize: 0.05
                        displayFactor: 100
                        decimals: 0
                        suffix: "%"
                        value: Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0
                        onValueChanged: if (Config.ready && Config.options.dock) Config.options.dock.scale = value
                    }
                }
            }

            // ── Window Preview Threshold ──────────────
            SegmentedWrapper {
                id: previewCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, previewRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                RowLayout {
                    id: previewRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol { text: "preview"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Preview List From"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; elide: Text.ElideRight }

                    StyledStepper {
                        Layout.alignment: Qt.AlignVCenter
                        from: 2; to: 6; stepSize: 1
                        displayFactor: 1
                        decimals: 0
                        value: Config.ready && Config.options.dock ? (Config.options.dock.previewThreshold ?? 3) : 3
                        onValueChanged: if (Config.ready && Config.options.dock) Config.options.dock.previewThreshold = value
                    }
                }
            }

            // ── Show App Launcher ──────────────
            SegmentedWrapper {
                id: launcherCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, launcherRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: launcherCard.rTopLeft
                    topRightRadius: launcherCard.rTopRight
                    bottomLeftRadius: launcherCard.rBottomLeft
                    bottomRightRadius: launcherCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.dock)
                        Config.options.dock.showLauncher = !Config.options.dock.showLauncher
                }

                RowLayout {
                    id: launcherRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "widgets"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show App Launcher"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? (Config.options.dock.showLauncher ?? true) : true
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showLauncher = !Config.options.dock.showLauncher
                    }
                }
            }

            // ── Show Overview Button ──────────────
            SegmentedWrapper {
                id: overviewCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, overviewRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: overviewCard.rTopLeft
                    topRightRadius: overviewCard.rTopRight
                    bottomLeftRadius: overviewCard.rBottomLeft
                    bottomRightRadius: overviewCard.rBottomRight
                    onClicked: if (Config.ready && Config.options.dock)
                        Config.options.dock.showOverview = !Config.options.dock.showOverview
                }

                RowLayout {
                    id: overviewRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale
                    MaterialSymbol { text: "grid_view"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: I18nService.tr("Show Overview Button"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
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
