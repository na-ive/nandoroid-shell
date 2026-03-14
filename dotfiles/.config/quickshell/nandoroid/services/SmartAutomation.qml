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

    // --- Main Automation Timer ---
    Timer {
        id: mainTimer
        interval: 10000 // Check every 10 seconds for high accuracy
        running: true
        repeat: true
        onTriggered: runAutomationCycle()
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
        Qt.callLater(() => runAutomationCycle());
    }
}
