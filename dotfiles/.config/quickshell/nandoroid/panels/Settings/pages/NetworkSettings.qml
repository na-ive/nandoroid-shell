import "../../../core"
import "../../../services"
import "../../../widgets"
import "../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Functional Network Settings page.
 * Provides WiFi scanning, listing, and connection management.
 */
Item {
    id: root

    property string currentView: "main" // "main", "saved", or "wired"

    onVisibleChanged: {
        if (visible) Network.update()
        else root.currentView = "main"
    }
    
    // Reset scroll when changing views
    onCurrentViewChanged: {
        mainFlicking.contentY = 0
        Network.update()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 24

        // ── Header ──
        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Back Button (only in sub-pages)
                RippleButton {
                    visible: root.currentView !== "main"
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: 20
                    colBackground: Appearance.colors.colLayer1
                    onClicked: root.currentView = "main"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        iconSize: 24
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    text: {
                        if (root.currentView === "main") return "Network & Internet"
                        if (root.currentView === "saved") return "Saved Networks"
                        if (root.currentView === "wired") return "Wired Network"
                        return "Network"
                    }
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                
                RowLayout {
                    visible: root.currentView === "main"
                    spacing: 12
                    
                    // Refresh Button
                    RippleButton {
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: 20
                        colBackground: Appearance.colors.colLayer1
                        onClicked: Network.rescanWifi()
                        
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                            
                            RotationAnimation on rotation {
                                id: refreshAnim
                                from: 0
                                to: 360
                                duration: 1000
                                loops: Animation.Infinite
                                running: Network.wifiScanning
                            }
                        }
                    }

                    // Add Network Button
                    RippleButton {
                        implicitWidth: 40
                        implicitHeight: 40
                        buttonRadius: 20
                        colBackground: Appearance.colors.colLayer1
                        onClicked: addNetworkDialog.open()
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "add"
                            iconSize: 20
                            color: Appearance.colors.colOnLayer1
                        }
                    }

                    // Global WiFi Toggle
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: Network.wifiEnabled
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer2

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: Network.wifiEnabled ? parent.width - width - 4 : 4
                            color: Network.wifiEnabled
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.toggleWifi()
                        }
                    }
                }
            }
            StyledText {
                text: {
                    if (root.currentView === "main") return "Manage your WiFi networks, Ethernet, and connectivity."
                    if (root.currentView === "saved") return "Manage and forget your saved WiFi networks."
                    if (root.currentView === "wired") return "Manage your wired ethernet connections."
                    return ""
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Scrollable Content Area ──
        Flickable {
            id: mainFlicking
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.implicitHeight
            clip: true
            interactive: true

            ScrollBar.vertical: ScrollBar {}

            ColumnLayout {
                id: contentCol
                width: parent.width
                spacing: 24

                // ── Main View: WiFi Scanning & Management ──
                ColumnLayout {
                    id: mainViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "main"
                    spacing: 24

                    // ── Available Networks Header ──
                    StyledText {
                        visible: Network.wifiEnabled && Network.friendlyWifiNetworks.length > 0
                        text: "Available Networks"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12
                    }

                    // ── Active WiFi List ──
                    Rectangle {
                        id: activeAreaRect
                        Layout.fillWidth: true
                        Layout.preferredHeight: wifiList.contentHeight + 24
                        visible: Network.wifiEnabled && Network.friendlyWifiNetworks.length > 0
                        radius: 16
                        color: Appearance.colors.colLayer1
                        clip: true

                        ListView {
                            id: wifiList
                            anchors.fill: parent
                            anchors.margins: 12
                            clip: true
                            spacing: 8
                            model: Network.friendlyWifiNetworks
                            interactive: false 

                            delegate: Item {
                                id: networkItem
                                width: wifiList.width - 24
                                height: networkCol.implicitHeight
                                
                                property bool expanded: modelData.askingPassword
                                property bool autoconnect: true 
                                property bool showPassword: false

                                ColumnLayout {
                                    id: networkCol
                                    width: parent.width
                                    spacing: 0

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 64
                                        buttonRadius: 16
                                        colBackground: {
                                            if (modelData.active) return Functions.ColorUtils.mix(Appearance.colors.colLayer1, Appearance.colors.colPrimary, 0.85);
                                            if (expanded) return Appearance.colors.colLayer2;
                                            return "transparent";
                                        }
                                        colBackgroundHover: {
                                            if (modelData.active) return colBackground;
                                            if (expanded) return colBackground;
                                            return Appearance.colors.colLayer1Hover;
                                        }
                                            
                                        // Header rounding overlay for expansion joint
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: expanded
                                            color: parent.colBackground
                                            z: -1
                                            radius: 16
                                            
                                            // Make bottom square
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: 16
                                                color: parent.color
                                            }
                                        }
                                        
                                        onClicked: {
                                            if (modelData.active) {
                                                Network.disconnectWifiNetwork();
                                            } else if (modelData.isSaved) {
                                                Network.connectToWifiNetwork(modelData);
                                            } else {
                                                modelData.askingPassword = !modelData.askingPassword;
                                                if (modelData.askingPassword) {
                                                    passInput.forceActiveFocus();
                                                }
                                            }
                                        }


                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            MaterialSymbol {
                                                text: {
                                                    const s = modelData.strength
                                                    if (s > 80) return "signal_wifi_4_bar"
                                                    if (s > 60) return "network_wifi_3_bar"
                                                    if (s > 40) return "network_wifi_2_bar"
                                                    if (s > 20) return "network_wifi_1_bar"
                                                    return "signal_wifi_0_bar"
                                                }
                                                iconSize: 24
                                                color: modelData.active ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0
                                                StyledText {
                                                    text: modelData.ssid
                                                    font.pixelSize: Appearance.font.pixelSize.normal
                                                    font.weight: modelData.active ? Font.Bold : Font.Normal
                                                    color: Appearance.colors.colOnLayer1
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                StyledText {
                                                    text: modelData.active ? "Connected" : (modelData.isSecure ? "Secured" : "Open")
                                                    font.pixelSize: Appearance.font.pixelSize.small
                                                    color: Appearance.colors.colSubtext
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            RowLayout {
                                                spacing: 8
                                                MaterialSymbol {
                                                    visible: modelData.active
                                                    text: "check"
                                                    iconSize: 24
                                                    color: Appearance.colors.colPrimary
                                                }
                                                MaterialSymbol {
                                                    visible: modelData.isSecure && !modelData.active
                                                    text: "lock"
                                                    iconSize: 20
                                                    color: Appearance.colors.colSubtext
                                                }

                                                MaterialSymbol {
                                                    visible: modelData.isSaved && modelData.priority > 0
                                                    text: "push_pin"
                                                    iconSize: 18
                                                    color: Appearance.colors.colPrimary
                                                    fill: 1
                                                }

                                                RippleButton {
                                                    implicitWidth: 32
                                                    implicitHeight: 32
                                                    buttonRadius: 16
                                                    colBackground: "transparent"
                                                    onClicked: networkItem.expanded = !networkItem.expanded
                                                    contentItem: MaterialSymbol {
                                                        anchors.centerIn: parent
                                                        text: "keyboard_arrow_down"
                                                        iconSize: 20
                                                        color: Appearance.colors.colSubtext
                                                        rotation: networkItem.expanded ? 180 : 0
                                                        Behavior on rotation { NumberAnimation { duration: 200 } }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // ── Expanded Area ──
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: networkItem.expanded ? (expansionCol.implicitHeight + 24) : 0
                                        clip: true
                                        color: Appearance.colors.colLayer2
                                        radius: 16
                                        opacity: networkItem.expanded ? 1 : 0
                                        visible: Layout.preferredHeight > 0
                                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                        Behavior on opacity { NumberAnimation { duration: 200 } }
                                        
                                        // Merge with header by making top square
                                        Rectangle {
                                            width: parent.width
                                            height: 16
                                            color: parent.color
                                            visible: networkItem.expanded
                                            anchors.top: parent.top
                                            z: 0
                                        }

                                        ColumnLayout {
                                            id: expansionCol
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 16

                                            // ── Mode: UNSAVED (Password Entry) ──
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 8
                                                visible: (!modelData.active && (!modelData.isSaved || modelData.askingPassword))

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 48
                                                    radius: 12
                                                    color: Appearance.colors.colLayer1
                                                    border.color: passInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                                                    border.width: 1

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: 12
                                                        anchors.rightMargin: 8
                                                        
                                                        TextInput {
                                                            id: passInput
                                                            Layout.fillWidth: true
                                                            verticalAlignment: TextInput.AlignVCenter
                                                            echoMode: networkItem.showPassword ? TextInput.Normal : TextInput.Password
                                                            color: Appearance.colors.colOnLayer1
                                                            font.pixelSize: Appearance.font.pixelSize.normal
                                                            
                                                            Text {
                                                                anchors.fill: parent
                                                                visible: !passInput.text && !passInput.activeFocus
                                                                text: "Enter Password..."
                                                                color: Appearance.colors.colSubtext
                                                                verticalAlignment: Text.AlignVCenter
                                                                font: passInput.font
                                                            }
                                                        }

                                                        RippleButton {
                                                            implicitWidth: 32
                                                            implicitHeight: 32
                                                            buttonRadius: 16
                                                            colBackground: "transparent"
                                                            onClicked: networkItem.showPassword = !networkItem.showPassword
                                                            MaterialSymbol {
                                                                anchors.centerIn: parent
                                                                text: networkItem.showPassword ? "visibility_off" : "visibility"
                                                                iconSize: 20
                                                                color: Appearance.colors.colSubtext
                                                            }
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    spacing: 8
                                                    RippleButton {
                                                        implicitWidth: 32
                                                        implicitHeight: 32
                                                        buttonRadius: 8
                                                        colBackground: "transparent"
                                                        onClicked: networkItem.autoconnect = !networkItem.autoconnect
                                                        contentItem: MaterialSymbol {
                                                            anchors.centerIn: parent
                                                            text: networkItem.autoconnect ? "check_box" : "check_box_outline_blank"
                                                            iconSize: 20
                                                            color: networkItem.autoconnect ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                                        }
                                                    }
                                                    StyledText {
                                                        text: "Connect automatically"
                                                        font.pixelSize: Appearance.font.pixelSize.small
                                                        color: Appearance.colors.colSubtext
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12
                                                    Item { Layout.fillWidth: true }
                                                    RippleButton {
                                                        buttonText: "Connect"
                                                        implicitWidth: 100
                                                        implicitHeight: 36
                                                        buttonRadius: 18
                                                        colBackground: Appearance.colors.colPrimary
                                                        colText: Appearance.colors.colOnPrimary
                                                        enabled: passInput.text.length > 0
                                                        onClicked: {
                                                            Network.connectWithPassword(modelData.ssid, passInput.text, false, networkItem.autoconnect);
                                                            modelData.askingPassword = false;
                                                        }
                                                    }
                                                }
                                            }

                                            // ── Mode: SAVED (Management) ──
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 12
                                                visible: (modelData.isSaved || modelData.active) && !modelData.askingPassword

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 12

                                                    StyledText {
                                                        text: `BSSID: ${modelData.bssid}`
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        color: Appearance.colors.colSubtext
                                                    }

                                                    Item { Layout.fillWidth: true }

                                                    RippleButton {
                                                        buttonText: "Forget"
                                                        implicitWidth: 80
                                                        implicitHeight: 36
                                                        buttonRadius: 18
                                                        colBackground: Appearance.m3colors.m3error
                                                        colText: Appearance.m3colors.m3onError
                                                        onClicked: Network.forgetNetwork(modelData.ssid)
                                                    }

                                                    RippleButton {
                                                        buttonText: "Edit"
                                                        implicitWidth: 70
                                                        implicitHeight: 36
                                                        buttonRadius: 18
                                                        colBackground: Appearance.colors.colLayer1
                                                        onClicked: modelData.askingPassword = true
                                                    }

                                                    RippleButton {
                                                        buttonText: "Pin"
                                                        implicitWidth: 60
                                                        implicitHeight: 36
                                                        buttonRadius: 18
                                                        colBackground: modelData.priority > 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                                        colText: modelData.priority > 0 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
                                                        onClicked: Network.setPriority(modelData.ssid, modelData.priority > 0 ? 0 : 100)
                                                    }
                                                }
                                            }
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
                        Layout.preferredHeight: 300
                        visible: !Network.wifiEnabled
                        spacing: 16
                        
                        Item { Layout.fillHeight: true }
                        
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "wifi_off"
                            iconSize: 64
                            color: Appearance.colors.colSubtext
                        }
                        
                        StyledText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: "WiFi is turned off"
                            font.pixelSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colSubtext
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                } // End mainViewCol

                // ── Saved Networks Sub-page View ──
                ColumnLayout {
                    id: savedViewCol
                    Layout.fillWidth: true
                    visible: root.currentView === "saved"
                    spacing: 24

                    StyledText {
                        text: "You have " + Network.savedConnections.length + " saved networks"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                    }

                    // ── Saved Networks Accordion List ──
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: savedRepeaterCol.implicitHeight + 32
                        radius: 20
                        color: Appearance.colors.colLayer1
                        
                        ColumnLayout {
                            id: savedRepeaterCol
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Repeater {
                                model: Network.savedConnections
                                delegate: ColumnLayout {
                                    id: savedItem
                                    Layout.fillWidth: true
                                    spacing: 0
                                    property bool expanded: false

                                    RippleButton {
                                        Layout.fillWidth: true
                                        implicitHeight: 64
                                        buttonRadius: 16
                                        colBackground: savedItem.expanded ? Appearance.colors.colLayer1Hover : "transparent"
                                        onClicked: savedItem.expanded = !savedItem.expanded

                                        // Header rounding overlay for expansion joint
                                        Rectangle {
                                            anchors.fill: parent
                                            visible: savedItem.expanded
                                            color: parent.colBackground
                                            z: -1
                                            radius: 16
                                            
                                            // Make bottom square
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: 16
                                                color: parent.color
                                            }
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            spacing: 16

                                            MaterialSymbol {
                                                text: "wifi"
                                                iconSize: 24
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
                                                iconSize: 20
                                                color: Appearance.colors.colSubtext
                                                rotation: savedItem.expanded ? 180 : 0
                                                Behavior on rotation { NumberAnimation { duration: 200 } }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: savedItem.expanded ? (savedActionCol.implicitHeight + 24) : 0
                                        visible: Layout.preferredHeight > 0
                                        clip: true
                                        color: Appearance.colors.colLayer2
                                        radius: 16
                                        
                                        // Merge with header by making top square
                                        Rectangle {
                                            width: parent.width
                                            height: 16
                                            color: parent.color
                                            visible: savedItem.expanded
                                            anchors.top: parent.top
                                        }

                                        ColumnLayout {
                                            id: savedActionCol
                                            anchors.fill: parent
                                            anchors.margins: 16
                                            spacing: 16

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 12

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
                                                    implicitWidth: 90
                                                    implicitHeight: 36
                                                    buttonRadius: 18
                                                    colBackground: Appearance.m3colors.m3error
                                                    colText: Appearance.m3colors.m3onError
                                                    onClicked: Network.forgetNetwork(modelData)
                                                }

                                                RippleButton {
                                                    buttonText: savedPassLabel.text.length > 0 ? "Hide" : "Share"
                                                    implicitWidth: 100
                                                    implicitHeight: 36
                                                    buttonRadius: 18
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

                // ── Wired Network Sub-page View ──
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
            } // End contentCol
        } // End Flickable

        // ── Bottom Management Buttons (Main View) ──
        RowLayout {
            id: bottomManagementRow
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.topMargin: 0
            spacing: 12
            visible: root.currentView === "main"

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.colors.colLayer1
                onClicked: root.currentView = "wired"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "lan"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Wired Network"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            RippleButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                buttonRadius: 16
                colBackground: Appearance.colors.colLayer1
                onClicked: root.currentView = "saved"
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "history"
                        iconSize: 20
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Saved Networks"
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    } // End root ColumnLayout

    Dialog {
        id: addNetworkDialog
        parent: root
        anchors.centerIn: parent
        width: Math.min(500, root.width * 0.9)
        implicitHeight: addCol.implicitHeight + 48
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property bool isHidden: false
        property bool showPassword: false

        onClosed: {
            ssidInput.text = "";
            hiddenPassInput.text = "";
            isHidden = false;
            showPassword = false;
        }

        background: Rectangle {
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.card
            border.width: 0
            
            // Shadow
            StyledRectangularShadow {
                target: parent
                z: -1
                offset: Qt.vector2d(0, 8)
                blur: 20
                color: Qt.rgba(0, 0, 0, 0.3)
            }
        }

        contentItem: ColumnLayout {
            id: addCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // Header Section
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "network_wifi"
                    iconSize: 32
                    color: Appearance.colors.colPrimary
                }
                
                ColumnLayout {
                    spacing: 4
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Add Network"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Enter the details of the network you want to join."
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                    }
                }
            }

            // Inputs (Polkit Style)
            ColumnLayout {
                spacing: 20
                Layout.fillWidth: true

                // SSID Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: "transparent"
                    border.width: ssidInput.activeFocus ? 2 : 1
                    border.color: ssidInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                    // Floating Label
                    Rectangle {
                        x: 12
                        y: -8
                        width: ssidLabel.width + 8
                        height: 16
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        StyledText {
                            id: ssidLabel
                            anchors.centerIn: parent
                            text: "Network Name"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: ssidInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline
                        }
                    }

                    TextInput {
                        id: ssidInput
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        verticalAlignment: TextInput.AlignVCenter
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.normal
                        
                        Text {
                            anchors.left: ssidInput.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !ssidInput.text && !ssidInput.activeFocus
                            text: "SSID"
                            color: Appearance.colors.colSubtext
                            font.pixelSize: Appearance.font.pixelSize.normal
                        }
                    }
                }

                // Password Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 8
                    color: "transparent"
                    border.width: hiddenPassInput.activeFocus ? 2 : 1
                    border.color: hiddenPassInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline

                    // Floating Label
                    Rectangle {
                        x: 12
                        y: -8
                        width: passLabel.width + 8
                        height: 16
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        StyledText {
                            id: passLabel
                            anchors.centerIn: parent
                            text: "Password"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: hiddenPassInput.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3outline
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        
                        TextInput {
                            id: hiddenPassInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: addNetworkDialog.showPassword ? TextInput.Normal : TextInput.Password
                            color: Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.normal
                            
                            Text {
                                anchors.left: hiddenPassInput.left
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !hiddenPassInput.text && !hiddenPassInput.activeFocus
                                text: "Optional"
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.normal
                            }
                        }

                        RippleButton {
                            implicitWidth: 32
                            implicitHeight: 32
                            buttonRadius: 16
                            colBackground: "transparent"
                            onClicked: addNetworkDialog.showPassword = !addNetworkDialog.showPassword
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: addNetworkDialog.showPassword ? "visibility_off" : "visibility"
                                iconSize: 20
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }

            // Options (Interactive Hidden Toggle)
            MouseArea {
                id: hiddenToggleArea
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                cursorShape: Qt.PointingHandCursor
                onClicked: addNetworkDialog.isHidden = !addNetworkDialog.isHidden
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    RippleButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        buttonRadius: 8
                        colBackground: "transparent"
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: addNetworkDialog.isHidden ? "check_box" : "check_box_outline_blank"
                            iconSize: 20
                            color: addNetworkDialog.isHidden ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        }
                    }
                    
                    StyledText {
                        text: "Hidden network"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                    }
                    
                    Item { Layout.fillWidth: true }
                }
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 12
                spacing: 12
                
                Item { Layout.fillWidth: true }
                
                RippleButton {
                    buttonText: "Cancel"
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.button
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    onClicked: addNetworkDialog.close()
                }
                
                RippleButton {
                    buttonText: "Connect"
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.button
                    colBackground: Appearance.colors.colPrimary
                    colText: Appearance.colors.colOnPrimary
                    enabled: ssidInput.text.length > 0
                    onClicked: {
                        Network.connectWithPassword(ssidInput.text, hiddenPassInput.text, addNetworkDialog.isHidden);
                        addNetworkDialog.close();
                    }
                }
            }
        }
    }
}
