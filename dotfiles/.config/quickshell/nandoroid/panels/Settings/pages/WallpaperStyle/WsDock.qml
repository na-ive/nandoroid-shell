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
        Layout.topMargin: 24
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
            spacing: 8

            // ── Enable Dock ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: enableRow.implicitHeight + 32
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
                implicitHeight: showDesktopRow.implicitHeight + 32
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
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.showOnlyInDesktop = !Config.options.dock.showOnlyInDesktop
                    }
                }
            }

            // ── Auto Hide Group ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: autoHideCol.implicitHeight + 32
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                
                ColumnLayout {
                    id: autoHideCol
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 16

                    RowLayout {
                        spacing: 16
                        MaterialSymbol { text: "visibility_off"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Auto Hide (Hover to Reveal)"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        AndroidToggle {
                            checked: Config.ready && Config.options.dock ? Config.options.dock.autoHide : false
                            onToggled: if (Config.ready && Config.options.dock)
                                Config.options.dock.autoHide = !Config.options.dock.autoHide
                        }
                    }

                    // Mode Selection (HANYA MUNCUL JIKA showOnlyInDesktop MATI)
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Config.ready && Config.options.dock && Config.options.dock.autoHide && !Config.options.dock.showOnlyInDesktop
                        spacing: 8
                        
                        StyledText { 
                            text: "Mode Sembunyi" 
                            font.pixelSize: 12
                            color: Appearance.colors.colSubtext 
                            Layout.leftMargin: 40
                        }

                        SegmentedWrapper {
                            Layout.fillWidth: true
                            Layout.leftMargin: 40
                            implicitHeight: 48
                            color: Appearance.m3colors.m3surfaceContainer
                            
                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                SegmentedButton {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    buttonText: "Intelligent"
                                    checked: Config.options.dock.autoHideMode === 0
                                    onClicked: Config.options.dock.autoHideMode = 0
                                }
                                SegmentedButton {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    buttonText: "Always"
                                    checked: Config.options.dock.autoHideMode === 1
                                    onClicked: Config.options.dock.autoHideMode = 1
                                }
                            }
                        }
                    }
                }
            }

            // ── Background Style ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: bgStyleCol.implicitHeight + 32
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                
                ColumnLayout {
                    id: bgStyleCol
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        spacing: 16
                        MaterialSymbol { text: "layers"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Background Style"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    }

                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: 48
                        color: Appearance.m3colors.m3surfaceContainer
                        
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            
                            SegmentedButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                buttonText: "None"
                                checked: Config.options.dock.backgroundStyle === 0
                                onClicked: Config.options.dock.backgroundStyle = 0
                            }
                            SegmentedButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                buttonText: "Floating"
                                checked: Config.options.dock.backgroundStyle === 1
                                onClicked: Config.options.dock.backgroundStyle = 1
                            }
                            SegmentedButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                buttonText: "Attached"
                                checked: Config.options.dock.backgroundStyle === 2
                                onClicked: Config.options.dock.backgroundStyle = 2
                            }
                        }
                    }
                }
            }

            // ── Monochrome Icons ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: monoRow.implicitHeight + 32
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
                    StyledText { text: "Monochrome Icons"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    AndroidToggle {
                        checked: Config.ready && Config.options.dock ? Config.options.dock.monochromeIcons : false
                        onToggled: if (Config.ready && Config.options.dock)
                            Config.options.dock.monochromeIcons = !Config.options.dock.monochromeIcons
                    }
                }
            }

            // ── Dock Height ──────────────
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: heightCol.implicitHeight + 32
                orientation: Qt.Vertical
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                enabled: Config.ready && Config.options.dock && Config.options.dock.enable
                opacity: enabled ? 1 : 0.5
                ColumnLayout {
                    id: heightCol
                    anchors.fill: parent; anchors.margins: 16
                    spacing: 8
                    RowLayout {
                        spacing: 16
                        MaterialSymbol { text: "height"; iconSize: 24; color: Appearance.colors.colPrimary }
                        StyledText { text: "Dock Height"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                        StyledText { 
                            text: (Config.ready && Config.options.dock ? Config.options.dock.height : 70) + "px"
                            color: Appearance.colors.colPrimary
                            font.weight: Font.Bold
                        }
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        from: 48
                        to: 120
                        stepSize: 2
                        value: Config.ready && Config.options.dock ? Config.options.dock.height : 70
                        onMoved: if (Config.ready && Config.options.dock) Config.options.dock.height = value
                    }
                }
            }
        }
    }
}
