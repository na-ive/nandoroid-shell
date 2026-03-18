import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

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

    readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
    readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth : 1200
    
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

    readonly property real targetSidePadding: isCentered ? Math.max(12, (root.width - centeredWidth) / 2) : 12
    property real sidePadding: targetSidePadding
    Behavior on sidePadding { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }

    // ── Click-to-close backdrop (invisible, catches unfocused clicks) ──
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.closeAllPanels()
    }


    // Left 35% of the screen clicks open Notifications
    FocusedScrollMouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.35
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
            tooltipText: "Scroll to change brightness"
            side: "left"
            anchors.left: parent.left
            anchors.leftMargin: root.isCentered ? root.sidePadding : 4
            anchors.verticalCenter: parent.verticalCenter
            color: root.contentColor
        }
    }

    // Right 35% of the screen clicks open Quick Settings
    FocusedScrollMouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.35
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
            tooltipText: "Scroll to change volume"
            side: "right"
            anchors.right: parent.right
            anchors.rightMargin: root.isCentered ? root.sidePadding : 4
            anchors.verticalCenter: parent.verticalCenter
            color: root.contentColor
        }
    }

    // Middle 30% of the screen clicks open Dashboard
    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * 0.30
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
        anchors.leftMargin: root.sidePadding + (root.isCentered ? 12 : 0)
        spacing: 8

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: leftClusterContent.implicitWidth

            RowLayout {
                id: leftClusterContent
                anchors.fill: parent
                spacing: 10

                // Distro icon (config-driven visibility)
                CustomIcon {
                    visible: Config.ready && Config.options.bar ? Config.options.bar.show_distro_icon : true
                    source: {
                        if (!Config.ready || !Config.options.bar) return SystemInfo.distroIcon || "linux-symbolic";
                        let custom = Config.options.bar.distroIcon;
                        return (custom && custom !== "") ? custom : (SystemInfo.distroIcon || "linux-symbolic");
                    }
                    colorize: true
                    color: root.contentColor
                    width: (root.monitor && root.monitor.width && root.monitor.width > 2000) ? 20 : 18
                    height: (root.monitor && root.monitor.width && root.monitor.width > 2000) ? 20 : 18
                    Layout.alignment: Qt.AlignVCenter
                }

                // Workspace indicator (moved to center)
                // WorkspaceIndicator { ... }

                // Active window title
                ActiveWindowTitle {
                    Layout.alignment: Qt.AlignVCenter
                    // Dynamically calculate max width: proportional to HUD width in centered mode
                    // Use root.width for stable calculation instead of parent.width
                    Layout.maximumWidth: root.isCentered ? (root.centeredWidth * 0.2) : Math.min(400, root.width * 0.25)
                    monitor: root.monitor
                    color: root.contentColor
                    subtextColor: root.subtextColor
                }
            }
        }
    }

    // ── Center Cluster (Dynamic Island host) ──
    DynamicIsland {
        id: dynamicIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        monitor: root.monitor
        indicatorWidth: wsIndicator.implicitWidth
    }

    // Time (Left of Notch)
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        x: dynamicIsland.x + dynamicIsland.pill.x - width - 16
        text: DateTime.currentTime
        font.pixelSize: 14 // Bigger font
        font.weight: Font.DemiBold
        color: root.contentColor
    }

    // Date (Right of Notch)
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        x: dynamicIsland.x + dynamicIsland.pill.x + dynamicIsland.pill.width + 16
        text: DateTime.currentDate
        font.pixelSize: 14 // Bigger font
        font.weight: Font.DemiBold
        color: root.contentColor
    }

    // --- Absolute Center Workspace Indicator ---
    WorkspaceIndicator {
        id: wsIndicator
        anchors.centerIn: parent
        monitor: root.monitor
        z: 10 // Ensure it's above the island background
    }


    // ── Right Cluster ──
    RowLayout {
        id: rightCluster
        anchors.right: privacyIndicator.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 8
        spacing: 4

        RowLayout {
            id: rightClusterContent
            spacing: 6

            // Network Speed Meter
            NetworkSpeedMeter {
                Layout.alignment: Qt.AlignVCenter
                color: root.contentColor
                subtextColor: root.subtextColor
            }

            // System Tray (Apps tray will be to the left of this)
            StatusBarTray {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 4
            }

            // VPN / WARP Key Icon
            MaterialSymbol {
                visible: Network.warpConnected
                text: "key"
                iconSize: 16
                fill: 1
                color: root.contentColor
            }

            // Notification counter (now moved before WiFi)
            Item {
                id: notificationCounter
                readonly property string style: (Config.ready && Config.options.notifications) ? Config.options.notifications.counterStyle : "counter"
                
                visible: style !== "hidden" && Notifications.unread > 0
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    id: bellIcon
                    anchors.centerIn: parent
                    text: "notifications_active"
                    iconSize: 16
                    fill: 1
                    color: root.contentColor
                }

                Rectangle {
                    visible: parent.style === "counter"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: -2
                    anchors.rightMargin: -2
                    width: Math.max(12, badgeText.implicitWidth + 4)
                    height: 12
                    radius: 6
                    color: bellIcon.color // Match the bell icon color

                    StyledText {
                        id: badgeText
                        anchors.centerIn: parent
                        text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        color: showBackground ? Appearance.m3colors.m3surface : Appearance.colors.colLayer0 // High contrast against the bell-colored badge
                    }
                }
            }

            // WiFi (real data from Network service)
            MaterialSymbol {
                text: Network.materialSymbol
                iconSize: 16
                fill: 1
                color: root.contentColor
            }

            // Bluetooth (real data from BluetoothStatus service)
            RowLayout {
                visible: BluetoothStatus.available
                spacing: 2
                MaterialSymbol {
                    text: BluetoothStatus.materialSymbol
                    iconSize: 16
                    fill: BluetoothStatus.connected ? 1 : 0
                    color: root.contentColor
                }

                // Vertical Battery Bar
                Rectangle {
                    readonly property var device: BluetoothStatus.connectedDevices.length > 0 ? BluetoothStatus.connectedDevices[0] : null
                    visible: BluetoothStatus.connected && device && device.batteryAvailable
                    width: 3
                    height: 12
                    radius: 1.5
                    color: root.subtextColor
                    Layout.alignment: Qt.AlignVCenter
                    
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * (parent.device ? parent.device.battery : 0)
                        radius: 1.5
                        color: root.contentColor
                    }
                }
            }

            // Battery (Clipped Progress Bar style)
            BatteryIndicator {
                visible: Battery.available
                Layout.alignment: Qt.AlignVCenter
                color: root.contentColor
            }

            // DND Indicator
            MaterialSymbol {
                visible: Notifications.silent
                text: "notifications_paused"
                iconSize: 16
                fill: 1
                color: root.contentColor
                Layout.alignment: Qt.AlignVCenter
            }


        }
    }


    // Privacy Indicator (Absolute Far Right)
    PrivacyIndicator {
        id: privacyIndicator
        anchors.right: parent.right
        anchors.rightMargin: root.sidePadding + (root.isCentered ? 8 : -4)
        anchors.verticalCenter: parent.verticalCenter
    }
}
