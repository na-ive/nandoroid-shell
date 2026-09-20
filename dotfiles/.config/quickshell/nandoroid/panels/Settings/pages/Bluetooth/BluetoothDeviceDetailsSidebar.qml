import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

/**
 * Android-style "Device details" right sidebar for Bluetooth.
 * Mirrors NetworkDetailsSidebar sizing/animation, with per-profile
 * toggles (calls/media/contacts) when the BlueZ backend reports them.
 */
Rectangle {
    id: detailsIsland

    property var device: null

    signal closed()

    // Width snaps in a single frame instead of animating: an animated width
    // re-solves the whole RowLayout AND the active page's layout tree on every
    // frame, which stutters. Motion comes from the opacity fade + content
    // slide below; on close the collapse is delayed so the fade finishes first.
    readonly property bool open: device !== null
    property bool collapsed: true
    onOpenChanged: {
        if (open) {
            closeDelay.stop();
            collapsed = false;
        } else {
            closeDelay.restart();
        }
    }
    Component.onCompleted: collapsed = !open

    Timer {
        id: closeDelay
        interval: 180
        onTriggered: detailsIsland.collapsed = true
    }

    Layout.fillHeight: true
    Layout.preferredWidth: collapsed ? 0 : 320 * Appearance.effectiveScale
    // Stay visible until the collapse delay elapses, otherwise exit pops.
    visible: Layout.preferredWidth > 0
    color: Appearance.colors.colLayer1
    radius: 28 * Appearance.effectiveScale
    clip: true

    opacity: open ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }

    // ── Device-derived state ──
    // Rename via Quickshell's alias write; an empty string falls back to the
    // name provided by the device itself.
    property bool renaming: false
    property string renameText: ""
    function startRename() {
        if (!device) return;
        renameText = device.name || device.deviceName || "";
        renaming = true;
    }
    function commitRename() {
        if (device) device.name = renameText.trim();
        renaming = false;
    }
    function cancelRename() {
        renaming = false;
    }

    // Probed profile UUIDs (may stay empty if bluetoothctl has no record).
    readonly property var uuids: BluetoothStatus.deviceUuids[device ? device.address : ""] || []
    readonly property string a2dpUuid: BluetoothStatus.a2dpUuidFor(uuids)
    readonly property string hfpUuid: BluetoothStatus.hfpUuidFor(uuids)
    readonly property bool pbapSupported: BluetoothStatus.hasPhonebook(uuids)

    onDeviceChanged: {
        renaming = false;
        BluetoothStatus.fetchDeviceUuids(device);
    }

    Connections {
        target: detailsIsland.device
        // Re-probe after pairing/first connect: bluetoothctl only learns the
        // UUID list once the device record exists or is updated.
        function onConnectedChanged() {
            if (detailsIsland.device) BluetoothStatus.fetchDeviceUuids(detailsIsland.device);
        }
    }

    function statusText() {
        if (!device) return "";
        if (device.connected) return I18nService.tr("Connected") + (device.batteryAvailable ? " · " + Math.round(device.battery * 100) + "%" : "");
        if (device.state === BluetoothDeviceState.Connecting) return I18nService.tr("Connecting...");
        if (device.pairing) return I18nService.tr("Pairing...");
        if (device.paired || device.trusted) return I18nService.tr("Paired");
        return I18nService.tr("Available");
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale
        spacing: 0
        // Track the collapsed flag (not device) so content keeps rendering
        // while the close fade plays.
        visible: !detailsIsland.collapsed

        transform: Translate {
            // Right-docked island: content enters from (and exits toward) the
            // right edge, clipped inside the island.
            x: detailsIsland.open ? 0 : 24 * Appearance.effectiveScale
            Behavior on x {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            RippleButton {
                implicitWidth: 32 * Appearance.effectiveScale
                implicitHeight: 32 * Appearance.effectiveScale
                buttonRadius: 16 * Appearance.effectiveScale
                colBackground: "transparent"
                onClicked: detailsIsland.closed()
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "arrow_back"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colSubtext
                }
            }

            StyledText {
                text: I18nService.tr("Device details")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8 * Appearance.effectiveScale
            contentHeight: detailsCol.implicitHeight
            clip: true
            interactive: true

            ColumnLayout {
                id: detailsCol
                width: parent.width
                spacing: 0

                // ── Device header: icon in a category-tinted circle ──
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12 * Appearance.effectiveScale
                    implicitWidth: 88 * Appearance.effectiveScale
                    implicitHeight: 88 * Appearance.effectiveScale
                    radius: width / 2
                    color: BluetoothStatus.deviceTypeColors(detailsIsland.device).container

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: BluetoothStatus.deviceTypeIcon(detailsIsland.device)
                        iconSize: 44 * Appearance.effectiveScale
                        color: BluetoothStatus.deviceTypeColors(detailsIsland.device).on
                    }
                }

                // ── Name (+ inline rename) ──
                // Centered as a group: the label hugs its content so the
                // pencil sits right next to the name, not pushed to the edge.
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8 * Appearance.effectiveScale
                    spacing: 4 * Appearance.effectiveScale
                    visible: !detailsIsland.renaming

                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.maximumWidth: detailsCol.width - (36 * Appearance.effectiveScale)
                        horizontalAlignment: Text.AlignHCenter
                        text: detailsIsland.device ? (detailsIsland.device.name || detailsIsland.device.deviceName || detailsIsland.device.address) : ""
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }

                    RippleButton {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 32 * Appearance.effectiveScale
                        implicitHeight: 32 * Appearance.effectiveScale
                        buttonRadius: 16 * Appearance.effectiveScale
                        colBackground: "transparent"
                        onClicked: detailsIsland.startRename()
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "edit"
                            iconSize: 18 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                // Rename editor (alias; empty resets to the device-provided name)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * Appearance.effectiveScale
                    spacing: 8 * Appearance.effectiveScale
                    visible: detailsIsland.renaming

                    StyledTextInput {
                        id: renameInput
                        Layout.fillWidth: true
                        implicitHeight: 40 * Appearance.effectiveScale
                        inputRadius: 12 * Appearance.effectiveScale
                        leftMargin: 12
                        rightMargin: 12
                        font.pixelSize: Appearance.font.pixelSize.normal
                        placeholder: detailsIsland.device ? (detailsIsland.device.deviceName || detailsIsland.device.address) : ""
                        text: detailsIsland.renameText
                        onTextChanged: detailsIsland.renameText = text
                        onAccepted: detailsIsland.commitRename()
                        Keys.onEscapePressed: detailsIsland.cancelRename()

                        onVisibleChanged: {
                            if (visible) forceActiveFocus()
                        }
                    }

                    RippleButton {
                        implicitWidth: 32 * Appearance.effectiveScale
                        implicitHeight: 32 * Appearance.effectiveScale
                        buttonRadius: 16 * Appearance.effectiveScale
                        colBackground: "transparent"
                        onClicked: detailsIsland.commitRename()
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "check"
                            iconSize: 18 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }

                    RippleButton {
                        implicitWidth: 32 * Appearance.effectiveScale
                        implicitHeight: 32 * Appearance.effectiveScale
                        buttonRadius: 16 * Appearance.effectiveScale
                        colBackground: "transparent"
                        onClicked: detailsIsland.cancelRename()
                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "close"
                            iconSize: 18 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 4 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignHCenter
                    text: detailsIsland.statusText()
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                // ── Actions: Forget / Connect-Disconnect ──
                // M3 40-size button: 16 horizontal padding
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 16 * Appearance.effectiveScale
                    Layout.leftMargin: 8 * Appearance.effectiveScale
                    Layout.rightMargin: 8 * Appearance.effectiveScale
                    spacing: 8 * Appearance.effectiveScale

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale
                        RippleButton {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 52 * Appearance.effectiveScale
                            implicitHeight: 40 * Appearance.effectiveScale
                            buttonRadius: 20 * Appearance.effectiveScale
                            colBackground: Appearance.m3colors.m3primaryContainer
                            enabled: detailsIsland.device && (detailsIsland.device.paired || detailsIsland.device.trusted)
                            opacity: enabled ? 1 : 0.5
                            onClicked: {
                                if (!detailsIsland.device) return;
                                if (detailsIsland.device.forget) detailsIsland.device.forget();
                                detailsIsland.device.trusted = false;
                                detailsIsland.closed();
                            }
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: "delete"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: I18nService.tr("Forget")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale
                        RippleButton {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 52 * Appearance.effectiveScale
                            implicitHeight: 40 * Appearance.effectiveScale
                            buttonRadius: 20 * Appearance.effectiveScale
                            colBackground: Appearance.m3colors.m3primaryContainer
                            enabled: detailsIsland.device && !detailsIsland.device.pairing
                            opacity: enabled ? 1 : 0.5
                            onClicked: {
                                if (!detailsIsland.device) return;
                                if (detailsIsland.device.connected) detailsIsland.device.disconnect();
                                else BluetoothStatus.pairAndTrust(detailsIsland.device);
                            }
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: detailsIsland.device && detailsIsland.device.connected ? "close" : "bluetooth"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: detailsIsland.device && detailsIsland.device.connected ? I18nService.tr("Disconnect") : I18nService.tr("Connect")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                // ── Per-profile toggles (only when BlueZ reports the UUIDs) ──
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    // Phone calls (HFP/HSP)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: detailsIsland.device && detailsIsland.device.connected && detailsIsland.hfpUuid !== ""
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "call"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Phone calls"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        }
                        AndroidToggle {
                            checked: detailsIsland.device ? BluetoothStatus.profileEnabled(detailsIsland.device.address, "hfp") : true
                            onToggled: {
                                if (!detailsIsland.device) return;
                                BluetoothStatus.setProfileEnabled(detailsIsland.device.address, "hfp", !checked);
                                if (checked) BluetoothStatus.disconnectProfile(detailsIsland.device, detailsIsland.hfpUuid);
                                else BluetoothStatus.connectProfile(detailsIsland.device, detailsIsland.hfpUuid);
                            }
                        }
                    }

                    // Media audio (A2DP)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: detailsIsland.device && detailsIsland.device.connected && detailsIsland.a2dpUuid !== ""
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "music_note"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Media audio"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                        }
                        AndroidToggle {
                            checked: detailsIsland.device ? BluetoothStatus.profileEnabled(detailsIsland.device.address, "a2dp") : true
                            onToggled: {
                                if (!detailsIsland.device) return;
                                BluetoothStatus.setProfileEnabled(detailsIsland.device.address, "a2dp", !checked);
                                if (checked) BluetoothStatus.disconnectProfile(detailsIsland.device, detailsIsland.a2dpUuid);
                                else BluetoothStatus.connectProfile(detailsIsland.device, detailsIsland.a2dpUuid);
                            }
                        }
                    }

                    // Contacts / call log access (PBAP)
                    RowLayout {
                        Layout.fillWidth: true
                        visible: detailsIsland.device && detailsIsland.device.connected && detailsIsland.pbapSupported
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "contacts"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Contacts and call log access"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            StyledText { text: I18nService.tr("Used, for example, for call notifications"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                        AndroidToggle {
                            checked: detailsIsland.device ? BluetoothStatus.profileEnabled(detailsIsland.device.address, "pbap") : true
                            onToggled: {
                                if (!detailsIsland.device) return;
                                BluetoothStatus.setProfileEnabled(detailsIsland.device.address, "pbap", !checked);
                                if (checked) BluetoothStatus.disconnectProfile(detailsIsland.device, BluetoothStatus.phonebookUuid);
                                else BluetoothStatus.connectProfile(detailsIsland.device, BluetoothStatus.phonebookUuid);
                            }
                        }
                    }

                    // Battery
                    RowLayout {
                        Layout.fillWidth: true
                        visible: detailsIsland.device && detailsIsland.device.batteryAvailable
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "battery_full"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Battery"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.device ? Math.round(detailsIsland.device.battery * 100) + "%" : ""
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                            }
                        }
                    }

                    // Address
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "bluetooth_connected"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Address"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.device ? detailsIsland.device.address : ""
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                                Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }
                }
            }
        }
    }
}
