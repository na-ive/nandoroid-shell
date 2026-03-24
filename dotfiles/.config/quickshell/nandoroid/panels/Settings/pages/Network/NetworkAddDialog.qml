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
        width: Math.min(500 * Appearance.effectiveScale, root.width * 0.9)
        implicitHeight: addCol.implicitHeight + 48 * Appearance.effectiveScale
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
                offset: Qt.vector2d(0, 8 * Appearance.effectiveScale)
                blur: 20 * Appearance.effectiveScale
                color: Qt.rgba(0, 0, 0, 0.3)
            }
        }

        contentItem: ColumnLayout {
            id: addCol
            anchors.fill: parent
            anchors.margins: 24 * Appearance.effectiveScale
            spacing: 20 * Appearance.effectiveScale

            // Header Section
            ColumnLayout {
                spacing: 20 * Appearance.effectiveScale
                Layout.fillWidth: true
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "network_wifi"
                    iconSize: 32 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                
                ColumnLayout {
                    spacing: 4 * Appearance.effectiveScale
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
                spacing: 20 * Appearance.effectiveScale
                Layout.fillWidth: true

                // SSID Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 * Appearance.effectiveScale
                    radius: 8 * Appearance.effectiveScale
                    color: "transparent"
                    border.width: ssidInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : Math.max(1, 1 * Appearance.effectiveScale)
                    border.color: ssidInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                    // Floating Label
                    Rectangle {
                        x: 12 * Appearance.effectiveScale
                        y: -8 * Appearance.effectiveScale
                        width: ssidLabel.width + 8 * Appearance.effectiveScale
                        height: 16 * Appearance.effectiveScale
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
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
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
                    Layout.preferredHeight: 52 * Appearance.effectiveScale
                    radius: 8 * Appearance.effectiveScale
                    color: "transparent"
                    border.width: hiddenPassInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : Math.max(1, 1 * Appearance.effectiveScale)
                    border.color: hiddenPassInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                    // Floating Label
                    Rectangle {
                        x: 12 * Appearance.effectiveScale
                        y: -8 * Appearance.effectiveScale
                        width: passLabel.width + 8 * Appearance.effectiveScale
                        height: 16 * Appearance.effectiveScale
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
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        
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
                            implicitWidth: 32 * Appearance.effectiveScale
                            implicitHeight: 32 * Appearance.effectiveScale
                            buttonRadius: 16 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: addNetworkDialog.showPassword = !addNetworkDialog.showPassword
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: addNetworkDialog.showPassword ? "visibility_off" : "visibility"
                                iconSize: 20 * Appearance.effectiveScale
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
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                cursorShape: Qt.PointingHandCursor
                onClicked: addNetworkDialog.isHidden = !addNetworkDialog.isHidden
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8 * Appearance.effectiveScale
                    
                    RippleButton {
                        implicitWidth: 32 * Appearance.effectiveScale
                        implicitHeight: 32 * Appearance.effectiveScale
                        buttonRadius: 8 * Appearance.effectiveScale
                        colBackground: "transparent"
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: addNetworkDialog.isHidden ? "check_box" : "check_box_outline_blank"
                            iconSize: 20 * Appearance.effectiveScale
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
                Layout.topMargin: 12 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale
                
                Item { Layout.fillWidth: true }
                
                RippleButton {
                    buttonText: "Cancel"
                    implicitWidth: 100 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: Appearance.rounding.button
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: addNetworkDialog.close()
                }
                
                RippleButton {
                    buttonText: "Connect"
                    implicitWidth: 100 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
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

