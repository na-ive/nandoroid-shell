import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
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

    // ── Click Areas ──
    FocusedScrollMouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.35
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
            tooltipText: "Scroll to change brightness"
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
        width: parent.width * 0.35
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
            tooltipText: "Scroll to change volume"
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
        width: parent.width * 0.30
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

        // Profile / DistroIcon Card
        M3StatusWrapper {
            id: leftDistroWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3primaryContainer
            m3ContentColor: Appearance.m3colors.m3onPrimaryContainer
            
            readonly property bool isLeftPosition: Config.ready && Config.options.notifications && Config.options.notifications.position === "left"
            readonly property bool showNotif: isLeftPosition && (Config.ready && Config.options.notifications && Config.options.notifications.counterStyle !== "hidden") && Notifications.unread > 0
            readonly property bool showDistro: Config.ready && Config.options.bar ? Config.options.bar.show_distro_icon : true
            show: showDistro || showNotif

            Item {
                Layout.preferredWidth: Math.max(distroIcon.width, notificationCounterLeft.width)
                Layout.preferredHeight: Math.max(distroIcon.height, notificationCounterLeft.height)
                Layout.alignment: Qt.AlignVCenter

                CustomIcon {
                    id: distroIcon
                    anchors.centerIn: parent
                    opacity: leftDistroWrapper.showNotif ? 0 : (leftDistroWrapper.showDistro ? 1 : 0)
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

                    Rectangle {
                    visible: (Config.ready && Config.options.notifications) ? Config.options.notifications.counterStyle === "counter" : false
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -2 * Appearance.effectiveScale
                    anchors.rightMargin: -2 * Appearance.effectiveScale
                    width: Math.max(12 * Appearance.effectiveScale, badgeText.implicitWidth + 4 * Appearance.effectiveScale)
                    height: 12 * Appearance.effectiveScale
                    radius: 6 * Appearance.effectiveScale
                    color: leftDistroWrapper.contentColor

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                        font.pixelSize: Math.round(8 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: leftDistroWrapper.m3Color
                    }
                    }
                }
            }
        }

        // Active Window Card (Left)
        M3StatusWrapper {
            id: leftTitleWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3secondaryContainer
            m3ContentColor: Appearance.m3colors.m3onSecondaryContainer
            Layout.maximumWidth: rootM3.isCentered ? (rootM3.centeredWidth * (leftSysMonWrapper.visible ? 0.15 : 0.4)) : Math.min((leftSysMonWrapper.visible ? 250 : 800) * Appearance.effectiveScale, rootM3.width * (leftSysMonWrapper.visible ? 0.15 : 0.4))
            show: Config.ready && Config.options.statusBar ? (Config.options.statusBar.activeWindowPosition !== undefined ? Config.options.statusBar.activeWindowPosition : "left") === "left" : true

            ActiveWindowTitle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: rootM3.isCentered ? (rootM3.centeredWidth * (leftSysMonWrapper.visible ? 0.15 : 0.4)) : Math.min((leftSysMonWrapper.visible ? 250 : 800) * Appearance.effectiveScale, rootM3.width * (leftSysMonWrapper.visible ? 0.15 : 0.4))
                maxWidth: rootM3.isCentered ? (rootM3.centeredWidth * (leftSysMonWrapper.visible ? 0.15 : 0.4)) : Math.min((leftSysMonWrapper.visible ? 250 : 800) * Appearance.effectiveScale, rootM3.width * (leftSysMonWrapper.visible ? 0.15 : 0.4))
                monitor: rootM3.monitor
                color: leftTitleWrapper.contentColor
                subtextColor: leftTitleWrapper.subtextColor
            }
        }

        // System Monitor Card (Left)
        M3StatusWrapper {
            id: leftSysMonWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3tertiaryContainer
            m3ContentColor: Appearance.m3colors.m3onTertiaryContainer
            show: Config.ready && Config.options.statusBar ? (Config.options.statusBar.systemMonitorPosition !== undefined ? Config.options.statusBar.systemMonitorPosition : "hidden") === "left" : false

            SystemMonitorModule {
                Layout.alignment: Qt.AlignVCenter
                color: leftSysMonWrapper.contentColor
                subtextColor: leftSysMonWrapper.subtextColor
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
        readonly property real islandWidth: Math.round(dynamicIsland.pill.width)
        
        height: Math.round(32 * Appearance.effectiveScale) + (padding * 2)
        width: sidePillWidth > 0 ? ((sidePillWidth * 2) + islandWidth + (spacing * 2) + (padding * 2)) : (islandWidth + (padding * 2))
        radius: height / 2
        color: Appearance.m3colors.m3surfaceContainer

        // Time Pill (Left)
        M3StatusWrapper {
            id: centerTimeWrapper
            width: centerClusterCard.sidePillWidth
            anchors.left: parent.left
            anchors.leftMargin: centerClusterCard.padding
            anchors.verticalCenter: parent.verticalCenter
            show: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.clockPosition !== "right" : true
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

        // Island (Center)
        Item {
            id: islandHost
            width: centerClusterCard.islandWidth
            height: Math.round(dynamicIsland.pill.height)
            anchors.centerIn: parent

            DynamicIsland {
                id: dynamicIsland
                forcedStyle: "m3"
                anchors.centerIn: parent
                monitor: rootM3.monitor
                indicatorWidth: wsIndicator.implicitWidth
            }
            WorkspaceIndicator {
                id: wsIndicator
                anchors.centerIn: parent
                monitor: rootM3.monitor
                z: 10
            }
        }

        // Date Pill (Right)
        M3StatusWrapper {
            id: centerDateWrapper
            width: centerClusterCard.sidePillWidth
            anchors.right: parent.right
            anchors.rightMargin: centerClusterCard.padding
            anchors.verticalCenter: parent.verticalCenter
            show: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.clockPosition !== "right" : true
            m3Color: Appearance.m3colors.m3primaryContainer
            m3ContentColor: Appearance.m3colors.m3onPrimaryContainer

            StyledText {
                text: DateTime.currentDate
                font.pixelSize: Appearance.font.pixelSize.small
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

        // Active Window Title (Right)
        M3StatusWrapper {
            id: rightTitleWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3secondaryContainer
            m3ContentColor: Appearance.m3colors.m3onSecondaryContainer
            Layout.maximumWidth: rootM3.isCentered ? (rootM3.centeredWidth * (rightSysMonWrapper.visible ? 0.15 : 0.4)) : Math.min((rightSysMonWrapper.visible ? 250 : 800) * Appearance.effectiveScale, rootM3.width * (rightSysMonWrapper.visible ? 0.15 : 0.4))
            show: Config.ready && Config.options.statusBar ? (Config.options.statusBar.activeWindowPosition !== undefined ? Config.options.statusBar.activeWindowPosition : "left") === "right" : false

            ActiveWindowTitle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: rootM3.isCentered ? (rootM3.centeredWidth * (rightSysMonWrapper.visible ? 0.15 : 0.4)) : Math.min((rightSysMonWrapper.visible ? 250 : 800) * Appearance.effectiveScale, rootM3.width * (rightSysMonWrapper.visible ? 0.15 : 0.4))
                maxWidth: rootM3.isCentered ? (rootM3.centeredWidth * (rightSysMonWrapper.visible ? 0.15 : 0.4)) : Math.min((rightSysMonWrapper.visible ? 250 : 800) * Appearance.effectiveScale, rootM3.width * (rightSysMonWrapper.visible ? 0.15 : 0.4))
                monitor: rootM3.monitor
                color: rightTitleWrapper.contentColor
                subtextColor: rightTitleWrapper.subtextColor
                textAlignment: Text.AlignRight
            }
        }

        // System Monitor Card (Right)
        M3StatusWrapper {
            id: rightSysMonWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3tertiaryContainer
            m3ContentColor: Appearance.m3colors.m3onTertiaryContainer
            show: Config.ready && Config.options.statusBar ? (Config.options.statusBar.systemMonitorPosition !== undefined ? Config.options.statusBar.systemMonitorPosition : "hidden") === "right" : false

            SystemMonitorModule {
                Layout.alignment: Qt.AlignVCenter
                color: rightSysMonWrapper.contentColor
                subtextColor: rightSysMonWrapper.subtextColor
            }
        }

        // Network Speed Meter
        M3StatusWrapper {
            id: rightNetSpeedWrapper
            show: Config.ready && Config.options.bar ? Config.options.bar.show_network_speed : false
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3surfaceContainerHigh
            m3ContentColor: Appearance.m3colors.m3onSurfaceVariant

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8 * Appearance.effectiveScale
                Layout.rightMargin: 8 * Appearance.effectiveScale
                spacing: 4 * Appearance.effectiveScale

                function formatSpeed(bytes) {
                    const k = 1024;
                    const mt = 1024 * 1024;
                    if (bytes >= mt) return (bytes / mt).toFixed(1) + " MB/s";
                    return (bytes / k).toFixed(1) + " KB/s";
                }

                // TX
                RowLayout {
                    spacing: 2 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "arrow_upward"
                        iconSize: 14 * Appearance.effectiveScale
                        color: SystemData.networkTxRate > 1024 ? rightNetSpeedWrapper.contentColor : rightNetSpeedWrapper.subtextColor
                    }
                    StyledText {
                        text: parent.parent.formatSpeed(SystemData.networkTxRate)
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: rightNetSpeedWrapper.contentColor
                    }
                }

                // Divider/Spacer
                Item {
                    Layout.preferredWidth: 2 * Appearance.effectiveScale
                    Layout.preferredHeight: 1
                }

                // RX
                RowLayout {
                    spacing: 2 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "arrow_downward"
                        iconSize: 14 * Appearance.effectiveScale
                        color: SystemData.networkRxRate > 1024 ? rightNetSpeedWrapper.contentColor : rightNetSpeedWrapper.subtextColor
                    }
                    StyledText {
                        text: parent.parent.formatSpeed(SystemData.networkRxRate)
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: rightNetSpeedWrapper.contentColor
                    }
                }
            }
        }

        // System Tray / VPN / Right Icons
        M3StatusWrapper {
            id: rightTrayWrapper
            show: SystemTray.items.values.length > 0 || networkWarpIcon.visible
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3secondaryContainer
            m3ContentColor: Appearance.m3colors.m3onSecondaryContainer

            StatusBarTray {
                id: statusBarTray
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 4 * Appearance.effectiveScale
            }

            MaterialSymbol {
                id: networkWarpIcon
                visible: Network.warpConnected
                text: "key"
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
                color: rightTrayWrapper.contentColor
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Battery
        M3StatusWrapper {
            id: rightBatteryWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3primaryContainer
            m3ContentColor: Appearance.m3colors.m3onPrimaryContainer
            show: Battery.available

            BatteryIndicator {
                Layout.alignment: Qt.AlignVCenter
                color: rightBatteryWrapper.contentColor
            }
        }

        // Quick Settings (Audio/WiFi/BT/Clock if right-aligned)
        M3StatusWrapper {
            id: rightQuickSettingsWrapper
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3tertiaryContainer
            m3ContentColor: Appearance.m3colors.m3onTertiaryContainer
            
            Item {
                id: notificationCounterRight
                readonly property string style: (Config.ready && Config.options.notifications) ? Config.options.notifications.counterStyle : "counter"
                readonly property bool isRightPosition: !Config.ready || !Config.options.notifications || Config.options.notifications.position !== "left"
                readonly property bool show: isRightPosition && style !== "hidden" && Notifications.unread > 0
                
                visible: opacity > 0 || Layout.preferredWidth > 0
                opacity: show ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                Layout.preferredWidth: show ? bellIconRight.width : 0
                Behavior on Layout.preferredWidth { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                Layout.preferredHeight: bellIconRight.height
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    id: bellIconRight
                    anchors.centerIn: parent
                    text: "notifications_active"
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: rightQuickSettingsWrapper.contentColor
                }

                Rectangle {
                    visible: parent.style === "counter"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -2 * Appearance.effectiveScale
                    anchors.rightMargin: -2 * Appearance.effectiveScale
                    width: Math.max(12 * Appearance.effectiveScale, badgeTextRight.implicitWidth + 4 * Appearance.effectiveScale)
                    height: 12 * Appearance.effectiveScale
                    radius: 6 * Appearance.effectiveScale
                    color: rightQuickSettingsWrapper.contentColor

                    StyledText {
                        id: badgeTextRight
                        anchors.centerIn: parent
                        text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                        font.pixelSize: Math.round(8 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: rightQuickSettingsWrapper.m3Color
                    }
                }
            }

            MaterialSymbol {
                visible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                text: Audio.muted || Audio.volume === 0 ? "volume_off" : (Audio.volume > 0.3 ? "volume_up" : "volume_down")
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
                color: rightQuickSettingsWrapper.contentColor
                Layout.alignment: Qt.AlignVCenter
            }

            MaterialSymbol {
                text: Network.materialSymbol
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
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
            MaterialSymbol {
                visible: Notifications.silent
                text: "notifications_paused"
                iconSize: 16 * Appearance.effectiveScale
                fill: 1
                color: rightQuickSettingsWrapper.contentColor
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Clock (Right-aligned position)
        M3StatusWrapper {
            id: rightClockWrapper
            show: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.clockPosition === "right" : false
            Layout.alignment: Qt.AlignVCenter
            m3Color: Appearance.m3colors.m3primaryContainer
            m3ContentColor: Appearance.m3colors.m3onPrimaryContainer
            
            ColumnLayout {
                spacing: -2 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 4 * Appearance.effectiveScale
                Layout.rightMargin: 4 * Appearance.effectiveScale

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: rightClockWrapper.subtextColor
                    text: DateTime.currentDate
                    font.weight: Font.Normal
                    Layout.alignment: Qt.AlignRight
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: rightClockWrapper.contentColor
                    font.weight: Font.Normal
                    text: DateTime.currentTime
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

        // Privacy Indicator (Rightmost inside cluster, matching M3 Style)
        M3StatusWrapper {
            id: m3PrivacyWrapper
            Layout.alignment: Qt.AlignVCenter
            show: Privacy.anyActive
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
