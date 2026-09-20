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
    spacing: 24 * Appearance.effectiveScale

    // Accordion: only one connection expanded at a time.
    property string expandedUuid: ""

    onVisibleChanged: if (!visible) expandedUuid = ""

    // Keep the expanded panel's info fresh while it is open; safe because
    // fetchWiredDetails only touches wiredDetails, never wiredConnections.
    Connections {
        target: Network
        function onWiredConnectionsChanged() {
            if (wiredViewCol.expandedUuid === "") return;
            const stillThere = Network.wiredConnections.some(c => c.uuid === wiredViewCol.expandedUuid);
            if (!stillThere) {
                wiredViewCol.expandedUuid = "";
                return;
            }
            Network.fetchWiredDetails(wiredViewCol.expandedUuid);
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: Network.wiredConnections.length > 0
        text: I18nService.tr("You have ") + Network.wiredConnections.length + I18nService.tr(" wired connections")
        font.pixelSize: Appearance.font.pixelSize.normal
        color: Appearance.colors.colSubtext
    }

    // ── Empty state ──
    ColumnLayout {
        visible: Network.wiredConnections.length === 0
        Layout.fillWidth: true
        spacing: 8 * Appearance.effectiveScale
        Item { Layout.preferredHeight: 40 * Appearance.effectiveScale }
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "lan_off"
            iconSize: 64 * Appearance.effectiveScale
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: I18nService.tr("No wired interfaces found")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: I18nService.tr("Plug in an ethernet cable or create a profile in advanced settings.")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    // ── Connection list + Advanced settings group ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2 * Appearance.effectiveScale

        Repeater {
            model: Network.wiredConnections
            delegate: SegmentedWrapper {
                id: segWired
                Layout.fillWidth: true
                orientation: Qt.Vertical
                // The advanced-settings row below always closes this group, so
                // connection cards are never standalone: the first card gets
                // the outer top radius, every card keeps a small connected
                // bottom radius (and fullRadius can never balloon when the
                // details panel expands).
                forceFirst: index === 0
                forceLast: false
                forceNotStandalone: true
                color: Appearance.m3colors.m3surfaceContainerHigh
                implicitHeight: wiredInner.implicitHeight

                ColumnLayout {
                    id: wiredInner
                    width: parent.width
                    spacing: 0

                    readonly property bool expanded: wiredViewCol.expandedUuid === modelData.uuid
                    onExpandedChanged: if (expanded) Network.fetchWiredDetails(modelData.uuid)

                    // Header row: tap to expand/collapse
                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 64 * Appearance.effectiveScale
                        topLeftRadius: segWired.rTopLeft
                        topRightRadius: segWired.rTopRight
                        bottomLeftRadius: wiredInner.expanded ? 0 : segWired.rBottomLeft
                        bottomRightRadius: wiredInner.expanded ? 0 : segWired.rBottomRight
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        onClicked: wiredViewCol.expandedUuid = wiredInner.expanded ? "" : modelData.uuid

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 16 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "lan"
                                iconSize: 24 * Appearance.effectiveScale
                                color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                StyledText {
                                    text: modelData.name
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: modelData.active ? Font.DemiBold : Font.Normal
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                StyledText {
                                    text: {
                                        const dev = (modelData.device !== "" && modelData.device !== "--") ? modelData.device : "";
                                        if (modelData.active) return I18nService.tr("Connected") + (dev !== "" ? " · " + dev : "");
                                        return I18nService.tr("Disconnected") + (dev !== "" ? " · " + dev : "");
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MaterialSymbol {
                                text: "keyboard_arrow_down"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                                rotation: wiredInner.expanded ? 180 : 0
                                Behavior on rotation { NumberAnimation { duration: 200 } }
                            }
                        }
                    }

                    // Expanded details panel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: wiredInner.expanded ? (wiredPanel.implicitHeight + 32 * Appearance.effectiveScale) : 0
                        visible: Layout.preferredHeight > 0
                        clip: true
                        color: Appearance.colors.colLayer2
                        // Match the wrapper's rounded silhouette (the wrapper
                        // does not clip children, so square corners would
                        // poke out of the card).
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: segWired.rBottomLeft
                        bottomRightRadius: segWired.rBottomRight
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            id: wiredPanel
                            anchors.fill: parent
                            anchors.margins: 16 * Appearance.effectiveScale
                            spacing: 14 * Appearance.effectiveScale

                            // Live profile info (IP/GW/DNS/MAC), refetched while expanded.
                            readonly property var dev: Network.wiredDetails
                            readonly property string ipText: {
                                let out = [];
                                for (const k in dev) {
                                    if (k.startsWith("ip4.address") && dev[k]) out.push(dev[k]);
                                }
                                return out.join(", ");
                            }
                            readonly property string gatewayText: dev["ip4.gateway"] || ""
                            readonly property string dnsText: {
                                let out = [];
                                for (const k in dev) {
                                    if (k.startsWith("ip4.dns") && dev[k]) out.push(dev[k]);
                                }
                                return out.join(", ");
                            }
                            readonly property string macText: dev["general.hwaddr"] || ""

                            Repeater {
                                // Values are looked up by index instead of living in
                                // the model, so refreshing wiredDetails never rebuilds
                                // these rows (they would visibly flicker).
                                model: [
                                    { icon: "dns", label: I18nService.tr("IP address") },
                                    { icon: "router", label: I18nService.tr("Gateway") },
                                    { icon: "public", label: I18nService.tr("DNS") },
                                    { icon: "memory", label: I18nService.tr("MAC address") }
                                ]
                                delegate: RowLayout {
                                    id: detailRow
                                    Layout.fillWidth: true
                                    spacing: 16 * Appearance.effectiveScale

                                    readonly property string value: [
                                        wiredPanel.ipText, wiredPanel.gatewayText, wiredPanel.dnsText, wiredPanel.macText
                                    ][index]

                                    MaterialSymbol {
                                        text: modelData.icon
                                        iconSize: 20 * Appearance.effectiveScale
                                        color: Appearance.colors.colSubtext
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        StyledText {
                                            text: modelData.label
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnLayer1
                                        }
                                        StyledText {
                                            text: detailRow.value !== "" ? detailRow.value : I18nService.tr("Not available")
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            color: Appearance.colors.colSubtext
                                            Layout.fillWidth: true
                                            wrapMode: Text.WrapAnywhere
                                        }
                                    }
                                }
                            }

                            // Autoconnect toggle (same widget/flow as the details sidebar)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16 * Appearance.effectiveScale

                                MaterialSymbol {
                                    text: "autorenew"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colSubtext
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        text: I18nService.tr("Connect automatically")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colOnLayer1
                                    }
                                    StyledText {
                                        text: I18nService.tr("Activate when the cable is plugged in")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colSubtext
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                    }
                                }

                                AndroidToggle {
                                    checked: Network.savedAutoConnect[modelData.name] !== false
                                    onToggled: Network.setAutoConnect(modelData.name, !checked)
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 4 * Appearance.effectiveScale
                                Item { Layout.fillWidth: true }
                                RippleButton {
                                    buttonText: modelData.active ? I18nService.tr("Disconnect") : I18nService.tr("Connect")
                                    implicitWidth: 110 * Appearance.effectiveScale
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    buttonRadius: 18 * Appearance.effectiveScale
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

        // Advanced settings (GUI editor, or nmtui in kitty as fallback) —
        // always reachable, becomes a standalone pill when the list is empty.
        SegmentedWrapper {
            id: advRow
            Layout.fillWidth: true
            orientation: Qt.Vertical
            forceFirst: Network.wiredConnections.length === 0
            forceLast: true
            forcePill: Network.wiredConnections.length === 0
            maxRadius: Network.wiredConnections.length === 0 ? 32 * Appearance.effectiveScale : undefined
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                topLeftRadius: advRow.rTopLeft
                topRightRadius: advRow.rTopRight
                bottomLeftRadius: advRow.rBottomLeft
                bottomRightRadius: advRow.rBottomRight
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer1Hover
                onClicked: Network.openAdvancedSettings()

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 16 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: "tune"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: I18nService.tr("Advanced settings")
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: Network.advEditorAvailable ? I18nService.tr("Edit profiles with nm-connection-editor") : I18nService.tr("Edit profiles with nmtui")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

}
