import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth
import QtQuick.Shapes

ColumnLayout {
            spacing: 24 * Appearance.effectiveScale
            

            // Header
            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                RippleButton {
                    implicitWidth: 40 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: "transparent"
                    onClicked: {
                        BluetoothStatus.stopDiscovery();
                        root.stackLevel = 0;
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                }
                StyledText {
                    text: "Pair new device"
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                }
            }

            // Navigation handler for async pairing
            Connections {
                target: BluetoothStatus
                function onDeviceConnected(device) {
                    root.stackLevel = 0;
                }
            }

            // Local Info
            ColumnLayout {
                spacing: 4 * Appearance.effectiveScale
                StyledText {
                    text: "Device name"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: (Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.name : "") || "Unknown"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }

            // Available Devices Section
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12 * Appearance.effectiveScale
                StyledText {
                    text: "Available devices"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                // Solid Arc Spinner
                Item {
                    implicitWidth: 24 * Appearance.effectiveScale
                    implicitHeight: 24 * Appearance.effectiveScale
                    visible: BluetoothStatus.enabled

                    Shape {
                        anchors.fill: parent
                        layer.enabled: true
                        layer.samples: 4
                        
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Appearance.colors.colPrimary
                            strokeWidth: 3 * Appearance.effectiveScale
                            capStyle: ShapePath.RoundCap
                            
                            PathAngleArc {
                                centerX: 12 * Appearance.effectiveScale; centerY: 12 * Appearance.effectiveScale
                                radiusX: 9 * Appearance.effectiveScale; radiusY: 9 * Appearance.effectiveScale
                                startAngle: -90
                                sweepAngle: 270
                            }
                        }
                        
                        RotationAnimation on rotation {
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: true
                        }
                    }
                }
            }

            // Available Devices List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16 * Appearance.effectiveScale
                color: Appearance.colors.colLayer1
                clip: true

                ListView {
                    id: unpairedList
                    anchors.fill: parent
                    anchors.margins: 8 * Appearance.effectiveScale
                    clip: true
                    spacing: 4 * Appearance.effectiveScale
                    model: BluetoothStatus.unpairedDevices

                    delegate: RippleButton {
                        width: unpairedList.width
                        implicitHeight: 64 * Appearance.effectiveScale
                        buttonRadius: 16 * Appearance.effectiveScale
                        colBackground: "transparent"
                        onClicked: {
                            BluetoothStatus.pairAndTrust(modelData);
                            // root.stackLevel = 0; // Don't pop immediately
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: {
                                    const type = modelData.deviceType;
                                    if (type === "phone") return "smartphone";
                                    if (type === "computer") return "computer";
                                    if (type === "audio-card") return "headset";
                                    return "bluetooth";
                                }
                                iconSize: 24 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    text: modelData.name || "Unknown Device"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: {
                                        if (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || BluetoothStatus.pairingAddress === modelData.address) return "Pairing...";
                                        return modelData.address;
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: (modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || BluetoothStatus.pairingAddress === modelData.address) ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        active: unpairedList.moving || unpairedList.flicking
                    }
                    
                }
            }
        }
