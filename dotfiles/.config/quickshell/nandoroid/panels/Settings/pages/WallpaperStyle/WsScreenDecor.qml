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
        searchString: "Screen Decor"
        aliases: ["Corners", "Borders", "Rounding"]
    }

    // ── Screen Decor Section ──

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16 * Appearance.effectiveScale
    
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "desktop_windows"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: I18nService.tr("Screen Decor")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
    
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale
    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, screenCornerToggleRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: screenCornerToggleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "rounded_corner"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Rounded screen corners"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { val: 0, label: I18nService.tr("Off") },
                                        { val: 1, label: I18nService.tr("Adaptive") },
                                        { val: 2, label: I18nService.tr("Always") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && (Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.mode : 1) === modelData.val
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.appearance.screenCorners)
                                            Config.options.appearance.screenCorners.mode = modelData.val
                                    }
                                }
                            }
                        }
                    }
    
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(64 * Appearance.effectiveScale, screenCornerRadRow.implicitHeight)
                        orientation: Qt.Vertical
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && (Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.mode : 1) > 0
                        RowLayout {
                            id: screenCornerRadRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            
                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                Layout.preferredWidth: 70 * Appearance.effectiveScale
                                MaterialSymbol { text: "straighten"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { 
                                    text: I18nService.tr("Corner radius")
                                    Layout.fillWidth: true
                                    color: Appearance.colors.colOnLayer1 
                                }
                            }

                            StyledStepper {
                                Layout.alignment: Qt.AlignVCenter
                                from: 0; to: 100; stepSize: 1
                                decimals: 0
                                suffix: "px"
                                value: Config.ready && Config.options.appearance.screenCorners ? Config.options.appearance.screenCorners.radius : 20
                                onValueChanged: if (Config.ready && Config.options.appearance.screenCorners)
                                    Config.options.appearance.screenCorners.radius = Math.round(value)
                            }
                        }
                    }
                }
            }
    

}
