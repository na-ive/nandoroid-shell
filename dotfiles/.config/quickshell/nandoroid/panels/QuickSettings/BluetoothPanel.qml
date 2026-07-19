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
                            id: cardHeader
                            Layout.fillWidth: true
                            implicitHeight: 64 * Appearance.effectiveScale
                            buttonRadius: 16 * Appearance.effectiveScale
                            colBackground: {
                                if (deviceItem.modelData.connected) return Functions.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.92)
                                if (deviceItem.expanded) return Appearance.colors.colLayer0Hover
                                return "transparent"
                            }
                            colBackgroundHover: deviceItem.modelData.connected ? colBackground : Appearance.colors.colLayer0Hover
                            onClicked: deviceItem.expanded = !deviceItem.expanded

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: {
                                        const type = deviceItem.modelData.deviceType;
                                        if (type === "phone") return "smartphone"
                                        if (type === "computer") return "computer"
                                        if (type === "audio-card") return "headset"
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
                                        font.weight: deviceItem.modelData.connected ? Font.DemiBold : Font.Normal
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    StyledText {
                                        readonly property var _d: deviceItem.modelData
                                        text: {
                                            if (_d.connected) return "Connected" + (_d.batteryAvailable ? " · " + Math.round(_d.battery * 100) + "%" : "")
                                            if (_d.state === BluetoothDeviceState.Connecting || BluetoothStatus.pairingAddress === _d.address) return "Connecting..."
                                            if (_d.pairing) return "Pairing..."
                                            if (_d.paired || _d.trusted) return "Paired"
                                            return "Available"
                                        }
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: _d.state === BluetoothDeviceState.Connecting || _d.pairing ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                RippleButton {
                                    implicitWidth: 32 * Appearance.effectiveScale
                                    implicitHeight: 32 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: deviceItem.expanded = !deviceItem.expanded
                                    contentItem: MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: deviceItem.expanded ? "expand_less" : "expand_more"
                                        iconSize: 20 * Appearance.effectiveScale
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                            }

                            // Header rounding overlay for expansion joint
                            Rectangle {
                                anchors.fill: parent
                                visible: deviceItem.expanded
                                color: cardHeader.colBackground
                                z: -1
                                radius: 16 * Appearance.effectiveScale
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 16 * Appearance.effectiveScale
                                    color: parent.color
                                }
                            }
                        }

                        // ── Expanded Actions ──
                        Rectangle {
                            id: cardExpansion
                            Layout.fillWidth: true
                            Layout.preferredHeight: deviceItem.expanded ? expansionColumn.implicitHeight + (32 * Appearance.effectiveScale) : 0
                            clip: true
                            color: Appearance.colors.colLayer2
                            radius: 16 * Appearance.effectiveScale
                            opacity: deviceItem.expanded ? 1 : 0
                            visible: Layout.preferredHeight > 0
                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            Rectangle {
                                width: parent.width
                                height: 16 * Appearance.effectiveScale
                                color: parent.color
                                visible: deviceItem.expanded
                                anchors.top: parent.top
                            }

                            ColumnLayout {
                                id: expansionColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 16 * Appearance.effectiveScale
                                anchors.rightMargin: 16 * Appearance.effectiveScale
                                anchors.top: parent.top
                                anchors.topMargin: 16 * Appearance.effectiveScale
                                spacing: 12 * Appearance.effectiveScale

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12 * Appearance.effectiveScale

                                    Item { Layout.fillWidth: true }

                                    RippleButton {
                                        visible: (deviceItem.modelData.paired || deviceItem.modelData.trusted) && !deviceItem.modelData.connected
                                        buttonText: "Forget"
                                        implicitWidth: 90 * Appearance.effectiveScale
                                        implicitHeight: 36 * Appearance.effectiveScale
                                        buttonRadius: 18 * Appearance.effectiveScale
                                        colBackground: Appearance.m3colors.m3error
                                        colText: Appearance.m3colors.m3onError
                                        onClicked: {
                                            if (deviceItem.modelData.forget) deviceItem.modelData.forget()
                                            else if (deviceItem.modelData.unpair) deviceItem.modelData.unpair()
                                            deviceItem.modelData.trusted = false
                                            deviceItem.expanded = false
                                        }
                                    }

                                    RippleButton {
                                        visible: deviceItem.modelData.paired
                                        buttonText: deviceItem.modelData.connected ? "Disconnect" : "Connect"
                                        implicitWidth: 110 * Appearance.effectiveScale
                                        implicitHeight: 36 * Appearance.effectiveScale
                                        buttonRadius: 18 * Appearance.effectiveScale
                                        colBackground: Appearance.colors.colPrimary
                                        colText: Appearance.colors.colOnPrimary
                                        onClicked: {
                                            if (deviceItem.modelData.connected) deviceItem.modelData.disconnect()
                                            else BluetoothStatus.pairAndTrust(deviceItem.modelData)
                                            deviceItem.expanded = false
                                        }
                                    }

                                    RippleButton {
                                        visible: !deviceItem.modelData.paired
                                        buttonText: "Pair & Connect"
                                        implicitWidth: 110 * Appearance.effectiveScale
                                        implicitHeight: 36 * Appearance.effectiveScale
                                        buttonRadius: 18 * Appearance.effectiveScale
                                        colBackground: Appearance.colors.colPrimary
                                        colText: Appearance.colors.colOnPrimary
                                        onClicked: {
                                            BluetoothStatus.pairAndTrust(deviceItem.modelData)
                                            deviceItem.expanded = false
                                        }
                                    }
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
