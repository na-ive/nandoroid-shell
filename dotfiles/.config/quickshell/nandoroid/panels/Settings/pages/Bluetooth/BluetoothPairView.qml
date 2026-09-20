import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    id: pairViewCol
    Layout.fillWidth: true
    visible: root.currentView === "pair"
    spacing: 24 * Appearance.effectiveScale

    // Kick off scanning when entering the pairing sub-page.
    onVisibleChanged: {
        if (visible && BluetoothStatus.enabled) {
            BluetoothStatus.startDiscovery();
        }
    }

    // Local Info
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale
        StyledText {
            text: I18nService.tr("Device name")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            text: (Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.name : "") || I18nService.tr("Unknown")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    // ── Available Devices ──
    ColumnLayout {
        Layout.fillWidth: true
        visible: BluetoothStatus.enabled
        spacing: 8 * Appearance.effectiveScale

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            StyledText {
                text: I18nService.tr("Available devices")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: 40 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer1
                onClicked: {
                    if (Bluetooth.defaultAdapter.discovering) {
                        BluetoothStatus.stopDiscovery();
                    } else {
                        BluetoothStatus.startDiscovery();
                    }
                }

                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Bluetooth.defaultAdapter.discovering ? "close" : "refresh"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Item {
            id: loadingDevices
            Layout.fillWidth: true
            implicitHeight: 80 * Appearance.effectiveScale
            readonly property bool isLoading: BluetoothStatus.enabled && (Bluetooth.defaultAdapter.discovering || BluetoothStatus.unpairedDevices.length === 0)
            visible: isLoading

            MaterialLoadingIndicator {
                anchors.centerIn: parent
                implicitSize: 60 * Appearance.effectiveScale
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * Appearance.effectiveScale
            visible: !loadingDevices.isLoading

            Repeater {
                model: BluetoothStatus.unpairedDevices
                delegate: SegmentedWrapper {
                    id: unpairedSeg
                    Layout.fillWidth: true
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RippleButton {
                        anchors.fill: parent
                        topLeftRadius: unpairedSeg.rTopLeft
                        topRightRadius: unpairedSeg.rTopRight
                        bottomLeftRadius: unpairedSeg.rBottomLeft
                        bottomRightRadius: unpairedSeg.rBottomRight
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: BluetoothStatus.pairAndTrust(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: BluetoothStatus.deviceTypeIcon(modelData)
                                iconSize: 24 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    text: modelData.name || I18nService.tr("Unknown Device")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: {
                                        if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || BluetoothStatus.pairingAddress === modelData.address) return I18nService.tr("Pairing...");
                                        return modelData.address;
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || BluetoothStatus.pairingAddress === modelData.address) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
