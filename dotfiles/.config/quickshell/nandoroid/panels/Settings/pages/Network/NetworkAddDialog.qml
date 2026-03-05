import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

    Dialog {
        id: addNetworkDialog
        parent: root
        anchors.centerIn: parent
        width: Math.min(500, root.width * 0.9)
        implicitHeight: addCol.implicitHeight + 48
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property bool isHidden: false
        property bool showPassword: false

        onClosed: {
            ssidInput.text = "";
            hiddenPassInput.text = "";
            isHidden = false;
            showPassword = false;
        }

        background: Rectangle {
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.card
            border.width: 0
            
            // Shadow
            StyledRectangularShadow {
                target: parent
                z: -1
                offset: Qt.vector2d(0, 8)
                blur: 20
                color: Qt.rgba(0, 0, 0, 0.3)
            }
        }

        contentItem: ColumnLayout {
            id: addCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Header Section
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "network_wifi"
                    iconSize: 32
                    color: Appearance.colors.colPrimary
                }
                
                ColumnLayout {
                    spacing: 4
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Add Network"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Enter the details of the network you want to join."
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Inputs (Polkit Style)
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true

                // SSID Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: "transparent"
                    border.width: ssidInput.activeFocus ? 2 : 1
                    border.color: ssidInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                    // Floating Label
                    Rectangle {
                        x: 12
                        y: -8
                        width: ssidLabel.width + 8
                        height: 16
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        StyledText {
                            id: ssidLabel
                            anchors.centerIn: parent
                            text: "Network Name"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: ssidInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline
                        }
                    }

                    TextInput {
                        id: ssidInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.normal
                        
                        Text {
                            anchors.left: ssidInput.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !ssidInput.text && !ssidInput.activeFocus
                            text: "SSID"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }
                }

                // Password Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: "transparent"
                    border.width: hiddenPassInput.activeFocus ? 2 : 1
                    border.color: hiddenPassInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                    // Floating Label
                    Rectangle {
                        x: 12
                        y: -8
                        width: passLabel.width + 8
                        height: 16
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        StyledText {
                            id: passLabel
                            anchors.centerIn: parent
                            text: "Password"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: hiddenPassInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        
                        TextInput {
                            id: hiddenPassInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: addNetworkDialog.showPassword ? TextInput.Normal : TextInput.Password
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                            
                            Text {
                                anchors.left: hiddenPassInput.left
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !hiddenPassInput.text && !hiddenPassInput.activeFocus
                                text: "Optional"
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: 16
                            colBackground: "transparent"
                            onClicked: addNetworkDialog.showPassword = !addNetworkDialog.showPassword
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: addNetworkDialog.showPassword ? "visibility_off" : "visibility"
                                iconSize: 20
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }

            // Options (Interactive Hidden Toggle)
            MouseArea {
                id: hiddenToggleArea
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                cursorShape: Qt.PointingHandCursor
                onClicked: addNetworkDialog.isHidden = !addNetworkDialog.isHidden
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    RippleButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: 8
                        colBackground: "transparent"
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: addNetworkDialog.isHidden ? "check_box" : "check_box_outline_blank"
                            iconSize: 20
                            color: addNetworkDialog.isHidden ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                    }
                    
                    StyledText {
                        text: "Hidden network"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                    
                    Item { Layout.fillWidth: true }
                }
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 12
                
                Item { Layout.fillWidth: true }
                
                RippleButton {
                    buttonText: "Cancel"
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.button
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: addNetworkDialog.close()
                }
                
                RippleButton {
                    buttonText: "Connect"
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.button
                    colBackground: Appearance.colors.colPrimary
                    colText: Appearance.colors.colOnPrimary
                    enabled: ssidInput.text.length > 0
                    onClicked: {
                        Network.connectWithPassword(ssidInput.text, hiddenPassInput.text, addNetworkDialog.isHidden);
                        addNetworkDialog.close();
                    }
                }
            }
        }
    }

