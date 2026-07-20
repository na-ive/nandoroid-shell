import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "System Interface"
        aliases: ["Privacy Indicators", "Window Snapping", "Region Selector"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "settings_suggest"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "System Interface"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Privacy Indicators
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: privRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            maxRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: privRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Privacy Indicators"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Show Android-style green pill when microphone or camera is active."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                    checked: (Config.ready && Config.options.privacy && Config.options.privacy.enable)
                    onToggled: {
                        if (Config.ready && Config.options.privacy) {
                            Config.options.privacy.enable = !Config.options.privacy.enable;
                        }
                    }
                }
            }
        }

        // Region Selector: Windows Snapping
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: snapRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            maxRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: snapRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Region Selector: Window Snapping"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Enable automatic window detection and snapping when selecting a region."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                    checked: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows)
                    onToggled: {
                        if (Config.ready && Config.options.regionSelector) {
                            Config.options.regionSelector.targetRegions.windows = !Config.options.regionSelector.targetRegions.windows;
                        }
                    }
                }
            }
        }
    }
}
