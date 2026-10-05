import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Dashboard Tab 0: Calendar (natural-height, square cells) + schedule summary
 * card (Now / Next today / Next / No schedule) + Pomodoro with arc ring.
 */
RowLayout {
    id: root

    // ── Calendar accent family (matches the Calendar rail button inactive state) ──
    readonly property color calContainer: Functions.ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colTertiaryContainer, 0.5)
    readonly property color calOnContainer: Functions.ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colOnTertiaryContainer, 0.5)

    readonly property string _todayStr: {
        const _ = DateTime.now;
        return root._fmtDate(DateTime.now);
    }
    // Recompute the summary card whenever the schedule / reminders change or each minute.
    readonly property int _minuteTrigger: DateTime.minutes
    on_MinuteTriggerChanged: root._recomputeSummary()
    property var _scheduleTrigger: ScheduleService.events
    on_ScheduleTriggerChanged: root._recomputeSummary()
    property var _reminderTrigger: ReminderService.reminders
    on_ReminderTriggerChanged: root._recomputeSummary()
    Component.onCompleted: root._recomputeSummary()
    // Build a flat list of all dates this event applies to (expand recurring)
    // Combined events for calendar: schedule + reminders (not yet fired)
    readonly property var allEvents: {
        let combined = ScheduleService.events.slice();
        for (const r of ReminderService.reminders) {
            if (r.fired) continue;
            combined.push({
                "_isReminder": true,
                "title": r.text,
                "description": r.linkedTitle || "",
                "time": r.time,
                "date": r.date,
                "recurrence": "once"
            });
        }
        return combined;
    }
    property var _summary: {
        "state": "none"
    }
    property string _summaryIcon: "event_busy"
    property string _summaryTitle: ""
    property string _summarySub: ""
    // Filters allEvents (schedule + todo deadlines) for a given YYYY-MM-DD string.
    // Delegates recurrence matching to ScheduleService.eventOccursOn — single source of truth.
    function _getEventsForDate(dateStr) {
        return root.allEvents.filter(ev => ScheduleService.eventOccursOn(ev, dateStr));
    }

    function _recomputeSummary() {
        // Use DateTime.now (SystemClock boundary-aligned) instead of new Date():
        // SystemClock fires within ±50ms of the boundary, so new Date() can still
        // be the previous minute right after the trigger — causing a 1-minute lag.
        const now = DateTime.now;
        const nowFrac = (now.getHours() * 60 + now.getMinutes()) / 1440;
        const today = root._todayStr;
        const todays = root._getEventsForDate(today).slice().sort((a, b) => {
            return (a.time || "00:00").localeCompare(b.time || "00:00");
        });
        // Now: event whose start <= now and end > now
        for (let ev of todays) {
            const s = root._frac(ev.time) ?? 0;
            const e = root._frac(ev.endTime);
            const end = (e !== null && e > s) ? e : 1;
            if (nowFrac >= s && nowFrac < end) {
                root._summary = {
                    "state": "now",
                    "ev": ev
                };
                root._syncSummaryDisplay();
                return;
            }
        }
        // Next event today
        for (let ev of todays) {
            const s = root._frac(ev.time) ?? 0;
            if (s > nowFrac) {
                root._summary = {
                    "state": "nextToday",
                    "ev": ev
                };
                root._syncSummaryDisplay();
                return;
            }
        }
        // Next future event (bounded search)
        for (let i = 1; i <= 60; i++) {
            const d = new Date(now.getTime() + i * 8.64e+07);
            const ds = root._fmtDate(d);
            const evs = root._getEventsForDate(ds);
            if (evs.length) {
                evs.sort((a, b) => {
                    return (a.time || "00:00").localeCompare(b.time || "00:00");
                });
                root._summary = {
                    "state": "nextLater",
                    "ev": evs[0],
                    "dayStr": ds
                };
                root._syncSummaryDisplay();
                return;
            }
        }
        root._summary = {
            "state": "none"
        };
        root._syncSummaryDisplay();
    }
    function _syncSummaryDisplay() {
        const s = root._summary;
        if (s.ev && s.ev._isReminder) {
            root._summaryIcon = "notifications_active";
        } else {
            switch (s.state) {
            case "now":
                root._summaryIcon = "timer";
                break;
            case "nextToday":
                root._summaryIcon = "today";
                break;
            case "nextLater":
                root._summaryIcon = "event";
                break;
            default:
                root._summaryIcon = "event_busy";
            }
        }
        if (s.state === "none") {
            root._summaryTitle = I18nService.tr("No schedule");
            root._summarySub = I18nService.tr("No more events today");
            return;
        }

        root._summaryTitle = s.ev.title;
        const start = calWidget._displayTime(s.ev.time);
        const end = s.ev.endTime ? calWidget._displayTime(s.ev.endTime) : "";
        const range = end && end !== start ? start + " - " + end : start;
        if (s.state === "now")
            root._summarySub = I18nService.tr("Now") + " · " + range;
        else if (s.state === "nextToday")
            root._summarySub = I18nService.tr("Next today") + " · " + start;
        else
            root._summarySub = I18nService.tr("Next") + " · " + root._dayLabelFor(s.dayStr) + " · " + start;
    }
    // Compact calendar sizing — natural cells (like ii), always 6 rows → stable height
    readonly property real _cellSize: Math.round(38 * Appearance.effectiveScale)
    readonly property real _cellSpacing: 4 * Appearance.effectiveScale
    readonly property real _sectionSpacing: 16 * Appearance.effectiveScale
    readonly property real _calendarCardWidth: 7 * root._cellSize + 6 * root._cellSpacing + 24 * Appearance.effectiveScale

    signal jumpToSchedule()

    function _fmtDate(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    }

    // ── Summary card computation ──
    function _frac(t) {
        const p = String(t || "").split(":");
        if (p.length < 2)
            return null;

        const h = +p[0], m = +p[1];
        if (isNaN(h) || isNaN(m))
            return null;

        return (h * 60 + m) / 1440;
    }

    function _dayLabelFor(dateStr) {
        if (dateStr === root._todayStr)
            return I18nService.tr("Today");

        const tom = DateTime.now;
        tom.setDate(tom.getDate() + 1);
        if (dateStr === root._fmtDate(tom))
            return I18nService.tr("Tomorrow");

        const p = String(dateStr).split("-").map(Number);
        if (p.length < 3)
            return dateStr;

        const days = [I18nService.tr("Sun"), I18nService.tr("Mon"), I18nService.tr("Tue"), I18nService.tr("Wed"), I18nService.tr("Thu"), I18nService.tr("Fri"), I18nService.tr("Sat")];
        return days[new Date(p[0], p[1] - 1, p[2]).getDay()];
    }

    spacing: 12 * Appearance.effectiveScale

    TapHandler {
        onTapped: calWidget.closePopup()
    }

    // ── Left column: calendar card + separate schedule summary card ──
    // Calendar keeps its natural width; the pomodoro card fills the remaining space
    ColumnLayout {
        Layout.fillWidth: false
        Layout.preferredWidth: root._calendarCardWidth
        Layout.fillHeight: true
        spacing: 12 * Appearance.effectiveScale

        // Calendar card (always 6 rows → stable height across 5/6-row months)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.normal

            Item {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale

                // Calendar at natural size, centred (ii-style: fixed cells, no stretching)
                CalendarWidget {
                    id: calWidget

                    anchors.centerIn: parent
                    width: Math.min(parent.width, implicitWidth)
                    height: implicitHeight
                    compact: true
                    cellSize: root._cellSize
                    cellSpacing: root._cellSpacing
                    sectionSpacing: root._sectionSpacing
                    scheduledEvents: root.allEvents
                }

            }

        }

        // Schedule summary card (own card, below the calendar)
        // Tinted when there is an upcoming event, neutral otherwise
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56 * Appearance.effectiveScale
            color: root._summary.state === "none" ? Appearance.colors.colLayer2 : root.calContainer
            radius: Appearance.rounding.normal
            clip: true

            RippleButton {
                anchors.fill: parent
                buttonRadius: Appearance.rounding.normal
                colBackground: "transparent"
                colBackgroundHover: root._summary.state === "none" ? Appearance.colors.colLayer2Hover : Functions.ColorUtils.mix(root.calContainer, root.calOnContainer, 0.92)
                colRipple: root._summary.state === "none" ? Appearance.colors.colLayer2Active : Functions.ColorUtils.mix(root.calContainer, root.calOnContainer, 0.85)
                onClicked: root.jumpToSchedule()

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14 * Appearance.effectiveScale
                    anchors.rightMargin: 6 * Appearance.effectiveScale
                    spacing: 10 * Appearance.effectiveScale

                    MaterialSymbol {
                        text: root._summaryIcon
                        iconSize: 22 * Appearance.effectiveScale
                        color: root._summary.state === "none" ? Appearance.colors.colSubtext : root.calOnContainer
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1 * Appearance.effectiveScale

                        StyledText {
                            Layout.fillWidth: true
                            text: root._summaryTitle
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: root._summarySub
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }

                    }

                    MaterialSymbol {
                        text: "chevron_right"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }

                }

                StyledToolTip {
                    text: I18nService.tr("Open schedule")
                }

            }

        }

    }

    // ── 3-in-1 Clock Widget (Pomodoro, Stopwatch, Timer) ──
    DashClock {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
    }

}
