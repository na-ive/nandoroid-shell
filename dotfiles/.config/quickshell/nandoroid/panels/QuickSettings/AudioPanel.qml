import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

/**
 * Functional Audio device selection panel.
 * Shared between Audio Output and Audio Input — configured via `isSink`.
 * Uses real Pipewire data from the Audio service.
 */
Rectangle {
    id: root
    signal dismiss()
    
    property string panelTitle: "Audio Output"
    property string panelIcon: "volume_up"
    property bool isSink: true

    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.panel

    // Block clicks from leaking through to the header
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Appearance.colors.colLayer2
                onClicked: root.dismiss()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20
                    color: Appearance.m3colors.m3onSurface
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.panelTitle
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            MaterialSymbol {
                text: root.panelIcon
                iconSize: 22
                color: Appearance.colors.colPrimary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        // Scrollable Content
        Flickable {
            id: audioFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: audioContentCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: audioContentCol
                width: audioFlick.width
                spacing: 20

                // Section: Devices
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    StyledText {
                        text: "Devices"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3outline
                        Layout.leftMargin: 4
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Repeater {
                            model: root.isSink ? Audio.outputDevices : Audio.inputDevices
                            delegate: RippleButton {
                                id: audioDeviceItem
                                required property var modelData
                                width: audioFlick.width
                                implicitHeight: 52
                                buttonRadius: Appearance.rounding.small
                                
                                readonly property bool isActive: root.isSink 
                                    ? (Audio.sink === modelData)
                                    : (Audio.source === modelData)

                                colBackground: audioDeviceItem.isActive ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85) : "transparent"
                                colBackgroundHover: audioDeviceItem.isActive ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75) : Appearance.colors.colLayer2
                                
                                onClicked: {
                                    if (root.isSink) Audio.setDefaultSink(audioDeviceItem.modelData);
                                    else Audio.setDefaultSource(audioDeviceItem.modelData);
                                }

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    MaterialSymbol {
                                        text: {
                                            if (!root.isSink) return "mic"
                                            const desc = audioDeviceItem.modelData.description.toLowerCase();
                                            if (desc.includes("headset") || desc.includes("headphone")) return "headphones"
                                            if (desc.includes("hdmi") || desc.includes("tv")) return "tv"
                                            return "speaker"
                                        }
                                        iconSize: 20
                                        fill: audioDeviceItem.isActive ? 1 : 0
                                        color: audioDeviceItem.isActive ? Appearance.colors.colPrimary : Appearance.m3colors.m3onSurfaceVariant
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: Audio.friendlyDeviceName(audioDeviceItem.modelData)
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.m3colors.m3onSurface
                                        elide: Text.ElideRight
                                    }

                                    MaterialSymbol {
                                        visible: audioDeviceItem.isActive
                                        text: "check_circle"
                                        iconSize: 18
                                        fill: 1
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }
                        }
                    }
                }

                // Section: Applications
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: (root.isSink ? Audio.streamNodes.length : Audio.micStreamNodes.length) > 0
                    
                    StyledText {
                        text: "Applications"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3outline
                        Layout.leftMargin: 4
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: root.isSink ? Audio.streamNodes : Audio.micStreamNodes
                            delegate: Rectangle {
                                id: streamItem
                                required property var modelData
                                width: audioFlick.width
                                implicitHeight: streamLayout.implicitHeight + 20 // Dynamic height + margins
                                color: Appearance.colors.colLayer1
                                radius: Appearance.rounding.small

                                ColumnLayout {
                                    id: streamLayout
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8
                                        
                                        Item {
                                            width: 22
                                            height: 22
                                            
                                            IconImage {
                                                id: appIcon
                                                anchors.fill: parent
                                                source: Quickshell.iconPath(Audio.appNodeIconName(streamItem.modelData), "image-missing")
                                                visible: status === Image.Ready
                                            }

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "settings_input_component"
                                                iconSize: 18
                                                color: Appearance.m3colors.m3primary
                                                visible: appIcon.status !== Image.Ready
                                            }
                                        }

                                        StyledText {
                                            text: Audio.appNodeDisplayName(streamItem.modelData)
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.Medium
                                            color: Appearance.m3colors.m3onSurface
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        StyledText {
                                            text: Math.round(streamItem.modelData.audio.volume * 100) + "%"
                                            font.pixelSize: 10
                                            color: Appearance.colors.colSubtext
                                        }
                                    }

                                    StyledSlider {
                                        Layout.fillWidth: true
                                        configuration: StyledSlider.Configuration.M
                                        value: streamItem.modelData.audio.volume
                                        stopIndicatorValues: []
                                        onMoved: Audio.setNodeVolume(streamItem.modelData, value)
                                    }
                                }
                            }
                        }
                    }
                }

                // Bottom spacer for better scrolling
                Item { Layout.preferredHeight: 12 }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: audioDoneText.implicitWidth + 24
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.12)
                onClicked: root.dismiss()
                StyledText {
                    id: audioDoneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
