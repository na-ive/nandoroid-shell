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

    // Apply DND state to Notifications service
    readonly property bool shouldBeDnd: scheduleDndActive || pomodoroDndActive
    onShouldBeDndChanged: {
        Notifications.silent = shouldBeDnd;
        root.dndActive = shouldBeDnd;
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

    // Watch for schedule changes to recalculate timing
    property var _eventWatch: ScheduleService.events
    on_EventWatchChanged: if (_ready) scheduleNext()

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
            let isEventDay = (event.date === nowDateStr);
            if (event.recurrence === "daily") isEventDay = true;
            else if (event.recurrence === "weekly") {
                const d = new Date(event.date + "T00:00:00");
                isEventDay = d.getDay() === now.getDay();
            } else if (event.recurrence === "monthly") {
                const d = new Date(event.date + "T00:00:00");
                isEventDay = d.getDate() === now.getDate();
            }
            if (!isEventDay) return;

            const eventStart = new Date(nowDateStr + "T" + event.time);
            const eventEnd = event.endTime
                ? new Date(nowDateStr + "T" + event.endTime)
                : new Date(eventStart.getTime() + 3600000);

            // Notification 1h before
            const notif1h = new Date(eventStart.getTime() - 3600000);
            if (notif1h > now) {
                nextMs = Math.min(nextMs, notif1h.getTime() - now.getTime());
            } else if (now < eventStart && !event.lastNotified1hDate) {
                // 1h window already open but notification not yet sent
                nextMs = Math.min(nextMs, 1000);
            }

            // Event start (for DND activation)
            if (event.focus && eventStart > now) nextMs = Math.min(nextMs, eventStart.getTime() - now.getTime());

            // Event end (for DND deactivation)
            if (event.focus && eventEnd > now) nextMs = Math.min(nextMs, eventEnd.getTime() - now.getTime());

            // Expired once event cleanup (30s after end)
            if (event.recurrence === "once") {
                const expire = new Date(eventEnd.getTime() + 30000);
                if (expire > now) nextMs = Math.min(nextMs, expire.getTime() - now.getTime());
                else nextMs = Math.min(nextMs, 1000);
            }
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
            let isEventDay = (event.date === nowDateStr);
            if (event.recurrence === "daily") isEventDay = true;
            else if (event.recurrence === "weekly") {
                const eventDate = new Date(event.date + "T00:00:00");
                isEventDay = (eventDate.getDay() === now.getDay());
            } else if (event.recurrence === "monthly") {
                const eventDate = new Date(event.date + "T00:00:00");
                isEventDay = (eventDate.getDate() === now.getDate());
            }

            if (!isEventDay) return;

            // 3. Time Check
            const eventStart = new Date(nowDateStr + "T" + event.time);
            const eventEnd = event.endTime 
                ? new Date(nowDateStr + "T" + event.endTime) 
                : new Date(eventStart.getTime() + 3600000);
            
            // 4. DND Active Check
            if (event.focus && now >= eventStart && now < eventEnd) {
                anyEventActive = true;
            }

            // 5. Notification Logic
            const diffMs = eventStart.getTime() - now.getTime();
            const diffHours = diffMs / 3600000;

            // 00:00 (Today) Notif
            const lastNotified00 = event.lastNotified00Date || "";
            if (lastNotified00 !== nowDateStr) {
                sendNotification("Today's Schedule", `Upcoming event: ${event.title} at ${event.time}`);
                ScheduleService.updateEvent(event.id, { lastNotified00Date: nowDateStr });
            }

            // 1h Before Notif
            const lastNotified1h = event.lastNotified1hDate || "";
            if (diffHours > 0 && diffHours <= 1.0 && lastNotified1h !== nowDateStr) {
                sendNotification("Starting Soon", `${event.title} starts in 1 hour (${event.time})`);
                ScheduleService.updateEvent(event.id, { lastNotified1hDate: nowDateStr });
            }

            // 6. Expiry Check (Auto-delete "once" events)
            if (event.recurrence === "once") {
                if (now.getTime() > (eventEnd.getTime() + 30000)) {
                    expiredEventIds.push(event.id);
                }
            }
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
            runAutomationCycle();
            _ready = true;
            scheduleNext();
        });
    }
}
