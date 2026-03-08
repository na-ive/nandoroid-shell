import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import QtQuick.Shapes

/**
 * Functional Bluetooth Settings page.
 * Provides adapter management and device listing/pairing.
 */
Item {
    id: root
    
    property int stackLevel: 0 // 0: Main, 1: Pair Menu

    function checkPairMode() {
        if (GlobalStates.settingsBluetoothPairMode) {
            root.stackLevel = 1;
        }
    }

    Component.onCompleted: checkPairMode()

    Connections {
        target: GlobalStates
        function onSettingsBluetoothPairModeChanged() {
            if (GlobalStates.settingsBluetoothPairMode && root.visible) {
                root.stackLevel = 1;
            }
        }
    }

    Connections {
        target: BluetoothStatus
        function onEnabledChanged() {
            if (!BluetoothStatus.enabled) {
                root.stackLevel = 0;
            }
        }
    }
    
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 24
        visible: stackLevel === 0

        // ── Header ──
        ColumnLayout {
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: "Bluetooth"
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                

                // Bluetooth Global Toggle
                Rectangle {
                    implicitWidth: 52
                    implicitHeight: 28
                    radius: 14
                    color: BluetoothStatus.enabled
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colLayer2

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: BluetoothStatus.enabled ? parent.width - width - 4 : 4
                        color: BluetoothStatus.enabled
                            ? Appearance.colors.colOnPrimary
                            : Appearance.colors.colSubtext
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Bluetooth.defaultAdapter) {
                                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                            }
                        }
                    }
                }
            }
            StyledText {
                text: "Pair and manage your Bluetooth devices."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Device Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: BluetoothStatus.enabled


            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.colors.colLayer1
                onClicked: root.stackLevel = 1
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "add"
                        iconSize: 20
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Pair new device"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            StyledText {
                text: "Saved devices"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                visible: BluetoothStatus.pairedButNotConnectedDevices.length + BluetoothStatus.connectedDevices.length > 0
                Layout.topMargin: 8
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: Appearance.colors.colLayer1
                clip: true

                ListView {
                    id: deviceList
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    spacing: 4
                    model: [...BluetoothStatus.connectedDevices, ...BluetoothStatus.pairedButNotConnectedDevices]

                    delegate: Item {
                        id: deviceItem
                        width: deviceList.width
                        height: implicitHeight
                        implicitHeight: deviceContent.implicitHeight
                        property bool expanded: false

                        ColumnLayout {
                            id: deviceContent
                            width: parent.width
                            spacing: 0

                            RippleButton {
                                id: cardHeader
                                Layout.fillWidth: true
                                implicitHeight: 64
                                buttonRadius: 16
                                colBackground: {
                                    if (modelData.connected) return Functions.ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.92)
                                    if (expanded) return Appearance.colors.colLayer1Hover
                                    return "transparent"
                                }
                                
                                onClicked: {
                                    if (modelData.connected) {
                                        modelData.disconnect();
                                    } else {
                                        modelData.connect();
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 16

                                    MaterialSymbol {
                                        text: {
                                            const type = modelData.deviceType;
                                            if (type === "phone") return "smartphone";
                                            if (type === "computer") return "computer";
                                            if (type === "audio-card") return "headset";
                                            return "bluetooth";
                                        }
                                        iconSize: 24
                                        color: modelData.connected ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        StyledText {
                                            text: modelData.name || modelData.address
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: modelData.connected ? Font.Bold : Font.Normal
                                            color: Appearance.colors.colOnLayer1
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        StyledText {
                                            text: {
                                                if (modelData.connected) return "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "");
                                                if (modelData.state === BluetoothDeviceState.Connecting) return "Connecting...";
                                                if (modelData.pairing) return "Pairing...";
                                                if (modelData.paired || modelData.trusted) return "Paired";
                                                return "Available";
                                            }
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: {
                                                if (modelData.state === BluetoothDeviceState.Connecting || modelData.pairing) return Appearance.colors.colPrimary;
                                                return Appearance.colors.colSubtext;
                                            }
                                            Layout.fillWidth: true
                                        }
                                    }

                                    RippleButton {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        buttonRadius: 16
                                        colBackground: "transparent"
                                        onClicked: deviceItem.expanded = !deviceItem.expanded
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: deviceItem.expanded ? "expand_less" : "expand_more"
                                            iconSize: 20
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
                                    radius: 16
                                    // Make bottom square
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 16
                                        color: parent.color
                                    }
                                }
                            }

                            // ── Expanded Actions ──
                            Rectangle {
                                id: cardExpansion
                                Layout.fillWidth: true
                                Layout.preferredHeight: deviceItem.expanded ? expansionColumn.implicitHeight + 32 : 0
                                clip: true
                                color: Appearance.colors.colLayer2
                                radius: 16
                                opacity: deviceItem.expanded ? 1 : 0
                                visible: Layout.preferredHeight > 0
                                Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                
                                // Merge with header by making top square
                                Rectangle {
                                    width: parent.width
                                    height: 16
                                    color: parent.color
                                    visible: deviceItem.expanded
                                    anchors.top: parent.top
                                }

                                ColumnLayout {
                                    id: expansionColumn
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    anchors.top: parent.top
                                    anchors.topMargin: 16
                                    spacing: 12


                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 12
                                        
                                        // Left Side: Address (Always left when expanded)
                                        StyledText {
                                            text: "Address: " + modelData.address
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                            Layout.alignment: Qt.AlignVCenter
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Right Side: Action Buttons
                                        // Forget button (only if saved and NOT currently connected)
                                        RippleButton {
                                            visible: (modelData.paired || modelData.trusted) && !modelData.connected
                                            buttonText: "Forget"
                                            implicitWidth: 90
                                            implicitHeight: 36
                                            buttonRadius: 18
                                            colBackground: Appearance.m3colors.m3error
                                            colText: Appearance.m3colors.m3onError
                                            onClicked: {
                                                if (modelData.forget) modelData.forget()
                                                else if (modelData.unpair) modelData.unpair()
                                                modelData.trusted = false
                                                deviceItem.expanded = false
                                            }
                                        }

                                        RippleButton {
                                            visible: modelData.paired
                                            buttonText: modelData.connected ? "Disconnect" : "Connect"
                                            implicitWidth: 110
                                            implicitHeight: 36
                                            buttonRadius: 18
                                            colBackground: Appearance.colors.colPrimary
                                            colText: Appearance.colors.colOnPrimary
                                            onClicked: {
                                                if (modelData.connected) modelData.disconnect()
                                                else modelData.connect()
                                                deviceItem.expanded = false
                                            }
                                        }

                                        RippleButton {
                                            visible: !modelData.paired
                                            buttonText: "Connect"
                                            implicitWidth: 90
                                            implicitHeight: 36
                                            buttonRadius: 18
                                            colBackground: Appearance.colors.colPrimary
                                            colText: Appearance.colors.colOnPrimary
                                            onClicked: {
                                                modelData.pair()
                                                deviceItem.expanded = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: deviceList.moving || deviceList.flicking
                    }
                }
            }
        }

        // ── Offline State ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !BluetoothStatus.enabled
            spacing: 16
            
            Item { Layout.fillHeight: true }
            
            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "bluetooth_disabled"
                iconSize: 64
                color: Appearance.colors.colSubtext
            }
            
            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: "Bluetooth is turned off"
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
            }
            
            Item { Layout.fillHeight: true }
        }
    }

    // ── Pair New Device Sub-page ──
    Loader {
        anchors.fill: parent
        visible: stackLevel === 1
        sourceComponent: Component { BluetoothPairDialog {} }
        onVisibleChanged: {
            if (visible && BluetoothStatus.enabled) {
                BluetoothStatus.startDiscovery();
            }
        }
    }

}
