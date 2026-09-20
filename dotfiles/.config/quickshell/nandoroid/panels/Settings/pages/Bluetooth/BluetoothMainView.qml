import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    id: mainViewCol
    Layout.fillWidth: true
    visible: root.currentView === "main"
    spacing: 24 * Appearance.effectiveScale

    readonly property var savedDevices: [...BluetoothStatus.connectedDevices, ...BluetoothStatus.pairedButNotConnectedDevices]

    // ── 1. Enable Bluetooth Card ──
    SegmentedWrapper {
        id: enableCard
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, enableRow.implicitHeight)
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
            onClicked: BluetoothStatus.toggle()
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
                text: I18nService.tr("Enable Bluetooth")
                Layout.fillWidth: true
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.normal
            }

            AndroidToggle {
                checked: BluetoothStatus.enabled
                onToggled: BluetoothStatus.toggle()
            }
        }
    }

    // ── 2. Saved Devices + Pair New Device ──
    // Rows open the window-level "Device details" sidebar (GlobalStates).
    ColumnLayout {
        Layout.fillWidth: true
        visible: BluetoothStatus.enabled
        spacing: 8 * Appearance.effectiveScale

        StyledText {
            text: I18nService.tr("Saved devices")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
            visible: mainViewCol.savedDevices.length > 0
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2 * Appearance.effectiveScale

            Repeater {
                model: mainViewCol.savedDevices
                delegate: SegmentedWrapper {
                    id: deviceSeg
                    Layout.fillWidth: true
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RippleButton {
                        anchors.fill: parent
                        topLeftRadius: deviceSeg.rTopLeft
                        topRightRadius: deviceSeg.rTopRight
                        bottomLeftRadius: deviceSeg.rBottomLeft
                        bottomRightRadius: deviceSeg.rBottomRight
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: root.openDetails(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale

                            Rectangle {
                                implicitWidth: 40 * Appearance.effectiveScale
                                implicitHeight: 40 * Appearance.effectiveScale
                                radius: width / 2
                                color: BluetoothStatus.deviceTypeColors(modelData).container

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: BluetoothStatus.deviceTypeIcon(modelData)
                                    iconSize: 22 * Appearance.effectiveScale
                                    color: BluetoothStatus.deviceTypeColors(modelData).on
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    text: modelData.name || modelData.address
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: modelData.connected ? Font.DemiBold : Font.Normal
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: {
                                        if (modelData.connected) return I18nService.tr("Connected") + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "");
                                        if (modelData.state === BluetoothDeviceState.Connecting) return I18nService.tr("Connecting...");
                                        if (modelData.pairing) return I18nService.tr("Pairing...");
                                        if (modelData.paired || modelData.trusted) return I18nService.tr("Paired");
                                        return I18nService.tr("Available");
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: {
                                        if (modelData.state === BluetoothDeviceState.Connecting || modelData.pairing) return Appearance.colors.colPrimary;
                                        return Appearance.colors.colSubtext;
                                    }
                                    Layout.fillWidth: true
                                }
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

            // Pair new device row (becomes a standalone pill when the list is empty)
            SegmentedWrapper {
                id: pairRow
                Layout.fillWidth: true
                orientation: Qt.Vertical
                forcePill: mainViewCol.savedDevices.length === 0
                forceFirst: mainViewCol.savedDevices.length === 0
                maxRadius: mainViewCol.savedDevices.length === 0 ? 32 * Appearance.effectiveScale : undefined
                forceLast: true
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    topLeftRadius: pairRow.rTopLeft
                    topRightRadius: pairRow.rTopRight
                    bottomLeftRadius: pairRow.rBottomLeft
                    bottomRightRadius: pairRow.rBottomRight
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    onClicked: root.openPairView()

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
                            text: I18nService.tr("Pair new device")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
