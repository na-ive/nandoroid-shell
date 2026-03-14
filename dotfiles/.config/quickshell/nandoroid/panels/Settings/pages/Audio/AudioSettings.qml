import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

/**
 * Functional Audio Settings page.
 * Provides master controls and device selection for input and output.
 */
Flickable {
    id: root
    contentHeight: mainCol.implicitHeight + 48
    clip: true

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            StyledText {
                text: "Audio"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: "Adjust volume levels and manage your audio input/output devices."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Volume Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            StyledText {
                text: "Volume Levels"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: volumeCol.implicitHeight + 32
                radius: 16
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: volumeCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 24

                    // Output Volume
                    ColumnLayout {
                        spacing: 8
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: Audio.volume > 0 ? (Audio.volume > 0.5 ? "volume_up" : "volume_down") : "volume_mute"
                                iconSize: 22
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                text: "Master Volume"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: Math.round(Audio.volume * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Audio.volume
                            stopIndicatorValues: []
                            onMoved: Audio.setVolume(value)
                        }
                    }
 
                    // Input Volume
                    ColumnLayout {
                        spacing: 8
                        RowLayout {
                            spacing: 8
                            MaterialSymbol {
                                text: "mic"
                                iconSize: 22
                                color: Appearance.colors.colSecondary
                            }
                            StyledText {
                                text: "Microphone"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: Math.round(Audio.microphoneVolume * 100) + "%"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        StyledSlider {
                            Layout.fillWidth: true
                            value: Audio.microphoneVolume
                            stopIndicatorValues: []
                            onMoved: Audio.setMicrophoneVolume(value)
                        }
                    }
                }
            }
        }

        // ── Per-App Volume Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16
            visible: Audio.streamNodes.length > 0

            StyledText {
                text: "Volume per Application"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: perAppCol.implicitHeight + 32
                radius: 16
                color: Appearance.colors.colLayer1

                ColumnLayout {
                    id: perAppCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 24

                    Repeater {
                        model: Audio.streamNodes
                        delegate: ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8
                            RowLayout {
                                spacing: 8
                                
                                Item {
                                    width: 20
                                    height: 20
                                    
                                    IconImage {
                                        id: appIcon
                                        anchors.fill: parent
                                        source: Quickshell.iconPath(Audio.appNodeIconName(modelData), "image-missing")
                                        visible: status === Image.Ready
                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "settings_input_component"
                                        iconSize: 20
                                        color: Appearance.colors.colPrimary
                                        visible: appIcon.status !== Image.Ready
                                    }
                                }

                                StyledText {
                                    text: Audio.appNodeDisplayName(modelData)
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer1
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: Math.round(modelData.audio.volume * 100) + "%"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }
                            StyledSlider {
                                Layout.fillWidth: true
                                value: modelData.audio.volume
                                stopIndicatorValues: []
                                onMoved: Audio.setNodeVolume(modelData, value)
                            }
                        }
                    }
                }
            }
        }

        // ── Device Section ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 24
            
            // Output Devices
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 12
                StyledText {
                    text: "Output Devices"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                AudioDeviceList {
                    model: Audio.outputDevices
                    isSink: true
                    onSelected: (node) => Audio.setDefaultSink(node)
                }
            }

            // Input Devices
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                spacing: 12
                StyledText {
                    text: "Input Devices"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                AudioDeviceList {
                    model: Audio.inputDevices
                    isSink: false
                    onSelected: (node) => Audio.setDefaultSource(node)
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

}
