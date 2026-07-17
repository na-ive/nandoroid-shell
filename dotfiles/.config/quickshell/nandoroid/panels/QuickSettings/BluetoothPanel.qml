import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

/**
 * Functional Bluetooth device list panel.
 * Shows real devices using Quickshell.Bluetooth.
 */
Rectangle {
    id: root
    signal dismiss()
    
    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.panel

    // Block clicks from leaking through to the header
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            RippleButton {
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer2
                onClicked: root.dismiss()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3onSurface
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Bluetooth Devices"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            // Bluetooth power toggle
            RippleButton {
                implicitWidth: 56 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: BluetoothStatus.enabled ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                colBackgroundHover: BluetoothStatus.enabled ? Qt.darker(Appearance.colors.colPrimary, 1.12) : Appearance.colors.colLayer2Hover
                onClicked: {
                    if (Bluetooth.defaultAdapter) {
                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                    }
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    iconSize: 20 * Appearance.effectiveScale
                    color: BluetoothStatus.enabled ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        // Device list
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16 * Appearance.effectiveScale
            color: Appearance.colors.colLayer0
            clip: true

            ListView {
                id: deviceList
                anchors.fill: parent
                anchors.margins: 4 * Appearance.effectiveScale
                clip: true
                spacing: 2 * Appearance.effectiveScale
                model: BluetoothStatus.enabled ? [...BluetoothStatus.connectedDevices, ...BluetoothStatus.pairedButNotConnectedDevices] : []

                delegate: Item {
                    id: deviceItem
                    required property var modelData
                    required property int index
                    property bool expanded: false
                    width: deviceList.width
                    implicitHeight: deviceContent.implicitHeight

                    ColumnLayout {
                        id: deviceContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0

                        RippleButton {
                            Layout.fillWidth: true
                            implicitHeight: 56 * Appearance.effectiveScale
                            buttonRadius: 16 * Appearance.effectiveScale
                            colBackground: deviceItem.modelData.connected ? Functions.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.92) : "transparent"
                            colBackgroundHover: deviceItem.modelData.connected ? colBackground : Appearance.colors.colLayer0Hover
                            onClicked: deviceItem.expanded = !deviceItem.expanded

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: {
                                        const devClass = deviceItem.modelData.deviceClass;
                                        if (devClass === BluetoothDevice.AudioVideo) return "headphones"
                                        if (devClass === BluetoothDevice.Peripheral) return "keyboard"
                                        if (devClass === BluetoothDevice.Computer) return "laptop"
                                        if (devClass === BluetoothDevice.Phone) return "smartphone"
                                        return "bluetooth"
                                    }
                                    iconSize: 22 * Appearance.effectiveScale
                                    color: deviceItem.modelData.connected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        text: deviceItem.modelData.name || deviceItem.modelData.address
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    StyledText {
                                        text: {
                                            let s = deviceItem.modelData.connected ? "Connected" : (deviceItem.modelData.paired ? "Paired" : "Ready to pair")
                                            if (deviceItem.modelData.batteryPercentage > 0) s += ` • ${deviceItem.modelData.batteryPercentage}%`
                                            return s
                                        }
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MaterialSymbol {
                                    text: "keyboard_arrow_down"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                    rotation: deviceItem.expanded ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                }
                            }
                        }

                        // Expanded actions
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 48 * Appearance.effectiveScale
                            Layout.rightMargin: 12 * Appearance.effectiveScale
                            Layout.bottomMargin: 8 * Appearance.effectiveScale
                            visible: deviceItem.expanded
                            spacing: 8 * Appearance.effectiveScale

                            Item { Layout.fillWidth: true }

                            // Connect/Disconnect
                            RippleButton {
                                implicitWidth: connectBtnText.implicitWidth + (24 * Appearance.effectiveScale)
                                implicitHeight: 32 * Appearance.effectiveScale
                                buttonRadius: 16 * Appearance.effectiveScale
                                colBackground: deviceItem.modelData.connected ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
                            onClicked: {
                                if (deviceItem.modelData.connected) {
                                    deviceItem.modelData.disconnect();
                                } else {
                                    BluetoothStatus.pairAndTrust(deviceItem.modelData);
                                }
                                deviceItem.expanded = false;
                            }
                                StyledText {
                                    id: connectBtnText
                                    anchors.centerIn: parent
                                    text: deviceItem.modelData.connected ? "Disconnect" : "Connect"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: deviceItem.modelData.connected ? Appearance.colors.colOnLayer1 : Appearance.colors.colOnPrimary
                                }
                            }

                            // Forget (Unpair)
                            RippleButton {
                                visible: deviceItem.modelData.paired
                                implicitWidth: forgetBtnText.implicitWidth + (24 * Appearance.effectiveScale)
                                implicitHeight: 32 * Appearance.effectiveScale
                                buttonRadius: 16 * Appearance.effectiveScale
                                colBackground: Appearance.m3colors.m3error
                                onClicked: {
                                    deviceItem.modelData.unpair();
                                    deviceItem.expanded = false;
                                }
                                StyledText {
                                    id: forgetBtnText
                                    anchors.centerIn: parent
                                    text: "Forget"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.m3colors.m3onError
                                }
                            }
                        }
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
            spacing: 8 * Appearance.effectiveScale

            RippleButton {
                visible: BluetoothStatus.enabled
                implicitWidth: btPairText.implicitWidth + (24 * Appearance.effectiveScale)
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: height / 2
                colBackground: Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: {
                    GlobalStates.settingsPageIndex = 1;
                    GlobalStates.settingsBluetoothPairMode = true;
                    GlobalStates.activateSettings();
                }
                StyledText {
                    id: btPairText
                    anchors.centerIn: parent
                    text: "Pair new device"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: btDoneText.implicitWidth + (24 * Appearance.effectiveScale)
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: height / 2
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.1)
                onClicked: root.dismiss()
                StyledText {
                    id: btDoneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
