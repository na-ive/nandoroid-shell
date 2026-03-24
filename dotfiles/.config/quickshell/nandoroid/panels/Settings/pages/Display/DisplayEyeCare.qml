import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            RowLayout {
                spacing: 12 * Appearance.effectiveScale
                Layout.bottomMargin: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "bedtime"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Eye Care"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: nightRow.implicitHeight + (40 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8 * Appearance.effectiveScale
                fullRadius: 20 * Appearance.effectiveScale
                
                RowLayout {
                    id: nightRow
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale
                    
                    ColumnLayout {
                        spacing: 2 * Appearance.effectiveScale
                        StyledText {
                            text: "Night Light"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Reduce eye strain by displaying warmer colors."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 52 * Appearance.effectiveScale
                        implicitHeight: 28 * Appearance.effectiveScale
                        radius: 14 * Appearance.effectiveScale
                        color: Hyprsunset.active ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20 * Appearance.effectiveScale
                            height: 20 * Appearance.effectiveScale
                            radius: 10 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                            x: Hyprsunset.active ? parent.width - width - (4 * Appearance.effectiveScale) : 4 * Appearance.effectiveScale
                            color: Hyprsunset.active ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Hyprsunset.toggle()
                        }
                    }
                }
            }

            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: colorTempCol.implicitHeight + (40 * Appearance.effectiveScale)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8 * Appearance.effectiveScale
                fullRadius: 20 * Appearance.effectiveScale
                
                opacity: Hyprsunset.active ? 1.0 : 0.4
                enabled: Hyprsunset.active

                ColumnLayout {
                    id: colorTempCol
                    anchors.fill: parent
                    anchors.margins: 20 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    RowLayout {
                        width: parent.width
                        StyledText {
                            text: "Color Temperature"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: Hyprsunset.colorTemperature + "K"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colPrimary
                        }
                    }

                    StyledSlider {
                        Layout.fillWidth: true
                        from: 1200
                        to: 6500
                        stepSize: 100
                        value: (Config.options && Config.options.nightMode) ? Config.options.nightMode.colorTemperature : 4000
                        configuration: StyledSlider.Configuration.M
                        onMoved: {
                            if (Config.ready && Config.options.nightMode) {
                                Config.options.nightMode.colorTemperature = value;
                            }
                        }
                    }
        }
    }
}
