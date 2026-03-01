import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

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
        anchors.margins: 12
        spacing: 8

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

        // Device list
        ListView {
            id: audioList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.isSink ? Audio.outputDevices : Audio.inputDevices

            delegate: RippleButton {
                id: audioDeviceItem
                required property var modelData
                required property int index
                
                // Determine if this is the default device
                readonly property bool isActive: root.isSink 
                    ? (Audio.sink === modelData)
                    : (Audio.source === modelData)

                width: audioList.width
                implicitHeight: 56
                buttonRadius: Appearance.rounding.small
                colBackground: audioDeviceItem.isActive ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.85) : "transparent"
                colBackgroundHover: audioDeviceItem.isActive ? Functions.ColorUtils.transparentize(Appearance.colors.colPrimary, 0.75) : Appearance.colors.colLayer2
                
                onClicked: {
                    if (root.isSink) {
                        Audio.setDefaultSink(audioDeviceItem.modelData);
                    } else {
                        Audio.setDefaultSource(audioDeviceItem.modelData);
                    }
                }

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    MaterialSymbol {
                        text: {
                            if (!root.isSink) return "mic"
                            // Basic mapping based on device name/type
                            const desc = audioDeviceItem.modelData.description.toLowerCase();
                            if (desc.includes("headset") || desc.includes("headphone")) return "headphones"
                            if (desc.includes("hdmi") || desc.includes("tv")) return "tv"
                            return "speaker"
                        }
                        iconSize: 22
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
                        iconSize: 20
                        fill: 1
                        color: Appearance.colors.colPrimary
                    }
                }
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
