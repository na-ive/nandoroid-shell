import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import QtQuick.Effects

/**
 * Quick Settings content — Android-style panel with:
 * - Brightness & Volume sliders
 * - Resizable toggle grid (size 1 = icon-only, size 2 = expanded)
 * - Edit mode to resize/reorder/enable/disable toggles
 * - Detail panels for WiFi, Bluetooth, Audio
 */
Item {
    id: root
    signal closed()
    property bool editMode: GlobalStates.quickSettingsEditMode
    implicitWidth: Appearance.sizes.notificationCenterWidth
    implicitHeight: contentColumn.implicitHeight + 20

    focus: true
    Keys.onEscapePressed: close()

    // Detail panel visibility
    property bool showWifiPanel: false
    property bool showBluetoothPanel: false
    property bool showAudioOutputPanel: false
    property bool showAudioInputPanel: false
    property bool showNightModePanel: false
    property bool showPowerProfilePanel: false

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.panel
        
        // MD3 Outline Style
        border.width: 1
        border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
    }

    function close() { root.closed(); }

    Connections {
        target: GlobalStates
        function onQuickSettingsOpenChanged() {
            if (GlobalStates.quickSettingsOpen) {
                root.forceActiveFocus();
            } else {
                root.showWifiPanel = false;
                root.showBluetoothPanel = false;
                root.showAudioOutputPanel = false;
                root.showAudioInputPanel = false;
                root.showNightModePanel = false;
                root.showPowerProfilePanel = false;
                GlobalStates.quickSettingsEditMode = false;
            }
        }
    }

    Component.onCompleted: {
        if (GlobalStates.quickSettingsOpen) {
            root.forceActiveFocus();
        }
    }

    // ── Toggle grid constants ──
    // 4 columns: size 1 = 1 col (square icon), size 2 = 2 cols (icon + text)
    readonly property int columns: 4
    readonly property real toggleSpacing: 6
    readonly property real togglePadding: 6
    readonly property real baseCellWidth: {
        const availableWidth = root.implicitWidth - 20 - (togglePadding * 2) - (toggleSpacing * (columns - 1))
        return Math.max(40, Math.floor(availableWidth / columns))
    }
    readonly property real baseCellHeight: 56

    // ── Toggle data registry ──
    readonly property var allToggles: ({
        "wifi": {
            name: "Wi-Fi",
            icon: "wifi",
            iconOff: "wifi_off",
            toggled: Network.wifiEnabled,
            statusText: Network.wifiEnabled ? Network.networkName || "On" : "Off",
            action: () => Network.toggleWifi(),
            hasDetails: true,
            detailsAction: () => {
                root.showWifiPanel = true
            }
        },
        "bluetooth": {
            name: "Bluetooth",
            icon: "bluetooth",
            iconOff: "bluetooth_disabled",
            toggled: BluetoothStatus.enabled,
            statusText: BluetoothStatus.connected ? `${BluetoothStatus.activeDeviceCount} connected` : (BluetoothStatus.enabled ? "On" : "Off"),
            action: () => BluetoothStatus.toggle(),
            hasDetails: true,
            detailsAction: () => {
                root.showBluetoothPanel = true
            }
        },
        "dnd": {
            name: "Do Not Disturb",
            icon: "do_not_disturb_on",
            iconOff: "do_not_disturb_off",
            toggled: Notifications.silent,
            statusText: Notifications.silent ? "On" : "Off",
            action: () => { Notifications.silent = !Notifications.silent }
        },
        "darkMode": {
            name: "Dark Mode",
            icon: "contrast",
            iconOff: "contrast",
            toggled: Config.options.appearance.background.darkmode,
            statusText: Config.options.appearance.background.darkmode ? "Dark" : "Light",
            action: () => Wallpapers.toggleDarkMode()
        },
        "caffeine": {
            name: "Keep Awake",
            icon: "kettle",
            iconOff: "coffee",
            toggled: Config.options.quickSettings.caffeineActive,
            statusText: Config.options.quickSettings.caffeineActive ? "Active" : "Inactive",
            action: () => {
                Config.options.quickSettings.caffeineActive = !Config.options.quickSettings.caffeineActive
            }
        },
        "nightLight": {
            name: "Night Mode",
            icon: "bedtime",
            iconOff: "bedtime",
            toggled: Hyprsunset.active,
            statusText: Hyprsunset.active ? "On" : "Off",
            action: () => Hyprsunset.toggle(),
            hasDetails: true,
            detailsAction: () => { root.showNightModePanel = true }
        },
        "warp": {
            name: "WARP VPN",
            icon: "cloud",
            iconOff: "cloud_off",
            toggled: Network.warpConnected,
            statusText: Network.warpConnected ? "Connected" : "Disconnected",
            available: Network.warpCLIInstalled,
            action: () => Network.toggleWarp()
        },
        "audioOutput": {
            name: "Audio Output",
            icon: "volume_up",
            iconOff: "volume_off",
            toggled: !audioMuted,
            statusText: audioMuted ? "Muted" : "Unmuted",
            action: () => Audio.toggleMute(),
            hasDetails: true,
            detailsAction: () => {
                root.showAudioOutputPanel = true
            }
        },
        "audioInput": {
            name: "Audio Input",
            icon: "mic",
            iconOff: "mic_off",
            toggled: !micMuted,
            statusText: micMuted ? "Muted" : "Enabled",
            action: () => Audio.toggleMicMute(),
            hasDetails: true,
            detailsAction: () => {
                root.showAudioInputPanel = true
            }
        },
        "powerProfile": {
            name: "Power Profile",
            icon: powerProfileIcon,
            iconOff: powerProfileIcon,
            toggled: PowerProfileService.currentProfile !== "daily",
            statusText: PowerProfileService.currentProfile === "performance" ? "Performance" : PowerProfileService.currentProfile === "balanced" ? "Balanced" : "Power Saving",
            action: () => PowerProfileService.cycle(),
            hasDetails: true,
            detailsAction: () => { root.showPowerProfilePanel = true }
        },
        "gameMode": {
            name: "Game Mode",
            icon: "gamepad",
            iconOff: "gamepad",
            toggled: GameMode.active,
            statusText: GameMode.active ? "On" : "Off",
            action: () => GameMode.toggle()
        },
        "colorPicker": {
            name: "Color Picker",
            icon: "colorize",
            iconOff: "colorize",
            toggled: false,
            statusText: "Pick",
            action: () => {
                root.close();
                Functions.General.delayedAction(300, () => Quickshell.execDetached(["hyprpicker", "-a"]));
            }
        },
        "screenSnip": {
            name: "Screen Snip",
            icon: "screenshot_region",
            iconOff: "screenshot_region",
            toggled: false,
            statusText: "Capture",
            action: () => {
                root.close();
                Functions.General.delayedAction(300, () => RegionService.screenshot());
            }
        },
        "screenRecord": {
            name: ScreenRecord.active ? "Recording" : "Record Screen",
            icon: "screen_record",
            iconOff: "screen_record",
            toggled: ScreenRecord.active,
            statusText: ScreenRecord.active ? "Tap to save" : ScreenRecord.modeLabel,
            tooltipText: ScreenRecord.active ? "Tap to save" : ("Mode: " + ScreenRecord.modeLabel),
            action: () => {
                if (ScreenRecord.active) ScreenRecord.stop();
                else {
                    root.close();
                    Functions.General.delayedAction(300, () => {
                        if (ScreenRecord.recordingMode === 0) RegionService.record();
                        else if (ScreenRecord.recordingMode === 1) RegionService.recordWithSound();
                        else if (ScreenRecord.recordingMode === 2) RegionService.recordFullscreenWithSound();
                    });
                }
            },
            altAction: () => {
                if (!ScreenRecord.active) {
                    ScreenRecord.cycleMode();
                }
            }
        },
        "musicRecognition": {
            name: "Identify Music",
            icon: SongRec.running ? "music_cast" : (SongRec.monitorSource === SongRec.MonitorSource.Monitor ? "music_note" : "frame_person_mic"),
            iconOff: "music_note",
            toggled: SongRec.running,
            statusText: SongRec.running ? "Listening..." : (SongRec.monitorSource === SongRec.MonitorSource.Monitor ? "System" : "Mic"),
            action: () => SongRec.toggleRunning(),
            altAction: () => SongRec.toggleMonitorSource(),
            tooltipText: "Mode: " + (SongRec.running ? "Listening" : "Idle") + " (" + SongRec.monitorSourceString + ")"
        },
        "easyEffects": {
            name: "EasyEffects",
            icon: "graphic_eq",
            iconOff: "graphic_eq",
            toggled: EasyEffects.active,
            available: EasyEffects.available,
            statusText: EasyEffects.active ? "On" : "Off",
            action: () => EasyEffects.toggle(),
            altAction: () => Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"])
        },
        "conservationMode": {
            name: "Conservation",
            icon: "battery_charging_80",
            iconOff: "battery_charging_full",
            toggled: ConservationMode.active,
            available: ConservationMode.available,
            statusText: ConservationMode.active ? "On" : "Off",
            action: () => ConservationMode.toggle(),
            tooltipText: "Lenovo Battery Conservation Mode"
        }
    })

    // ── Toggle state properties ──
    property bool audioMuted: Audio.muted
    property bool micMuted: Audio.microphoneMuted
    property string powerProfileIcon: PowerProfileService.currentProfile === "performance" ? "local_fire_department" : (PowerProfileService.currentProfile === "balanced" ? "balance" : "eco")

    // ── Toggle data (matching example pattern exactly) ──
    readonly property list<string> availableToggleTypes: [
        "wifi", "bluetooth", "dnd", "darkMode", "caffeine", "nightLight",
        "warp", "audioOutput", "audioInput", "powerProfile",
        "gameMode", "colorPicker", "screenSnip", "screenRecord",
        "musicRecognition", "easyEffects", "conservationMode"
    ]
    readonly property list<var> toggles: Config.options.quickSettings.toggles
    readonly property list<var> toggleRows: toggleRowsForList(toggles)
    readonly property list<var> unusedToggles: {
        const types = availableToggleTypes.filter(type => {
            if (toggles.some(toggle => (toggle && toggle.type === type))) return false;
            const typeInfo = root.allToggles[type];
            if (typeInfo && typeInfo.available === false) return false;
            return true;
        })
        return types.map(type => { return { type: type, size: 1 } })
    }
    readonly property list<var> unusedToggleRows: toggleRowsForList(unusedToggles)

    function toggleRowsForList(togglesList) {
        var rows = [];
        var row = [];
        var totalSize = 0;
        for (var i = 0; i < togglesList.length; i++) {
            if (!togglesList[i]) continue;
            var typeInfo = root.allToggles[togglesList[i].type];
            
            // Skip if the toggle is not registered or explicitly marked as unavailable
            if (!typeInfo || typeInfo.available === false) continue;

            var size = togglesList[i].size || 1;
            if (totalSize + size > columns) {
                rows.push(row);
                row = [];
                totalSize = 0;
            }
            // Clone the object and add the original index
            var toggleWithIdx = Object.assign({}, togglesList[i]);
            toggleWithIdx.originalIndex = i;
            row.push(toggleWithIdx);
            totalSize += size;
        }
        if (row.length > 0) rows.push(row);
        return rows;
    }

    // ── VOLUME/MIC WATCHERS ──
    Component.onDestruction: {
        // Cleanup if needed
    }


    // ── CONTENT UI ──
    ColumnLayout {
        id: contentColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 10
        }
        spacing: 12

        // Main QS Header
        Rectangle {
            id: qsHeader
            Layout.fillWidth: true
            implicitHeight: 64
            radius: Appearance.rounding.panel
            color: Appearance.colors.colLayer1
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // User avatar
                Item {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    
                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: {
                            const cfgPath = Config.options.bar?.avatar_path;
                            if (cfgPath && cfgPath !== "") return `file://${cfgPath}`;
                            const sysPath = SystemInfo.userAvatarPath;
                            if (!sysPath || sysPath.includes("/var/lib/AccountsService/icons/")) return "";
                            return `file://${sysPath}`;
                        }
                        sourceSize: Qt.size(44, 44)
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.fill: parent
                        radius: 22
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: avatarImage
                        maskSource: avatarMask
                        visible: avatarImage.status === Image.Ready
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: avatarImage.status !== Image.Ready
                        text: "person"
                        iconSize: 24
                        fill: 1
                        color: Appearance.m3colors.m3onPrimaryContainer
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: avatarPickerProc.running = true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: -2

                    StyledText {
                        text: SystemInfo.realName
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: `Up ${DateTime.uptime}`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3outline
                    }
                }

                 // Right-side buttons
                Row {
                    spacing: 4

                    RippleButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: {
                            GlobalStates.quickWallpaperOpen = !GlobalStates.quickWallpaperOpen
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "palette"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }
                    }

                    RippleButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        colBackground: root.editMode ? Appearance.m3colors.m3primaryContainer : Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: GlobalStates.quickSettingsEditMode = !GlobalStates.quickSettingsEditMode
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.editMode ? "check" : "edit"
                            iconSize: 18
                            color: root.editMode ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurface
                        }
                    }

                    RippleButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: {
                            GlobalStates.quickSettingsOpen = false
                            GlobalStates.activateSettings()
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "settings"
                            iconSize: 18
                            color: Appearance.m3colors.m3onSurface
                        }
                    }

                    RippleButton {
                        implicitWidth: 36
                        implicitHeight: 36
                        buttonRadius: 18
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: {
                            GlobalStates.quickSettingsOpen = false
                            GlobalStates.sessionOpen = true
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "power_settings_new"
                            iconSize: 18
                            color: Appearance.m3colors.m3error
                        }
                    }
                }
            }
        }

        // ── Performance Stats Island ──
        PerformanceStats {
            visible: Config.options.quickSettings?.showPerformanceStats ?? true
            Layout.preferredHeight: visible ? implicitHeight : 0
            clip: !visible
        }

        // ── Sliders Island ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: sliderCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: sliderCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Brightness (Full Width)
                QuickSlider {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    configuration: StyledSlider.Configuration.M
                    visible: true
                    from: 0.0
                    to: 1.0
                    property var mon: {
                        const screen = Hyprland.focusedMonitor;
                        if (!screen) return null;
                        return Brightness.getMonitorByName(screen.name);
                    }
                    value: mon ? mon.brightness : 0.5
                    materialSymbol: "brightness_6"
                    onMoved: {
                        if (mon) mon.setBrightness(value);
                    }
                }

                // Volume + Mic (Row)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                        QuickSlider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            configuration: StyledSlider.Configuration.M
                            visible: true
                            from: 0.0
                            to: 1.0
                            value: Audio.volume
                            materialSymbol: Audio.muted ? "volume_off" : "volume_up"
                            onMoved: Audio.setVolume(value)
                        }
                    
                    
                        QuickSlider {
                            id: micSlider
                            Layout.fillWidth: true
                            configuration: StyledSlider.Configuration.M
                            visible: true
                            from: 0.0
                            to: 1.0
                            value: Audio.microphoneVolume
                            materialSymbol: Audio.microphoneMuted ? "mic_off" : "mic"
                            onMoved: Audio.setMicrophoneVolume(value)
                        }
                }
            }
        }

    component QuickSlider: StyledSlider { 
        id: quickSlider
        required property string materialSymbol
        configuration: StyledSlider.Configuration.L
        stopIndicatorValues: []
        
        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.82
            anchors {
                verticalCenter: parent.verticalCenter
                right: nearFull ? quickSlider.handle.right : parent.right
                rightMargin: icon.nearFull ? 16 : 10
            }
            iconSize: 20
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: quickSlider.materialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }

        // ── Toggle Grid Island ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: toggleColumn.implicitHeight + (root.togglePadding * 2)
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1

            Column {
                id: toggleColumn
                anchors {
                    fill: parent
                    margins: root.togglePadding
                }
                spacing: 12

                // Active toggles
                Column {
                    id: activeRows
                    width: parent.width
                    spacing: root.toggleSpacing

                    Repeater {
                        model: ScriptModel {
                            values: Array(root.toggleRows.length)
                        }

                        delegate: RowLayout {
                            id: toggleRow
                            required property int index
                            property var modelData: root.toggleRows[index]
                            width: parent.width
                            spacing: root.toggleSpacing

                            Repeater {
                                model: ScriptModel {
                                    values: toggleRow?.modelData ?? []
                                    objectProp: "type"
                                }

                                delegate: ToggleDelegate {
                                    required property var modelData
                                    required property int index
                                    buttonIndex: modelData.originalIndex ?? -1
                                    buttonData: modelData
                                    allToggles: root.allToggles
                                    editMode: root.editMode
                                    baseCellWidth: root.baseCellWidth
                                    baseCellHeight: root.baseCellHeight
                                    cellSpacing: root.toggleSpacing

                                    onOpenDetails: {
                                        const type = modelData.type
                                        // Handle new panels directly — JS closures in reactive allToggles
                                        // can lose their binding context on re-evaluation
                                        if (type === "powerProfile") {
                                            root.showPowerProfilePanel = true
                                            return
                                        }
                                        if (type === "nightLight") {
                                            root.showNightModePanel = true
                                            return
                                        }
                                        const data = root.allToggles[type]
                                        if (data?.detailsAction) data.detailsAction()
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // Separator (edit mode only)
                // Removed by user request

                // Available/unused toggles (edit mode only)
                Loader {
                    width: parent.width
                    active: root.editMode && root.unusedToggles.length > 0
                    visible: active
                    sourceComponent: Column {
                        spacing: 8

                        StyledText {
                            text: "Available toggles"
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3outline
                        }

                        Column {
                            width: parent.width
                            spacing: root.toggleSpacing

                            Repeater {
                                model: ScriptModel {
                                    values: Array(root.unusedToggleRows.length)
                                }

                                delegate: RowLayout {
                                    id: unusedRow
                                    required property int index
                                    property var modelData: root.unusedToggleRows[index]
                                    width: parent.width
                                    spacing: root.toggleSpacing

                                    Repeater {
                                        model: ScriptModel {
                                            values: unusedRow?.modelData ?? []
                                            objectProp: "type"
                                        }

                                        delegate: ToggleDelegate {
                                            required property var modelData
                                            required property int index
                                            buttonIndex: -1  // Not in active list
                                            buttonData: modelData
                                            allToggles: root.allToggles
                                            editMode: root.editMode
                                            baseCellWidth: root.baseCellWidth
                                            baseCellHeight: root.baseCellHeight
                                            cellSpacing: root.toggleSpacing
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Privacy Info Island ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: privacyCol.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            visible: Privacy.anyActive

            ColumnLayout {
                id: privacyCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: Privacy.microphoneActive

                    MaterialSymbol {
                        text: "mic"
                        iconSize: 18
                        color: Appearance.m3colors.m3primary
                        fill: 1
                    }

                    StyledText {
                        text: `Microphone is being used by <b>${Privacy.microphoneApp}</b>`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurface
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: Privacy.screensharingActive

                    MaterialSymbol {
                        text: "screen_share"
                        iconSize: 18
                        color: Appearance.m3colors.m3primary
                        fill: 1
                    }

                    StyledText {
                        text: `Screen is being shared by <b>${Privacy.screensharingApp}</b>`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurface
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // ── Interactive Key Helpers (Edit Mode) ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer1
            visible: root.editMode
            opacity: root.editMode ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                RowLayout {
                    spacing: 20
                    opacity: 0.8

                    // Add/Remove
                    RowLayout {
                        spacing: 8
                        StyledText { text: "Add/Remove"; font.pixelSize: 10; color: Appearance.colors.colOnLayer1 }
                        Rectangle {
                            width: 44; height: 18; radius: 4
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "LClick"; font.pixelSize: 9; font.weight: Font.Bold }
                        }
                    }

                    // Resize
                    RowLayout {
                        spacing: 8
                        StyledText { text: "Resize"; font.pixelSize: 10; color: Appearance.colors.colOnLayer1 }
                        Rectangle {
                            width: 44; height: 18; radius: 4
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "RClick"; font.pixelSize: 9; font.weight: Font.Bold }
                        }
                    }


                    // Move
                    RowLayout {
                        spacing: 8
                        StyledText { text: "Move"; font.pixelSize: 10; color: Appearance.colors.colOnLayer1 }
                        Rectangle {
                            width: 38; height: 18; radius: 4
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "Scroll"; font.pixelSize: 10; font.weight: Font.Bold }
                        }
                    }
                }
            }

        }

    }

    // ════════════════════════════════════════
    //            DETAIL PANELS
    // ════════════════════════════════════════

    // WiFi Panel
    Loader {
        anchors.fill: parent
        active: root.showWifiPanel
        sourceComponent: WifiPanel {
            onDismiss: root.showWifiPanel = false
        }
    }

    // Bluetooth Panel
    Loader {
        anchors.fill: parent
        active: root.showBluetoothPanel
        sourceComponent: BluetoothPanel {
            onDismiss: root.showBluetoothPanel = false
        }
    }

    // Audio Output Panel
    Loader {
        anchors.fill: parent
        active: root.showAudioOutputPanel
        sourceComponent: AudioPanel {
            isSink: true
            panelTitle: "Audio Output"
            panelIcon: "volume_up"
            onDismiss: root.showAudioOutputPanel = false
        }
    }

    // Audio Input Panel
    Loader {
        anchors.fill: parent
        active: root.showAudioInputPanel
        sourceComponent: AudioPanel {
            isSink: false
            panelTitle: "Audio Input"
            panelIcon: "mic"
            onDismiss: root.showAudioInputPanel = false
        }
    }

    // Night Mode Panel
    Loader {
        anchors.fill: parent
        active: root.showNightModePanel
        sourceComponent: NightModePanel {
            onDismiss: root.showNightModePanel = false
        }
    }

    // Power Profile Panel
    Loader {
        anchors.fill: parent
        active: root.showPowerProfilePanel
        sourceComponent: PowerProfilePanel {
            currentMode: PowerProfileService.currentProfile
            onSetProfile: (id) => PowerProfileService.setProfile(id)
            onDismiss: root.showPowerProfilePanel = false
        }
    }
    
    Process {
        id: avatarPickerProc
        command: ["bash", "-c", "cd /tmp && qs -c nandoroid ipc call spotlight browse_avatar"]
    }
}
