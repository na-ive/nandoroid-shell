import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    id: mainViewCol
    Layout.fillWidth: true
    visible: root.currentView === "main"
    spacing: 24 * Appearance.effectiveScale

    readonly property var otherNetworks: Network.friendlyWifiNetworks.filter(n => !n.active)

    // ── 1. Connected Network Card ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2 * Appearance.effectiveScale
        SegmentedWrapper {
            id: enableCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, enableRow.implicitHeight)
            visible: root.currentView === "main"
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: enableCard.rTopLeft
                topRightRadius: enableCard.rTopRight
                bottomLeftRadius: enableCard.rBottomLeft
                bottomRightRadius: enableCard.rBottomRight
                onClicked: Network.toggleWifi()
            }

            RowLayout {
                id: enableRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                StyledText {
                    text: I18nService.tr("Enable WiFi")
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.normal
                    }

                AndroidToggle {
                    checked: Network.wifiEnabled
                    onToggled: Network.toggleWifi()
                }
            }
        }

        SegmentedWrapper {
            id: connectedCard
            Layout.fillWidth: true
            visible: Network.wifiEnabled && Network.activeNetwork !== null
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                topLeftRadius: connectedCard.rTopLeft
                topRightRadius: connectedCard.rTopRight
                bottomLeftRadius: connectedCard.rBottomLeft
                bottomRightRadius: connectedCard.rBottomRight
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: root.openDetails(Network.activeNetwork)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    NetworkIcon {
                        strength: Network.activeNetwork ? Network.activeNetwork.strength : 0
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: Network.activeNetwork ? Network.activeNetwork.ssid : ""
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: I18nService.tr("Connected")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            Layout.fillWidth: true
                        }
                    }

                    MaterialSymbol {
                        visible: (Network.activeNetwork && Network.activeNetwork.priority > 0) || false
                        text: "push_pin"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                        fill: 1
                    }

                    MaterialSymbol {
                        text: "settings"
                        iconSize: 20 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }

    // ── 2. Other Networks + Add Network ──
    ColumnLayout {
        Layout.fillWidth: true
        visible: Network.wifiEnabled
        spacing: 8 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale

            StyledText {
                text: I18nService.tr("Available Networks")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            
            RippleButton {
                implicitWidth: 40 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer1
                onClicked: Network.wifiScanning ? Network.cancelRescanWifi() : Network.rescanWifi()

                contentItem: MaterialSymbol {
                    id: refreshIconNetwork
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Network.wifiScanning ? "close" : "refresh"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        Item {
            id: loadingNetwork
            Layout.fillWidth: true
            implicitHeight: 80 * Appearance.effectiveScale
            readonly property bool isLoading: Network.wifiEnabled && (Network.wifiScanning || mainViewCol.otherNetworks.length === 0)
            visible: isLoading

            MaterialLoadingIndicator {
                anchors.centerIn: parent
                implicitSize: 60 * Appearance.effectiveScale
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * Appearance.effectiveScale
            visible: !loadingNetwork.isLoading

            Repeater {
                model: mainViewCol.otherNetworks
                delegate: SegmentedWrapper {
                    id: netRow
                    Layout.fillWidth: true
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RippleButton {
                        anchors.fill: parent
                        topLeftRadius: netRow.rTopLeft
                        topRightRadius: netRow.rTopRight
                        bottomLeftRadius: netRow.rBottomLeft
                        bottomRightRadius: netRow.rBottomRight
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover

                        onClicked: {
                            if (modelData.isSaved) {
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
                                color: Appearance.colors.colSubtext
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    text: modelData.ssid
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: {
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
                                visible: modelData.isSecure
                                text: "lock"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }

                            MaterialSymbol {
                                visible: modelData.isSaved
                                text: "chevron_right"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }

            // Add network row
            SegmentedWrapper {
                id: addRow
                Layout.fillWidth: true
                orientation: Qt.Vertical
                forcePill: mainViewCol.otherNetworks.length === 0
                forceFirst: mainViewCol.otherNetworks.length === 0
                maxRadius: mainViewCol.otherNetworks.length === 0 ? 32 * Appearance.effectiveScale : undefined
                forceLast: true
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    topLeftRadius: addRow.rTopLeft
                    topRightRadius: addRow.rTopRight
                    bottomLeftRadius: addRow.rBottomLeft
                    bottomRightRadius: addRow.rBottomRight
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    onClicked: GlobalStates.addNetworkDialogOpen = true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "add"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }

                        StyledText {
                            text: I18nService.tr("Add network")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    // ── 3. Wired / Saved Networks Group ──
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8 * Appearance.effectiveScale
        spacing: 2 * Appearance.effectiveScale

        SegmentedWrapper {
            id: wiredRow
            Layout.fillWidth: true
            orientation: Qt.Vertical
            forceFirst: true
            forceLast: false
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                topLeftRadius: wiredRow.rTopLeft
                topRightRadius: wiredRow.rTopRight
                bottomLeftRadius: wiredRow.rBottomLeft
                bottomRightRadius: wiredRow.rBottomRight
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: root.currentView = "wired"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: "lan"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: I18nService.tr("Wired Network")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
            }
        }

        SegmentedWrapper {
            id: savedRow
            Layout.fillWidth: true
            orientation: Qt.Vertical
            forceFirst: false
            forceLast: true
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                topLeftRadius: savedRow.rTopLeft
                topRightRadius: savedRow.rTopRight
                bottomLeftRadius: savedRow.rBottomLeft
                bottomRightRadius: savedRow.rBottomRight
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: root.currentView = "saved"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: "history"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }

                    StyledText {
                        text: I18nService.tr("Saved Networks")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}