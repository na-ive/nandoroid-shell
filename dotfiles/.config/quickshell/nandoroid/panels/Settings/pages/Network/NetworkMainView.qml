import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

                // Android behavior: saved/open -> connect, connected -> details, secured -> password dialog
                ColumnLayout {
                    id: mainViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "main"
                    spacing: 24 * Appearance.effectiveScale

                    // ── Available Networks Header ──
                    StyledText {
                        visible: Network.wifiEnabled && Network.friendlyWifiNetworks.length > 0
                        text: I18nService.tr("Available Networks")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    // ── Available Networks List ──
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
                                width: wifiList.width
                                height: 64 * Appearance.effectiveScale

                                RippleButton {
                                    anchors.fill: parent
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    colBackground: {
                                        if (modelData.active) return Functions.ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.85);
                                        if (GlobalStates.networkDetailsTarget === modelData) return Appearance.colors.colLayer2;
                                        return "transparent";
                                    }
                                    colBackgroundHover: {
                                        if (modelData.active) return colBackground;
                                        return Appearance.colors.colLayer1Hover;
                                    }

                                    onClicked: {
                                        if (modelData.active) {
                                            root.openDetails(modelData);
                                        } else if (modelData.isSaved) {
                                            Network.connectToWifiNetwork(modelData);
                                        } else if (!modelData.isSecure) {
                                            Network.connectToWifiNetwork(modelData);
                                        } else {
                                            root.openPassword(modelData);
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16 * Appearance.effectiveScale
                                        anchors.rightMargin: 16 * Appearance.effectiveScale
                                        spacing: 16 * Appearance.effectiveScale

                                        NetworkIcon {
                                            strength: modelData.strength
                                            iconSize: 24 * Appearance.effectiveScale
                                            color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            StyledText {
                                                text: modelData.ssid
                                                font.pixelSize: Appearance.font.pixelSize.normal
                                                font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                                color: Appearance.colors.colOnLayer1
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            StyledText {
                                                text: {
                                                    if (modelData.active) return I18nService.tr("Connected");
                                                    if (modelData.isSaved) return I18nService.tr("Saved");
                                                    if (modelData.isSecure) return I18nService.tr("Secured");
                                                    return I18nService.tr("Open");
                                                }
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                color: Appearance.colors.colSubtext
                                                Layout.fillWidth: true
                                            }
                                        }

                                        MaterialSymbol {
                                            visible: modelData.isSecure && !modelData.active
                                            text: "lock"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: Appearance.colors.colSubtext
                                        }

                                        MaterialSymbol {
                                            visible: modelData.priority > 0
                                            text: "push_pin"
                                            iconSize: 18 * Appearance.effectiveScale
                                            color: Appearance.colors.colPrimary
                                            fill: 1
                                        }

                                        // Connected row: pin (if any) + settings gear, no checkmark
                                        MaterialSymbol {
                                            visible: modelData.active
                                            text: "settings"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: Appearance.colors.colSubtext
                                        }

                                        MaterialSymbol {
                                            visible: !modelData.active && modelData.isSaved
                                            text: "chevron_right"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: Appearance.colors.colSubtext
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
                            text: I18nService.tr("WiFi is turned off")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.family: Appearance.font.family.title
                            color: Appearance.colors.colSubtext
                        }

                        Item { Layout.fillHeight: true }
                    }
                } // End mainViewCol
