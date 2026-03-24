import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

                // ── Main View: WiFi Scanning & Management ──
                ColumnLayout {
                    id: mainViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "main"
                    spacing: 24 * Appearance.effectiveScale

                    // ── Available Networks Header ──
                    StyledText {
                        visible: Network.wifiEnabled && Network.friendlyWifiNetworks.length > 0
                        text: "Available Networks"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    // ── Active WiFi List ──
                    Rectangle {
                        id: activeAreaRect
                        Layout.fillWidth: true
                        Layout.preferredHeight: wifiList.contentHeight + 24 * Appearance.effectiveScale
                        visible: Network.wifiEnabled && Network.friendlyWifiNetworks.length > 0
                        radius: 16 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1
                        clip: true

                        ListView {
                            id: wifiList
                            anchors.fill: parent
                            anchors.margins: 12 * Appearance.effectiveScale
                            clip: true
                            spacing: 8 * Appearance.effectiveScale
                            model: Network.friendlyWifiNetworks
                            interactive: false 

                            delegate: Item {
                                id: networkItem
                                width: wifiList.width - 24 * Appearance.effectiveScale
                                height: networkCol.implicitHeight
                                
                                property bool expanded: modelData.askingPassword
                                property bool autoconnect: true 
                                property bool showPassword: false

                                ColumnLayout {
                                    id: networkCol
                                    width: parent.width
                                    spacing: 0

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 64 * Appearance.effectiveScale
                                        buttonRadius: 16 * Appearance.effectiveScale
                                        colBackground: {
                                            if (modelData.active) return Functions.ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.85);
                                            if (expanded) return Appearance.colors.colLayer2;
                                            return "transparent";
                                        }
                                        colBackgroundHover: {
                                            if (modelData.active) return colBackground;
                                            if (expanded) return colBackground;
                                            return Appearance.colors.colLayer1Hover;
                                        }
                                            
                                        // Header rounding overlay for expansion joint
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: expanded
                                            color: parent.colBackground
                                            z: -1
                                            radius: 16 * Appearance.effectiveScale
                                            
                                            // Make bottom square
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: 16 * Appearance.effectiveScale
                                                color: parent.color
                                            }
                                        }
                                        
                                        onClicked: {
                                            if (modelData.active) {
                                                Network.disconnectWifiNetwork();
                                            } else if (modelData.isSaved) {
                                                Network.connectToWifiNetwork(modelData);
                                            } else {
                                                modelData.askingPassword = !modelData.askingPassword;
                                                if (modelData.askingPassword) {
                                                    passInput.forceActiveFocus();
                                                }
                                            }
                                        }


                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16 * Appearance.effectiveScale
                                            anchors.rightMargin: 16 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale

                                            MaterialSymbol {
                                                text: {
                                                    const s = modelData.strength
                                                    if (s > 80) return "signal_wifi_4_bar"
                                                    if (s > 60) return "network_wifi_3_bar"
                                                    if (s > 40) return "network_wifi_2_bar"
                                                    if (s > 20) return "network_wifi_1_bar"
                                                    return "signal_wifi_0_bar"
                                                }
                                                iconSize: 24 * Appearance.effectiveScale
                                                color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0
                                                StyledText {
                                                    text: modelData.ssid
                                                    font.pixelSize: Appearance.font.pixelSize.normal
                                                    font.weight: modelData.active ? Font.Bold : Font.Normal
                                                    color: Appearance.colors.colOnLayer1
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                StyledText {
                                                    text: modelData.active ? "Connected" : (modelData.isSecure ? "Secured" : "Open")
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colSubtext
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            RowLayout {
                                                spacing: 8 * Appearance.effectiveScale
                                                MaterialSymbol {
                                                    visible: modelData.active
                                                    text: "check"
                                                    iconSize: 24 * Appearance.effectiveScale
                                                    color: Appearance.colors.colPrimary
                                                }
                                                MaterialSymbol {
                                                    visible: modelData.isSecure && !modelData.active
                                                    text: "lock"
                                                    iconSize: 20 * Appearance.effectiveScale
                                                    color: Appearance.colors.colSubtext
                                                }

                                                MaterialSymbol {
                                                    visible: modelData.isSaved && modelData.priority > 0
                                                    text: "push_pin"
                                                    iconSize: 18 * Appearance.effectiveScale
                                                    color: Appearance.colors.colPrimary
                                                    fill: 1
                                                }

                                                RippleButton {
                                                    implicitWidth: 32 * Appearance.effectiveScale
                                                    implicitHeight: 32 * Appearance.effectiveScale
                                                    buttonRadius: 16 * Appearance.effectiveScale
                                                    colBackground: "transparent"
                                                    onClicked: networkItem.expanded = !networkItem.expanded
                                                    contentItem: MaterialSymbol {
                                                        anchors.centerIn: parent
                                                        text: "keyboard_arrow_down"
                                                        iconSize: 20 * Appearance.effectiveScale
                                                        color: Appearance.colors.colSubtext
                                                        rotation: networkItem.expanded ? 180 : 0
                                                        Behavior on rotation { NumberAnimation { duration: 200 } }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ── Expanded Area ──
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: networkItem.expanded ? (expansionCol.implicitHeight + 24 * Appearance.effectiveScale) : 0
                                        clip: true
                                        color: Appearance.colors.colLayer2
                                        radius: 16 * Appearance.effectiveScale
                                        opacity: networkItem.expanded ? 1 : 0
                                        visible: Layout.preferredHeight > 0
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                        
                                        // Merge with header by making top square
                                        Rectangle {
                                            width: parent.width
                                            height: 16 * Appearance.effectiveScale
                                            color: parent.color
                                            visible: networkItem.expanded
                                            anchors.top: parent.top
                                            z: 0
                                        }

                                        ColumnLayout {
                                            id: expansionCol
                                            anchors.fill: parent
                                            anchors.margins: 12 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale

                                            // ── Mode: UNSAVED (Password Entry) ──
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 8 * Appearance.effectiveScale
                                                visible: (!modelData.active && (!modelData.isSaved || modelData.askingPassword))

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                                                    radius: 12 * Appearance.effectiveScale
                                                    color: Appearance.colors.colLayer1
                                                    border.color: passInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                                                    border.width: Math.max(1, 1 * Appearance.effectiveScale)

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 12 * Appearance.effectiveScale
                                                        anchors.rightMargin: 8 * Appearance.effectiveScale
                                                        
                                                        TextInput {
                                                            id: passInput
                                                            Layout.fillWidth: true
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            echoMode: networkItem.showPassword ? TextInput.Normal : TextInput.Password
                                                            color: Appearance.colors.colOnLayer1
                                                            font.pixelSize: Appearance.font.pixelSize.normal
                                                            
                                                            Text {
                                                                anchors.fill: parent
                                                                visible: !passInput.text && !passInput.activeFocus
                                                                text: "Enter Password..."
                                                                color: Appearance.colors.colSubtext
                                                                verticalAlignment: Text.AlignVCenter
                                                                font: passInput.font
                                                            }
                                                        }

                                                        RippleButton {
                                                            implicitWidth: 32 * Appearance.effectiveScale
                                                            implicitHeight: 32 * Appearance.effectiveScale
                                                            buttonRadius: 16 * Appearance.effectiveScale
                                                            colBackground: "transparent"
                                                            onClicked: networkItem.showPassword = !networkItem.showPassword
                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: networkItem.showPassword ? "visibility_off" : "visibility"
                                                                iconSize: 20 * Appearance.effectiveScale
                                                                color: Appearance.colors.colSubtext
                                                            }
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    spacing: 8 * Appearance.effectiveScale
                                                    RippleButton {
                                                        implicitWidth: 32 * Appearance.effectiveScale
                                                        implicitHeight: 32 * Appearance.effectiveScale
                                                        buttonRadius: 8 * Appearance.effectiveScale
                                                        colBackground: "transparent"
                                                        onClicked: networkItem.autoconnect = !networkItem.autoconnect
                                                        contentItem: MaterialSymbol {
                                                            anchors.centerIn: parent
                                                            text: networkItem.autoconnect ? "check_box" : "check_box_outline_blank"
                                                            iconSize: 20 * Appearance.effectiveScale
                                                            color: networkItem.autoconnect ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                                        }
                                                    }
                                                    StyledText {
                                                        text: "Connect automatically"
                                                        font.pixelSize: Appearance.font.pixelSize.small
                                                        color: Appearance.colors.colSubtext
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12 * Appearance.effectiveScale
                                                    Item { Layout.fillWidth: true }
                                                    RippleButton {
                                                        buttonText: "Connect"
                                                        implicitWidth: 100 * Appearance.effectiveScale
                                                        implicitHeight: 36 * Appearance.effectiveScale
                                                        buttonRadius: 18 * Appearance.effectiveScale
                                                        colBackground: Appearance.colors.colPrimary
                                                        colText: Appearance.colors.colOnPrimary
                                                        enabled: passInput.text.length > 0
                                                        onClicked: {
                                                            Network.connectWithPassword(modelData.ssid, passInput.text, false, networkItem.autoconnect);
                                                            modelData.askingPassword = false;
                                                        }
                                                    }
                                                }
                                            }

                                            // ── Mode: SAVED (Management) ──
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 12 * Appearance.effectiveScale
                                                visible: (modelData.isSaved || modelData.active) && !modelData.askingPassword

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12 * Appearance.effectiveScale

                                                    StyledText {
                                                        text: `BSSID: ${modelData.bssid}`
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.colors.colSubtext
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    RippleButton {
                                                        buttonText: "Forget"
                                                        implicitWidth: 80 * Appearance.effectiveScale
                                                        implicitHeight: 36 * Appearance.effectiveScale
                                                        buttonRadius: 18 * Appearance.effectiveScale
                                                        colBackground: Appearance.m3colors.m3error
                                                        colText: Appearance.m3colors.m3onError
                                                        onClicked: Network.forgetNetwork(modelData.ssid)
                                                    }

                                                    RippleButton {
                                                        buttonText: "Edit"
                                                        implicitWidth: 70 * Appearance.effectiveScale
                                                        implicitHeight: 36 * Appearance.effectiveScale
                                                        buttonRadius: 18 * Appearance.effectiveScale
                                                        colBackground: Appearance.colors.colLayer1
                                                        onClicked: modelData.askingPassword = true
                                                    }

                                                    RippleButton {
                                                        buttonText: "Pin"
                                                        implicitWidth: 60 * Appearance.effectiveScale
                                                        implicitHeight: 36 * Appearance.effectiveScale
                                                        buttonRadius: 18 * Appearance.effectiveScale
                                                        colBackground: modelData.priority > 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                                        colText: modelData.priority > 0 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                                        onClicked: Network.setPriority(modelData.ssid, modelData.priority > 0 ? 0 : 100)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } // End activeAreaRect

                    // ── Offline State ──
                    ColumnLayout {
                        id: offlineContent
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300 * Appearance.effectiveScale
                        visible: !Network.wifiEnabled
                        spacing: 16 * Appearance.effectiveScale
                        
                        Item { Layout.fillHeight: true }
                        
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "wifi_off"
                            iconSize: 64 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "WiFi is turned off"
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colSubtext
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                } // End mainViewCol

