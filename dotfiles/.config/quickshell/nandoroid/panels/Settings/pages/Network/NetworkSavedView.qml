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
                    spacing: 24 * Appearance.effectiveScale

                    StyledText {
                        text: "You have " + Network.savedConnections.length + " saved networks"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    // ── Saved Networks Accordion List ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: savedRepeaterCol.implicitHeight + 32 * Appearance.effectiveScale
                        radius: 20 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1
                        
                        ColumnLayout {
                            id: savedRepeaterCol
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            Repeater {
                                model: Network.savedConnections
                                delegate: ColumnLayout {
                                    id: savedItem
                                    Layout.fillWidth: true
                                    spacing: 0
                                    property bool expanded: false

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 64 * Appearance.effectiveScale
                                        buttonRadius: 16 * Appearance.effectiveScale
                                        colBackground: savedItem.expanded ? Appearance.colors.colLayer1Hover : "transparent"
                                        onClicked: savedItem.expanded = !savedItem.expanded

                                        // Header rounding overlay for expansion joint
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: savedItem.expanded
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

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16 * Appearance.effectiveScale
                                            anchors.rightMargin: 16 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale

                                            MaterialSymbol {
                                                text: "wifi"
                                                iconSize: 24 * Appearance.effectiveScale
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
                                                iconSize: 20 * Appearance.effectiveScale
                                                color: Appearance.colors.colSubtext
                                                rotation: savedItem.expanded ? 180 : 0
                                                Behavior on rotation { NumberAnimation { duration: 200 } }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: savedItem.expanded ? (savedActionCol.implicitHeight + 24 * Appearance.effectiveScale) : 0
                                        visible: Layout.preferredHeight > 0
                                        clip: true
                                        color: Appearance.colors.colLayer2
                                        radius: 16 * Appearance.effectiveScale
                                        
                                        // Merge with header by making top square
                                        Rectangle {
                                            width: parent.width
                                            height: 16 * Appearance.effectiveScale
                                            color: parent.color
                                            visible: savedItem.expanded
                                            anchors.top: parent.top
                                        }

                                        ColumnLayout {
                                            id: savedActionCol
                                            anchors.fill: parent
                                            anchors.margins: 16 * Appearance.effectiveScale
                                            spacing: 16 * Appearance.effectiveScale

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12 * Appearance.effectiveScale

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
                                                    implicitWidth: 90 * Appearance.effectiveScale
                                                    implicitHeight: 36 * Appearance.effectiveScale
                                                    buttonRadius: 18 * Appearance.effectiveScale
                                                    colBackground: Appearance.m3colors.m3error
                                                    colText: Appearance.m3colors.m3onError
                                                    onClicked: Network.forgetNetwork(modelData)
                                                }

                                                RippleButton {
                                                    buttonText: savedPassLabel.text.length > 0 ? "Hide" : "Share"
                                                    implicitWidth: 100 * Appearance.effectiveScale
                                                    implicitHeight: 36 * Appearance.effectiveScale
                                                    buttonRadius: 18 * Appearance.effectiveScale
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

