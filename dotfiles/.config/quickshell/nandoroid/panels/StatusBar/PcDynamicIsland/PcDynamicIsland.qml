import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"

Item {
    id: root
    property bool mirrored: false
    property alias pill: pill

    readonly property real pillHeight: 32
    readonly property real idleCollapsedWidth: 144
    property real idleTextContentWidth: 0
    property real idleExpandedContentWidth: 0
    property bool idleExpanded: idleHoverHandler.hovered
    readonly property real idleExpandedWidthCap: 260
    readonly property real idleExpandedWidth: Math.min(root.idleExpandedWidthCap, Math.max(root.idleCollapsedWidth, root.idleExpandedContentWidth))
    readonly property real idleWidth: root.idleExpanded ? root.idleExpandedWidth : Math.max(root.idleCollapsedWidth, root.idleTextContentWidth)
    readonly property real mediaCollapsedWidth: 140
    readonly property real mediaExpandedWidthCap: 220
    property real mediaTextContentWidth: 0
    property bool mediaTrackInfoVisible: mediaHoverHandler.hovered || mediaTrackChangeTimer.running
    readonly property real mediaExpandedWidth: Math.min(root.mediaExpandedWidthCap, root.mediaTextContentWidth)
    readonly property real mediaWidth: root.mediaTrackInfoVisible ? root.mediaExpandedWidth : root.mediaCollapsedWidth
    // --- Timer / Pomodoro / Stopwatch: dynamic width like media (measured content, not hardcoded) ---
    property real pomodoroTextContentWidth: 0
    property real stopwatchTextContentWidth: 0
    property real countdownTextContentWidth: 0
    property bool timerControlsExpanded: timerHoverHandler.hovered
    readonly property real pomodoroCollapsedWidth: 140
    readonly property real pomodoroExpandedWidthCap: 220
    readonly property real pomodoroExpandedWidth: Math.min(root.pomodoroExpandedWidthCap, Math.max(root.pomodoroCollapsedWidth, root.pomodoroTextContentWidth))
    // NOTE: no activeContentId guard here on purpose. It is redundant (each
    // width only applies while its own content is displayed, and the two
    // branches are mathematically identical when hovered) and it closes a
    // binding loop (widths -> contentProviders -> displayedProvider ->
    // activeContentId -> widths) that freezes the pill at the old width.
    readonly property real pomodoroWidth: root.timerControlsExpanded ? root.pomodoroExpandedWidth : Math.max(root.pomodoroCollapsedWidth, Math.min(root.pomodoroExpandedWidth, root.pomodoroTextContentWidth))
    readonly property real stopwatchCollapsedWidth: 150
    readonly property real stopwatchExpandedWidthCap: 240
    readonly property real stopwatchExpandedWidth: Math.min(root.stopwatchExpandedWidthCap, Math.max(root.stopwatchCollapsedWidth, root.stopwatchTextContentWidth))
    readonly property real stopwatchWidth: root.timerControlsExpanded ? root.stopwatchExpandedWidth : Math.max(root.stopwatchCollapsedWidth, Math.min(root.stopwatchExpandedWidth, root.stopwatchTextContentWidth))
    readonly property real countdownCollapsedWidth: 140
    readonly property real countdownExpandedWidthCap: 220
    readonly property real countdownExpandedWidth: Math.min(root.countdownExpandedWidthCap, Math.max(root.countdownCollapsedWidth, root.countdownTextContentWidth))
    readonly property real countdownWidth: root.timerControlsExpanded ? root.countdownExpandedWidth : Math.max(root.countdownCollapsedWidth, Math.min(root.countdownExpandedWidth, root.countdownTextContentWidth))
    readonly property real timerWidth: 130
    readonly property real osdWidth: OsdHelper.pillWidth
    readonly property real notificationWidth: 220
    readonly property real batteryWidth: 170
    readonly property real badgeSize: 32
    readonly property real badgeSpacing: 6
    readonly property bool isMaterial: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle === "m3"
    readonly property string islandStyle: Config.ready && Config.options.statusBar ? (Config.options.statusBar.islandStyle ?? "pill") : "pill"
    readonly property bool isWaterdrop: islandStyle === "waterdrop" && !isMaterial
    property bool insideM3Card: false
    property bool vertical: false

    property string manualFocusId: ""
    property string forcedCycleId: ""

    property bool forceIdle: false

    // --- Deferred width reporting ---
    // Content items must NEVER write their measured widths back synchronously
    // (onCompleted / onChanged / Binding): the Loader instantiates them in the
    // middle of the provider-switch evaluation cascade, so a synchronous write
    // re-enters displayedProvider's evaluation ("Binding loop detected") and
    // the corrective update gets dropped — the pill sticks at the old width
    // until something (e.g. a manual rehover) forces a clean pass. Deferring
    // one event loop keeps every report outside the cascade. The delay is
    // invisible under the 350ms pill animation.
    property var _pendingWidths: ({})
    property bool _widthFlushQueued: false
    function reportWidth(prop, value) {
        _pendingWidths[prop] = value
        if (root._widthFlushQueued) return
        root._widthFlushQueued = true
        Qt.callLater(flushReportedWidths)
    }
    function flushReportedWidths() {
        root._widthFlushQueued = false
        const pending = root._pendingWidths
        root._pendingWidths = ({})
        for (const k in pending) {
            if (root[k] !== pending[k]) root[k] = pending[k]
        }
    }

    readonly property var displayedProvider: {
        const alwaysWinActive = root.contentProviders.find(p => root.alwaysWinIds.includes(p.id) && p.active)
        if (alwaysWinActive) return alwaysWinActive
        if (root.forcedCycleId !== "") {
            if (root.forcedCycleId === "idle") return null
            const forced = root.contentProviders.find(p => p.id === root.forcedCycleId && p.active)
            if (forced) return forced
        }
        return root.forceIdle ? null : root.activeProvider
    }

    onActiveProviderChanged: {
        if (root.activeProvider && root.alwaysWinIds.includes(root.activeProvider.id)) {
            root.forceIdle = false
        }
    }

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasMedia: root.activePlayer !== null
        && ((root.activePlayer.trackTitle ?? "") !== "" || root.activePlayer.isPlaying)
    readonly property var latestNotification: {
        if (Notifications.popupList && Notifications.popupList.length > 0)
            return Notifications.popupList[Notifications.popupList.length - 1]
        return Notifications.activePopup
    }
    readonly property bool isRecording: ScreenRecord.active
    property int recordingElapsedSeconds: ScreenRecord.seconds

    function formatRecordingTime(s) {
        return Math.floor(s / 60).toString().padStart(2, '0') + ":" + (s % 60).toString().padStart(2, '0')
    }

    // --- Battery alert (derived from Battery service) ---
    property bool batteryAlertActive: false
    property string batteryAlertKind: ""
    readonly property int batteryAlertDuration: 4000

    Timer {
        id: batteryAlertTimer
        interval: root.batteryAlertDuration
        repeat: false
        onTriggered: root.batteryAlertActive = false
    }

    Timer {
        id: mediaTrackChangeTimer
        interval: 3000
        repeat: false
    }

    Connections {
        target: root.activePlayer
        function onTrackTitleChanged() { mediaTrackChangeTimer.restart() }
        function onTrackArtistChanged() { mediaTrackChangeTimer.restart() }
    }

    function triggerBatteryAlert(kind) {
        root.batteryAlertKind = kind
        root.batteryAlertActive = true
        batteryAlertTimer.restart()
    }

    Connections {
        target: Battery
        function onIsCriticalChanged() {
            if (Battery.isCritical && !Battery.isCharging) root.triggerBatteryAlert("critical")
        }
        function onIsLowChanged() {
            if (Battery.isLow && !Battery.isCritical && !Battery.isCharging) root.triggerBatteryAlert("low")
        }
        function onIsChargingChanged() {
            if (Battery.isCharging) root.triggerBatteryAlert("charging")
        }
    }

    function batteryStatusText() {
        switch (root.batteryAlertKind) {
            case "critical": return I18nService.tr("Critical Battery")
            case "charging": return I18nService.tr("Charging")
            default:         return I18nService.tr("Low Battery")
        }
    }

    function batteryIcon() {
        if (root.batteryAlertKind === "charging" || Battery.isCharging) return "battery_android_frame_bolt"
        const pct = Battery.percentage
        if (pct <= 0.1) return "battery_android_frame_alert"
        if (pct <= 0.2) return "battery_android_frame_1"
        if (pct <= 0.4) return "battery_android_frame_2"
        if (pct <= 0.6) return "battery_android_frame_3"
        if (pct <= 0.8) return "battery_android_frame_4"
        if (pct < 1)    return "battery_android_frame_5"
        return "battery_android_full"
    }

    function batteryAlertColor() {
        return root.batteryAlertKind === "charging" ? Appearance.m3colors.m3success : Appearance.colors.colError
    }

    // --- Separate timer sessions — pause keeps DI visible for resume & switching ---
    readonly property bool hasPomodoro: PomodoroService.isSessionRunning
    readonly property bool _hasStopwatchSession: StopwatchService.active || StopwatchService.elapsedMs > 0
    readonly property bool hasStopwatch: root._hasStopwatchSession
    readonly property bool _hasTimerSession: {
        if (TimerService.active || TimerService.overflowing) return true
        if (TimerService.setSeconds <= 0) return false
        return Math.abs(TimerService.remainingMs - TimerService.setSeconds * 1000) > 100
    }
    readonly property bool hasCountdown: root._hasTimerSession
    // kept for legacy single-timer fallback
    readonly property bool hasActiveTimer: root.hasPomodoro || root.hasStopwatch || root.hasCountdown
    property string engagedTimerKind: {
        if (root.hasPomodoro) return "pomodoro"
        if (root.hasStopwatch) return "stopwatch"
        if (root.hasCountdown) return "countdown"
        return ""
    }

    function timerIcon() {
        switch (root.engagedTimerKind) {
            case "pomodoro":  return "coffee"
            case "countdown": return "hourglass_top"
            case "stopwatch": return "timer"
            default:          return "timer"
        }
    }

    function timerValueText() {
        switch (root.engagedTimerKind) {
            case "pomodoro":  return PomodoroService.timeString
            case "countdown": return TimerService.timeString
            case "stopwatch": return StopwatchService.timeString.split(".")[0]
            default:          return ""
        }
    }

    function timerRunning() {
        switch (root.engagedTimerKind) {
            case "pomodoro":  return PomodoroService.active
            case "countdown": return TimerService.active
            case "stopwatch": return StopwatchService.active
            default:          return false
        }
    }

    function toggleActiveTimer() {
        switch (root.engagedTimerKind) {
            case "pomodoro":  PomodoroService.active ? PomodoroService.pause() : PomodoroService.start(); break
            case "countdown": TimerService.active ? TimerService.pause() : TimerService.start(); break
            case "stopwatch": StopwatchService.active ? StopwatchService.pause() : StopwatchService.start(); break
        }
    }

    function resetActiveTimer() {
        switch (root.engagedTimerKind) {
            case "pomodoro":  PomodoroService.reset(); break
            case "countdown": TimerService.reset(); break
            case "stopwatch": StopwatchService.reset(); break
        }
    }

    // --- OSD bridging (via GlobalStates) ---
    // GlobalStates.osdVolumeOpen / osdIndicatorType set by OSD.qml or direct volume/brightness changes
    readonly property bool osdActive: GlobalStates.osdVolumeOpen ?? false

    readonly property var contentProviders: [
        { id: "notification", active: root.latestNotification !== null, component: notificationComponent, width: root.notificationWidth },
        { id: "battery",      active: root.batteryAlertActive,          component: batteryComponent,      width: root.batteryWidth },
        { id: "recording",    active: root.isRecording,                 component: recordingComponent,    width: 140 },
        { id: "pomodoro",     active: root.hasPomodoro,                 component: pomodoroComponent,     width: root.pomodoroWidth },
        { id: "stopwatch",    active: root.hasStopwatch,                component: stopwatchComponent,    width: root.stopwatchWidth },
        { id: "countdown",    active: root.hasCountdown,                component: countdownComponent,    width: root.countdownWidth },
        // legacy aggregated timer (hidden, kept for icon fallback)
        { id: "timer",        active: false,                            component: timerComponent,        width: root.timerWidth },
        { id: "osd",          active: root.osdActive,                   component: osdComponent,          width: root.osdWidth },
        { id: "media",        active: root.hasMedia,                    component: mediaComponent,        width: root.mediaWidth },
    ]

    readonly property var alwaysWinIds: ["notification", "battery", "osd"]

    readonly property var activeOthers: root.contentProviders.filter(p => !root.alwaysWinIds.includes(p.id) && p.active)

    readonly property var activeProvider: {
        const forcedTop = root.contentProviders.find(p => root.alwaysWinIds.includes(p.id) && p.active)
        if (forcedTop) return forcedTop
        if (root.manualFocusId !== "") {
            const forced = root.activeOthers.find(p => p.id === root.manualFocusId)
            if (forced) return forced
        }
        return root.activeOthers[0] ?? null
    }

    // --- New arrivals steal focus ---
    // activeOthers is in static priority order, so without this a newcomer
    // with lower priority (e.g. media while pomodoro runs) would never be
    // shown. Detect newly activated ids and focus the latest one, clearing
    // any wheel pin so the new item actually takes over.
    readonly property var activeOtherIds: root.activeOthers.map(p => p.id)
    property var prevActiveOtherIds: []
    onActiveOtherIdsChanged: {
        const prev = root.prevActiveOtherIds
        const added = root.activeOtherIds.filter(id => !prev.includes(id))
        root.prevActiveOtherIds = [...root.activeOtherIds]
        if (added.length === 0) return
        root.forcedCycleId = ""
        root.forceIdle = false
        root.manualFocusId = added[added.length - 1]
    }

    readonly property var badgeProviders: {
        if (root.alwaysWinIds.some(id => root.contentProviders.find(p => p.id === id)?.active)) return []
        return root.activeOthers.filter(p => p.id !== root.activeProvider?.id)
    }

    function iconForProviderId(id) {
        switch (id) {
            case "media":     return "music_note"
            case "recording": return "screen_record"
            case "pomodoro":  return "coffee"
            case "stopwatch": return "timer"
            case "countdown": return "hourglass_top"
            case "timer":     return root.timerIcon()
            case "battery":   return root.batteryIcon()
            case "osd":
                return OsdHelper.osdIcon()
            default: return "circle"
        }
    }

    function osdText() {
        return OsdHelper.osdText()
    }

    readonly property string activeContentId: root.displayedProvider?.id ?? "idle"

    implicitHeight: 40 * Appearance.effectiveScale
    implicitWidth: root.displayedProvider?.width ?? root.idleWidth

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 350
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }

    Rectangle {
        id: pill
        anchors.left: parent.left
        y: root.isWaterdrop ? 0 : (root.insideM3Card ? 0 : 4 * Appearance.effectiveScale)
        width: root.displayedProvider?.width ?? root.idleWidth
        height: root.isWaterdrop ? 34 * Appearance.effectiveScale : (root.insideM3Card ? 40 * Appearance.effectiveScale : 32 * Appearance.effectiveScale)
        color: "black"
        radius: height / 2
        clip: false
        visible: !root.vertical

        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Behavior on width {
            NumberAnimation {
                duration: 350
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        // Waterdrop: square off top edge (attach to bar) — match DynamicIsland.qml:346
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: parent.radius
            color: "black"
            visible: root.isWaterdrop
        }
        RoundCorner {
            anchors.right: parent.left; anchors.top: parent.top
            implicitSize: parent.radius; color: "black"; corner: RoundCorner.CornerEnum.TopRight
            visible: root.isWaterdrop; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }
        RoundCorner {
            anchors.left: parent.right; anchors.top: parent.top
            implicitSize: parent.radius; color: "black"; corner: RoundCorner.CornerEnum.TopLeft
            visible: root.isWaterdrop; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Behavior on width {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuint }
        }

        // NOTE: these stay always-enabled AND ungated on purpose. Gating
        // `enabled` on activeContentId breaks the first hover when content
        // switches while the cursor is already over the pill (Qt doesn't
        // refresh `hovered` until the pointer moves again), and gating the
        // derived bools on activeContentId creates a binding loop
        // (widths -> contentProviders -> displayedProvider -> activeContentId
        // -> widths) that freezes the pill at the old provider's width.
        // No gating is needed: each width only applies while its own content
        // is displayed.
        HoverHandler {
            id: mediaHoverHandler
        }

        HoverHandler {
            id: timerHoverHandler
        }

        HoverHandler {
            id: idleHoverHandler
        }

        WheelHandler {
            id: globalCycleWheelHandler
            target: pill
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                const order = ["idle","media","recording","pomodoro","stopwatch","countdown"]
                const activeOrder = order.filter(id => id === "idle" || root.contentProviders.find(p => p.id === id)?.active)
                if (activeOrder.length <= 1) return
                const curId = root.forcedCycleId !== "" ? root.forcedCycleId : root.activeContentId
                let idx = activeOrder.indexOf(curId)
                if (idx === -1) idx = 0
                event.accepted = true
                if (event.angleDelta.y > 0) idx = (idx - 1 + activeOrder.length) % activeOrder.length
                else idx = (idx + 1) % activeOrder.length
                root.forcedCycleId = activeOrder[idx]
                root.manualFocusId = ""
                root.forceIdle = false
            }
        }

        WheelHandler {
            id: idleToggleWheelHandler
            target: pill
            enabled: false
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            property bool coolingDown: false
            onWheel: (event) => {
                if (coolingDown) return
                coolingDown = true
                idleToggleDebounceTimer.restart()
                root.forceIdle = !root.forceIdle
            }
        }
        readonly property bool wheelCooling: idleToggleWheelHandler.coolingDown

        Timer {
            id: idleToggleDebounceTimer
            interval: 200
            onTriggered: idleToggleWheelHandler.coolingDown = false
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: root.displayedProvider?.component ?? idleComponent
            active: !root.vertical
        }

        Component {
            id: idleComponent
            PcDiIdle { di: root }
        }

        Component {
            id: mediaComponent
            PcDiMedia { di: root }
        }

        Component {
            id: osdComponent
            PcDiOsd { di: root }
        }

        Component {
            id: notificationComponent
            PcDiNotifs { di: root }
        }

        Component {
            id: timerComponent
            PcDiTimers { di: root }
        }

        Component {
            id: pomodoroComponent
            PcDiTimers { di: root }
        }
        Component {
            id: stopwatchComponent
            PcDiStopwatch { di: root }
        }
        Component {
            id: countdownComponent
            PcDiTimer { di: root }
        }

        Component {
            id: recordingComponent
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 10
                }
                spacing: 6

                Item {
                    id: stopButton
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 16
                    implicitHeight: 16

                    MaterialSymbol {
                        anchors.fill: parent
                        text: "stop_circle"
                        fill: 1
                        iconSize: root.isMaterial ? 26 : 16
                        color: Appearance.colors.colError
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ScreenRecord.stop()
                    }
                }

                Item { Layout.fillWidth: true }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.formatRecordingTime(root.recordingElapsedSeconds)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.features: { "tnum": 1 }
                    color: Appearance.colors.colNotchText
                }
            }
        }

        Component {
            id: batteryComponent
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 6

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.batteryStatusText()
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: root.batteryAlertColor()
                }

                Item { Layout.fillWidth: true }

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.batteryIcon()
                    fill: 1
                    iconSize: 16
                    color: root.batteryAlertColor()
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: `${Math.round(Battery.percentage * 100)}`
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.features: { "tnum": 1 }
                    color: root.batteryAlertColor()
                }
            }
        }
    }

}
