import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Bluetooth

/**
 * Functional Bluetooth Settings page.
 * Provides adapter management and device listing/pairing.
 */
Item {
    id: root

    property string currentView: "main" // "main" or "pair"

    function openPairView() {
        root.currentView = "pair";
    }
    function closePairView() {
        root.currentView = "main";
    }

    // Device details island lives at window level (Settings.qml); selection
    // is kept in GlobalStates, mirroring the Network page.
    function openDetails(device) {
        GlobalStates.openBluetoothDetails(device);
    }
    function closeDetails() {
        GlobalStates.closeBluetoothDetails();
    }
    // Close the details island when its device is forgotten or vanishes.
    function closeIfDeviceGone() {
        const t = GlobalStates.bluetoothDetailsTarget;
        if (!t) return;
        const stillThere = [...BluetoothStatus.connectedDevices, ...BluetoothStatus.pairedButNotConnectedDevices]
            .some(d => d.address === t.address);
        if (!stillThere) GlobalStates.closeBluetoothDetails();
    }

    // Deep link from QuickSettings: jump straight into pairing mode.
    function checkPairMode() {
        if (GlobalStates.settingsBluetoothPairMode) {
            root.currentView = "pair";
        }
    }
    Component.onCompleted: checkPairMode()

    onVisibleChanged: {
        if (visible) checkPairMode()
        else {
            root.currentView = "main";
            BluetoothStatus.stopDiscovery();
            root.closeDetails();
        }
    }

    // Reset scroll and stop scanning when changing views
    onCurrentViewChanged: {
        mainFlicking.contentY = 0
        if (currentView !== "pair") BluetoothStatus.stopDiscovery()
        if (currentView !== "main") root.closeDetails()
    }

    Connections {
        target: GlobalStates
        function onSettingsBluetoothPairModeChanged() {
            if (GlobalStates.settingsBluetoothPairMode) {
                root.currentView = "pair";
            }
        }
    }

    Connections {
        target: BluetoothStatus
        function onEnabledChanged() {
            if (!BluetoothStatus.enabled) {
                root.currentView = "main";
                root.closeDetails();
            }
        }
        // Return to the device list once pairing finishes successfully.
        function onDeviceConnected(device) {
            root.currentView = "main";
        }
        // Auto-close the details island when its device is forgotten.
        function onConnectedDevicesChanged() { root.closeIfDeviceGone() }
        function onPairedButNotConnectedDevicesChanged() { root.closeIfDeviceGone() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 24 * Appearance.effectiveScale

        // ── Header ──
        ColumnLayout {
            spacing: 4 * Appearance.effectiveScale
            Layout.fillWidth: true
            Layout.rightMargin: 24 * Appearance.effectiveScale

            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * Appearance.effectiveScale

                // Back Button (only in sub-pages)
                RippleButton {
                    visible: root.currentView !== "main"
                    implicitWidth: 40 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.colors.colLayer1
                    onClicked: root.currentView = "main"
                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "arrow_back"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    text: {
                        if (root.currentView === "main") return I18nService.tr("Bluetooth")
                        if (root.currentView === "pair") return I18nService.tr("Pair new device")
                        return I18nService.tr("Bluetooth")
                    }
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.family: Appearance.font.family.title
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
            }
            StyledText {
                text: {
                    if (root.currentView === "main") return I18nService.tr("Pair and manage your Bluetooth devices.")
                    if (root.currentView === "pair") return I18nService.tr("Select a nearby device to pair.")
                    return ""
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Scrollable Content Area ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: mainFlicking
                anchors.fill: parent
                contentHeight: contentCol.implicitHeight
                clip: true
                interactive: true

                ScrollBar.vertical: ScrollBar {}

                ColumnLayout {
                    id: contentCol
                    width: parent.width - (24 * Appearance.effectiveScale)
                    spacing: 24 * Appearance.effectiveScale

                    BluetoothMainView {
                        id: mainViewCol
                        Layout.fillWidth: true
                        visible: root.currentView === "main"
                    }
                    BluetoothPairView {
                        id: pairViewCol
                        Layout.fillWidth: true
                        visible: root.currentView === "pair"
                    }
                }
            } // End Flickable
        }
    }
}
