pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Smart Automation Service — handles DND, scheduled notifications, and update checks.
 */
Singleton {
    id: root

    // --- State ---
    property bool dndActive: false
    property bool scheduleDndActive: false
    property bool pomodoroDndActive: PomodoroService.active && PomodoroService.mode === 0
    property string lastUpdateCheckDate: "" // Track daily update check

    // Focus mode writes to Config (persistent source of truth) on event start/end
    // _ready guard prevents startup from overriding user's saved preference
    readonly property bool shouldBeDnd: scheduleDndActive || pomodoroDndActive
    onShouldBeDndChanged: {
        if (!_ready && shouldBeDnd) return;
        _setDnd(shouldBeDnd);
    }

    function _setDnd(value) {
        Notifications.silent = value;
        root.dndActive = value;
        if (Config.ready && Config.options.system) {
            Config.options.system.dndActive = value;
        }
    }

    // Sync user's manual toggle back to Config
    Connections {
        target: Notifications
        function onSilentChanged() {
            root.dndActive = Notifications.silent;
            if (Config.ready && Config.options.system) {
                Config.options.system.dndActive = Notifications.silent;
            }
        }
    }

    // --- Battery low/critical push notifications (for non-PcIsland or as persistent notif) ---
    property string _lastBatteryNotif: ""
    Connections {
        target: Battery
        function onIsCriticalChanged() {
            if (Battery.isCritical && !Battery.isCharging) {
                if (root._lastBatteryNotif !== "critical") {
                    root._lastBatteryNotif = "critical"
                    root.sendNotification("Critical Battery", `Battery at ${Math.round(Battery.percentage * 100)}% — plug in now`)
                }
            }
        }
        function onIsLowChanged() {
            if (Battery.isLow && !Battery.isCritical && !Battery.isCharging) {
                if (root._lastBatteryNotif !== "low") {
                    root._lastBatteryNotif = "low"
                    root.sendNotification("Low Battery", `Battery at ${Math.round(Battery.percentage * 100)}%`)
                }
            } else if (!Battery.isLow && !Battery.isCritical) {
                root._lastBatteryNotif = ""
            }
        }
        function onIsChargingChanged() {
            if (Battery.isCharging) root._lastBatteryNotif = ""
        }
    }

    // --- Notifications only for Schedule DND ---
    onScheduleDndActiveChanged: {
        if (scheduleDndActive) {
            sendNotification("Scheduled Focus Active", "Do Not Disturb has been enabled for your event.");
        } else if (!pomodoroDndActive) {
            sendNotification("Scheduled Focus Ended", "Do Not Disturb has been disabled.");
        }
    }

    // --- Dynamic One-Shot Automation Timer ---
    Timer {
        id: mainTimer
        interval: 60000
        repeat: false
        onTriggered: runThenSchedule()
    }

    property bool _ready: false
    property bool _cycleGuard: false

    Connections {
        target: ScheduleService
        function onEventsChanged() {
            if (_ready && !_cycleGuard) {
                _cycleGuard = true;
                scheduleNext();
                runAutomationCycle();
                _cycleGuard = false;
            }
        }
    }

    Connections {
        target: ReminderService
        function onRemindersChanged() {
            if (_ready && !_cycleGuard) {
                _cycleGuard = true;
                scheduleNext();
                runAutomationCycle();
                _cycleGuard = false;
            }
        }
    }

    Connections {
        target: AlarmService
        function onAlarmsChanged() {
            if (_ready && !_cycleGuard) {
                _cycleGuard = true;
                scheduleNext();
                runAutomationCycle();
                _cycleGuard = false;
            }
        }
    }

    function runThenSchedule() {
        runAutomationCycle();
        scheduleNext();
    }

    function scheduleNext() {
        const now = new Date();
        let nextMs = Infinity;

        // Next midnight (for daily update check)
        const midnight = new Date(now);
        midnight.setDate(midnight.getDate() + 1);
        midnight.setHours(0, 0, 0, 0);
        nextMs = Math.min(nextMs, midnight.getTime() - now.getTime() + 1000);

        ScheduleService.events.forEach(event => {
            const nowDateStr = Qt.formatDate(now, "yyyy-MM-dd");

            if (event.endDate && nowDateStr > event.endDate) return;

            let isEventDay = false;
            if (event.recurrence === "once") {
                if (event.endDate) {
                    isEventDay = nowDateStr >= event.date && nowDateStr <= event.endDate;
                } else {
                    isEventDay = event.date === nowDateStr;
                }
            } else {
                if (event.date === nowDateStr) isEventDay = true;
                else if (event.recurrence === "daily") isEventDay = true;
                else if (event.recurrence === "weekly") {
                    const d = new Date(event.date + "T00:00:00");
                    isEventDay = d.getDay() === now.getDay();
                } else if (event.recurrence === "monthly") {
                    const d = new Date(event.date + "T00:00:00");
                    isEventDay = d.getDate() === now.getDate();
                }
                if (isEventDay && event.date) isEventDay = nowDateStr >= event.date;
            }
            if (!isEventDay) return;

            const eventStart = new Date(nowDateStr + "T" + event.time);
            let eventEnd = event.endTime
                ? new Date(nowDateStr + "T" + event.endTime)
                : new Date(eventStart.getTime() + 3600000);

            if (event.endTime) {
                const [sh, sm] = event.time.split(":").map(Number);
                const [eh, em] = event.endTime.split(":").map(Number);
                if (eh < sh || (eh === sh && em <= sm)) eventEnd.setDate(eventEnd.getDate() + 1);
            }

            // Notification 1h before
            const notif1h = new Date(eventStart.getTime() - 3600000);
            if (notif1h > now) {
                nextMs = Math.min(nextMs, notif1h.getTime() - now.getTime());
            } else if (now < eventStart && !event.lastNotified1hDate) {
                nextMs = Math.min(nextMs, 1000);
            }

            // Event start (for DND activation)
            if (event.focus && eventStart > now) nextMs = Math.min(nextMs, eventStart.getTime() - now.getTime());

            // Event end (for DND deactivation)
            if (event.focus) {
                let dndEnd = eventEnd;
                if (event.endTime) {
                    const [sh, sm] = event.time.split(":").map(Number);
                    const [eh, em] = event.endTime.split(":").map(Number);
                    if (eh < sh || (eh === sh && em <= sm)) {
                        const tailEnd = new Date(nowDateStr + "T" + event.endTime);
                        if (now < tailEnd) dndEnd = tailEnd;
                    }
                }
                if (dndEnd > now) nextMs = Math.min(nextMs, dndEnd.getTime() - now.getTime());
            }

            // Expired once event cleanup (30s after end of last day)
            if (event.recurrence === "once") {
                const expiryDate = event.endDate || event.date;
                const expiryTime = event.endTime || "23:59";
                if (nowDateStr === expiryDate) {
                    let expire = new Date(expiryDate + "T" + expiryTime);
                    if (event.endTime) {
                        const [sh, sm] = (event.time || "00:00").split(":").map(Number);
                        const [eh, em] = event.endTime.split(":").map(Number);
                        if (eh < sh || (eh === sh && em <= sm)) expire.setDate(expire.getDate() + 1);
                    }
                    expire.setTime(expire.getTime() + 30000);
                    if (expire > now) nextMs = Math.min(nextMs, expire.getTime() - now.getTime());
                    else nextMs = Math.min(nextMs, 1000);
                }
            }
        });

        // Reminder scheduling
        ReminderService.reminders.forEach(r => {
            if (r.fired) {
                // Auto-delete window: 30 min after fire time
                const rDate = new Date(r.date + "T" + r.time);
                const autoDeleteAt = new Date(rDate.getTime() + 1800000);
                if (autoDeleteAt > now)
                    nextMs = Math.min(nextMs, autoDeleteAt.getTime() - now.getTime());
                return;
            }
            const rDate = new Date(r.date + "T" + r.time);
            if (rDate > now)
                nextMs = Math.min(nextMs, rDate.getTime() - now.getTime());
        });

        // Alarm "2h before" notification scheduling — same window as the
        // Dismiss affordance in AlarmView (one-shot dismiss = turn off)
        AlarmService.alarms.forEach(a => {
            if (!a.enabled) return;
            const occ = AlarmService._nextOccurrence(a, now);
            if (occ === null) return;
            const key = Qt.formatDate(occ, "yyyy-MM-dd") + " " + Qt.formatTime(occ, "HH:mm");
            if (a.lastNotifiedKey === key) return;
            const notifyIn = occ.getTime() - 7200000 - now.getTime();
            nextMs = Math.min(nextMs, Math.max(notifyIn, 1000));
        });

        if (nextMs < Infinity) {
            mainTimer.interval = Math.max(1000, nextMs);
            mainTimer.running = true;
        }
    }

    function runAutomationCycle() {
        const now = new Date();
        const nowDateStr = Qt.formatDate(now, "yyyy-MM-dd");
        
        // 1. Daily Update Check (Strictly once per day, persists across restarts)
        if (Config.ready && Config.options.system) {
            const lastCheck = Config.options.system.lastUpdateCheckDate || "";
            if (lastCheck !== nowDateStr) {
                updateCheckProc.running = true;
                Config.options.system.lastUpdateCheckDate = nowDateStr;
            }
        }

        let anyEventActive = false;
        let expiredEventIds = [];

        ScheduleService.events.forEach(event => {
            // 2. Recurrence / Day Check
            if (event.endDate && nowDateStr > event.endDate) return;

            let isEventDay = false;
            if (event.recurrence === "once") {
                if (event.endDate) {
                    isEventDay = nowDateStr >= event.date && nowDateStr <= event.endDate;
                } else {
                    isEventDay = event.date === nowDateStr;
                }
            } else {
                if (event.date === nowDateStr) isEventDay = true;
                else if (event.recurrence === "daily") isEventDay = true;
                else if (event.recurrence === "weekly") {
                    const eventDate = new Date(event.date + "T00:00:00");
                    isEventDay = (eventDate.getDay() === now.getDay());
                } else if (event.recurrence === "monthly") {
                    const eventDate = new Date(event.date + "T00:00:00");
                    isEventDay = (eventDate.getDate() === now.getDate());
                }
                if (isEventDay && event.date) isEventDay = nowDateStr >= event.date;
            }

            if (!isEventDay) return;

            // 3. Time Check
            const eventStart = new Date(nowDateStr + "T" + event.time);
            let eventEnd = event.endTime 
                ? new Date(nowDateStr + "T" + event.endTime) 
                : new Date(eventStart.getTime() + 3600000);

            if (event.endTime) {
                const [sh, sm] = event.time.split(":").map(Number);
                const [eh, em] = event.endTime.split(":").map(Number);
                if (eh < sh || (eh === sh && em <= sm)) eventEnd.setDate(eventEnd.getDate() + 1);
            }
            
            // 4. DND Active Check
            if (event.focus) {
                let isActive = now >= eventStart && now < eventEnd;
                if (!isActive && event.endTime) {
                    const [sh, sm] = event.time.split(":").map(Number);
                    const [eh, em] = event.endTime.split(":").map(Number);
                    if (eh < sh || (eh === sh && em <= sm)) {
                        const tailEnd = new Date(nowDateStr + "T" + event.endTime);
                        if (now < tailEnd) isActive = true;
                    }
                }
                if (isActive) anyEventActive = true;
            }

            // 5. Notification Logic
            const diffMs = eventStart.getTime() - now.getTime();
            const diffHours = diffMs / 3600000;

            // 00:00 (Today) Notif — only on first day for multi-day once events
            const lastNotified00 = event.lastNotified00Date || "";
            if (lastNotified00 !== nowDateStr) {
                if (!event.endDate || event.recurrence !== "once" || nowDateStr === event.date) {
                    sendNotification("Today's Schedule", `Upcoming event: ${event.title} at ${event.time}`);
                    ScheduleService.updateEvent(event.id, { lastNotified00Date: nowDateStr });
                }
            }

            // 1h Before Notif (only on first day for multi-day events)
            const lastNotified1h = event.lastNotified1hDate || "";
            if (diffHours > 0 && diffHours <= 1.0 && lastNotified1h !== nowDateStr) {
                if (!event.endDate || nowDateStr === event.date) {
                    sendNotification("Starting Soon", `${event.title} starts in 1 hour (${event.time})`);
                    ScheduleService.updateEvent(event.id, { lastNotified1hDate: nowDateStr });
                }
            }

            // 6. Expiry Check (Auto-delete "once" events)
            if (event.recurrence === "once") {
                const expiryDate = event.endDate || event.date;
                const expiryTime = event.endTime || "23:59";
                if (nowDateStr === expiryDate) {
                    let expiryEnd = new Date(expiryDate + "T" + expiryTime);
                    if (event.endTime) {
                        const [sh, sm] = (event.time || "00:00").split(":").map(Number);
                        const [eh, em] = event.endTime.split(":").map(Number);
                        if (eh < sh || (eh === sh && em <= sm)) expiryEnd.setDate(expiryEnd.getDate() + 1);
                    }
                    expiryEnd.setTime(expiryEnd.getTime() + 30000);
                    if (now.getTime() > expiryEnd.getTime()) {
                        expiredEventIds.push(event.id);
                    }
                }
            }
        });

        // 7. Reminder Firing & Auto-cleanup
        const expiredReminderIds = [];
        ReminderService.reminders.forEach(r => {
            if (r.fired) {
                // Auto-delete 30 minutes after fire time
                const rDate = new Date(r.date + "T" + r.time);
                if (now.getTime() > rDate.getTime() + 1800000)
                    expiredReminderIds.push(r.id);
                return;
            }
            const rDate = new Date(r.date + "T" + r.time);
            if (rDate <= now && r.lastFiredDate !== nowDateStr) {
                let body = r.text;
                if (r.linkedTitle) body += " \u00b7 " + r.linkedTitle;
                root.sendNotification("Reminder", body);
                ReminderService.updateReminder(r.id, { fired: true, lastFiredDate: nowDateStr });
            }
        });
        expiredReminderIds.forEach(id => ReminderService.deleteReminder(id));

        // 8. Alarm "2h before" notifications — same window as AlarmView's
        // Dismiss; one-shot alarms included (dismiss = turn off)
        AlarmService.alarms.forEach(a => {
            if (!a.enabled) return;
            const occ = AlarmService._nextOccurrence(a, now);
            if (occ === null) return;
            const key = Qt.formatDate(occ, "yyyy-MM-dd") + " " + Qt.formatTime(occ, "HH:mm");
            if (a.lastNotifiedKey === key) return;
            if (occ.getTime() - now.getTime() > 7200000) return;
            const label = (a.label && a.label !== "") ? a.label + " \u00b7 " : "";
            root.sendAlarmNotification(a.id, key, "Upcoming Alarm", label + "Alarm set for " + a.time);
            AlarmService.updateAlarm(a.id, { lastNotifiedKey: key });
        });

        // Apply DND State
        if (root.scheduleDndActive !== anyEventActive) {
            root.scheduleDndActive = anyEventActive;
        }

        // Cleanup Expired Events
        expiredEventIds.forEach(id => {
            ScheduleService.deleteEvent(id);
        });
    }

    function sendNotification(title, body) {
        const iconPath = Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg";
        const cmd = [
            "notify-send",
            "-a", "NAnDoroid",
            "-i", iconPath,
            "-t", "8000",
            title,
            body
        ];
        Quickshell.execDetached(cmd);
    }

    // Actionable alarm notification: Dismiss skips the occurrence (repeating)
    // or turns the alarm off (one-shot). notify-send prints the clicked
    // action identifier to stdout, collected by the notification's own
    // process instance. One instance per notification: a shared Process
    // drops sends while busy (notify-send -A runs until click/timeout)
    // and its shared target state could misroute Dismiss actions.
    Component {
        id: alarmNotifProcess
        Process {
            property string targetAlarmId: ""
            property string targetKey: ""
            command: []
            stdout: StdioCollector {
                onStreamFinished: {
                    if (this.text.trim() !== "dismiss") return;
                    const a = AlarmService.alarms.find(x => x.id === targetAlarmId);
                    if (!a) return;
                    if (!a.days || a.days.length === 0) {
                        AlarmService.updateAlarm(a.id, { enabled: false });
                    } else if (targetKey !== "") {
                        AlarmService.updateAlarm(a.id, { lastFiredKey: targetKey });
                    }
                }
            }
            onExited: Qt.callLater(destroy)
        }
    }

    function sendAlarmNotification(alarmId, occurrenceKey, title, body) {
        const iconPath = Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg";
        const proc = alarmNotifProcess.createObject(root, {
            targetAlarmId: alarmId,
            targetKey: occurrenceKey,
            command: [
                "notify-send",
                "-a", "NAnDoroid",
                "-i", iconPath,
                "-t", "60000",
                "-A", "dismiss=Dismiss",
                title,
                body
            ]
        });
        proc.running = true;
    }

    Process {
        id: updateCheckProc
        command: ["bash", "-c", `
            STATE_FILE="$HOME/.config/nandoroid/install_state.json"
            if [ ! -f "$STATE_FILE" ]; then exit 0; fi
            DIR=$(python -c 'import json,sys; print(json.load(open(sys.argv[1])).get("install_dir",""))' "$STATE_FILE" 2>/dev/null)
            CHANNEL=$(python -c 'import json,sys; print(json.load(open(sys.argv[1])).get("channel","stable"))' "$STATE_FILE" 2>/dev/null)
            if [ -z "$DIR" ]; then exit 0; fi
            
            cd "$DIR" || exit 0
            
            if [ "$CHANNEL" = "stable" ]; then
                git fetch --tags >/dev/null 2>&1
                LATEST=$(git describe --tags $(git rev-list --tags --max-count=1 2>/dev/null) 2>/dev/null)
                if [ -z "$LATEST" ]; then exit 0; fi
                LOCAL_COMMIT=$(git rev-parse HEAD 2>/dev/null)
                TAG_COMMIT=$(git rev-list -n 1 "$LATEST" 2>/dev/null)
                if [ "$LOCAL_COMMIT" != "$TAG_COMMIT" ]; then
                    echo "Update available ($LATEST)"
                fi
            else
                git fetch origin main >/dev/null 2>&1
                LOCAL=$(git rev-parse HEAD 2>/dev/null)
                REMOTE=$(git rev-parse origin/main 2>/dev/null)
                if [ "$LOCAL" != "$REMOTE" ] && [ -n "$LOCAL" ] && [ -n "$REMOTE" ]; then
                    echo "New commits available on main"
                fi
            fi
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const msg = this.text.trim();
                if (msg !== "") {
                    root.sendNotification("Update Available", msg + ". Check Settings > About to update.");
                }
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            if (Config.ready && Config.options.system) {
                Notifications.silent = Config.options.system.dndActive;
            }
            runAutomationCycle();
            _ready = true;
            scheduleNext();
        });
    }
}
