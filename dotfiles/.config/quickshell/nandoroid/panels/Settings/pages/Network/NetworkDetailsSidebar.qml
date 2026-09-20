import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Android-style "Network details" right sidebar.
 * Mirrors WallSelDetailsIsland sizing/animation.
 */
Rectangle {
    id: detailsIsland

    property var network: null
    property string sharedPassword: ""

    signal closed()

    function signalLabel(strength) {
        if (strength >= 75) return I18nService.tr("Excellent");
        if (strength >= 55) return I18nService.tr("Good");
        if (strength >= 35) return I18nService.tr("Fair");
        return I18nService.tr("Poor");
    }

    function freqLabel(mhz) {
        if (mhz >= 5900) return "6 GHz";
        if (mhz >= 4900) return "5 GHz";
        if (mhz >= 2400) return "2.4 GHz";
        if (mhz > 0) return (mhz / 1000).toFixed(1) + " GHz";
        return I18nService.tr("Unknown");
    }

    function securityLabel(sec) {
        if (!sec || sec.length === 0) return I18nService.tr("None (Open)");
        const s = sec.toUpperCase();
        if (s.includes("WPA3")) return "WPA3-Personal";
        if (s.includes("WPA2") && s.includes("WPA")) return "WPA/WPA2-Personal";
        if (s.includes("WPA2")) return "WPA2-Personal";
        if (s.includes("WPA")) return "WPA-Personal";
        if (s.includes("WEP")) return "WEP";
        if (s.includes("SAE")) return "WPA3-Personal";
        if (s.includes("PSK")) return "WPA-Personal";
        if (s.includes("EAP") || s.includes("802.1X")) return "WPA-Enterprise";
        return sec;
    }

    // Width snaps in a single frame instead of animating: an animated width
    // re-solves the whole RowLayout AND the active page's layout tree on every
    // frame, which stutters. Motion comes from the opacity fade + content
    // slide below; on close the collapse is delayed so the fade finishes first.
    readonly property bool open: network !== null
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

    onNetworkChanged: {
        sharedPassword = "";
        if (network) Network.fetchWifiDetails();
    }

    // Live device info (IP/GW/DNS/MAC). Refetched while open; safe because
    // fetchWifiDetails only touches wifiDetails, never wifiNetworks.
    readonly property var _dev: Network.wifiDetails
    readonly property string ipAddr: {
        const a = _dev["ip4.address[1]"] || _dev["ip4.address"] || "";
        return a.includes("/") ? a.split("/")[0] : a;
    }
    readonly property string subnetBits: {
        const a = _dev["ip4.address[1]"] || _dev["ip4.address"] || "";
        return a.includes("/") ? a.split("/")[1] : "";
    }
    readonly property string gatewayAddr: _dev["ip4.gateway"] || ""
    readonly property string dnsAddrs: {
        let out = [];
        for (const k in _dev) {
            if (k.startsWith("ip4.dns") && _dev[k]) out.push(_dev[k]);
        }
        return out.join(", ");
    }
    readonly property string macAddr: _dev["general.hwaddr"] || ""

    Connections {
        target: Network
        function onWifiNetworksChanged() {
            if (detailsIsland.network && detailsIsland.network.active) {
                Network.fetchWifiDetails();
            }
        }
    }

    Connections {
        target: Network
        function onPasswordRecovered(password) {
            if (detailsIsland.network) sharedPassword = password;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale
        spacing: 0
        // Track the collapsed flag (not network) so content keeps rendering
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
                text: I18nService.tr("Network details")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: 32 * Appearance.effectiveScale
                implicitHeight: 32 * Appearance.effectiveScale
                buttonRadius: 16 * Appearance.effectiveScale
                colBackground: "transparent"
                visible: detailsIsland.network && detailsIsland.network.isSaved
                onClicked: if (detailsIsland.network) GlobalStates.openNetworkPasswordEdit(detailsIsland.network)
                contentItem: MaterialSymbol {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "edit"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colSubtext
                }
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

                MaterialSymbol { 
                    text: "wifi"
                    iconSize: 48 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12 * Appearance.effectiveScale
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * Appearance.effectiveScale
                    horizontalAlignment: Text.AlignHCenter
                    text: detailsIsland.network ? detailsIsland.network.ssid : ""
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: detailsIsland.network && detailsIsland.network.active ? I18nService.tr("Connected") : (detailsIsland.network && detailsIsland.network.isSaved ? I18nService.tr("Saved") : I18nService.tr("Not connected"))
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }

                // ── Actions ──
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
                            enabled: detailsIsland.network && detailsIsland.network.isSaved
                            opacity: enabled ? 1 : 0.5
                            onClicked: if (detailsIsland.network) Network.forgetNetwork(detailsIsland.network.ssid)
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

                    // Disconnect when connected, Connect when in range, hidden when out of range
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: detailsIsland.network && (detailsIsland.network.active || !detailsIsland.network.isPlaceholder)
                        spacing: 4 * Appearance.effectiveScale
                        RippleButton {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 52 * Appearance.effectiveScale
                            implicitHeight: 40 * Appearance.effectiveScale
                            buttonRadius: 20 * Appearance.effectiveScale
                            colBackground: Appearance.m3colors.m3primaryContainer
                            onClicked: {
                                if (!detailsIsland.network) return;
                                if (detailsIsland.network.active) Network.disconnectWifiNetwork();
                                else Network.connectToWifiNetwork(detailsIsland.network);
                            }
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: detailsIsland.network && detailsIsland.network.active ? "close" : "wifi"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: detailsIsland.network && detailsIsland.network.active ? I18nService.tr("Disconnect") : I18nService.tr("Connect")
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
                            enabled: detailsIsland.network && detailsIsland.network.isSaved
                            opacity: enabled ? 1 : 0.5
                            onClicked: {
                                if (!detailsIsland.network) return;
                                if (sharedPassword.length > 0) sharedPassword = "";
                                else Network.getSavedPassword(detailsIsland.network.ssid);
                            }
                            contentItem: MaterialSymbol {
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: "qr_code_2"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onPrimaryContainer
                            }
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: I18nService.tr("Share")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * Appearance.effectiveScale
                    visible: sharedPassword.length > 0
                    horizontalAlignment: Text.AlignHCenter
                    text: I18nService.tr("Password: ") + sharedPassword
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colPrimary
                    wrapMode: Text.WrapAnywhere
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !(detailsIsland.network && detailsIsland.network.isPlaceholder)
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "wifi"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Signal strength"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: signalLabel(detailsIsland.network ? detailsIsland.network.strength : 0); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !(detailsIsland.network && detailsIsland.network.isPlaceholder)
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "wifi_tethering"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Frequency"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: freqLabel(detailsIsland.network ? detailsIsland.network.frequency : 0); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !(detailsIsland.network && detailsIsland.network.isPlaceholder)
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "lock"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Security"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: securityLabel(detailsIsland.network ? detailsIsland.network.security : ""); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        visible: detailsIsland.network && detailsIsland.network.active
                        MaterialSymbol { text: "dns"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("IP address"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.ipAddr !== "" ? detailsIsland.ipAddr + (detailsIsland.subnetBits !== "" ? " /" + detailsIsland.subnetBits : "") : I18nService.tr("Not available")
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                                Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        visible: detailsIsland.network && detailsIsland.network.active
                        MaterialSymbol { text: "router"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Gateway"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.gatewayAddr !== "" ? detailsIsland.gatewayAddr : I18nService.tr("Not available")
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                                Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        visible: detailsIsland.network && detailsIsland.network.active
                        MaterialSymbol { text: "public"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("DNS"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.dnsAddrs !== "" ? detailsIsland.dnsAddrs : I18nService.tr("Not available")
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                                Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        visible: detailsIsland.network && detailsIsland.network.active && detailsIsland.macAddr !== ""
                        MaterialSymbol { text: "memory"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("MAC address"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.macAddr
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                                Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: detailsIsland.network && detailsIsland.network.bssid !== ""
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "router"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: "BSSID"; font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText {
                                text: detailsIsland.network ? detailsIsland.network.bssid : ""
                                font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext
                                Layout.fillWidth: true; wrapMode: Text.WrapAnywhere
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        visible: detailsIsland.network && detailsIsland.network.isSaved
                        MaterialSymbol { text: "group"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Connect automatically"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: I18nService.tr("Reconnect when in range"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                        AndroidToggle {
                            checked: detailsIsland.network ? (Network.savedAutoConnect[detailsIsland.network.ssid] !== false) : true
                            onToggled: if (detailsIsland.network) Network.setAutoConnect(detailsIsland.network.ssid, !checked)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "push_pin"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Pin network"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: I18nService.tr("Prioritize this network"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                        AndroidToggle {
                            checked: detailsIsland.network ? (detailsIsland.network.priority > 0) : false
                            onToggled: if (detailsIsland.network) Network.setPriority(detailsIsland.network.ssid, !checked ? 100 : 0)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol { text: "visibility_off"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText { text: I18nService.tr("Privacy"); font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.Medium; color: Appearance.colors.colOnLayer1 }
                            StyledText { text: I18nService.tr("Use randomized MAC (default)"); font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
