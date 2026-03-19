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
    property real islandYOffset: 30
    
    Behavior on islandOpacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on islandScale   { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on islandYOffset { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    Component.onCompleted: {
        forceFieldFocus()
        islandOpacity = 1
        islandScale = 1
        islandYOffset = 0
    }

    // ── Background ──
    Image {
        id: wallpaper
        anchors.fill: parent
        z: -2
        source: {
            if (!Config.ready) return ""
            if (Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath !== "") {
                return Config.options.lock.wallpaperPath
            }
            return Config.options.appearance?.background?.wallpaperPath ?? ""
        }
        fillMode: Image.PreserveAspectCrop
        
        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            visible: wallpaper.status !== Image.Ready
        }
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

    WaveVisualizer {
        id: lockWave
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height * 0.6
        z: -1 // Behind Jam and Password input
        
        color: Appearance.m3colors.m3primary
        opacityMultiplier: 0.15
        opacity: root.shouldVisualize ? root.islandOpacity : 0
        visible: opacity > 0
        
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    }

    // Scrim removed as requested

    // ── Lockscreen Status Bar (Matching System Style) ──
    Item {
        id: lockStatusBarContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Appearance.sizes.statusBarHeight
        z: 10

        readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
        readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth : 1200
        readonly property real sidePadding: isCentered ? Math.round((parent.width - Math.min(centeredWidth, parent.width - 40)) / 2) : 12
        readonly property int cornerRadius: (Config.ready && Config.options.statusBar?.backgroundCornerRadius) || 20

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
        property color contentColor: barBg.showBg ? Appearance.m3colors.m3onSurface : Appearance.colors.colStatusBarText
        property color subtextColor: barBg.showBg ? Appearance.m3colors.m3onSurfaceVariant : Appearance.colors.colStatusBarSubtext

        Behavior on contentColor { ColorAnimation { duration: 300 } }
        Behavior on subtextColor { ColorAnimation { duration: 300 } }

        // 1. Solid background (follows system config)
        Rectangle {
            id: barBg
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            
            readonly property bool showBg: (lockStatusBarContainer.bgStyle === 1) || (lockStatusBarContainer.bgStyle === 2 && lockStatusBarContainer.hasTiledWindows)
            
            width: (lockStatusBarContainer.isCentered && showBg) ? Math.min(lockStatusBarContainer.centeredWidth, parent.width - 40) : parent.width
            height: parent.height + (lockStatusBarContainer.isCentered && showBg ? lockStatusBarContainer.cornerRadius : 0)
            anchors.topMargin: (lockStatusBarContainer.isCentered && showBg) ? -lockStatusBarContainer.cornerRadius : 0
            
            color: showBg ? Appearance.colors.colStatusBarSolid : "transparent"
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
            opacity: !barBg.showBg && (Config.ready && Config.options.statusBar ? (Config.options.statusBar.useGradient ?? true) : true) ? 1.0 : 0.0
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
            anchors.horizontalCenter: parent.horizontalCenter
            
            // Idle: y=6, height=28. Waterdrop: y=0, height=34.
            y: lockStatusBarContainer.isWaterdrop ? 0 : 6
            height: lockStatusBarContainer.isWaterdrop ? 34 : 28
            width: lockedContent.implicitWidth + 24
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
                implicitSize: 12; color: "black"; corner: RoundCorner.CornerEnum.TopRight
                visible: lockStatusBarContainer.isWaterdrop
            }

            RoundCorner {
                anchors.left: parent.right; anchors.top: parent.top
                implicitSize: 12; color: "black"; corner: RoundCorner.CornerEnum.TopLeft
                visible: lockStatusBarContainer.isWaterdrop
            }

            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

            RowLayout {
                id: lockedContent
                anchors.centerIn: parent
                spacing: 6
                MaterialSymbol {
                    text: "lock"
                    iconSize: 14
                    color: Appearance.colors.colNotchText
                    fill: 1
                }
                StyledText {
                    text: "Locked"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colNotchText
                }
            }
        }

        // 4. Content
        Item {
            id: lockStatusBarContent
            anchors.fill: parent
            
            // Left: User + Network
            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: lockStatusBarContainer.sidePadding + (lockStatusBarContainer.isCentered ? 12 : 0)
                spacing: 8
                StyledText {
                    text: SystemInfo.username + "  •  " + (Network.wifiEnabled ? (Network.networkName || "Offline") : "WiFi Off")
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: lockStatusBarContainer.contentColor
                }
            }

            // Right: System Icons
            RowLayout {
                anchors.right: privacyIndicator.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10
                spacing: 8

                // Notifications
                Item {
                    visible: Notifications.unread > 0
                    width: 20; height: 20
                    MaterialSymbol {
                        id: lockBellIcon
                        anchors.centerIn: parent
                        text: "notifications_active"
                        iconSize: 16
                        fill: 1
                        color: lockStatusBarContainer.contentColor
                    }
                    Rectangle {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -2
                        anchors.rightMargin: -2
                        width: Math.max(12, badgeText.implicitWidth + 4)
                        height: 12
                        radius: 6
                        color: lockBellIcon.color
                        StyledText {
                            id: badgeText
                            anchors.centerIn: parent
                            text: Notifications.unread > 99 ? "99+" : Notifications.unread.toString()
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            color: barBg.showBg ? Appearance.m3colors.m3surface : Appearance.colors.colLayer0
                        }
                    }
                }

                // WiFi
                MaterialSymbol {
                    text: Network.materialSymbol
                    iconSize: 16
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }

                // Bluetooth
                MaterialSymbol {
                    visible: BluetoothStatus.available
                    text: BluetoothStatus.materialSymbol
                    iconSize: 16
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
                    iconSize: 16
                    fill: 1
                    color: lockStatusBarContainer.contentColor
                }
            }

            // Privacy Indicator
            PrivacyIndicator {
                id: privacyIndicator
                anchors.right: parent.right
                anchors.rightMargin: lockStatusBarContainer.sidePadding + (lockStatusBarContainer.isCentered ? 8 : -2)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ── Clock & Weather Cluster ──
    Column {
        anchors.centerIn: parent
        // Offset slightly up to make room for media and password if they feel crowded, 
        // but user asked for "exactly in center" so we start with 0 offset.
        spacing: 20

        NandoClock {
            id: lockClock
            color: Appearance.colors.colLockscreenClock
            isLockscreen: true
            anchors.horizontalCenter: parent.horizontalCenter
            x: 0; y: 0 // Override NandoClock's internal x/y centering
        }

        // Weather (Adaptive color)
        ColumnLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            visible: Config.ready && (Config.options.weather?.enable ?? true)

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                CustomIcon {
                    source: Weather.current.icon
                    iconFolder: "assets/icons/google-weather"
                    width: 32; height: 32
                    colorize: false
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: Weather.current.temp + "°"
                    font.pixelSize: 32
                    font.weight: Font.Medium
                    color: Appearance.colors.colLockscreenWeatherText
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Weather.current.condition
                font.pixelSize: 15
                font.weight: Font.Normal
                color: Appearance.colors.colLockscreenWeatherSubtext
            }
        }
    }

    // ── Components ──
    component Pill: Rectangle {
        default property alias contents: innerRow.data
        property alias rowSpacing: innerRow.spacing
        
        implicitHeight: Math.min(56, Quickshell.screens[0].height * 0.08)
        implicitWidth: innerRow.implicitWidth + 16 
        radius: height / 2
        color: Appearance.colors.colLayer2 // Surface Container
        
        StyledRectangularShadow {
            target: parent
            z: -1
            offset: Qt.vector2d(0, 4)
            blur: 10
            // Tailwind shadow-md approximation (slightly darker for dark bg)
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        RowLayout { 
            id: innerRow
            anchors.fill: parent
            anchors.margins: 8 // Padding 8
            spacing: 4
        }
    }

    component PowerBtn: RippleButton {
        id: pb
        required property int targetAction
        required property string btnIcon
        property bool isActive: root.context.targetAction === pb.targetAction
        
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
        
        colBackground: isActive ? Appearance.m3colors.m3primary : "transparent"
        colBackgroundHover: isActive ? Qt.darker(Appearance.m3colors.m3primary, 1.1) : Appearance.colors.colLayer2Hover
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
            iconSize: 20
            color: pb.isActive ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
        }
    }

    // ── Media Card ──
    MediaCard {
        id: lockMediaCard
        showVisualizer: false
        anchors.bottom: bottomIsland.top
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(400, parent.width * 0.9)
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
            bottomMargin: 32
        }
        
        // Match MediaCard width with responsiveness
        implicitWidth: Math.min(400, parent.width * 0.9)
        scale: root.islandScale
        opacity: root.islandOpacity
        y: root.islandYOffset

        // Fingerprint
        Loader {
            active: root.context.fingerprintsConfigured
            visible: active
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
            sourceComponent: MaterialSymbol {
                text: "fingerprint"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.m3colors.m3primary
            }
        }

        // Input
        Rectangle {
            id: inputWrapper
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.colors.colLayer1
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
                padding: 12

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
                    
                    charSize: 18
                    selectionColor: Appearance.m3colors.m3secondary
                }

                Text {
                    anchors.centerIn: parent
                    visible: passwordInput.text.length === 0
                    text: GlobalStates.screenUnlockFailed ? "Incorrect password" : "Enter password"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.family: Appearance.font.family.main
                    color: GlobalStates.screenUnlockFailed ? Appearance.m3colors.m3error : Appearance.m3colors.m3onSurfaceVariant
                }
            }
            
            // Shake
             SequentialAnimation {
                id: shakeAnim
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to: -10; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:  10; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:  -5; duration: 50 }
                NumberAnimation { target: inputWrapper; property: "Layout.leftMargin"; to:   5; duration: 50 }
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
            implicitWidth: 64; implicitHeight: 40; buttonRadius: 20
            
            colBackground: root.context.unlockInProgress 
                ? Appearance.m3colors.m3surfaceContainerHigh 
                : Appearance.m3colors.m3primary
            colBackgroundHover: root.context.unlockInProgress
                ? Appearance.m3colors.m3surfaceContainerHigh
                : Qt.darker(Appearance.m3colors.m3primary, 1.1)

            enabled: !root.context.unlockInProgress
            onClicked: root.context.tryUnlock()

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: 22
                text: root.context.unlockInProgress ? "progress_activity" : "arrow_right_alt"
                color: root.context.unlockInProgress
                    ? Appearance.m3colors.m3onSurfaceVariant
                    : Appearance.m3colors.m3onPrimary
            }
        }
    }

    // ── Screen Rounding (Matching system config) ──
    RoundCorner {
        anchors.top: parent.top; anchors.left: parent.left
        corner: RoundCorner.CornerEnum.TopLeft
        implicitSize: Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.top: parent.top; anchors.right: parent.right
        corner: RoundCorner.CornerEnum.TopRight
        implicitSize: Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.bottom: parent.bottom; anchors.left: parent.left
        corner: RoundCorner.CornerEnum.BottomLeft
        implicitSize: Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
    RoundCorner {
        anchors.bottom: parent.bottom; anchors.right: parent.right
        corner: RoundCorner.CornerEnum.BottomRight
        implicitSize: Config.ready ? (Config.options.appearance?.screenCorners?.radius ?? 20) : 20
        color: "#000000"
        z: 100
        visible: Config.ready && (Config.options.appearance?.screenCorners?.mode ?? 1) !== 0
    }
}
