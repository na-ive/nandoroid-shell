import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

                ColumnLayout {
                    id: wiredViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "wired"
                    spacing: 24

                    StyledText {
                        text: "Ethernet Connections"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: Network.wiredConnections
                            delegate: ColumnLayout {
                                id: wiredItem
                                Layout.fillWidth: true
                                spacing: 0
                                property bool expanded: false

                                onExpandedChanged: if (expanded) Network.fetchWiredDetails(modelData.uuid)

                                RippleButton {
                                    Layout.fillWidth: true
                                    implicitHeight: 64
                                    buttonRadius: 16
                                    colBackground: modelData.active ? Functions.ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.85) : Appearance.colors.colLayer1
                                    onClicked: wiredItem.expanded = !wiredItem.expanded

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 16

                                        MaterialSymbol {
                                            text: "lan"
                                            iconSize: 24
                                            color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        }

                                        ColumnLayout {
                                            spacing: 0
                                            StyledText {
                                                text: modelData.name
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                font.weight: modelData.active ? Font.Bold : Font.Normal
                                                color: Appearance.colors.colOnLayer1
                                            }
                                            StyledText {
                                                text: modelData.active ? "Connected" : "Disconnected"
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: Appearance.colors.colSubtext
                                            }
                                        }

                                        Item { Layout.fillWidth: true }

                                        MaterialSymbol {
                                            text: "keyboard_arrow_down"
                                            iconSize: 20
                                            color: Appearance.colors.colSubtext
                                            rotation: wiredItem.expanded ? 180 : 0
                                            Behavior on rotation { NumberAnimation { duration: 200 } }
                                        }
                                    }
                                }

                                // Expanded details
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: wiredItem.expanded ? (detailsCol.implicitHeight + 32) : 0
                                    visible: Layout.preferredHeight > 0
                                    clip: true
                                    color: Appearance.colors.colLayer2
                                    radius: 16
                                    
                                    // Merge with header by making top square
                                    Rectangle {
                                        width: parent.width
                                        height: 16
                                        color: parent.color
                                        visible: wiredItem.expanded
                                        anchors.top: parent.top
                                        z: 0
                                    }

                                    ColumnLayout {
                                        id: detailsCol
                                        anchors.fill: parent
                                        anchors.margins: 16
                                        spacing: 12

                                        Repeater {
                                            model: [
                                                { label: "IP Address", key: "ip4.address[1]" },
                                                { label: "Gateway", key: "ip4.gateway" },
                                                { label: "DNS", key: "ip4.dns[1]" },
                                                { label: "MAC Address", key: "general.hwaddr" }
                                            ]
                                            delegate: RowLayout {
                                                Layout.fillWidth: true
                                                StyledText {
                                                    text: modelData.label
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colSubtext
                                                    Layout.preferredWidth: 100
                                                }
                                                StyledText {
                                                    text: Network.wiredDetails[modelData.key] || "Not available"
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colOnLayer1
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WrapAnywhere
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            Layout.topMargin: 4
                                            Item { Layout.fillWidth: true }
                                            RippleButton {
                                                buttonText: modelData.active ? "Disconnect" : "Connect"
                                                implicitWidth: 110
                                                implicitHeight: 32
                                                buttonRadius: 16
                                                colBackground: modelData.active ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
                                                colText: modelData.active ? Appearance.m3colors.m3onError : Appearance.colors.colOnPrimary
                                                onClicked: Network.toggleWiredConnection(modelData.uuid, modelData.active)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // No devices state
                    ColumnLayout {
                        visible: Network.wiredConnections.length === 0
                        Layout.fillWidth: true
                        spacing: 16
                        Item { Layout.preferredHeight: 40 }
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "lan_off"
                            iconSize: 64
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No wired interfaces found"
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colSubtext
                        }
                    }
                } // End wiredViewCol

