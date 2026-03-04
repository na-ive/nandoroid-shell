import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * Functional Audio Settings page.
 * Provides master controls and device selection for input and output.
 */
Flickable {
    id: root
    contentHeight: mainCol.implicitHeight
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
