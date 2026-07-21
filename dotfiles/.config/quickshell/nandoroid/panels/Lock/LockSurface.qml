pragma ComponentBehavior: Bound
import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Qt5Compat.GraphicalEffects
import "../NotificationCenter"
import "../StatusBar"

/**
 * Nandoroid lock screen surface — M3 Android 16 style (ii clone).
 * Features:
 * - Full-screen wallpaper with dark scrim
 * - Three "Surface Container" colored pills (islands)
 * - Password input with animated specific shapes (PasswordChars)
 */
MouseArea {
    id: root
    anchors.fill: parent
    required property LockContext context

    readonly property bool requirePasswordToPower: Config.options.lock?.security?.requirePasswordToPower ?? true

    // Monitor detection for adaptive colors/background
    readonly property var screen: root.QsWindow.window ? root.QsWindow.window.screen : null
    readonly property int monitorIndex: screen ? screen.index : 0
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    function forceFieldFocus() { passwordInput.forceActiveFocus() }
    Connections {
        target: context
        function onShouldReFocus() { root.forceFieldFocus() }
    }

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: forceFieldFocus()
    onPositionChanged: forceFieldFocus()

    property bool ctrlHeld: false
    Keys.onPressed: event => {
        root.context.resetClearTimer()
        if (event.key === Qt.Key_Control) root.ctrlHeld = true
        if (event.key === Qt.Key_Escape)  root.context.currentText = ""
        forceFieldFocus()
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Control) root.ctrlHeld = false
        forceFieldFocus()
    }

    // Animations
    property real islandOpacity: 0
    property real islandScale: 0.95
    property real islandYOffset: 30 * Appearance.effectiveScale
    
    Behavior on islandOpacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on islandScale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on islandYOffset { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    Component.onCompleted: {
        forceFieldFocus()
        islandOpacity = 1
        islandScale = 1
        islandYOffset = 0
    }

    // ── Background Cava (v1.2 Wave Visualizer) ──
    property bool _cavaActive: false
    readonly property bool shouldVisualize: root.visible && MprisController.isPlaying && (Config.ready && Config.options.lock.showCava)
    onShouldVisualizeChanged: {
        if (shouldVisualize && !_cavaActive) {
            CavaService.refCount++;
            _cavaActive = true;
        } else if (!shouldVisualize && _cavaActive) {
            CavaService.refCount--;
            _cavaActive = false;
        }
    }
    Component.onDestruction: {
        if (_cavaActive) CavaService.refCount--;
    }

    FadeLoader {
        id: lockVisualizerLoader
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.6
        z: -1 // Behind Jam and Password input
        shown: root.shouldVisualize

        sourceComponent: WaveVisualizer {
            anchors.fill: parent
            color: Appearance.lockM3colors.m3primary
            opacityMultiplier: (Config.ready && Config.options.lock) ? Config.options.lock.cavaOpacity : 0.15
        }
    }

    // Scrim removed as requested

    // ── Lockscreen Status Bar (Matching System Style) ──
    Item {
        id: lockStatusBarContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        readonly property bool isM3: Config.ready && Config.options.statusBar?.moduleStyle === "m3"
        readonly property bool notifIsLeft: (Config.ready && Config.options.notifications) ? Config.options.notifications.position === "left" : false
        height: isM3 ? Math.round(48 * Appearance.effectiveScale) : Appearance.sizes.statusBarHeight
        z: 10

        readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
        readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200 * Appearance.effectiveScale
        readonly property real sidePadding: isCentered ? Math.round((parent.width - Math.min(centeredWidth, parent.width - 40 * Appearance.effectiveScale)) / 2) : 12 * Appearance.effectiveScale
        readonly property int cornerRadius: Math.round(((Config.ready && Config.options.statusBar?.backgroundCornerRadius) || 20) * Appearance.effectiveScale)

        // Adaptive background detection
        readonly property int bgStyle: (Config.ready && Config.options.statusBar) ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
        readonly property int activeWorkspaceId: root.monitor?.activeWorkspace?.id ?? -1
        readonly property bool hasTiledWindows: {
            if (bgStyle !== 2 || activeWorkspaceId === -1) return false;
            return HyprlandData.windowList.some(w => 
                w.workspace.id === activeWorkspaceId && 
                !w.floating && 
                w.monitor === root.monitorIndex
            );
        }

        // Selection of the final color based on actual visibility
        property color contentColor: {
            if (barBg.showBg) return Appearance.lockM3colors.m3onSurface;
            const mode = Config.ready && Config.options.statusBar ? (Config.options.statusBar.textColorMode ?? "adaptive") : "adaptive";
            if (mode === "dark") return "#1E1E1E";
            if (mode === "light") return "#F5F5F5";
            return Appearance.lockM3colors.m3onSurface; // adaptive
        }
        property color subtextColor: {
            if (barBg.showBg) return Appearance.lockM3colors.m3onSurfaceVariant;
            const mode = Config.ready && Config.options.statusBar ? (Config.options.statusBar.textColorMode ?? "adaptive") : "adaptive";
            if (mode === "dark") return "#1E1E1E";
            if (mode === "light") return "#F5F5F5";
            return Appearance.lockM3colors.m3onSurfaceVariant; // adaptive
        }

        Behavior on contentColor { ColorAnimation { duration: 300 } }
        Behavior on subtextColor { ColorAnimation { duration: 300 } }

        // 1. Solid background (follows system config)
        Rectangle {
            id: barBg
            visible: !lockStatusBarContainer.isM3
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            
            readonly property bool showBg: (lockStatusBarContainer.bgStyle === 1) || (lockStatusBarContainer.bgStyle === 2 && lockStatusBarContainer.hasTiledWindows)
            
            width: (lockStatusBarContainer.isCentered && showBg) ? Math.min(lockStatusBarContainer.centeredWidth, parent.width - 40 * Appearance.effectiveScale) : parent.width
            height: parent.height + (lockStatusBarContainer.isCentered && showBg ? lockStatusBarContainer.cornerRadius : 0)
            anchors.topMargin: (lockStatusBarContainer.isCentered && showBg) ? -lockStatusBarContainer.cornerRadius : 0
            
            color: showBg ? Appearance.lockM3colors.m3surfaceContainerLow : "transparent"
            radius: (lockStatusBarContainer.isCentered && showBg) ? lockStatusBarContainer.cornerRadius : 0

            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

            // concanve corners
            // Standard Corners
            RoundCorner {
                anchors.left: parent.left
                anchors.top: parent.bottom
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopLeft
                visible: barBg.showBg && !lockStatusBarContainer.isCentered
            }
            RoundCorner {
                anchors.right: parent.right
                anchors.top: parent.bottom
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopRight
                visible: barBg.showBg && !lockStatusBarContainer.isCentered
            }

            // HUD Corners
            RoundCorner {
                anchors { right: parent.left; top: parent.top; topMargin: lockStatusBarContainer.cornerRadius }
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopRight 
                visible: barBg.showBg && lockStatusBarContainer.isCentered
            }
            RoundCorner {
                anchors { left: parent.right; top: parent.top; topMargin: lockStatusBarContainer.cornerRadius }
                implicitSize: lockStatusBarContainer.cornerRadius
                color: barBg.color
                corner: RoundCorner.CornerEnum.TopLeft
                visible: barBg.showBg && lockStatusBarContainer.isCentered
            }
        }

        // 2. Gradient overlay
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height
            color: "transparent"
            opacity: !lockStatusBarContainer.isM3 && !barBg.showBg && (Config.ready && Config.options.statusBar ? (Config.options.statusBar.useGradient ?? true) : true) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 300 } }
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: Appearance.colors.colStatusBarGradientStart }
                GradientStop { position: 1.0; color: Appearance.colors.colStatusBarGradientEnd }
            }
        }

        // 3. Center: Dynamic Island Wannabe (Locked Indicator)
        readonly property string islandStyle: Config.options.statusBar?.islandStyle ?? "pill"
        readonly property bool isWaterdrop: islandStyle === "waterdrop"

        Rectangle {
            id: lockIndicatorPill
            visible: !lockStatusBarContainer.isM3
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Idle: y=6, height=28. Waterdrop: y=0, height=34.
            y: lockStatusBarContainer.isWaterdrop ? 0 : 6 * Appearance.effectiveScale
            height: lockStatusBarContainer.isWaterdrop ? 34 * Appearance.effectiveScale : 28 * Appearance.effectiveScale
            width: lockedContent.implicitWidth + (24 * Appearance.effectiveScale)
            color: "black"
            radius: height / 2

            // The "Flattener" - Square off the top part for Waterdrop
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                height: parent.radius
                color: "black"
                visible: lockStatusBarContainer.isWaterdrop
            }

            // Concave Corners for Waterdrop
            RoundCorner {
                anchors.right: parent.left; anchors.top: parent.top
                implicitSize: 12 * Appearance.effectiveScale; color: "black"; corner: RoundCorner.CornerEnum.TopRight
                visible: lockStatusBarContainer.isWaterdrop
            }

            RoundCorner {
                anchors.left: parent.right; anchors.top: parent.top
                implicitSize: 12 * Appearance.effectiveScale; color: "black"; corner: RoundCorner.CornerEnum.TopLeft
                visible: lockStatusBarContainer.isWaterdrop
            }

            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

            RowLayout {
                id: lockedContent
                anchors.centerIn: parent
                spacing: 6 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "lock"
                    iconSize: 14 * Appearance.effectiveScale
                    color: Appearance.colors.colNotchText
                    fill: 1
                }
                StyledText {
                    text: "Locked"
                    font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colNotchText
                }
            }
        }

        // 4. Content (Base Style)
        Item {
            id: lockStatusBarContent
            visible: !lockStatusBarContainer.isM3
            anchors.fill: parent
            
            // Left: User + Network + (Notifications when position=left)
            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: lockStatusBarContainer.sidePadding + (lockStatusBarContainer.isCentered ? 12 * Appearance.effectiveScale : 0)
                spacing: 8 * Appearance.effectiveScale
                // Notifications (when position is left)
                Item {
                    visible: Notifications.unread > 0 && lockStatusBarContainer.notifIsLeft
                    width: 20 * Appearance.effectiveScale; height: 20 * Appearance.effectiveScale
                    MaterialSymbol {
                        id: lockBellIconLeft
                        anchors.centerIn: parent
                        text: "notifications_active"
                        iconSize: 16 * Appearance.effectiveScale
                        fill: 1
                        color: lockStatusBarContainer.contentColor
                    }
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -2 * Appearance.effectiveScale
                        anchors.rightMargin: -2 * Appearance.effectiveScale
                        width: Math.max(12 * Appearance.effectiveScale, badgeTextLeft.implicitWidth + 4 * Appearance.effectiveScale)
                        height: 12 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: lockBellIconLeft.color
                        StyledText {
                            id: badgeTextLeft
                            anchors.centerIn: parent
                            text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                            font.pixelSize: Math.round(8 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: Functions.ColorUtils.getContrastingTextColor(lockBellIconLeft.color)
                        }
                    }
                }

                StyledText {
                    text: SystemInfo.username + "  •  " + (Network.wifiEnabled ? (Network.networkName || "Offline") : "WiFi Off")
                    font.pixelSize: Math.round(14 * Appearance.effectiveScale)
                    font.weight: Font.Medium
                    color: lockStatusBarContainer.contentColor
                }


            }

            // Right: System Icons
            RowLayout {
                anchors.right: privacyIndicator.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // Notifications (when position is NOT left)
                Item {
                    visible: Notifications.unread > 0 && !lockStatusBarContainer.notifIsLeft
                    width: 20 * Appearance.effectiveScale; height: 20 * Appearance.effectiveScale
                    MaterialSymbol {
                        id: lockBellIcon
                        anchors.centerIn: parent
                        text: "notifications_active"
                        iconSize: 16 * Appearance.effectiveScale
                        fill: 1
                        color: lockStatusBarContainer.contentColor
                    }
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -2 * Appearance.effectiveScale
                        anchors.rightMargin: -2 * Appearance.effectiveScale
                        width: Math.max(12 * Appearance.effectiveScale, badgeText.implicitWidth + 4 * Appearance.effectiveScale)
                        height: 12 * Appearance.effectiveScale
                        radius: 6 * Appearance.effectiveScale
                        color: lockBellIcon.color
                        StyledText {
                            id: badgeText
                            anchors.centerIn: parent
                            text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                            font.pixelSize: Math.round(8 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: Functions.ColorUtils.getContrastingTextColor(lockBellIcon.color)
                        }
                    }
                }

                // Volume / Speaker (always show, including muted)
                MaterialSymbol {
                    visible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                    text: Audio.muted || Audio.volume === 0 ? "volume_off" : (Audio.volume > 0.3 ? "volume_up" : "volume_down")
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }

                // WiFi
                MaterialSymbol {
                    text: Network.materialSymbol
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }

                // Bluetooth
                MaterialSymbol {
                    visible: BluetoothStatus.available
                    text: BluetoothStatus.materialSymbol
                    iconSize: 16 * Appearance.effectiveScale
                    fill: BluetoothStatus.connected ? 1 : 0
                    color: lockStatusBarContainer.contentColor
                }

                // Battery
                BatteryIndicator {
                    visible: Battery.available
                    Layout.alignment: Qt.AlignVCenter
                    color: lockStatusBarContainer.contentColor
                }

                // DND Indicator
                MaterialSymbol {
                    visible: Notifications.silent
                    text: "notifications_paused"
                    iconSize: 16 * Appearance.effectiveScale
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }
            }

            // Privacy Indicator
            PrivacyIndicator {
                id: privacyIndicator
                anchors.right: parent.right
                anchors.rightMargin: lockStatusBarContainer.sidePadding + (lockStatusBarContainer.isCentered ? 8 * Appearance.effectiveScale : -2 * Appearance.effectiveScale)
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // 5. M3 Layout
        Item {
            id: lockM3StatusBar
            visible: lockStatusBarContainer.isM3
            anchors.fill: parent

            // ── Left Cluster ──
            Rectangle {
                id: lockM3LeftCluster
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: lockStatusBarContainer.sidePadding
                height: lockM3LeftRow.implicitHeight + (8 * Appearance.effectiveScale)
                width: lockM3LeftRow.implicitWidth + (8 * Appearance.effectiveScale)
                radius: height / 2
                color: Appearance.lockM3colors.m3surfaceContainer

                RowLayout {
                    id: lockM3LeftRow
                    anchors.centerIn: parent
                    spacing: 4 * Appearance.effectiveScale

                    // Notifications pill (when position is left)
                    M3StatusWrapper {
                        id: lockM3NotifLeftWrapper
                        Layout.alignment: Qt.AlignVCenter
                        show: Notifications.unread > 0 && lockStatusBarContainer.notifIsLeft
                        m3Color: Appearance.lockM3colors.m3tertiaryContainer
                        m3ContentColor: Appearance.lockM3colors.m3onTertiaryContainer

                        Item {
                            Layout.preferredWidth: lockM3BellIconLeft.width
                            Layout.preferredHeight: lockM3BellIconLeft.height
                            Layout.alignment: Qt.AlignVCenter

                            MaterialSymbol {
                                id: lockM3BellIconLeft
                                anchors.centerIn: parent
                                text: "notifications_active"
                                iconSize: 16 * Appearance.effectiveScale
                                fill: 1
                                color: lockM3NotifLeftWrapper.contentColor
                            }

                            Rectangle {
                                visible: Notifications.unread > 0
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: -2 * Appearance.effectiveScale
                                anchors.rightMargin: -2 * Appearance.effectiveScale
                                width: Math.max(12 * Appearance.effectiveScale, lockM3BadgeTextLeft.implicitWidth + 4 * Appearance.effectiveScale)
                                height: 12 * Appearance.effectiveScale
                                radius: 6 * Appearance.effectiveScale
                                color: lockM3NotifLeftWrapper.contentColor

                                StyledText {
                                    id: lockM3BadgeTextLeft
                                    anchors.centerIn: parent
                                    text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                                    font.pixelSize: Math.round(8 * Appearance.effectiveScale)
                                    font.weight: Font.DemiBold
                                    color: lockM3NotifLeftWrapper.m3Color
                                }
                            }
                        }
                    }

                    // Username pill (with circular avatar photo)
                    M3StatusWrapper {
                        id: lockM3UserWrapper
                        Layout.alignment: Qt.AlignVCenter
                        m3Color: Appearance.lockM3colors.m3primaryContainer
                        m3ContentColor: Appearance.lockM3colors.m3onPrimaryContainer

                        // Avatar photo (circular)
                        Item {
                            id: lockM3AvatarContainer
                            width: 20 * Appearance.effectiveScale
                            height: 20 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: lockM3AvatarImage
                                anchors.fill: parent
                                source: {
                                    const cfgPath = Config.options.bar?.avatar_path;
                                    if (cfgPath && cfgPath !== "") return `file://${cfgPath}`;
                                    const sysPath = SystemInfo.userAvatarPath;
                                    if (!sysPath || sysPath.includes("/var/lib/AccountsService/icons/")) return "";
                                    return `file://${sysPath}`;
                                }
                                sourceSize: Qt.size(width, height)
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                            }
                            Rectangle {
                                id: lockM3AvatarMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                            }
                            OpacityMask {
                                anchors.fill: parent
                                source: lockM3AvatarImage
                                maskSource: lockM3AvatarMask
                                visible: lockM3AvatarImage.status === Image.Ready
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: lockM3AvatarImage.status !== Image.Ready
                                text: "person"
                                iconSize: 16 * Appearance.effectiveScale
                                fill: 1
                                color: lockM3UserWrapper.contentColor
                            }
                        }

                        StyledText {
                            text: SystemInfo.username
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: lockM3UserWrapper.contentColor
                        }
                    }

                    // Network pill
                    M3StatusWrapper {
                        id: lockM3NetworkWrapper
                        Layout.alignment: Qt.AlignVCenter
                        m3Color: Appearance.lockM3colors.m3secondaryContainer
                        m3ContentColor: Appearance.lockM3colors.m3onSecondaryContainer

                        StyledText {
                            text: Network.wifiEnabled ? (Network.networkName || "Offline") : "WiFi Off"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: lockM3NetworkWrapper.contentColor
                        }
                    }


                }
            }

            // ── Center Cluster ──
            Rectangle {
                id: lockM3CenterCluster
                anchors.centerIn: parent

                readonly property real padding: Math.round(4 * Appearance.effectiveScale)

                height: Math.round(32 * Appearance.effectiveScale) + (padding * 2)
                width: lockM3LockWrapper.implicitWidth + (padding * 2)
                radius: height / 2
                color: Appearance.lockM3colors.m3surfaceContainer

                M3StatusWrapper {
                    id: lockM3LockWrapper
                    anchors.centerIn: parent
                    m3Color: "black"
                    m3ContentColor: "white"

                    MaterialSymbol {
                        text: "lock"
                        iconSize: 14 * Appearance.effectiveScale
                        fill: 1
                        color: lockM3LockWrapper.contentColor
                    }
                    StyledText {
                        text: "Locked"
                        font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: lockM3LockWrapper.contentColor
                    }
                }
            }

            // ── Right Cluster ──
            Rectangle {
                id: lockM3RightCluster
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: lockStatusBarContainer.sidePadding
                height: lockM3RightRow.implicitHeight + (8 * Appearance.effectiveScale)
                width: lockM3RightRow.implicitWidth + (8 * Appearance.effectiveScale)
                radius: height / 2
                color: Appearance.lockM3colors.m3surfaceContainer

                RowLayout {
                    id: lockM3RightRow
                    anchors.centerIn: parent
                    spacing: 4 * Appearance.effectiveScale



                    // Battery pill (terpisah, m3primaryContainer)
                    M3StatusWrapper {
                        id: lockM3BatteryWrapper
                        Layout.alignment: Qt.AlignVCenter
                        show: Battery.available
                        m3Color: Appearance.lockM3colors.m3primaryContainer
                        m3ContentColor: Appearance.lockM3colors.m3onPrimaryContainer

                        BatteryIndicator {
                            Layout.alignment: Qt.AlignVCenter
                            color: lockM3BatteryWrapper.contentColor
                        }
                    }

                    // System icons pill (Notif + Volume + WiFi + BT + DND)
                    M3StatusWrapper {
                        id: lockM3SystemWrapper
                        Layout.alignment: Qt.AlignVCenter
                        m3Color: Appearance.lockM3colors.m3tertiaryContainer
                        m3ContentColor: Appearance.lockM3colors.m3onTertiaryContainer

                        Item {
                            visible: Notifications.unread > 0 && !lockStatusBarContainer.notifIsLeft
                            Layout.preferredWidth: lockM3BellIcon.width
                            Layout.preferredHeight: lockM3BellIcon.height
                            Layout.alignment: Qt.AlignVCenter

                            MaterialSymbol {
                                id: lockM3BellIcon
                                anchors.centerIn: parent
                                text: "notifications_active"
                                iconSize: 16 * Appearance.effectiveScale
                                fill: 1
                                color: lockM3SystemWrapper.contentColor
                            }

                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: -2 * Appearance.effectiveScale
                                anchors.rightMargin: -2 * Appearance.effectiveScale
                                width: Math.max(12 * Appearance.effectiveScale, lockM3BadgeText.implicitWidth + 4 * Appearance.effectiveScale)
                                height: 12 * Appearance.effectiveScale
                                radius: 6 * Appearance.effectiveScale
                                color: lockM3SystemWrapper.contentColor

                                StyledText {
                                    id: lockM3BadgeText
                                    anchors.centerIn: parent
                                    text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                                    font.pixelSize: Math.round(8 * Appearance.effectiveScale)
                                    font.weight: Font.DemiBold
                                    color: lockM3SystemWrapper.m3Color
                                }
                            }
                        }

                        // Volume (selalu visible sesuai showVolumeIndicator)
                        MaterialSymbol {
                            visible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                            text: Audio.muted || Audio.volume === 0 ? "volume_off" : (Audio.volume > 0.3 ? "volume_up" : "volume_down")
                            iconSize: 16 * Appearance.effectiveScale
                            fill: 1
                            color: lockM3SystemWrapper.contentColor
                            Layout.alignment: Qt.AlignVCenter
                        }

                        MaterialSymbol {
                            text: Network.materialSymbol
                            iconSize: 16 * Appearance.effectiveScale
                            fill: 1
                            color: lockM3SystemWrapper.contentColor
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
                                color: lockM3SystemWrapper.contentColor
                            }
                        }

                        MaterialSymbol {
                            visible: Notifications.silent
                            text: "notifications_paused"
                            iconSize: 16 * Appearance.effectiveScale
                            fill: 1
                            color: lockM3SystemWrapper.contentColor
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    // Privacy pill (only when active)
                    M3StatusWrapper {
                        id: lockM3PrivacyWrapper
                        Layout.alignment: Qt.AlignVCenter
                        show: Privacy.anyActive
                        m3Color: Appearance.lockM3colors.m3primary
                        m3ContentColor: Appearance.lockM3colors.m3onPrimary

                        MaterialSymbol {
                            visible: Privacy.microphoneActive
                            text: "mic"
                            iconSize: 16 * Appearance.effectiveScale
                            fill: 1
                            color: lockM3PrivacyWrapper.contentColor
                        }
                        MaterialSymbol {
                            visible: Privacy.cameraActive
                            text: "videocam"
                            iconSize: 16 * Appearance.effectiveScale
                            fill: 1
                            color: lockM3PrivacyWrapper.contentColor
                        }
                        MaterialSymbol {
                            visible: Privacy.screensharingActive
                            text: "screen_share"
                            iconSize: 16 * Appearance.effectiveScale
                            fill: 1
                            color: lockM3PrivacyWrapper.contentColor
                        }
                    }
                }
            }
        }
    }

    // ── Clock & Weather Cluster ──
    Column {
        anchors.centerIn: parent
        // Offset slightly up to make room for media and password if they feel crowded, 
        // but user asked for "exactly in center" so we start with 0 offset.
        spacing: 20 * Appearance.effectiveScale

        NandoClock {
            id: lockClock
            color: Appearance.lockM3colors.m3onSurface
            isLockscreen: true
            anchors.horizontalCenter: parent.horizontalCenter
            x: 0; y: 0 // Override NandoClock's internal x/y centering
        }

        // Weather (Adaptive color)
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6 * Appearance.effectiveScale
            visible: Config.ready && (Config.options.weather?.enable ?? true) && (Config.options.lock?.showWeather ?? true)

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12 * Appearance.effectiveScale
                CustomIcon {
                    source: Weather.current.icon
                    iconFolder: "assets/icons/google-weather"
                    width: 32 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale
                    colorize: false
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: Weather.current.temp + "°"
                    font.pixelSize: Math.round(32 * Appearance.effectiveScale)
                    font.weight: Font.Medium
                    color: Appearance.colors.colLockscreenWeatherText
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.current.condition
                font.pixelSize: Math.round(15 * Appearance.effectiveScale)
                font.weight: Font.Normal
                color: Appearance.colors.colLockscreenWeatherSubtext
            }
        }
    }

    // ── Components ──
    component Pill: Rectangle {
        default property alias contents: innerRow.data
        property alias rowSpacing: innerRow.spacing
        
        implicitHeight: Math.min(56 * Appearance.effectiveScale, Quickshell.screens[0].height * 0.08)
        implicitWidth: innerRow.implicitWidth + (16 * Appearance.effectiveScale)
        radius: height / 2
        color: Appearance.lockM3colors.m3surfaceContainer
        
        StyledRectangularShadow {
            target: parent
            z: -1
            offset: Qt.vector2d(0, 4 * Appearance.effectiveScale)
            blur: 10 * Appearance.effectiveScale
            // Tailwind shadow-md approximation (slightly darker for dark bg)
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        RowLayout { 
            id: innerRow
            anchors.fill: parent
            anchors.margins: 8 * Appearance.effectiveScale // Padding 8
            spacing: 4 * Appearance.effectiveScale
        }
    }

    component PowerBtn: RippleButton {
        id: pb
        required property int targetAction
        required property string btnIcon
        property bool isActive: root.context.targetAction === pb.targetAction
        
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 40 * Appearance.effectiveScale; implicitHeight: 40 * Appearance.effectiveScale; buttonRadius: 20 * Appearance.effectiveScale
        
        colBackground: isActive ? Appearance.lockM3colors.m3primary : "transparent"
        colBackgroundHover: isActive ? Qt.darker(Appearance.lockM3colors.m3primary, 1.1) : Functions.ColorUtils.mix(Appearance.lockM3colors.m3surfaceContainer, Appearance.lockM3colors.m3onSurface, 0.90)
        onClicked: {
                if (!root.requirePasswordToPower) {
                root.context.unlocked(pb.targetAction); return
            }
            if (root.context.targetAction === pb.targetAction) {
                root.context.resetTargetAction()
            } else {
                root.context.targetAction = pb.targetAction
                root.context.shouldReFocus()
            }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: pb.btnIcon
            iconSize: 20 * Appearance.effectiveScale
            color: pb.isActive ? Appearance.lockM3colors.m3onPrimary : Appearance.lockM3colors.m3onSurfaceVariant
        }
    }

    // ── Media Card ──
    MediaCard {
        id: lockMediaCard
        showVisualizer: false
        isLockscreen: true
        anchors.bottom: bottomIsland.top
        anchors.bottomMargin: 24 * Appearance.effectiveScale
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(400 * Appearance.effectiveScale, parent.width * 0.9)
        scale: root.islandScale
        opacity: (Config.ready && Config.options.lock.showMediaCard) ? root.islandOpacity * (MprisController.activePlayer ? 1 : 0) : 0
        visible: opacity > 0
        y: root.islandYOffset
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ── Bottom Island (Password Only) ──
    Pill {
        id: bottomIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 32 * Appearance.effectiveScale
        }
        
        // Match MediaCard width with responsiveness
        implicitWidth: Math.min(400 * Appearance.effectiveScale, parent.width * 0.9)
        scale: root.islandScale
        opacity: root.islandOpacity
        y: root.islandYOffset

        // Fingerprint
        Loader {
            active: root.context.fingerprintsConfigured
            visible: active
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6 * Appearance.effectiveScale
            sourceComponent: MaterialSymbol {
                text: "fingerprint"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.lockM3colors.m3primary
            }
        }

        // Input
        Rectangle {
            id: inputWrapper
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.lockM3colors.m3surfaceContainerLow
            radius: height / 2

            TextInput {
                id: passwordInput
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                
                font.pixelSize: Appearance.font.pixelSize.small
                color: "transparent"
                cursorVisible: false
                inputMethodHints: Qt.ImhSensitiveData
                echoMode: TextInput.Normal
                cursorDelegate: Item {}
                clip: true
                padding: 12 * Appearance.effectiveScale

                onTextChanged: root.context.currentText = text
                onAccepted:    root.context.tryUnlock(root.ctrlHeld)
                Keys.onPressed: event => root.context.resetClearTimer()

                Connections {
                    target: root.context
                    function onCurrentTextChanged() {
                        if (passwordInput.text !== root.context.currentText)
                            passwordInput.text = root.context.currentText
                    }
                }

                PasswordChars {
                    anchors.fill: parent
                    active: passwordInput.activeFocus
                    length: root.context.currentText.length
                    selectionStart: passwordInput.selectionStart
                    selectionEnd: passwordInput.selectionEnd
                    cursorPosition: passwordInput.cursorPosition
                    
                    charSize: 18 * Appearance.effectiveScale
                    selectionColor: Appearance.lockM3colors.m3secondary
                }

                Text {
                    anchors.centerIn: parent
                    visible: passwordInput.text.length === 0
                    text: GlobalStates.screenUnlockFailed ? "Incorrect password" : "Enter password"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    color: GlobalStates.screenUnlockFailed ? Appearance.lockM3colors.m3error : Appearance.lockM3colors.m3onSurfaceVariant
                }
            }
            
            // Shake
             SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to: -10 * Appearance.effectiveScale; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:  10 * Appearance.effectiveScale; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:  -5 * Appearance.effectiveScale; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:   5 * Appearance.effectiveScale; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:   0; duration: 50 }
            }
            Connections {
                target: GlobalStates
                function onScreenUnlockFailedChanged() {
                    if (GlobalStates.screenUnlockFailed) shakeAnim.restart()
                }
            }
        }

        // Main Action Button (Unlock)
        RippleButton {
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 0
            implicitWidth: 64 * Appearance.effectiveScale; implicitHeight: 40 * Appearance.effectiveScale; buttonRadius: 20 * Appearance.effectiveScale
            
            colBackground: root.context.unlockInProgress 
                ? Appearance.lockM3colors.m3surfaceContainerHigh 
                : Appearance.lockM3colors.m3primary
            colBackgroundHover: root.context.unlockInProgress
                ? Appearance.lockM3colors.m3surfaceContainerHigh
                : Qt.darker(Appearance.lockM3colors.m3primary, 1.1)

            enabled: !root.context.unlockInProgress
            onClicked: root.context.tryUnlock()

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 22 * Appearance.effectiveScale
                text: root.context.unlockInProgress ? "progress_activity" : "arrow_right_alt"
                color: root.context.unlockInProgress
                    ? Appearance.lockM3colors.m3onSurfaceVariant
                    : Appearance.lockM3colors.m3onPrimary
            }
        }
    }

    // ── Screen Rounding (Matching system config) ──
    RoundCorner {
        anchors.top: parent.top; anchors.left: parent.left
        corner: RoundCorner.CornerEnum.TopLeft
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.top: parent.top; anchors.right: parent.right
        corner: RoundCorner.CornerEnum.TopRight
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.bottom: parent.bottom; anchors.left: parent.left
        corner: RoundCorner.CornerEnum.BottomLeft
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.bottom: parent.bottom; anchors.right: parent.right
        corner: RoundCorner.CornerEnum.BottomRight
        implicitSize: Math.round((Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20) * Appearance.effectiveScale)
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
}
