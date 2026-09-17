import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import "PcDynamicIsland" as PcDynamicIsland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell
import Quickshell.Hyprland

Item {
    id: rootM3
    property int monitorIndex: 0
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(rootM3.QsWindow.window ? rootM3.QsWindow.window.screen : null)

    readonly property bool isPcIsland: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "pcIsland"
    readonly property bool isCentered: false
    readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200 * Appearance.effectiveScale
    


    property color contentColor: Appearance.m3colors.m3onSurface
    property color subtextColor: Appearance.m3colors.m3onSurfaceVariant

    readonly property real targetSidePadding: isCentered ? Math.max(12 * Appearance.effectiveScale, (rootM3.width - centeredWidth) / 2) : 12 * Appearance.effectiveScale
    property real sidePadding: targetSidePadding
    Behavior on sidePadding { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.closeAllPanels()
    }

    // ── Universal M3 Component Library ──
    Component { id: m3ActiveWindowComponent; M3StatusWrapper {
        id: activeWinWrapper
        readonly property bool isRight: Config.ready && Config.options.statusBar && Config.options.statusBar.rightModules ? Config.options.statusBar.rightModules.includes("activeWindow") : false
        readonly property bool hasSysMon: {
            if (!Config.ready || !Config.options.statusBar) return false;
            let lefts = Config.options.statusBar.leftModules || [];
            let rights = Config.options.statusBar.rightModules || [];
            return lefts.includes("systemMonitor") || rights.includes("systemMonitor");
        }
        m3Color: Appearance.m3colors.m3secondaryContainer
        m3ContentColor: Appearance.m3colors.m3onSecondaryContainer
        Layout.maximumWidth: rootM3.isCentered ? (rootM3.centeredWidth * (hasSysMon ? 0.12 : 0.25)) : Math.min((hasSysMon ? 180 : 350) * Appearance.effectiveScale, rootM3.width * (hasSysMon ? 0.14 : 0.25))
        show: true

        ActiveWindowTitle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: activeWinWrapper.Layout.maximumWidth
            maxWidth: activeWinWrapper.Layout.maximumWidth
            textAlignment: activeWinWrapper.isRight ? Text.AlignRight : Text.AlignLeft
            monitor: rootM3.monitor
            color: activeWinWrapper.m3ContentColor
            subtextColor: activeWinWrapper.subtextColor
        }
    }}

    Component { id: m3SysMonComponent; M3StatusWrapper {
        id: sysMonWrapper
        m3Color: Appearance.m3colors.m3tertiaryContainer
        m3ContentColor: Appearance.m3colors.m3onTertiaryContainer
        show: true

        SystemMonitorModule {
            Layout.alignment: Qt.AlignVCenter
            color: sysMonWrapper.m3ContentColor
            subtextColor: sysMonWrapper.subtextColor
        }
    }}

    Component { id: m3NetSpeedComponent; M3StatusWrapper {
        id: m3NetSpeedWrapper
        show: Config.ready && Config.options.bar ? Config.options.bar.show_network_speed : false
        Layout.alignment: Qt.AlignVCenter
        m3Color: Appearance.m3colors.m3surfaceContainerHigh
        m3ContentColor: Appearance.m3colors.m3onSurfaceVariant

        function formatSpeed(bytes) {
            const k = 1024;
            const mt = 1024 * 1024;
            if (bytes >= mt) return (bytes / mt).toFixed(1) + " MB/s";
            return (bytes / k).toFixed(1) + " KB/s";
        }

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4 * Appearance.effectiveScale

            RowLayout {
                spacing: 2 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "arrow_upward"
                    iconSize: 14 * Appearance.effectiveScale
                    color: SystemData.networkTxRate > 1024 ? m3NetSpeedWrapper.contentColor : m3NetSpeedWrapper.subtextColor
                }
                Item {
                    implicitWidth: txSpeedMetrics.width
                    implicitHeight: txSpeedText.implicitHeight
                    TextMetrics {
                        id: txSpeedMetrics
                        text: "999.9 MB/s"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.numbers
                    }
                    StyledText {
                        id: txSpeedText
                        anchors.centerIn: parent
                        text: m3NetSpeedWrapper.formatSpeed(SystemData.networkTxRate)
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: m3NetSpeedWrapper.contentColor
                    }
                }
            }

            Item {
                Layout.preferredWidth: 2 * Appearance.effectiveScale
                Layout.preferredHeight: 1
            }

            RowLayout {
                spacing: 2 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "arrow_downward"
                    iconSize: 14 * Appearance.effectiveScale
                    color: SystemData.networkRxRate > 1024 ? m3NetSpeedWrapper.contentColor : m3NetSpeedWrapper.subtextColor
                }
                Item {
                    implicitWidth: rxSpeedMetrics.width
                    implicitHeight: rxSpeedText.implicitHeight
                    TextMetrics {
                        id: rxSpeedMetrics
                        text: "999.9 MB/s"
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        font.family: Appearance.font.family.numbers
                    }
                    StyledText {
                        id: rxSpeedText
                        anchors.centerIn: parent
                        text: m3NetSpeedWrapper.formatSpeed(SystemData.networkRxRate)
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: m3NetSpeedWrapper.contentColor
                    }
                }
            }
        }
    }}

    Component { id: m3DistroIconComponent; M3StatusWrapper {
        id: leftDistroWrapper
        Layout.alignment: Qt.AlignVCenter
        m3Color: Appearance.m3colors.m3primaryContainer
        m3ContentColor: Appearance.m3colors.m3onPrimaryContainer

        readonly property bool isHost: !rootM3.isPcIsland && (Config.ready && Config.options.notifications && (Config.options.notifications.hostModule ?? "distroIcon") === "distroIcon")
        readonly property bool showNotif: !rootM3.isPcIsland && isHost && (Config.ready && Config.options.notifications && Config.options.notifications.counterStyle !== "hidden") && Notifications.unread > 0

        show: true

        Item {
            Layout.preferredWidth: Math.max(distroIcon.width, notificationCounterLeft.width)
            Layout.preferredHeight: Math.max(distroIcon.height, notificationCounterLeft.height)
            Layout.alignment: Qt.AlignVCenter

            CustomIcon {
                id: distroIcon
                anchors.centerIn: parent
                opacity: leftDistroWrapper.showNotif ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                source: {
                    if (!Config.ready || !Config.options.bar) return SystemInfo.distroIcon || "linux-symbolic";
                    let custom = Config.options.bar.distroIcon;
                    return (custom && custom !== "") ? custom : (SystemInfo.distroIcon || "linux-symbolic");
                }
                colorize: true
                color: leftDistroWrapper.contentColor
                width: (rootM3.monitor && rootM3.monitor.width && rootM3.monitor.width > 2000) ? 20 * Appearance.effectiveScale : 18 * Appearance.effectiveScale
                height: width
            }

            Item {
                id: notificationCounterLeft
                anchors.centerIn: parent
                width: bellIcon.width
                height: bellIcon.height
                opacity: leftDistroWrapper.showNotif ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                MaterialSymbol {
                    id: bellIcon
                    anchors.centerIn: parent
                    text: "notifications_active"
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: leftDistroWrapper.contentColor
                }

                StyledBadge {
                    visible: Notifications.unread > 0 && ((Config.ready && Config.options.notifications) ? Config.options.notifications.counterStyle === "counter" : false)
                    anchors.top: parent.top
                    anchors.left: parent.right
                    anchors.topMargin: -4 * Appearance.effectiveScale
                    anchors.leftMargin: -12 * Appearance.effectiveScale
                    count: Notifications.unread
                }
            }
        }
    }}

    Component { id: m3SysTrayComponent; M3StatusWrapper {
        show: SystemTray.items.values.length > 0
        Layout.alignment: Qt.AlignVCenter
        m3Color: Appearance.m3colors.m3secondaryContainer
        m3ContentColor: Appearance.m3colors.m3onSecondaryContainer

        StatusBarTray {
            Layout.alignment: Qt.AlignVCenter
        }
    }}

    Component { id: m3VpnKeyComponent; Item { visible: false; implicitWidth: 0; implicitHeight: 0 } }

    Component { id: m3BatteryComponent; M3StatusWrapper {
        id: batteryWrapper
        Layout.alignment: Qt.AlignVCenter
        m3Color: Appearance.m3colors.m3primaryContainer
        m3ContentColor: Appearance.m3colors.m3onPrimaryContainer
        show: Battery.available

        BatteryIndicator {
            Layout.alignment: Qt.AlignVCenter
            color: batteryWrapper.m3ContentColor
        }
    }}

    Component { id: m3StatusIconsGroupComponent; M3StatusWrapper {
        id: rightQuickSettingsWrapper
        Layout.alignment: Qt.AlignVCenter
        m3Color: Appearance.m3colors.m3tertiaryContainer
        m3ContentColor: Appearance.m3colors.m3onTertiaryContainer

        readonly property bool isHost: !rootM3.isPcIsland && (Config.ready && Config.options.notifications && Config.options.notifications.hostModule === "statusIconsGroup")
        readonly property bool showNotifBadge: !rootM3.isPcIsland && isHost && (Config.options.notifications.counterStyle ?? "counter") !== "hidden" && Notifications.unread > 0

        // Unread Notification Badge Item (when hosted on Status Icons Group)
        Item {
            visible: rightQuickSettingsWrapper.showNotifBadge
            Layout.preferredWidth: 16 * Appearance.effectiveScale
            Layout.preferredHeight: 16 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter

            MaterialSymbol {
                anchors.centerIn: parent
                text: "notifications_active"
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
                color: rightQuickSettingsWrapper.m3ContentColor
            }

            StyledBadge {
                visible: Notifications.unread > 0 && ((Config.ready && Config.options.notifications ? Config.options.notifications.counterStyle : "counter") === "counter")
                anchors.top: parent.top
                anchors.left: parent.right
                anchors.topMargin: -4 * Appearance.effectiveScale
                anchors.leftMargin: -12 * Appearance.effectiveScale
                count: Notifications.unread
            }
        }

        MaterialSymbol {
            visible: Network.warpConnected
            text: "key"
            iconSize: 16 * Appearance.effectiveScale
            fill: 1
            color: rightQuickSettingsWrapper.m3ContentColor
            Layout.alignment: Qt.AlignVCenter
        }

        // DND Indicator
        MaterialSymbol {
            visible: Notifications.silent
            text: "notifications_paused"
            iconSize: 16 * Appearance.effectiveScale
            fill: 1
            color: rightQuickSettingsWrapper.m3ContentColor
            Layout.alignment: Qt.AlignVCenter
        }

        MaterialSymbol {
            visible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
            text: Audio.muted || Audio.volume === 0 ? "volume_off" : (Audio.volume > 0.3 ? "volume_up" : "volume_down")
            iconSize: 16 * Appearance.effectiveScale
            fill: 1
            color: rightQuickSettingsWrapper.m3ContentColor
            Layout.alignment: Qt.AlignVCenter
        }

        NetworkIcon {
            overrideBackground: Network.materialSymbolBackground
            overrideForeground: Network.materialSymbol
            iconSize: 16 * Appearance.effectiveScale
            color: rightQuickSettingsWrapper.contentColor
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            visible: BluetoothStatus.available
            spacing: 2 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter
            
            MaterialSymbol {
                text: BluetoothStatus.materialSymbol
                iconSize: 16 * Appearance.effectiveScale
                fill: BluetoothStatus.connected ? 1 : 0
                color: rightQuickSettingsWrapper.contentColor
            }

            Rectangle {
                readonly property var device: BluetoothStatus.connectedDevices.length > 0 ? BluetoothStatus.connectedDevices[0] : null
                visible: BluetoothStatus.connected && device && device.batteryAvailable
                width: 3 * Appearance.effectiveScale
                height: 12 * Appearance.effectiveScale
                radius: 1.5 * Appearance.effectiveScale
                color: rightQuickSettingsWrapper.subtextColor
                Layout.alignment: Qt.AlignVCenter
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * (parent.device ? parent.device.battery : 0)
                    radius: 1.5 * Appearance.effectiveScale
                    color: rightQuickSettingsWrapper.contentColor
                }
            }
        }
    }}

    Component { id: m3ClockComponent; M3StatusWrapper {
        id: m3ClockWrapper
        show: true
        Layout.alignment: Qt.AlignVCenter
        m3Color: Appearance.m3colors.m3primaryContainer
        m3ContentColor: Appearance.m3colors.m3onPrimaryContainer

        RowLayout {
            id: m3ClockPill
            spacing: 4 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter

            property var timeParts: DateTime.currentTime.split(/[: ]/)
            property string hours: timeParts[0] ?? "00"
            property string minutes: timeParts[1] ?? "00"
            property string ampm: timeParts[2] ?? ""

            StyledText {
                font.family: Appearance.font.family.numbers
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.m3colors.m3onPrimaryContainer
                text: DateTime.currentDate
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.preferredWidth: clockTimeText.implicitWidth + (16 * Appearance.effectiveScale)
                Layout.preferredHeight: 24 * Appearance.effectiveScale
                radius: height / 2
                color: Appearance.m3colors.m3primary
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: clockTimeText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onPrimary
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: m3ClockPill.ampm !== "" ? m3ClockPill.hours.padStart(2, "0") + ":" + m3ClockPill.minutes.padStart(2, "0") : DateTime.currentTime
                    font.family: Appearance.font.family.numbers
                    font.features: { "tnum": 1 }
                }
            }

            Rectangle {
                visible: m3ClockPill.ampm !== ""
                z: 1
                Layout.preferredWidth: ampmText.implicitWidth + (8 * Appearance.effectiveScale)
                Layout.preferredHeight: 24 * Appearance.effectiveScale
                radius: height / 2
                color: Appearance.m3colors.m3tertiaryContainer
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: -10 * Appearance.effectiveScale

                StyledText {
                    id: ampmText
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3onTertiaryContainer
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: m3ClockPill.ampm
                }
            }
        }
    }}

    Component { id: m3WorkspaceIndicatorComponent; M3StatusWrapper {
        Layout.alignment: Qt.AlignVCenter
        show: true
        m3Color: Appearance.m3colors.m3surfaceContainerHigh
        m3ContentColor: Appearance.m3colors.m3onSurfaceVariant
        WorkspaceIndicator {
            Layout.alignment: Qt.AlignVCenter
            monitor: rootM3.monitor
            forcedStyle: "unified"
        }
    }}

    function getM3ModuleComponent(name) {
        switch (name) {
            case "distroIcon": return m3DistroIconComponent;
            case "activeWindow": return m3ActiveWindowComponent;
            case "systemMonitor": return m3SysMonComponent;
            case "networkSpeed": return m3NetSpeedComponent;
            case "sysTray": return m3SysTrayComponent;
            case "vpnWarpKey": return m3VpnKeyComponent;
            case "battery": return m3BatteryComponent;
            case "statusIconsGroup": return m3StatusIconsGroupComponent;
            case "clock": return m3ClockComponent;
            case "workspaceIndicator": return m3WorkspaceIndicatorComponent;
            default: return null;
        }
    }

    function isM3ModuleVisible(name) {
        if (name === "sysTray") return SystemTray.items.values.length > 0;
        if (name === "vpnWarpKey") return false;
        if (name === "battery") return Battery.available;
        if (name === "networkSpeed") return Config.ready && Config.options.bar && Config.options.bar.show_network_speed;
        return true;
    }

    // ── Click Areas ──
    FocusedScrollMouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 3
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        propagateComposedEvents: true
        onClicked: {
            GlobalStates.activeScreen = rootM3.QsWindow.window.screen;
            GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen;
        }
        onScrollUp: Brightness.increaseBrightness()
        onScrollDown: Brightness.decreaseBrightness()
        onMovedAway: {}

        ScrollHint {
            hovered: parent.hovered
            icon: "light_mode"
            tooltipText: I18nService.tr("Scroll to change brightness")
            side: "left"
            anchors.left: parent.left
            anchors.leftMargin: rootM3.isCentered ? rootM3.sidePadding : 4 * Appearance.effectiveScale
            anchors.verticalCenter: parent.verticalCenter
            color: rootM3.contentColor
        }
    }

    FocusedScrollMouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 3
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        propagateComposedEvents: true
        onClicked: {
            GlobalStates.activeScreen = rootM3.QsWindow.window.screen;
            GlobalStates.quickSettingsOpen = !GlobalStates.quickSettingsOpen;
        }
        onScrollUp: Audio.incrementVolume()
        onScrollDown: Audio.decrementVolume()
        onMovedAway: {}

        ScrollHint {
            hovered: parent.hovered
            icon: "volume_up"
            tooltipText: I18nService.tr("Scroll to change volume")
            side: "right"
            anchors.right: parent.right
            anchors.rightMargin: rootM3.isCentered ? rootM3.sidePadding : 4 * Appearance.effectiveScale
            anchors.verticalCenter: parent.verticalCenter
            color: rootM3.contentColor
        }
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            GlobalStates.activeScreen = rootM3.QsWindow.window.screen;
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }
    }

    // ── Left Cluster ──
    Rectangle {
        id: leftClusterCard
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: rootM3.sidePadding + (rootM3.isCentered ? 12 * Appearance.effectiveScale : 0)
        height: leftCluster.implicitHeight + (8 * Appearance.effectiveScale)
        width: leftCluster.implicitWidth + (8 * Appearance.effectiveScale)
        radius: height / 2
        color: Appearance.m3colors.m3surfaceContainer
        
        RowLayout {
            id: leftCluster
            anchors.centerIn: parent
            spacing: 4 * Appearance.effectiveScale

            Repeater {
                model: {
                    let mods = (Config.ready && Config.options.statusBar && Config.options.statusBar.leftModules) ? Array.from(Config.options.statusBar.leftModules) : ["distroIcon", "activeWindow", "systemMonitor"];
                    return mods.filter(m => rootM3.isM3ModuleVisible(m));
                }
                delegate: Loader {
                    id: leftModLoader
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: rootM3.getM3ModuleComponent(modelData)
                }
            }
        }
    }

    // ── Center Cluster ──
    Rectangle {
        id: centerClusterCard
        anchors.centerIn: parent
        
        readonly property real padding: Math.round(4 * Appearance.effectiveScale)
        readonly property real spacing: Math.round(4 * Appearance.effectiveScale)
        
        readonly property real timePillWidth: centerTimeWrapper.visible ? centerTimeWrapper.implicitWidth : 0
        readonly property real datePillWidth: centerDateWrapper.visible ? centerDateWrapper.implicitWidth : 0
        readonly property real sidePillWidth: Math.round(Math.max(timePillWidth, datePillWidth))
        readonly property real islandWidth: rootM3.isPcIsland ? Math.round(pcIslandM3.implicitWidth) : Math.round(dynamicIsland.pill.width)
        
        height: Math.round(32 * Appearance.effectiveScale) + (padding * 2)
        width: rootM3.isPcIsland ? islandWidth : (sidePillWidth > 0 ? ((sidePillWidth * 2) + islandWidth + (spacing * 2) + (padding * 2)) : (islandWidth + (padding * 2)))
        radius: height / 2
        color: rootM3.isPcIsland ? "transparent" : Appearance.m3colors.m3surfaceContainer
        border.width: rootM3.isPcIsland ? 0 : 0

        // Time Pill (Left)
        M3StatusWrapper {
            id: centerTimeWrapper
            width: centerClusterCard.sidePillWidth
            anchors.left: parent.left
            anchors.leftMargin: centerClusterCard.padding
            anchors.verticalCenter: parent.verticalCenter
            show: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "clock"
            m3Color: Appearance.m3colors.m3primaryContainer
            m3ContentColor: Appearance.m3colors.m3onPrimaryContainer

            StyledText {
                text: DateTime.currentTime
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Normal
                color: centerTimeWrapper.contentColor
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        // Island (Center) — PcIsland replaces DynamicIsland when active
        Item {
            id: islandHost
            width: rootM3.isPcIsland ? pcIslandM3.implicitWidth : centerClusterCard.islandWidth
            height: rootM3.isPcIsland ? pcIslandM3.pill.height : Math.round(dynamicIsland.pill.height)
            anchors.centerIn: parent
            visible: !rootM3.isPcIsland || true

            DynamicIsland {
                id: dynamicIsland
                visible: !rootM3.isPcIsland
                forcedStyle: "m3"
                anchors.centerIn: parent
                monitor: rootM3.monitor
                indicatorWidth: wsIndicator.implicitWidth
                indicatorStyle: wsIndicator.indicatorStyle
            }
            WorkspaceIndicator {
                id: wsIndicator
                visible: !rootM3.isPcIsland
                anchors.centerIn: parent
                monitor: rootM3.monitor
                z: 10
            }
            PcDynamicIsland.PcDynamicIsland {
                id: pcIslandM3
                visible: rootM3.isPcIsland
                insideM3Card: true
                anchors.centerIn: parent
            }
        }

        // Date Pill (Right)
        M3StatusWrapper {
            id: centerDateWrapper
            width: centerClusterCard.sidePillWidth
            anchors.right: parent.right
            anchors.rightMargin: centerClusterCard.padding
            anchors.verticalCenter: parent.verticalCenter
            show: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "clock"
            m3Color: Appearance.m3colors.m3primaryContainer
            m3ContentColor: Appearance.m3colors.m3onPrimaryContainer

            StyledText {
                text: DateTime.currentDate
                font.pixelSize: Appearance.font.pixelSize.small
                font.family: Appearance.font.family.numbers
                font.weight: Font.Normal
                color: centerDateWrapper.contentColor
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }
    }

    // ── Right Cluster ──
    Rectangle {
        id: rightClusterCard
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: rootM3.sidePadding + (rootM3.isCentered ? 12 * Appearance.effectiveScale : 0)
        height: rightCluster.implicitHeight + (8 * Appearance.effectiveScale)
        width: rightCluster.implicitWidth + (8 * Appearance.effectiveScale)
        radius: height / 2
        color: Appearance.m3colors.m3surfaceContainer
        
        RowLayout {
            id: rightCluster
            anchors.centerIn: parent
            spacing: 4 * Appearance.effectiveScale

            Repeater {
                model: {
                    let mods = (Config.ready && Config.options.statusBar && Config.options.statusBar.rightModules) ? Array.from(Config.options.statusBar.rightModules) : ["networkSpeed", "sysTray", "statusIconsGroup", "battery"];
                    return mods.filter(m => rootM3.isM3ModuleVisible(m));
                }
                delegate: Loader {
                    id: modLoader
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: rootM3.getM3ModuleComponent(modelData)
                }
            }

            // Privacy Indicator (Rightmost inside cluster, matching M3 Style)
            M3StatusWrapper {
                id: m3PrivacyWrapper
                Layout.alignment: Qt.AlignVCenter
                show: (Config.ready && Config.options.privacy && Config.options.privacy.enable) ? Privacy.anyActive : false
                m3Color: Appearance.m3colors.m3primary
                m3ContentColor: Appearance.m3colors.m3onPrimary

                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    Layout.alignment: Qt.AlignVCenter
                    
                    MaterialSymbol {
                        visible: Privacy.microphoneActive
                        text: "mic"
                        iconSize: 16 * Appearance.effectiveScale
                        color: m3PrivacyWrapper.contentColor
                        fill: 1
                    }

                    MaterialSymbol {
                        visible: Privacy.cameraActive
                        text: "videocam"
                        iconSize: 16 * Appearance.effectiveScale
                        color: m3PrivacyWrapper.contentColor
                        fill: 1
                    }

                    MaterialSymbol {
                        visible: Privacy.screensharingActive
                        text: "screen_share"
                        iconSize: 16 * Appearance.effectiveScale
                        color: m3PrivacyWrapper.contentColor
                        fill: 1
                    }
                }
            }
        }
    }
}
