pragma ComponentBehavior: Bound
import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Qt5Compat.GraphicalEffects
import "../NotificationCenter"

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
    
    // ── Background Cava ──
    CavaWidget {
        id: lockCava
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        z: -1 // Behind Jam and Password input
        
        maxHeight: root.height * 0.75
        barCount: 128
        spacing: 2
        barWidth: (root.width - (barCount - 1) * spacing) / barCount
        
        barColor: Appearance.m3colors.m3primary
        
        opacity: (Config.ready && Config.options.lock.showCava) ? 0.15 * root.islandOpacity * (MprisController.isPlaying ? 1 : 0) : 0
        visible: opacity > 0
        
        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
    }

    // Scrim removed as requested

    // ── Clock & Date ──
    NandoClock {
        color: Appearance.colors.colLockscreenClock
        isLockscreen: true
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
        anchors.bottom: bottomIslands.top
        anchors.bottomMargin: 30
        anchors.horizontalCenter: parent.horizontalCenter
        width: 400
        scale: root.islandScale
        opacity: (Config.ready && Config.options.lock.showMediaCard) ? root.islandOpacity * (MprisController.activePlayer ? 1 : 0) : 0
        visible: opacity > 0
        y: root.islandYOffset
        
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // ── Bottom Islands ──
    Row {
        id: bottomIslands
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        spacing: 10
        scale: root.islandScale
        opacity: root.islandOpacity
        y: root.islandYOffset

        // 1. User
        Pill {
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 8

                // Avatar
                Item {
                    width: 24; height: 24
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: lockAvatarImage
                        anchors.fill: parent
                        source: {
                            const cfgPath = Config.options.bar?.avatar_path
                            if (cfgPath && cfgPath !== "") return `file://${cfgPath}`
                            return `file://${SystemInfo.userAvatarPath}`
                        }
                        sourceSize: Qt.size(24, 24)
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: lockAvatarMask
                        anchors.fill: parent
                        radius: 12
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: lockAvatarImage
                        maskSource: lockAvatarMask
                        visible: lockAvatarImage.status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: lockAvatarImage.status !== Image.Ready
                        text: "person"
                        iconSize: Appearance.font.pixelSize.huge
                        fill: 1
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemInfo.username
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSurface
                }
            }
        }

        // 2. Password & Main Action
        Pill {
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
                Layout.preferredWidth: Appearance.sizes.lockInputWidth
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

                    // Shape Overlay
                    PasswordChars {
                        anchors.fill: parent
                        // Bind directly to text input state
                        active: passwordInput.activeFocus
                        length: root.context.currentText.length
                        selectionStart: passwordInput.selectionStart
                        selectionEnd: passwordInput.selectionEnd
                        cursorPosition: passwordInput.cursorPosition
                        
                        charSize: 18
                        selectionColor: Appearance.m3colors.m3secondary
                    }

                    // Placeholder
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

            // Main Action Button (Unlock/Power/etc)
            RippleButton {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 0
                implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
                
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
                    iconSize: 20
                    text: {
                        if (root.context.unlockInProgress) return "progress_activity"
                        switch (root.context.targetAction) {
                            case LockContext.ActionEnum.Poweroff: return "power_settings_new"
                            case LockContext.ActionEnum.Reboot:   return "restart_alt"
                            case LockContext.ActionEnum.Suspend:  return "dark_mode"
                            default:                              return "arrow_right_alt"
                        }
                    }
                    color: root.context.unlockInProgress
                        ? Appearance.m3colors.m3onSurfaceVariant
                        : Appearance.m3colors.m3onPrimary
                }
            }
        }

        // 3. System
        Pill {
            Row {
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 10
                Layout.rightMargin: 4
                visible: UPower.displayDevice.isPresent
                spacing: 4
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: UPower.displayDevice.isCharging ? "bolt" : "battery_android_full"
                    iconSize: Appearance.font.pixelSize.huge
                    fill: 1
                    animateChange: true
                    color: (UPower.displayDevice.percentage < 0.2 && !UPower.displayDevice.isCharging)
                        ? Appearance.m3colors.m3error
                        : Appearance.m3colors.m3onSurfaceVariant
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(UPower.displayDevice.percentage * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSurfaceVariant
                }
            }
            
            // Sleep
            RippleButton {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "dark_mode"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.m3colors.m3onSurfaceVariant
                }
            }
            
            PowerBtn { targetAction: LockContext.ActionEnum.Poweroff; btnIcon: "power_settings_new" }
            PowerBtn { targetAction: LockContext.ActionEnum.Reboot;   btnIcon: "restart_alt"
                Layout.rightMargin: 4
            }
        }
    }
}
