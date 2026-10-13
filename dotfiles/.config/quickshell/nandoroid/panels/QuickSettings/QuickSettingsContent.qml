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
    implicitHeight: contentColumn.implicitHeight + (20 * Appearance.effectiveScale)

    focus: true

    // Detail panel visibility
    property bool showWifiPanel: false
    property bool showBluetoothPanel: false
    property bool showAudioOutputPanel: false
    property bool showAudioInputPanel: false
    property bool showNightModePanel: false
    property bool showPowerProfilePanel: false
    property bool showNotificationModePanel: false

    // ── Keyboard navigation state ──
    property bool cheatsheetOpen: false
    property bool navEngaged: false
    property string navZone: "grid"
    property int navSliderIndex: 0
    property string navGridType: ""
    property var _toggleDelegates: ({})
    property bool panelOpenedViaKeyboard: false
    readonly property bool anyDetailOpen: root.showWifiPanel || root.showBluetoothPanel || root.showAudioOutputPanel
        || root.showAudioInputPanel || root.showNightModePanel || root.showPowerProfilePanel || root.showNotificationModePanel
    readonly property bool navActive: root.activeFocus && GlobalStates.quickSettingsOpen && !root.editMode && !root.anyDetailOpen



    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.panel
        
        
        // Prevent clicks inside the panel from falling through to the Overlay background closer
    }

    function close() { root.closed(); }

    function closeOverlayOrPanel() {
        if (root.anyDetailOpen) root.closeDetailPanels();
        else root.close();
    }

    function closeDetailPanels() {
        root.showWifiPanel = false;
        root.showBluetoothPanel = false;
        root.showAudioOutputPanel = false;
        root.showAudioInputPanel = false;
        root.showNightModePanel = false;
        root.showPowerProfilePanel = false;
        root.showNotificationModePanel = false;
    }

    // ── Keyboard navigation ──

    function findByName(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        const kids = item.children;
        for (let i = 0; i < kids.length; i++) {
            const r = root.findByName(kids[i], name);
            if (r) return r;
        }
        return null;
    }

    function headerButton(i) {
        const names = ["qsHeaderWallpaper", "qsHeaderEdit", "qsHeaderSettings", "qsHeaderPower"];
        if (i < 0 || i >= names.length) return null;
        const host = qsHeaderLoader.item;
        if (!host) return null;
        return root.findByName(host, names[i]);
    }

    function sliderAt(i) {
        if (i === 0) return brightnessSlider;
        if (i === 1) return volumeSlider;
        if (i === 2) return micSlider;
        return null;
    }

    function sliderAdjust(delta) {
        const s = root.sliderAt(root.navSliderIndex);
        if (!s) return;
        const target = Math.max(s.from, Math.min(s.to, s.value + delta));
        if (root.navSliderIndex === 0) {
            if (target >= s.gammaBoundary) {
                const b = (target - s.gammaBoundary) / (1 - s.gammaBoundary);
                if (s.mon) s.mon.setBrightness(b);
                if (s.dimming) Hyprsunset.resetGamma();
            } else {
                if (s.mon && s.mon.brightness !== 0) s.mon.setBrightness(0);
                Hyprsunset.setGamma(target / s.gammaBoundary * (100 - Hyprsunset.gammaLowerLimit) + Hyprsunset.gammaLowerLimit);
            }
        } else if (root.navSliderIndex === 1) {
            Audio.setVolume(target);
        } else {
            Audio.setMicrophoneVolume(target);
        }
    }

    function setZone(z) {
        root.navZone = z;
        if (z === "grid") {
            const keys = root.gridDelegateKeys();
            if (keys.length === 0 || keys.indexOf(root.navGridType) < 0) {
                root.navGridType = keys.length > 0 ? keys[0] : "";
            }
        }
    }

    function zoneNext(dir) {
        root.navEngaged = true;
        const zones = root.gridAvailable ? ["grid", "sliders"] : ["sliders"];
        const i = zones.indexOf(root.navZone);
        if (i >= 0) {
            root.setZone(zones[(i + dir + zones.length) % zones.length]);
        } else {
            root.setZone(zones[0]);
        }
        root.syncNavHighlight();
    }

    function resetNav() {
        root.navEngaged = false;
        root.navZone = root.gridAvailable ? "grid" : "sliders";
        root.navSliderIndex = 0;
        root.navGridType = "";
        Qt.callLater(() => { root.syncNavHighlight(); });
    }

    function syncNavHighlight() {
        if (!root.navActive) {
            navRing.visible = false; return;
        }
        let target = null;
        if (root.navZone === "sliders") {
            target = root.sliderAt(root.navSliderIndex);
        } else {
            target = root._toggleDelegates[root.navGridType];
            if (!target || !target.visible) {
                const keys = root.gridDelegateKeys();
                if (keys.length === 0) { navRing.visible = false; return; }
                if (keys.indexOf(root.navGridType) < 0) root.navGridType = keys[0];
                target = root._toggleDelegates[root.navGridType];
            }
        }
        if (!target || !target.visible) {
            navRing.visible = false; return;
        }
        navRing.targetItem = target;
        navRing.visible = root.navActive && root.navEngaged;
    }

    function navUp() {
        root.navEngaged = true;
        if (root.navZone === "sliders") {
            if (root.navSliderIndex > 0) root.navSliderIndex--;
            root.syncNavHighlight();
            return;
        }
        const t = root.gridMove(-1, 0);
        if (t !== "") root.navGridType = t;
        root.syncNavHighlight();
    }

    function navDown() {
        root.navEngaged = true;
        if (root.navZone === "sliders") {
            if (root.navSliderIndex < 2) root.navSliderIndex++;
            root.syncNavHighlight();
            return;
        }
        const t = root.gridMove(1, 0);
        if (t !== "") root.navGridType = t;
        root.syncNavHighlight();
    }

    function navLeft() {
        root.navEngaged = true;
        if (root.navZone === "sliders") {
            root.sliderAdjust(-0.05);
        } else {
            const t = root.gridMove(0, -1);
            if (t !== "") root.navGridType = t;
            root.syncNavHighlight();
        }
    }

    function navRight() {
        root.navEngaged = true;
        if (root.navZone === "sliders") {
            root.sliderAdjust(0.05);
        } else {
            const t = root.gridMove(0, 1);
            if (t !== "") root.navGridType = t;
            root.syncNavHighlight();
        }
    }

    function navActivate() {
        if (root.navZone === "grid") {
            const del = root._toggleDelegates[root.navGridType];
            if (del && typeof del.triggerAction === "function") {
                // Pulse the row squeeze so keyboard toggles feel like presses
                if (typeof del.squeezePulse === "function") del.squeezePulse();
                del.triggerAction();
            }
            else if (del) del.click();
        }
        root.syncNavHighlight();
    }

    function navOpenDetails() {
        if (root.navZone !== "grid") return;
        const del = root._toggleDelegates[root.navGridType];
        if (del) {
            root.panelOpenedViaKeyboard = true;
            del.openDetails();
            root.panelOpenedViaKeyboard = false;
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Slash) {
            root.cheatsheetOpen = !root.cheatsheetOpen;
            event.accepted = true;
            return;
        } else if (root.cheatsheetOpen && event.key === Qt.Key_Escape) {
            root.cheatsheetOpen = false;
            event.accepted = true;
            return;
        } else if (event.key === Qt.Key_Escape) {
            root.closeOverlayOrPanel();
            event.accepted = true;
            return;
        }
        
        const hasMods = (event.modifiers & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier));

        if (!hasMods && event.key === Qt.Key_X && root.anyDetailOpen) {
            root.closeDetailPanels();
            event.accepted = true;
            return;
        }

        if (root.anyDetailOpen || root.editMode) return;
        
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            root.zoneNext(event.key === Qt.Key_Backtab ? -1 : 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.navUp();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.navDown();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.navLeft();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.navRight();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space || (!hasMods && event.key === Qt.Key_C)) {
            root.navActivate();
            event.accepted = true;
        } else if (!hasMods && event.key === Qt.Key_A) {
            const b = root.headerButton(0);
            if (b) b.click();
            event.accepted = true;
        } else if (!hasMods && event.key === Qt.Key_S) {
            const b = root.headerButton(1);
            if (b) b.click();
            event.accepted = true;
        } else if (!hasMods && event.key === Qt.Key_D) {
            const b = root.headerButton(2);
            if (b) b.click();
            event.accepted = true;
        } else if (!hasMods && event.key === Qt.Key_F) {
            const b = root.headerButton(3);
            if (b) b.click();
            event.accepted = true;
        } else if (!hasMods && event.key === Qt.Key_V) {
            root.navOpenDetails();
            event.accepted = true;
        }
    }

    Connections {
        target: GlobalStates
        function onQuickSettingsOpenChanged() {
            if (GlobalStates.quickSettingsOpen) {
                root.forceActiveFocus();
                root.resetNav();
            } else {
                root.closeDetailPanels();
                root.cheatsheetOpen = false;
                navRing.visible = false;
                GlobalStates.quickSettingsEditMode = false;
            }
        }
    }

    onActiveFocusChanged: {
        if (root.activeFocus && GlobalStates.quickSettingsOpen && !root.editMode && !root.anyDetailOpen) root.syncNavHighlight();
        else navRing.visible = false;
    }

    Component.onCompleted: {
        if (GlobalStates.quickSettingsOpen) {
            root.forceActiveFocus();
            root.resetNav();
        }
    }

    // ── Toggle grid constants ──
    // 4 columns: size 1 = 1 col (square icon), size 2 = 2 cols (icon + text)
    readonly property int columns: 4
    readonly property real toggleSpacing: 6 * Appearance.effectiveScale
    readonly property real togglePadding: 6 * Appearance.effectiveScale
    readonly property real baseCellWidth: {
        const availableWidth = root.implicitWidth - (20 * Appearance.effectiveScale) - (togglePadding * 2) - (toggleSpacing * (columns - 1))
        return Math.max(40 * Appearance.effectiveScale, Math.floor(availableWidth / columns))
    }
    readonly property real baseCellHeight: 56 * Appearance.effectiveScale

    // ── Toggle data registry ──
    readonly property var allToggles: ({
        "wifi": {
            name: I18nService.tr("Wi-Fi"),
            icon: "wifi",
            iconOff: "wifi_off",
            toggled: Network.wifiEnabled,
            statusText: Network.wifiEnabled ? Network.networkName || I18nService.tr("On") : I18nService.tr("Off"),
            action: () => Network.toggleWifi(),
            hasDetails: true,
            detailsAction: () => {
                root.showWifiPanel = true
            }
        },
        "bluetooth": {
            name: I18nService.tr("Bluetooth"),
            icon: "bluetooth",
            iconOff: "bluetooth_disabled",
            toggled: BluetoothStatus.enabled,
            statusText: BluetoothStatus.connected ? `${BluetoothStatus.activeDeviceCount} ${I18nService.tr("connected")}` : (BluetoothStatus.enabled ? I18nService.tr("On") : I18nService.tr("Off")),
            action: () => BluetoothStatus.toggle(),
            hasDetails: true,
            detailsAction: () => {
                root.showBluetoothPanel = true
            }
        },
        "dnd": {
            name: I18nService.tr("Notification Mode"),
            icon: Notifications.mode === 2 ? "notifications_off" : (Notifications.mode === 1 ? "vibration" : "notifications_active"),
            iconOff: Notifications.mode === 2 ? "notifications_off" : (Notifications.mode === 1 ? "vibration" : "notifications_active"),
            toggled: Notifications.mode > 0,
            statusText: Notifications.mode === 2 ? I18nService.tr("DND") : (Notifications.mode === 1 ? I18nService.tr("Silent") : I18nService.tr("Normal")),
            action: () => { Notifications.mode = (Notifications.mode + 1) % 3 },
            hasDetails: true,
            detailsAction: () => { root.showNotificationModePanel = true }
        },
        "darkMode": {
            name: I18nService.tr("Dark Mode"),
            icon: "contrast",
            iconOff: "contrast",
            toggled: Config.options.appearance.background.darkmode,
            statusText: Config.options.appearance.background.darkmode ? I18nService.tr("Dark") : I18nService.tr("Light"),
            action: () => Wallpapers.toggleDarkMode()
        },
        "caffeine": {
            name: I18nService.tr("Keep Awake"),
            icon: "kettle",
            iconOff: "coffee",
            toggled: Config.options.quickSettings.caffeineActive,
            statusText: Config.options.quickSettings.caffeineActive ? I18nService.tr("Active") : I18nService.tr("Inactive"),
            action: () => {
                Config.options.quickSettings.caffeineActive = !Config.options.quickSettings.caffeineActive
            }
        },
        "nightLight": {
            name: I18nService.tr("Night Mode"),
            icon: "bedtime",
            iconOff: "bedtime",
            toggled: Hyprsunset.active,
            statusText: Hyprsunset.active ? I18nService.tr("On") : I18nService.tr("Off"),
            action: () => Hyprsunset.toggle(),
            hasDetails: true,
            detailsAction: () => { root.showNightModePanel = true }
        },
        "warp": {
            name: I18nService.tr("WARP VPN"),
            icon: "cloud",
            iconOff: "cloud_off",
            toggled: Network.warpConnected,
            statusText: Network.warpConnected ? I18nService.tr("Connected") : I18nService.tr("Disconnected"),
            available: Network.warpCLIInstalled,
            action: () => Network.toggleWarp()
        },
        "audioOutput": {
            name: I18nService.tr("Audio Output"),
            icon: "volume_up",
            iconOff: "volume_off",
            toggled: !audioMuted,
            statusText: audioMuted ? I18nService.tr("Muted") : I18nService.tr("Unmuted"),
            action: () => Audio.toggleMute(),
            hasDetails: true,
            detailsAction: () => {
                root.showAudioOutputPanel = true
            }
        },
        "audioInput": {
            name: I18nService.tr("Audio Input"),
            icon: "mic",
            iconOff: "mic_off",
            toggled: !micMuted,
            statusText: micMuted ? I18nService.tr("Muted") : I18nService.tr("Enabled"),
            action: () => Audio.toggleMicMute(),
            hasDetails: true,
            detailsAction: () => {
                root.showAudioInputPanel = true
            }
        },
        "powerProfile": {
            name: I18nService.tr("Power Profile"),
            icon: powerProfileIcon,
            iconOff: powerProfileIcon,
            toggled: PowerProfileService.currentProfile !== "daily",
            statusText: PowerProfileService.currentProfile === "performance" ? I18nService.tr("Performance") : PowerProfileService.currentProfile === "balanced" ? I18nService.tr("Balanced") : I18nService.tr("Power Saving"),
            action: () => PowerProfileService.cycle(),
            hasDetails: true,
            detailsAction: () => { root.showPowerProfilePanel = true }
        },
        "gameMode": {
            name: I18nService.tr("Game Mode"),
            icon: "gamepad",
            iconOff: "gamepad",
            toggled: GameMode.active,
            statusText: GameMode.active ? I18nService.tr("On") : I18nService.tr("Off"),
            action: () => GameMode.toggle()
        },
        "colorPicker": {
            name: I18nService.tr("Color Picker"),
            icon: "colorize",
            iconOff: "colorize",
            toggled: false,
            statusText: I18nService.tr("Pick"),
            action: () => {
                root.close();
                Functions.General.delayedAction(300, () => Quickshell.execDetached(["hyprpicker", "-a"]));
            }
        },
        "screenSnip": {
            name: I18nService.tr("Screen Snip"),
            icon: "screenshot_region",
            iconOff: "screenshot_region",
            toggled: false,
            statusText: I18nService.tr("Capture"),
            action: () => {
                root.close();
                Functions.General.delayedAction(300, () => RegionService.screenshot());
            }
        },
        "screenRecord": {
            name: ScreenRecord.active ? I18nService.tr("Recording") : I18nService.tr("Record Screen"),
            icon: "screen_record",
            iconOff: "screen_record",
            toggled: ScreenRecord.active,
            statusText: ScreenRecord.active ? I18nService.tr("Tap to save") : ScreenRecord.modeLabel,
            tooltipText: ScreenRecord.active ? I18nService.tr("Tap to save") : (I18nService.tr("Mode: ") + ScreenRecord.modeLabel),
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
            name: I18nService.tr("Identify Music"),
            icon: SongRec.running ? "music_cast" : (SongRec.monitorSource === SongRec.MonitorSource.Monitor ? "music_note" : "frame_person_mic"),
            iconOff: "music_note",
            toggled: SongRec.running,
            statusText: SongRec.running ? I18nService.tr("Listening...") : (SongRec.monitorSource === SongRec.MonitorSource.Monitor ? I18nService.tr("System") : I18nService.tr("Mic")),
            action: () => SongRec.toggleRunning(),
            altAction: () => SongRec.toggleMonitorSource(),
            tooltipText: I18nService.tr("Mode: ") + (SongRec.running ? I18nService.tr("Listening") : I18nService.tr("Idle")) + " (" + SongRec.monitorSourceString + ")"
        },
        "easyEffects": {
            name: I18nService.tr("EasyEffects"),
            icon: "graphic_eq",
            iconOff: "graphic_eq",
            toggled: EasyEffects.active,
            available: EasyEffects.available,
            statusText: EasyEffects.active ? I18nService.tr("On") : I18nService.tr("Off"),
            action: () => EasyEffects.toggle(),
            altAction: () => Quickshell.execDetached(["bash", "-c", "flatpak run com.github.wwmm.easyeffects || easyeffects"])
        },
        "conservationMode": {
            name: I18nService.tr("Conservation"),
            icon: "battery_charging_80",
            iconOff: "battery_charging_full",
            toggled: ConservationMode.active,
            available: ConservationMode.available,
            statusText: ConservationMode.active ? I18nService.tr("On") : I18nService.tr("Off"),
            action: () => ConservationMode.toggle(),
            tooltipText: I18nService.tr("Lenovo Battery Conservation Mode")
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

    // ── Keyboard grid model (geometry-based: operates on the actual rendered toggles) ──
    readonly property bool gridAvailable: root.toggleRows.length > 0

    function gridDelegateKeys() {
        const keys = [];
        for (const k in root._toggleDelegates) {
            const d = root._toggleDelegates[k];
            if (d && d.visible) keys.push(k);
        }
        return keys;
    }

    function gridStructure() {
        const island = toggleGridIsland;
        if (!island) return [];
        const entries = [];
        for (const k in root._toggleDelegates) {
            const d = root._toggleDelegates[k];
            if (!d || !d.visible) continue;
            let p = null;
            try { p = d.mapToItem(island, 0, 0); } catch (e) { continue; }
            if (!p) continue;
            entries.push({ idx: k, x: p.x, y: p.y, w: d.width, h: d.height });
        }
        const buckets = [];
        const ys = [];
        for (const e of entries) {
            let placed = false;
            for (let r = 0; r < ys.length; r++) {
                if (Math.abs(e.y - ys[r]) <= 2) { buckets[r].push(e); placed = true; break; }
            }
            if (!placed) { ys.push(e.y); buckets.push([e]); }
        }
        const order = ys.map((y, r) => r).sort((a, b) => ys[a] - ys[b]);
        return order.map(r => buckets[r].slice().sort((a, b) => a.x - b.x));
    }

    function isGridTopRow() {
        const grid = root.gridStructure();
        if (grid.length === 0) return false;
        return grid[0].some(c => c.idx === root.navGridType);
    }

    function gridMove(dr, dc) {
        const grid = root.gridStructure();
        if (grid.length === 0) return "";
        let curRow = -1;
        let curIdx = -1;
        for (let r = 0; r < grid.length && curRow < 0; r++) {
            for (let c = 0; c < grid[r].length; c++) {
                if (grid[r][c].idx === root.navGridType) { curRow = r; curIdx = c; break; }
            }
        }
        if (curRow < 0) { root.navGridType = grid[0][0].idx; return ""; }
        const cur = grid[curRow][curIdx];
        if (dr !== 0) {
            const tr = curRow + dr;
            if (tr < 0 || tr >= grid.length) return "";
            const myStart = cur.x;
            const myEnd = cur.x + cur.w;
            const myCenter = cur.x + cur.w / 2;
            let best = "";
            let bestScore = -Infinity;
            for (const f of grid[tr]) {
                const overlap = Math.max(0, Math.min(f.x + f.w, myEnd) - Math.max(f.x, myStart));
                const fCenter = f.x + f.w / 2;
                const score = overlap * 10000 - Math.abs(fCenter - myCenter);
                if (score > bestScore) { bestScore = score; best = f.idx; }
            }
            return best;
        }
        const target = dc > 0 ? curIdx + 1 : curIdx - 1;
        if (target >= 0 && target < grid[curRow].length) return grid[curRow][target].idx;
        return "";
    }

    function registerToggleDelegate(type, d) {
        if (!type) return;
        root._toggleDelegates[type] = d;
    }

    function unregisterToggleDelegate(type, d) {
        if (!type) return;
        if (d === undefined || root._toggleDelegates[type] === d) {
            delete root._toggleDelegates[type];
        }
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
            margins: 10 * Appearance.effectiveScale
        }
        spacing: 12 * Appearance.effectiveScale

        // Main QS Header / Banner
        Loader {
            id: qsHeaderLoader
            Layout.fillWidth: true
            Layout.preferredHeight: item ? item.implicitHeight : 0
            sourceComponent: Config.options.quickSettings.showBanner ? bannerComponent : normalHeaderComponent
        }

        Component {
            id: normalHeaderComponent
            Rectangle {
                implicitHeight: 64 * Appearance.effectiveScale
                radius: Appearance.rounding.panel
                color: Appearance.colors.colLayer1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12 * Appearance.effectiveScale
                    anchors.rightMargin: 12 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    // User avatar
                    Item {
                        Layout.preferredWidth: 44 * Appearance.effectiveScale
                        Layout.preferredHeight: 44 * Appearance.effectiveScale

                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            source: {
                                const profPath = Config.options.profile?.avatarPicture;
                                if (profPath && profPath !== "") return "file://" + profPath;
                                const cfgPath = Config.options.bar?.avatar_path;
                                if (cfgPath && cfgPath !== "") return "file://" + cfgPath;
                                if (SystemInfo.userAvatarValid) return "file://" + SystemInfo.userAvatarPath;
                                return "";
                            }
                            sourceSize: Qt.size(44 * Appearance.effectiveScale, 44 * Appearance.effectiveScale)
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        Rectangle {
                            id: avatarMask
                            anchors.fill: parent
                            radius: 22 * Appearance.effectiveScale
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
                            iconSize: 24 * Appearance.effectiveScale
                            fill: 1
                            color: Appearance.m3colors.m3onPrimaryContainer
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.close()
                                GlobalStates.settingsPageIndex = 9
                                GlobalStates.activateSettings()
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2 * Appearance.effectiveScale

                        StyledText {
                            text: {
                                const displayName = Config.options.profile?.displayName;
                                if (displayName && displayName !== "") return displayName;
                                return SystemInfo.realName || SystemInfo.username;
                            }
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.m3colors.m3onSurface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: {
                                const descMode = Config.options.profile?.descriptionText || "::distro::";
                                if (descMode === "::uptime::") return I18nService.tr("Up ") + DateTime.uptime;
                                return SystemInfo.distroName || "Linux System";
                            }
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.family: Appearance.font.family.numbers
                            color: Appearance.m3colors.m3outline
                        }
                    }

                    // Right-side buttons
                    Row {
                        spacing: 4 * Appearance.effectiveScale

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderWallpaper"
                            onClicked: {
                                root.close()
                                GlobalStates.wallpaperSelectorTarget = "desktop"
                                GlobalStates.wallpaperSelectorOpen = true
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "palette"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: I18nService.tr("Change Wallpaper") }
                        }

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: root.editMode ? Appearance.m3colors.m3primaryContainer : "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderEdit"
                            onClicked: GlobalStates.quickSettingsEditMode = !GlobalStates.quickSettingsEditMode
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: root.editMode ? "check" : "edit"
                                iconSize: 18 * Appearance.effectiveScale
                                color: root.editMode ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: root.editMode ? I18nService.tr("Done Editing") : I18nService.tr("Edit Toggles") }
                        }

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderSettings"
                            onClicked: {
                                GlobalStates.quickSettingsOpen = false
                                GlobalStates.activateSettings()
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "settings"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: I18nService.tr("System Settings") }
                        }

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderPower"
                            onClicked: {
                                GlobalStates.quickSettingsOpen = false
                                GlobalStates.sessionOpen = true
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: I18nService.tr("Power Menu") }
                        }
                    }
                }
            }
        }

        Component {
            id: bannerComponent
            Rectangle {
                implicitHeight: 180 * Appearance.effectiveScale
                radius: Appearance.rounding.panel
                color: Appearance.colors.colLayer1
                clip: true

                Rectangle {
                    id: bannerImgRect
                    anchors {
                        top: parent.top; left: parent.left; right: parent.right
                        topMargin: 2; leftMargin: 2; rightMargin: 2
                    }
                    height: 120 * Appearance.effectiveScale
                    radius: parent.radius - 2
                    color: "transparent"

                    StyledImage {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: Config.options.profile.bannerImage !== ""
                            ? "file://" + Config.options.profile.bannerImage
                            : Config.options.appearance.background.wallpaperPath
                        cache: false
                        antialiasing: true
                        sourceSize.width: bannerImgRect.width * 2
                        sourceSize.height: bannerImgRect.height * 2
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: bannerImgRect.width
                                height: bannerImgRect.height
                                radius: bannerImgRect.radius
                            }
                        }
                    }
                }

                // Bottom area: avatar + identity (left), buttons (right), vertically centered
                Item {
                    anchors {
                        top: bannerImgRect.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }

                    RowLayout {
                        anchors {
                            left: parent.left
                            right: buttonsRow.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 12 * Appearance.effectiveScale
                            rightMargin: 8 * Appearance.effectiveScale
                        }
                        spacing: 10 * Appearance.effectiveScale

                        Rectangle {
                            width: 44 * Appearance.effectiveScale
                            height: 44 * Appearance.effectiveScale
                            radius: width / 2
                            color: Appearance.colors.colPrimaryContainer

                            Image {
                                id: bannerAvatar
                                anchors.fill: parent
                                source: {
                                    const profPath = Config.options.profile?.avatarPicture;
                                    if (profPath && profPath !== "") return "file://" + profPath;
                                    const cfgPath = Config.options.bar?.avatar_path;
                                    if (cfgPath && cfgPath !== "") return "file://" + cfgPath;
                                    if (SystemInfo.userAvatarValid) return "file://" + SystemInfo.userAvatarPath;
                                    return "";
                                }
                                sourceSize: Qt.size(44 * Appearance.effectiveScale, 44 * Appearance.effectiveScale)
                                fillMode: Image.PreserveAspectCrop
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: 44 * Appearance.effectiveScale
                                        height: 44 * Appearance.effectiveScale
                                        radius: 22 * Appearance.effectiveScale
                                    }
                                }
                                onStatusChanged: {
                                    if (status === Image.Error) visible = false
                                }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "account_circle"
                                iconSize: 28 * Appearance.effectiveScale
                                color: Appearance.colors.colOnPrimaryContainer
                                visible: bannerAvatar.status === Image.Error
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.close()
                                    GlobalStates.settingsPageIndex = 9
                                    GlobalStates.activateSettings()
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -2 * Appearance.effectiveScale

                            StyledText {
                                text: {
                                    const displayName = Config.options.profile?.displayName;
                                    if (displayName && displayName !== "") return displayName;
                                    return SystemInfo.realName || SystemInfo.username;
                                }
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            StyledText {
                                text: {
                                    const descMode = Config.options.profile?.descriptionText || "::distro::";
                                    if (descMode === "::uptime::") return I18nService.tr("Up ") + DateTime.uptime;
                                    return SystemInfo.distroName || "Linux System";
                                }
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.family: Appearance.font.family.numbers
                                color: Appearance.m3colors.m3outline
                            }
                        }
                    }

                    Row {
                        id: buttonsRow
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            rightMargin: 12 * Appearance.effectiveScale
                        }
                        spacing: 4 * Appearance.effectiveScale

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderWallpaper"
                            onClicked: {
                                root.close()
                                GlobalStates.wallpaperSelectorTarget = "desktop"
                                GlobalStates.wallpaperSelectorOpen = true
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "palette"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: I18nService.tr("Change Wallpaper") }
                        }

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: root.editMode ? Appearance.m3colors.m3primaryContainer : "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderEdit"
                            onClicked: GlobalStates.quickSettingsEditMode = !GlobalStates.quickSettingsEditMode
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: root.editMode ? "check" : "edit"
                                iconSize: 18 * Appearance.effectiveScale
                                color: root.editMode ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: root.editMode ? I18nService.tr("Done Editing") : I18nService.tr("Edit Toggles") }
                        }

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderSettings"
                            onClicked: {
                                GlobalStates.quickSettingsOpen = false
                                GlobalStates.activateSettings()
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "settings"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: I18nService.tr("System Settings") }
                        }

                        RippleButton {
                            focusPolicy: Qt.NoFocus
                            implicitWidth: 36 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2
                            colRipple: Appearance.colors.colLayer2Active
                            objectName: "qsHeaderPower"
                            onClicked: {
                                GlobalStates.quickSettingsOpen = false
                                GlobalStates.sessionOpen = true
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "power_settings_new"
                                iconSize: 18 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledToolTip { text: I18nService.tr("Power Menu") }
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
            implicitHeight: sliderCol.implicitHeight + (20 * Appearance.effectiveScale)
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            ColumnLayout {
                id: sliderCol
                anchors.fill: parent
                anchors.margins: 10 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // Brightness (Full Width) with gamma dimming
                QuickSlider {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    configuration: StyledSlider.Configuration.M
                    showTrailingDot: false
                    visible: true
                    readonly property real gammaBoundary: 0.3
                    readonly property bool dimming: Hyprsunset.gamma !== 100
                    materialSymbol: dimming ? "wb_twilight" : "brightness_6"
                    secondaryMaterialSymbol: "wb_twilight"
                    stopIndicatorValues: dimming ? [] : [gammaBoundary]
                    dividerValues: [gammaBoundary]
                    property var mon: {
                        const screen = Hyprland.focusedMonitor;
                        if (!screen) return null;
                        return Brightness.getMonitorByName(screen.name);
                    }
                    value: dimming
                        ? (Hyprsunset.gamma - Hyprsunset.gammaLowerLimit) / (100 - Hyprsunset.gammaLowerLimit) * gammaBoundary
                        : gammaBoundary + (mon ? mon.brightness * (1 - gammaBoundary) : 0)
                        
                    tooltipContent: {
                        if (value >= gammaBoundary) {
                            return Math.round((value - gammaBoundary) / (1 - gammaBoundary) * 100) + "%";
                        } else {
                            const g = (value / gammaBoundary) * (100 - Hyprsunset.gammaLowerLimit) + Hyprsunset.gammaLowerLimit;
                            return Math.round(g) + "% Dim";
                        }
                    }
                        
                    onMoved: {
                        if (value >= gammaBoundary) {
                            const b = (value - gammaBoundary) / (1 - gammaBoundary);
                            if (mon) mon.setBrightness(b);
                            if (dimming) Hyprsunset.resetGamma();
                        } else {
                            if (mon && mon.brightness !== 0) mon.setBrightness(0);
                            Hyprsunset.setGamma(value / gammaBoundary * (100 - Hyprsunset.gammaLowerLimit) + Hyprsunset.gammaLowerLimit);
                        }
                    }

                }

                // Volume + Mic (Row)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                        QuickSlider {
                            id: volumeSlider
                            Layout.fillWidth: true
                            configuration: StyledSlider.Configuration.M
                            showTrailingDot: false
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
                            showTrailingDot: false
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
        focusPolicy: Qt.NoFocus
        required property string materialSymbol
        property string secondaryMaterialSymbol
        configuration: StyledSlider.Configuration.M
        
        // Override default M configuration for QS specifically
        trackWidth: 36 * Appearance.effectiveScale
        handleHeight: 48 * Appearance.effectiveScale
        trackRadius: 12 * Appearance.effectiveScale
        insetIconSize: 22 * Appearance.effectiveScale
        
        stopIndicatorValues: []
        
        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.82
            anchors {
                verticalCenter: parent.verticalCenter
                right: nearFull ? quickSlider.handle.right : parent.right
                rightMargin: icon.nearFull ? 16 * Appearance.effectiveScale : 10 * Appearance.effectiveScale
            }
            iconSize: quickSlider.insetIconSize
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: quickSlider.materialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol {
            id: secondaryIcon
            visible: secondaryMaterialSymbol.length > 0
            readonly property real iconLocation: 0.3
            property bool nearIcon: iconLocation - quickSlider.value <= 0.1 && iconLocation - quickSlider.value > (quickSlider.handleWidth + 8 * Appearance.effectiveScale - 14 * Appearance.effectiveScale) / quickSlider.effectiveDraggingWidth
            anchors {
                verticalCenter: parent.verticalCenter
                right: nearIcon ? quickSlider.handle.right : parent.right
                rightMargin: nearIcon ? 14 * Appearance.effectiveScale : (1 - iconLocation) * quickSlider.effectiveDraggingWidth + quickSlider.rightPadding + 8 * Appearance.effectiveScale
            }
            iconSize: quickSlider.insetIconSize
            color: quickSlider.value >= iconLocation - 0.1 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: secondaryMaterialSymbol

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
            id: toggleGridIsland
            Layout.fillWidth: true
            implicitHeight: toggleColumn.implicitHeight + (root.togglePadding * 2)
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            Column {
                id: toggleColumn
                anchors {
                    fill: parent
                    margins: root.togglePadding
                }
                spacing: 12 * Appearance.effectiveScale

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

                            // Shared press state for the toggle squeeze effect
                            property int pressedIndex: -1
                            readonly property int rowToggleCount: modelData?.length ?? 0

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
                                    keyboardHost: root
                                    rowIndex: index
                                    rowCoordinator: toggleRow

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
                        spacing: 8 * Appearance.effectiveScale

                        StyledText {
                            text: I18nService.tr("Available toggles")
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

                                    // Shared press state for the toggle squeeze effect
                                    property int pressedIndex: -1
                                    readonly property int rowToggleCount: modelData?.length ?? 0

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
                                            rowIndex: index
                                            rowCoordinator: unusedRow
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
            implicitHeight: privacyCol.implicitHeight + (20 * Appearance.effectiveScale)
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            visible: Privacy.anyActive

            ColumnLayout {
                id: privacyCol
                anchors.fill: parent
                anchors.margins: 10 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12 * Appearance.effectiveScale
                    visible: Privacy.microphoneActive

                    MaterialSymbol {
                        text: "mic"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3primary
                        fill: 1
                    }

                    StyledText {
                        text: I18nService.tr("Microphone is being used by ") + `<b>${Privacy.microphoneApp}</b>`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.m3colors.m3onSurface
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12 * Appearance.effectiveScale
                    visible: Privacy.screensharingActive

                    MaterialSymbol {
                        text: "screen_share"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3primary
                        fill: 1
                    }

                    StyledText {
                        text: I18nService.tr("Screen is being shared by ") + `<b>${Privacy.screensharingApp}</b>`
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
            implicitHeight: 40 * Appearance.effectiveScale
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            visible: root.editMode
            opacity: root.editMode ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12 * Appearance.effectiveScale

                RowLayout {
                    spacing: 20 * Appearance.effectiveScale
                    opacity: 0.8

                    // Add/Remove
                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        StyledText { text: I18nService.tr("Add/Remove"); font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                        Rectangle {
                            width: 44 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "LClick"; font.pixelSize: Math.round(9 * Appearance.effectiveScale); font.weight: Font.DemiBold }
                        }
                    }

                    // Resize
                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        StyledText { text: I18nService.tr("Resize"); font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                        Rectangle {
                            width: 74 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: I18nService.tr("RClick / Drag"); font.pixelSize: Math.round(9 * Appearance.effectiveScale); font.weight: Font.DemiBold }
                        }
                    }

                    // Move
                    RowLayout {
                        spacing: 8 * Appearance.effectiveScale
                        StyledText { text: I18nService.tr("Move"); font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                        Rectangle {
                            width: 38 * Appearance.effectiveScale; height: 18 * Appearance.effectiveScale; radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "Scroll"; font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold }
                        }
                    }
                }
            }

        }

    }

    // ── Keyboard focus ring ──
    Rectangle {
        id: navRing
        property Item targetItem: null

        readonly property real pad: 4 * Appearance.effectiveScale

        // Absolute position resolved by walking up the parent chain; the
        // binding reads x/y along the way so it stays reactive to layout
        // changes — including the animated width of a squeezed toggle.
        function mapToRootX(item) {
            let x = 0;
            for (let it = item; it && it !== root; it = it.parent) x += it.x;
            return x;
        }
        function mapToRootY(item) {
            let y = 0;
            for (let it = item; it && it !== root; it = it.parent) y += it.y;
            return y;
        }

        visible: false
        z: 999
        enabled: false
        color: "transparent"
        border.width: Math.max(1, 2 * Appearance.effectiveScale)
        border.color: Appearance.m3colors.m3primary
        opacity: 0.9

        x: targetItem ? mapToRootX(targetItem) - pad : 0
        y: targetItem ? mapToRootY(targetItem) - pad : 0
        width: targetItem ? targetItem.width + pad * 2 : 0
        height: targetItem ? targetItem.height + pad * 2 : 0
        // Mirror the target's own corner shape so pills get pill rings
        radius: {
            const r = (targetItem && targetItem.buttonRadius !== undefined)
                ? targetItem.buttonRadius + pad
                : 12 * Appearance.effectiveScale;
            return Math.min(r, height / 2);
        }

        // No geometry Behaviors: bindings above must track the target 1:1 so
        // the ring stays in lockstep with squeeze animations instead of
        // trailing behind them. Only the visibility fade is animated.
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    // ════════════════════════════════════════
    //            DETAIL PANELS
    // ════════════════════════════════════════

    // WiFi Panel
    Loader {
        anchors.fill: parent
        active: root.showWifiPanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: WifiPanel {
            inheritedNav: root.panelOpenedViaKeyboard
            onDismiss: root.showWifiPanel = false
        }
    }

    // Bluetooth Panel
    Loader {
        anchors.fill: parent
        active: root.showBluetoothPanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: BluetoothPanel {
            inheritedNav: root.panelOpenedViaKeyboard
            onDismiss: root.showBluetoothPanel = false
        }
    }

    // Audio Output Panel
    Loader {
        anchors.fill: parent
        active: root.showAudioOutputPanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: AudioPanel {
            isSink: true
            panelTitle: "Audio Output"
            panelIcon: "volume_up"
            inheritedNav: root.panelOpenedViaKeyboard
            onDismiss: root.showAudioOutputPanel = false
        }
    }

    // Audio Input Panel
    Loader {
        anchors.fill: parent
        active: root.showAudioInputPanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: AudioPanel {
            isSink: false
            panelTitle: "Audio Input"
            panelIcon: "mic"
            inheritedNav: root.panelOpenedViaKeyboard
            onDismiss: root.showAudioInputPanel = false
        }
    }

    // Night Mode Panel
    Loader {
        anchors.fill: parent
        active: root.showNightModePanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: NightModePanel {
            inheritedNav: root.panelOpenedViaKeyboard
            onDismiss: root.showNightModePanel = false
        }
    }

    // Power Profile Panel
    Loader {
        anchors.fill: parent
        active: root.showPowerProfilePanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: PowerProfilePanel {
            currentMode: PowerProfileService.currentProfile
            inheritedNav: root.panelOpenedViaKeyboard
            onSetProfile: (id) => PowerProfileService.setProfile(id)
            onDismiss: root.showPowerProfilePanel = false
        }
    }

    // Notification Mode Panel
    Loader {
        anchors.fill: parent
        active: root.showNotificationModePanel
        onActiveChanged: { if (!active) root.forceActiveFocus(); }
        sourceComponent: NotificationModePanel {
            inheritedNav: root.panelOpenedViaKeyboard
            onDismiss: root.showNotificationModePanel = false
        }
    }
    
    DialogCheatsheet {
        visible: root.cheatsheetOpen
        onClosed: root.cheatsheetOpen = false
        shortcuts: [
            { key: "Tab / Shift+Tab", action: "Switch Zones (Grid/Sliders)" },
            { key: "↑ ↓ ← →", action: "Navigate Grid / Adjust Sliders" },
            { key: "Enter / Space / C", action: "Toggle Setting" },
            { key: "A", action: "Wallpaper Settings" },
            { key: "S", action: "Edit Toggles" },
            { key: "D", action: "Open System Settings" },
            { key: "F", action: "Power Menu" },
            { key: "V", action: "Open Details Menu" },
            { key: "X", action: "Close Details Menu" },
            { key: "Z", action: "Toggle Power State (Detail Panel)" }
        ]
    }

}
