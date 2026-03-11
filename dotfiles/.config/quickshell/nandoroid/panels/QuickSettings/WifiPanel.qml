import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Functional Wi-Fi network selection panel.
 * Shows real networks using nmcli scanning.
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
        anchors.margins: 14
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
                text: "Connect to Wi-Fi"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            // Refresh Button
            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Appearance.colors.colLayer2
                onClicked: Network.rescanWifi()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 18
                    color: Appearance.m3colors.m3onSurface
                    
                    RotationAnimation on rotation {
                        id: refreshAnim
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: Network.wifiScanning
                    }
                }
            }

            // WiFi Power Toggle
            RippleButton {
                implicitWidth: 56
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Network.wifiEnabled ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                colBackgroundHover: Network.wifiEnabled ? Qt.darker(Appearance.colors.colPrimary, 1.12) : Appearance.colors.colLayer2Hover
                onClicked: Network.toggleWifi()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Network.wifiEnabled ? "wifi" : "wifi_off"
                    iconSize: 18
                    color: Network.wifiEnabled ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        // Network list
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "transparent"
            clip: true

            ListView {
                id: wifiList
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                spacing: 2
                model: Network.friendlyWifiNetworks

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index
                    width: wifiList.width
                    height: delegateCol.implicitHeight

                    ColumnLayout {
                        id: delegateCol
                        anchors.fill: parent
                        spacing: 0

                        RippleButton {
                            id: networkItem
                            Layout.fillWidth: true
                            implicitHeight: 56
                            buttonRadius: 16
                            colBackground: {
                                if (delegateRoot.modelData.active) return Functions.ColorUtils.mix(Appearance.colors.colLayer0, Appearance.colors.colPrimary, 0.85);
                                if (delegateRoot.modelData.askingPassword) return Appearance.colors.colLayer2;
                                return "transparent";
                            }
                            colBackgroundHover: {
                                if (delegateRoot.modelData.active) return colBackground;
                                if (delegateRoot.modelData.askingPassword) return colBackground;
                                return Appearance.colors.colLayer0Hover;
                            }
                            onClicked: {
                                if (delegateRoot.modelData.active) {
                                    Network.disconnectWifiNetwork();
                                } else if (delegateRoot.modelData.isSaved) {
                                    Network.connectToWifiNetwork(delegateRoot.modelData);
                                } else {
                                    delegateRoot.modelData.askingPassword = !delegateRoot.modelData.askingPassword;
                                    if (delegateRoot.modelData.askingPassword && delegateRoot.modelData.isSecure) {
                                        passwordInput.forceActiveFocus();
                                    }
                                }
                            }

                            // Header rounding overlay for expansion joint
                            Rectangle {
                                anchors.fill: parent
                                visible: delegateRoot.modelData.askingPassword
                                color: parent.colBackground
                                z: -1
                                radius: 16
                                
                                // Make bottom square
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 12
                                    color: parent.color
                                }
                            }

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                MaterialSymbol {
                                    text: {
                                        const s = delegateRoot.modelData.strength
                                        if (s > 80) return "signal_wifi_4_bar"
                                        if (s > 60) return "network_wifi_3_bar"
                                        if (s > 40) return "network_wifi_2_bar"
                                        if (s > 20) return "network_wifi_1_bar"
                                        return "signal_wifi_0_bar"
                                    }
                                    iconSize: 22
                                    color: (delegateRoot.modelData.active || delegateRoot.modelData.askingPassword) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        text: delegateRoot.modelData.ssid
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer1
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    StyledText {
                                        text: delegateRoot.modelData.active ? "Connected" : (delegateRoot.modelData.isSaved ? "Saved" : (delegateRoot.modelData.isSecure ? "Secured" : "Open"))
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        Layout.fillWidth: true
                                    }
                                }

                                MaterialSymbol {
                                    visible: delegateRoot.modelData.active
                                    text: "check"
                                    iconSize: 20
                                    color: Appearance.colors.colPrimary
                                }

                                MaterialSymbol {
                                    visible: delegateRoot.modelData.isSecure && !delegateRoot.modelData.active
                                    text: "lock"
                                    iconSize: 18
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }

                        // Password entry / Connect area
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: delegateRoot.modelData.askingPassword ? 56 : 0

                            visible: Layout.preferredHeight > 0
                            clip: true
                            color: Appearance.colors.colLayer2
                            radius: 16
                            opacity: delegateRoot.modelData.askingPassword ? 1 : 0
                            Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            // Merge with header by making top square
                            Rectangle {
                                width: parent.width
                                height: 12
                                color: parent.color
                                visible: delegateRoot.modelData.askingPassword
                                anchors.top: parent.top
                                z: 0
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                anchors.topMargin: 8
                                anchors.bottomMargin: 8
                                spacing: 8


                                // Password Input Field
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    radius: 20
                                    visible: delegateRoot.modelData.isSecure
                                    color: Appearance.colors.colLayer1
                                    border.color: passwordInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 4
                                        spacing: 8

                                        TextInput {
                                            id: passwordInput
                                            Layout.fillWidth: true
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colOnLayer1
                                            echoMode: showPasswordBtn.revealed ? TextInput.Normal : TextInput.Password
                                            verticalAlignment: TextInput.AlignVCenter
                                            clip: true
                                            selectByMouse: true
                                            
                                            onAccepted: {
                                                Network.connectWithPassword(delegateRoot.modelData.ssid, text);
                                                delegateRoot.modelData.askingPassword = false;
                                            }

                                            Text {
                                                visible: passwordInput.text === "" && !passwordInput.activeFocus
                                                text: "Enter password..."
                                                font: passwordInput.font
                                                color: Appearance.colors.colSubtext
                                                anchors.fill: parent
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                        }

                                        RippleButton {
                                            id: showPasswordBtn
                                            property bool revealed: false
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            buttonRadius: 16
                                            colBackground: "transparent"
                                            onClicked: revealed = !revealed
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: showPasswordBtn.revealed ? "visibility" : "visibility_off"
                                                iconSize: 18
                                                color: showPasswordBtn.revealed ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                            }
                                        }
                                    }
                                }

                                // Connect Button
                                RippleButton {
                                    implicitWidth: 80
                                    implicitHeight: 40
                                    buttonRadius: 20
                                    colBackground: Appearance.colors.colPrimary
                                    colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.1)
                                    onClicked: {
                                        if (delegateRoot.modelData.isSecure) {
                                            Network.connectWithPassword(delegateRoot.modelData.ssid, passwordInput.text);
                                        } else {
                                            Network.connectToWifiNetwork(delegateRoot.modelData);
                                        }
                                        delegateRoot.modelData.askingPassword = false;
                                    }
                                    StyledText {
                                        anchors.centerIn: parent
                                        text: "Connect"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnPrimary
                                    }
                                }
                            }
                        }
                    }
                }


            }
        }

        // Footer
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RippleButton {
                implicitWidth: detailsText.implicitWidth + 24
                implicitHeight: 36
                buttonRadius: height / 2
                colBackground: Appearance.colors.colLayer1
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: {
                    GlobalStates.settingsPageIndex = 0;
                    GlobalStates.activateSettings();
                }
                StyledText {
                    id: detailsText
                    anchors.centerIn: parent
                    text: "Details"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onSurface
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: doneText.implicitWidth + 24
                implicitHeight: 36
                buttonRadius: height / 2
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.1)
                onClicked: root.dismiss()
                StyledText {
                    id: doneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
