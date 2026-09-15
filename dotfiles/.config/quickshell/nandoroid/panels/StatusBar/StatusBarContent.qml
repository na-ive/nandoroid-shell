import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import "PcDynamicIsland" as PcDynamicIsland

/**
 * Status bar content layout with Android-style gradient.
 * Left: distro icon + workspace pills + active window → triggers Notification Center
 * Center: clock + date
 * Right: system status icons → triggers Quick Settings
 */
Item {
    id: root
    property int monitorIndex: 0
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window ? root.QsWindow.window.screen : null)

    readonly property bool isPcIsland: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "pcIsland"
    readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
    readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200 * Appearance.effectiveScale
    
    // Dynamic background detection for color switching
    readonly property int bgStyle: (Config.ready && Config.options.statusBar) ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
    readonly property int activeWorkspaceId: monitor?.activeWorkspace?.id ?? -1
    readonly property bool hasTiledWindows: {
        if (bgStyle !== 2 || activeWorkspaceId === -1) return false;
        return HyprlandData.windowList.some(w => 
            w.workspace.id === activeWorkspaceId && 
            !w.floating && 
            w.monitor === monitorIndex
        );
    }
    readonly property bool showBackground: bgStyle === 1 || (bgStyle === 2 && hasTiledWindows)

    // Selection of the final color based on actual visibility
    property color contentColor: showBackground ? Appearance.m3colors.m3onSurface : Appearance.colors.colStatusBarText
    property color subtextColor: showBackground ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colStatusBarSubtext

    Behavior on contentColor { ColorAnimation { duration: 300 } }
    Behavior on subtextColor { ColorAnimation { duration: 300 } }

    readonly property real targetSidePadding: isCentered ? Math.max(12 * Appearance.effectiveScale, (root.width - centeredWidth) / 2) : 12 * Appearance.effectiveScale
    property real sidePadding: targetSidePadding
    Behavior on sidePadding { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

    // Universal Module Component Library (Root Scoped)
    Component { id: activeWindowComponent; ActiveWindowTitle {
        id: activeWinTitle
        readonly property bool isRight: Config.ready && Config.options.statusBar && Config.options.statusBar.rightModules ? Config.options.statusBar.rightModules.includes("activeWindow") : false
        readonly property bool hasSysMon: {
            if (!Config.ready || !Config.options.statusBar) return false;
            let lefts = Config.options.statusBar.leftModules || [];
            let rights = Config.options.statusBar.rightModules || [];
            return lefts.includes("systemMonitor") || rights.includes("systemMonitor");
        }
        textAlignment: isRight ? Text.AlignRight : Text.AlignLeft
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        Layout.maximumWidth: {
            let maxW = activeWinTitle.hasSysMon ? 180 * Appearance.effectiveScale : 400 * Appearance.effectiveScale;
            let maxPct = activeWinTitle.hasSysMon ? 0.12 : 0.25;
            return Math.min(implicitWidth, Math.min(maxW, root.width * maxPct));
        }
        maxWidth: {
            let maxW = activeWinTitle.hasSysMon ? 180 * Appearance.effectiveScale : 400 * Appearance.effectiveScale;
            let maxPct = activeWinTitle.hasSysMon ? 0.12 : 0.25;
            return Math.min(maxW, root.width * maxPct);
        }
        monitor: root.monitor
        color: root.contentColor
        subtextColor: root.subtextColor
    }}

    Component { id: sysMonComponent; SystemMonitorModule {
        Layout.alignment: Qt.AlignVCenter
        color: root.contentColor
        subtextColor: root.subtextColor
    }}

    Component { id: netSpeedComponent; NetworkSpeedMeter {
        Layout.alignment: Qt.AlignVCenter
        color: root.contentColor
        subtextColor: root.subtextColor
    }}

    Component { id: sysTrayComponent; StatusBarTray {
        Layout.alignment: Qt.AlignVCenter
    }}

    Component { id: vpnKeyComponent; Item { visible: false; implicitWidth: 0; implicitHeight: 0 } }

    Component { id: batteryComponent; BatteryIndicator {
        visible: Battery.available
        Layout.alignment: Qt.AlignVCenter
        color: root.contentColor
    }}

    Component { id: statusIconsGroupComponent; RowLayout {
        spacing: 6 * Appearance.effectiveScale
        Layout.alignment: Qt.AlignVCenter

        readonly property bool isHost: !root.isPcIsland && (Config.ready && Config.options.notifications && Config.options.notifications.hostModule === "statusIconsGroup")
        readonly property bool showNotifBadge: !root.isPcIsland && isHost && (Config.options.notifications.counterStyle ?? "counter") !== "hidden" && Notifications.unread > 0

        // Unread Notification Badge Item (when hosted on Status Icons Group)
        Item {
            visible: parent.showNotifBadge
            Layout.preferredWidth: 16 * Appearance.effectiveScale
            Layout.preferredHeight: 16 * Appearance.effectiveScale
            Layout.alignment: Qt.AlignVCenter

            MaterialSymbol {
                anchors.centerIn: parent
                text: "notifications_active"
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
                color: root.contentColor
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
            color: root.contentColor
        }

        // DND Indicator
        MaterialSymbol {
            visible: Notifications.silent
            text: "notifications_paused"
            iconSize: 16 * Appearance.effectiveScale
            fill: 1
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
        }

        MaterialSymbol {
            visible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
            text: Audio.muted || Audio.volume === 0 ? "volume_off" : (Audio.volume > 0.3 ? "volume_up" : "volume_down")
            iconSize: 16 * Appearance.effectiveScale
            fill: 1
            color: root.contentColor
        }

        NetworkIcon {
            overrideBackground: Network.materialSymbolBackground
            overrideForeground: Network.materialSymbol
            iconSize: 16 * Appearance.effectiveScale
            color: root.contentColor
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            visible: BluetoothStatus.available
            spacing: 2 * Appearance.effectiveScale
            MaterialSymbol {
                text: BluetoothStatus.materialSymbol
                iconSize: 16 * Appearance.effectiveScale
                fill: BluetoothStatus.connected ? 1 : 0
                color: root.contentColor
            }

            Rectangle {
                readonly property var device: BluetoothStatus.connectedDevices.length > 0 ? BluetoothStatus.connectedDevices[0] : null
                visible: BluetoothStatus.connected && device && device.batteryAvailable
                width: 3 * Appearance.effectiveScale
                height: 12 * Appearance.effectiveScale
                radius: 1.5 * Appearance.effectiveScale
                color: root.subtextColor
                Layout.alignment: Qt.AlignVCenter
                
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * (parent.device ? parent.device.battery : 0)
                    radius: 1.5 * Appearance.effectiveScale
                    color: root.contentColor
                }
            }
        }
    }}

    Component { id: clockComponent; RowLayout {
        spacing: 6 * Appearance.effectiveScale
        Layout.alignment: Qt.AlignVCenter
        visible: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centerModule !== "clock" : false

        StyledText {
            text: DateTime.currentDate + " • " + DateTime.currentTime
            font.family: Appearance.font.family.numbers
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.Medium
            color: root.contentColor
        }
    }}

    Component { id: workspaceIndicatorComponent; WorkspaceIndicator {
        Layout.alignment: Qt.AlignVCenter
        monitor: root.monitor
        forcedStyle: "unified"
    }}

    Component { id: distroIconComponent; Item {
        implicitWidth: Math.max(distroIconImg.width, 20 * Appearance.effectiveScale)
        implicitHeight: Math.max(distroIconImg.height, 20 * Appearance.effectiveScale)
        Layout.alignment: Qt.AlignVCenter

        readonly property bool isHost: !root.isPcIsland && (Config.ready && Config.options.notifications && (Config.options.notifications.hostModule ?? "distroIcon") === "distroIcon")
        readonly property bool showNotif: !root.isPcIsland && isHost && (Config.options.notifications.counterStyle ?? "counter") !== "hidden" && Notifications.unread > 0

        CustomIcon {
            id: distroIconImg
            anchors.centerIn: parent
            opacity: parent.showNotif ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            source: {
                if (!Config.ready || !Config.options.bar) return SystemInfo.distroIcon || "linux-symbolic";
                let custom = Config.options.bar.distroIcon;
                return (custom && custom !== "") ? custom : (SystemInfo.distroIcon || "linux-symbolic");
            }
            colorize: true
            color: root.contentColor
            width: (root.monitor && root.monitor.width && root.monitor.width > 2000) ? 20 * Appearance.effectiveScale : 18 * Appearance.effectiveScale
            height: (root.monitor && root.monitor.width && root.monitor.width > 2000) ? 20 * Appearance.effectiveScale : 18 * Appearance.effectiveScale
        }

        Item {
            anchors.fill: parent
            opacity: parent.showNotif ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "notifications_active"
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
                color: root.contentColor
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
    }}

    function getVisibleClusterModules(moduleList) {
        if (!Config.ready || !Config.options.statusBar) return moduleList;
        let sb = Config.options.statusBar;
        let isBase = (sb.moduleStyle ?? "base") !== "m3";
        let isCentered = sb.layoutStyle === "centered";
        if (!isBase || !isCentered) return moduleList;

        let hasCollision = moduleList.includes("activeWindow") && moduleList.includes("systemMonitor");
        let currentPoints = 0;
        let maxPoints = 4;
        let visibleList = [];

        for (let i = 0; i < moduleList.length; i++) {
            let mod = moduleList[i];
            if (mod === "activeWindow" && hasCollision) {
                continue;
            }
            let weight = (mod === "systemMonitor" || mod === "activeWindow" || mod === "clock") ? 2 : 1;
            if (currentPoints + weight <= maxPoints) {
                currentPoints += weight;
                visibleList.push(mod);
            }
        }
        return visibleList;
    }

    function getModuleComponent(name) {
        switch (name) {
            case "distroIcon": return distroIconComponent;
            case "activeWindow": return activeWindowComponent;
            case "systemMonitor": return sysMonComponent;
            case "networkSpeed": return netSpeedComponent;
            case "sysTray": return sysTrayComponent;
            case "vpnWarpKey": return vpnKeyComponent;
            case "battery": return batteryComponent;
            case "statusIconsGroup": return statusIconsGroupComponent;
            case "clock": return clockComponent;
            case "workspaceIndicator": return workspaceIndicatorComponent;
            default: return null;
        }
    }

    function isModuleVisible(name) {
        if (name === "sysTray") return SystemTray.items.values.length > 0;
        if (name === "vpnWarpKey") return false;
        if (name === "battery") return Battery.available;
        if (name === "networkSpeed") return Config.ready && Config.options.bar && Config.options.bar.show_network_speed;
        return true;
    }

    // ── Click-to-close backdrop (invisible, catches unfocused clicks) ──
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.closeAllPanels()
    }


    // Left 1/3 of the screen clicks open Notifications
    FocusedScrollMouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 3
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        propagateComposedEvents: true
        onClicked: {
            GlobalStates.activeScreen = root.QsWindow.window.screen;
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
            anchors.leftMargin: root.isCentered ? root.sidePadding : 4 * Appearance.effectiveScale
            anchors.verticalCenter: parent.verticalCenter
            color: root.contentColor
        }
    }

    // Right 1/3 of the screen clicks open Quick Settings
    FocusedScrollMouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 3
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        propagateComposedEvents: true
        onClicked: {
            GlobalStates.activeScreen = root.QsWindow.window.screen;
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
            anchors.rightMargin: root.isCentered ? root.sidePadding : 4 * Appearance.effectiveScale
            anchors.verticalCenter: parent.verticalCenter
            color: root.contentColor
        }
    }

    // Middle 1/3 of the screen clicks open Dashboard
    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width / 3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            GlobalStates.activeScreen = root.QsWindow.window.screen;
            GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen;
        }
    }


    // ── Left Cluster ──
    RowLayout {
        id: leftCluster
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.sidePadding + (root.isCentered ? 12 * Appearance.effectiveScale : 0)
        spacing: 8 * Appearance.effectiveScale

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: leftClusterContent.implicitWidth

            RowLayout {
                id: leftClusterContent
                anchors.fill: parent
                spacing: 10 * Appearance.effectiveScale

                Repeater {
                    model: {
                        let mods = (Config.ready && Config.options.statusBar && Config.options.statusBar.leftModules) ? Array.from(Config.options.statusBar.leftModules) : ["distroIcon", "activeWindow", "systemMonitor"];
                        return root.getVisibleClusterModules(mods).filter(m => root.isModuleVisible(m));
                    }
                    delegate: Loader {
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: root.getModuleComponent(modelData)
                    }
                }
            }
        }
    }

    // ── Center Cluster (Dynamic Island host) ──
    // PcDynamicIsland takes over when centerModule === "pcIsland"
    Item {
        id: pcIslandHost
        visible: root.isPcIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: pcIsland.implicitWidth
        implicitHeight: pcIsland.implicitHeight
        PcDynamicIsland.PcDynamicIsland {
            id: pcIsland
            anchors.centerIn: parent
        }
    }

    DynamicIsland {
        id: dynamicIsland
        visible: !root.isPcIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        monitor: root.monitor
        indicatorWidth: wsIndicator.implicitWidth
        indicatorStyle: wsIndicator.indicatorStyle
    }

    // Time (Left of Notch) — hidden when PcIsland
    StyledText {
        visible: !root.isPcIsland && Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "clock"
        anchors.verticalCenter: parent.verticalCenter
        x: dynamicIsland.x + dynamicIsland.pill.x - width - 16 * Appearance.effectiveScale
        font.family: Appearance.font.family.numbers
        text: DateTime.currentTime
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Normal
        color: root.contentColor
    }

    // Date (Right of Notch)
    StyledText {
        visible: !root.isPcIsland && Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "clock"
        anchors.verticalCenter: parent.verticalCenter
        x: dynamicIsland.x + dynamicIsland.pill.x + dynamicIsland.pill.width + 16 * Appearance.effectiveScale
        font.family: Appearance.font.family.numbers
        text: DateTime.currentDate
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Normal
        color: root.contentColor
    }

    // --- Absolute Center Workspace Indicator (hide when PcIsland, use module instead) ---
    WorkspaceIndicator {
        id: wsIndicator
        visible: !root.isPcIsland
        anchors.centerIn: parent
        monitor: root.monitor
        z: 10
        onHoveredChanged: (hovered) => {
            if (hovered) dynamicIsland.triggerMediaHover()
        }
    }


    // ── Right Cluster ──
    RowLayout {
        id: rightCluster
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.sidePadding + (root.isCentered ? 12 * Appearance.effectiveScale : 0)
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            id: rightClusterContent
            spacing: 6 * Appearance.effectiveScale

            Repeater {
                model: {
                    let mods = (Config.ready && Config.options.statusBar && Config.options.statusBar.rightModules) ? Array.from(Config.options.statusBar.rightModules) : ["networkSpeed", "sysTray", "statusIconsGroup", "battery"];
                    return root.getVisibleClusterModules(mods).filter(m => root.isModuleVisible(m));
                }
                delegate: Loader {
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: root.getModuleComponent(modelData)
                }
            }



            // Right-aligned clock
            ColumnLayout {
                id: rightClock
                visible: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.clockPosition === "right" : false
                spacing: -2 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4 * Appearance.effectiveScale

                StyledText {
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: root.subtextColor
                    text: DateTime.currentDate
                    font.weight: Font.Normal
                    Layout.alignment: Qt.AlignRight
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.family: Appearance.font.family.numbers
                    color: root.contentColor
                    font.weight: Font.Normal
                    text: DateTime.currentTime
                    Layout.alignment: Qt.AlignRight
                }
            }

            // Privacy Indicator (Rightmost inside cluster)
            PrivacyIndicator {
                id: privacyIndicator
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
