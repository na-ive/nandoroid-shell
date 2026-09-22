pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Alarm Service — standalone Android-style alarms (DashClock > Alarm tab).
 * Own persistence, own firing timer; completely independent from reminders.
 * Bypasses DND entirely: dedicated panel + looping ringtone via ffplay,
 * no involvement of the notification pipeline.
 *
 * Schema per alarm:
 * {
 *   id           : string   — unique ID
 *   label        : string   — optional name shown on the alarm panel
 *   time         : string   — "HH:MM" (24h)
 *   enabled      : bool
 *   days         : number[] — 0=Mon..6=Sun (matches firstDayOfWeek default); empty = one-shot (auto-disables after ring)
 *   lastFiredKey : string   — "YYYY-MM-DD HH:MM" guard against double-firing
 *   lastNotifiedKey : string — "YYYY-MM-DD HH:MM" guard against duplicate 2h-before notifications
 * }
 *
 * Storage: {"version": 2, "alarms": [...]}. A bare array is the legacy v1
 * format with Sun-based days; it is migrated (shifted) on load.
 *
 * Note: accurate only while the system is awake (no wake-from-suspend yet).
 */
Singleton {
    id: root

    property var alarms: []
    onAlarmsChanged: root._scheduleNext()

    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/alarms.json"

    // "" | "ringing" | "snoozed"
    property string alarmState: ""
    readonly property bool ringing: alarmState === "ringing"
    readonly property bool snoozed: alarmState === "snoozed"

    property string message: "" // alarm label shown on the panel
    property string snoozeUntil: "" // HH:MM display of next ring

    readonly property int defaultSnoozeMinutes: 5
    readonly property int maxRingMinutes: 5 // auto-dismiss after this long

    // Theme default ringtone — ~/.local/share/sounds first, then /usr/share/sounds;
    // final fallback to the freedesktop theme (custom themes may lack the sound)
    readonly property var defaultRingtoneCommand: {
        const local = `${Directories.home.replace("file://", "")}/.local/share/sounds/${Audio.audioTheme}/stereo/alarm-clock-elapsed`;
        const system = `/usr/share/sounds/${Audio.audioTheme}/stereo/alarm-clock-elapsed`;
        const freedesktop = "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed";
        return ["bash", "-c", `f='${local}.oga'; [ -f "$f" ] || f='${local}.ogg'; [ -f "$f" ] || f='${system}.oga'; [ -f "$f" ] || f='${system}.ogg'; [ -f "$f" ] || f='${freedesktop}.oga'; [ -f "$f" ] || f='${freedesktop}.ogg'; exec ffplay -nodisp -autoexit -loop 0 "$f"`];
    }
    readonly property string ringtonePath: {
        const custom = (Config.ready && Config.options.sounds) ? Config.options.sounds.alarm : "";
        return custom !== "" ? custom : "";
    }
    readonly property var ringtoneCommand: root.ringtonePath !== ""
        ? ["ffplay", "-nodisp", "-autoexit", "-loop", "0", root.ringtonePath]
        : root.defaultRingtoneCommand

    property var _pendingAlarm: null

    // ── CRUD ──
    function save() {
        alarmFile.setText(JSON.stringify({ version: 2, alarms: root.alarms }, null, 2));
    }

    function addAlarm(alarm) {
        root.alarms = [...root.alarms, alarm];
        save();
    }

    function updateAlarm(id, updatedFields) {
        root.alarms = root.alarms.map(a => a.id === id ? Object.assign({}, a, updatedFields) : a);
        save();
    }

    function deleteAlarm(id) {
        root.alarms = root.alarms.filter(a => a.id !== id);
        save();
    }

    function toggleAlarm(id) {
        const a = root.alarms.find(x => x.id === id);
        if (!a) return;
        // Clearing lastFiredKey restores the Dismiss affordance for the
        // upcoming occurrence after an off→on cycle; lastNotifiedKey lets
        // the 2h-before notification fire again
        updateAlarm(id, { enabled: !a.enabled, lastFiredKey: "", lastNotifiedKey: "" });
    }

    // Dismiss one upcoming occurrence: one-shot off, repeating skipped.
    function dismissUpcomingOccurrence(id, occurrenceKey) {
        const a = root.alarms.find(x => x.id === id);
        if (!a) return;
        if (!a.days || a.days.length === 0) {
            updateAlarm(a.id, { enabled: false });
        } else if (occurrenceKey !== "") {
            updateAlarm(a.id, { lastFiredKey: occurrenceKey });
        }
    }

    // Sent when a ringing alarm auto-stops unanswered.
    function sendMissedNotification(alarm) {
        const iconPath = Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg";
        const label = (alarm.label && alarm.label !== "") ? alarm.label + " · " : "";
        Quickshell.execDetached([
            "notify-send",
            "-a", "NAnDoroid",
            "-i", iconPath,
            "-t", "8000",
            I18nService.tr("Missed alarm"),
            label + alarm.time
        ]);
    }

    // ── Firing: event-driven single-shot scheduling (zero periodic polling) ──
    // The timer is armed exactly for the earliest upcoming occurrence and
    // re-armed whenever alarms change, after a ring, or after a snooze.
    property var _scheduledTarget: null

    function _nextOccurrence(alarm, from) {
        const now = from || new Date();
        const parts = String(alarm.time || "").split(":").map(Number);
        for (let i = 0; i < 8; i++) {
            const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i, parts[0] || 0, parts[1] || 0);
            if (d <= now) continue;
            // days are Mon-based (0=Mon..6=Sun); Date.getDay() is Sun-based
            if (alarm.days && alarm.days.length > 0 && !alarm.days.includes((d.getDay() + 6) % 7)) continue;
            const key = Qt.formatDate(d, "yyyy-MM-dd") + " " + Qt.formatTime(d, "HH:mm");
            if (alarm.lastFiredKey && alarm.lastFiredKey === key) continue;
            return d;
        }
        return null;
    }

    function _scheduleNext() {
        let best = null;
        for (let i = 0; i < root.alarms.length; i++) {
            if (!root.alarms[i].enabled) continue;
            const d = root._nextOccurrence(root.alarms[i], new Date());
            if (d !== null && (best === null || d < best)) best = d;
        }
        root._scheduledTarget = best;
        if (best === null) {
            fireTimer.running = false;
            return;
        }
        // Fires late after suspend — the handler still rings the missed target.
        // restart() (not running = true): an already-running timer must be
        // re-armed for the NEW target, or it fires on the old schedule while
        // the handler reads the new one → rings a minute (or more) early.
        fireTimer.interval = Math.max(250, best.getTime() - Date.now());
        fireTimer.restart();
    }

    function _skippedInGameMessage(alarm) {
        const t = alarm ? alarm.time : Qt.formatTime(new Date(), "HH:mm");
        return I18nService.tr("Alarm %1 skipped (Game Mode active)").replace("%1", t);
    }

    function ring(alarm) {
        // Game Mode owns the screen: no panel, no sound — leave a fully
        // click-through notice instead. The fire handler has already marked
        // the occurrence fired (one-shot stays disabled), so nothing re-rings.
        if (GameMode.active) {
            SnackbarService.showInert(_skippedInGameMessage(alarm));
            return;
        }
        root._pendingAlarm = alarm || null;
        root.message = alarm ? (alarm.label || "") : "";
        root.snoozeUntil = "";
        root.alarmState = "ringing";
        ringProc.command = root.ringtoneCommand;
        ringProc.running = true;
        autoStopTimer.restart();
    }

    // Game Mode activated mid-ring: close the panel, kill the sound, downgrade
    // to the same click-through notice
    Connections {
        target: GameMode
        function onActiveChanged() {
            if (!GameMode.active || !root.ringing) return;
            const a = root._pendingAlarm;
            root.stop();
            SnackbarService.showInert(_skippedInGameMessage(a));
        }
    }

    function stop() {
        ringProc.running = false;
        snoozeTimer.stop();
        autoStopTimer.stop();
        root._pendingAlarm = null;
        root.alarmState = "";
        root.snoozeUntil = "";
    }

    function snooze(minutes) {
        const mins = minutes > 0 ? minutes : root.defaultSnoozeMinutes;
        const until = new Date(Date.now() + mins * 60000);
        root.snoozeUntil = Qt.formatTime(until, "HH:mm");
        ringProc.running = false;
        autoStopTimer.stop();
        root.alarmState = "snoozed";
        snoozeTimer.interval = mins * 60000;
        snoozeTimer.restart();
        SnackbarService.show(
            I18nService.tr("Snoozed until") + " " + root.snoozeUntil,
            I18nService.tr("Stop"),
            () => root.stop()
        );
    }

    Timer {
        id: fireTimer
        interval: 60000
        repeat: false
        running: false
        onTriggered: {
            // Ring the scheduled target regardless of lateness (suspend-safe),
            // guarded by lastFiredKey against double-firing
            if (root._scheduledTarget !== null && !root.ringing) {
                const target = root._scheduledTarget;
                // Qt timers can fire tens of ms early (coalescing/drift) —
                // never ring before the target instant; re-arm instead
                const remaining = target.getTime() - Date.now();
                if (remaining > 0) {
                    fireTimer.interval = Math.max(remaining, 50);
                    fireTimer.restart();
                    return;
                }
                const timeStr = Qt.formatTime(target, "HH:mm");
                const key = Qt.formatDate(target, "yyyy-MM-dd") + " " + timeStr;

                for (let i = 0; i < root.alarms.length; i++) {
                    const a = root.alarms[i];
                    if (!a.enabled || a.time !== timeStr) continue;
                    if (a.days && a.days.length > 0 && !a.days.includes((target.getDay() + 6) % 7)) continue;
                    if (a.lastFiredKey === key) continue;

                    const isOneShot = !a.days || a.days.length === 0;
                    updateAlarm(a.id, { lastFiredKey: key, enabled: isOneShot ? false : a.enabled });
                    
                    // Skip ringing if missed during a long suspend
                    const maxLateness = root.maxRingMinutes * 60000;
                    const lateness = Date.now() - target.getTime();

                    if (lateness <= maxLateness) {
                        root.ring(a);
                    }
                    break;
                }
            }
            root._scheduleNext();
        }
    }

    Timer {
        id: snoozeTimer
        interval: root.defaultSnoozeMinutes * 60000
        repeat: false
        onTriggered: root.ring(root._pendingAlarm)
    }

    Timer {
        id: autoStopTimer
        interval: root.maxRingMinutes * 60000
        repeat: false
        onTriggered: {
            // Unanswered for the full window: stop, then leave a missed notice.
            const a = root._pendingAlarm;
            root.stop();
            if (a) root.sendMissedNotification(a);
        }
    }

    Process {
        id: ringProc
        command: []
        running: false
    }

    property bool _created: false

    FileView {
        id: alarmFile
        path: root.storagePath
        watchChanges: false
        printErrors: false
        blockWrites: true
        onLoaded: {
            try {
                const content = alarmFile.text();
                if (content && content.trim() !== "") {
                    const parsed = JSON.parse(content);
                    if (Array.isArray(parsed)) {
                        // Legacy v1: bare array with Sun-based days → shift to Mon-based
                        root.alarms = parsed.map(a => (a.days && a.days.length > 0)
                            ? Object.assign({}, a, { days: a.days.map(d => (d + 6) % 7) })
                            : a);
                        root.save();
                    } else if (parsed && Array.isArray(parsed.alarms)) {
                        root.alarms = parsed.alarms;
                    }
                }
            } catch (e) {
                console.warn("AlarmService: failed to parse alarms.json:", e);
            }
        }
        onLoadFailed: {
            if (root._created) return;
            root._created = true;
            alarmFile.setText("[]");
            alarmFile.reload();
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", storagePath.substring(0, storagePath.lastIndexOf('/'))]);
        alarmFile.reload();
    }
}
