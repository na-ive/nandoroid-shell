import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

                ColumnLayout {
                    id: savedViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "saved"
                    spacing: 24

                    StyledText {
                        text: "You have " + Network.savedConnections.length + " saved networks"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    // ── Saved Networks Accordion List ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: savedRepeaterCol.implicitHeight + 32
                        radius: 20
                        color: Appearance.colors.colLayer1
                        
                        ColumnLayout {
                            id: savedRepeaterCol
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Repeater {
                                model: Network.savedConnections
                                delegate: ColumnLayout {
                                    id: savedItem
                                    Layout.fillWidth: true
                                    spacing: 0
                                    property bool expanded: false

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 64
                                        buttonRadius: 16
                                        colBackground: savedItem.expanded ? Appearance.colors.colLayer1Hover : "transparent"
                                        onClicked: savedItem.expanded = !savedItem.expanded

                                        // Header rounding overlay for expansion joint
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: savedItem.expanded
                                            color: parent.colBackground
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

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            MaterialSymbol {
                                                text: "wifi"
                                                iconSize: 24
                                                color: Appearance.colors.colSubtext
                                            }

                                            StyledText {
                                                text: modelData
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                color: Appearance.colors.colOnLayer1
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            MaterialSymbol {
                                                text: "keyboard_arrow_down"
                                                iconSize: 20
                                                color: Appearance.colors.colSubtext
                                                rotation: savedItem.expanded ? 180 : 0
                                                Behavior on rotation { NumberAnimation { duration: 200 } }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: savedItem.expanded ? (savedActionCol.implicitHeight + 24) : 0
                                        visible: Layout.preferredHeight > 0
                                        clip: true
                                        color: Appearance.colors.colLayer2
                                        radius: 16
                                        
                                        // Merge with header by making top square
                                        Rectangle {
                                            width: parent.width
                                            height: 16
                                            color: parent.color
                                            visible: savedItem.expanded
                                            anchors.top: parent.top
                                        }

                                        ColumnLayout {
                                            id: savedActionCol
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 16

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12

                                                StyledText {
                                                    id: savedPassLabel
                                                    visible: text.length > 0
                                                    text: ""
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colPrimary
                                                    font.weight: Font.Bold
                                                    Layout.alignment: Qt.AlignVCenter
                                                }

                                                Item { Layout.fillWidth: true }

                                                RippleButton {
                                                    buttonText: "Forget"
                                                    implicitWidth: 90
                                                    implicitHeight: 36
                                                    buttonRadius: 18
                                                    colBackground: Appearance.m3colors.m3error
                                                    colText: Appearance.m3colors.m3onError
                                                    onClicked: Network.forgetNetwork(modelData)
                                                }

                                                RippleButton {
                                                    buttonText: savedPassLabel.text.length > 0 ? "Hide" : "Share"
                                                    implicitWidth: 100
                                                    implicitHeight: 36
                                                    buttonRadius: 18
                                                    colBackground: Appearance.colors.colPrimary
                                                    colText: Appearance.colors.colOnPrimary
                                                    onClicked: {
                                                        if (savedPassLabel.text.length > 0) {
                                                            savedPassLabel.text = "";
                                                        } else {
                                                            Network.getSavedPassword(modelData);
                                                        }
                                                    }
                                                }
                                            }

                                            Connections {
                                                target: Network
                                                function onPasswordRecovered(password) {
                                                    if (savedItem.expanded) {
                                                        savedPassLabel.text = "Password: " + password;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } // End savedViewCol

