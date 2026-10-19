import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab 1: Schedule
 * "Today" timeline (Google Calendar style) with a floating "+" action.
 * Page 0 = day timeline, Page 1 = event editor (CRUD form).
 */
Item {
    id: root

    // ── Navigation state ──
    property string _view: "timeline"
    // "timeline" | "editor" | "reminder-editor"
    property string _editingId: ""
    property string _editingReminderId: ""
    property int dayOffset: 0 // 0 = today

    // ── Items from parent (for reminder linked-item picker) ──
    property var notepadItems: []
    property var todoItems: []
    // ── Timeline metrics ──
    readonly property real hourHeight: 40 * Appearance.effectiveScale
    readonly property real gutterWidth: 46 * Appearance.effectiveScale
    readonly property real minBlockHeight: 22 * Appearance.effectiveScale
    readonly property real timelineContentHeight: 24 * root.hourHeight
    // Current-time fraction for the "now" line.
    // Bound directly to the system clock so it is always accurate — it moves
    // every minute regardless of timers or dashboard visibility. Previously
    // this was only refreshed by a timer that ran while the dashboard was
    // open, so the line froze at the moment of the last refresh after reopen.
    readonly property real nowFrac: {
        const now = DateTime.now;
        return (now.getHours() + now.getMinutes() / 60) / 24;
    }
    // Guard with DateTime.currentDate so the day re-evaluates when the clock
    // rolls over at midnight: `new Date()` inside _dateForOffset is evaluated
    // non-reactively, and without this guard the selection freezes on the day
    // the shell started (stale "Today" events in overnight sessions). The
    // current date string only flips at midnight, so downstream bindings
    // (dayEvents/dayLayout → Repeater) never churn per-second.
    readonly property string _dayDate: {
        const _ = DateTime.currentDate;
        return root._canonical(root._dateForOffset(root.dayOffset));
    }
    readonly property string _dayLabel: {
        const _ = DateTime.currentDate; // midnight rollover (see _dayDate)
        const d = root._dateForOffset(root.dayOffset);

        if (root.dayOffset === 0)
            return I18nService.tr("Today");

        if (root.dayOffset === 1)
            return I18nService.tr("Tomorrow");

        if (root.dayOffset === -1)
            return I18nService.tr("Yesterday");

        const days = [I18nService.tr("Sunday"), I18nService.tr("Monday"), I18nService.tr("Tuesday"), I18nService.tr("Wednesday"), I18nService.tr("Thursday"), I18nService.tr("Friday"), I18nService.tr("Saturday")];
        const months = [I18nService.tr("Jan"), I18nService.tr("Feb"), I18nService.tr("Mar"), I18nService.tr("Apr"), I18nService.tr("May"), I18nService.tr("Jun"), I18nService.tr("Jul"), I18nService.tr("Aug"), I18nService.tr("Sep"), I18nService.tr("Oct"), I18nService.tr("Nov"), I18nService.tr("Dec")];
        return days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()];
    }
    // ── Events for the selected day ──
    // Recurrence matching delegated to ScheduleService.eventOccursOn — single source of truth.
    readonly property var dayEvents: {
        const day = root._dayDate;
        const list = ScheduleService.events.filter(ev => ScheduleService.eventOccursOn(ev, day));
        list.sort((a, b) => (a.time || "00:00").localeCompare(b.time || "00:00"));
        return list;
    }
    // Unified column layout for overlapping events AND reminders.
    // Returns [{ item, sf, ef, isReminder, col, colCount }] sorted by start time.
    readonly property var dayLayout: {
        const items = [];

        // Add events
        for (let i = 0; i < root.dayEvents.length; i++) {
            const ev = root.dayEvents[i];
            items.push({ "item": ev, "sf": root._blockStartFrac(ev), "ef": root._blockEndFrac(ev), "isReminder": false });
        }

        // Add reminders (fixed 1-hour height)
        for (let j = 0; j < root.dayReminders.length; j++) {
            const rem = root.dayReminders[j];
            const sf = root._timeFrac(rem.time) ?? 0;
            items.push({ "item": rem, "sf": sf, "ef": Math.min(1, sf + 1 / 24), "isReminder": true });
        }

        if (items.length === 0) return [];

        // Sort by start time
        items.sort(function(a, b) { return a.sf - b.sf; });

        // Group overlapping items into clusters
        const clusters = [];
        let current = [];
        for (let k = 0; k < items.length; k++) {
            const it = items[k];
            let overlaps = false;
            for (let m = 0; m < current.length; m++) {
                if (it.sf < current[m].ef && current[m].sf < it.ef) { overlaps = true; break; }
            }
            if (overlaps) {
                current.push(it);
            } else {
                if (current.length) clusters.push(current);
                current = [it];
            }
        }
        if (current.length) clusters.push(current);

        // Greedy column assignment
        const result = [];
        for (let ci = 0; ci < clusters.length; ci++) {
            const cluster = clusters[ci];
            const colEnds = [];
            const placed = [];
            for (let pi = 0; pi < cluster.length; pi++) {
                const it = cluster[pi];
                let col = 0;
                while (col < colEnds.length && it.sf < colEnds[col]) col++;
                if (col === colEnds.length) colEnds.push(0);
                colEnds[col] = Math.max(colEnds[col], it.ef);
                placed.push({ "item": it.item, "sf": it.sf, "ef": it.ef, "isReminder": it.isReminder, "col": col });
            }
            const colCount = colEnds.length;
            for (let ri = 0; ri < placed.length; ri++) {
                const p = placed[ri];
                result.push({ "item": p.item, "sf": p.sf, "ef": p.ef, "isReminder": p.isReminder, "col": p.col, "colCount": colCount });
            }
        }
        return result;
    }
    // ── Editor form state ──
    property string formTitle: ""
    property string formDate: _defaultDateStr()
    property string formTime: "00:00"
    property string formEndTime: "01:00"
    property string formRecurrence: "once" // once | daily | weekly | monthly
    property string formEndDate: ""
    property string formDescription: ""
    property bool formFocus: false

    // ── Reminder form state ──
    property string reminderText: ""
    property string reminderDate: _defaultDateStr()
    property string reminderTime: "09:00"
    property string reminderType: "basic" // "basic" | "notepad" | "todo"
    property string reminderLinkedId: ""
    property string reminderLinkedTitle: ""

    // ── Reminders for selected day ──
    readonly property var dayReminders: {
        const day = root._dayDate;
        return ReminderService.reminders.filter(r => r.date === day && !r.fired);
    }
    property int _multiDayDiff: {
        if (!formEndDate.trim() || formEndDate === formDate)
            return 0;

        const s = root._parseDateObj(formDate);
        const e = root._parseDateObj(formEndDate);
        if (!s || !e)
            return 0;

        return Math.round((e - s) / 8.64e+07);
    }
    property bool formDatesValid: {
        if (!root.formEndDate.trim())
            return true;

        const s = root._parseDateObj(root.formDate);
        const e = root._parseDateObj(root.formEndDate);
        if (!s || !e)
            return false;

        if (e.getTime() < s.getTime())
            return false;

        if (e.getTime() > s.getTime())
            return true;

        const t = (str) => {
            const p = String(str || "").split(":").map(Number);
            return p.length >= 2 && !isNaN(p[0]) && !isNaN(p[1]) ? p[0] * 60 + p[1] : 0;
        };
        return t(root.formEndTime) > t(root.formTime);
    }
    // ── Date/time pickers ──
    property string _datePickerTarget: ""
    property string _timePickerTarget: ""

    // ── Date helpers ──
    function _canonical(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0');
    }

    function _dateForOffset(offset) {
        const d = new Date();
        d.setDate(d.getDate() + offset);
        return d;
    }

    function _hourLabel(h) {
        const style = Config.ready && Config.options.time ? Config.options.time.timeStyle : "24H";
        if (style === "24H")
            return String(h).padStart(2, "0") + ":00";

        const upper = style === "12H_PM";
        const ap = h >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am");
        const h12 = h % 12 || 12;
        return h12 + " " + ap;
    }

    function _formatDateObj(d) {
        if (!d)
            return "";

        let y = d.getFullYear(), m = d.getMonth() + 1, day = d.getDate();
        const ys = String(y).padStart(4, '0');
        const ms = String(m).padStart(2, '0');
        const ds = String(day).padStart(2, '0');
        let style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY";
        if (style === "YMD")
            return ys + "/" + ms + "/" + ds;

        if (style === "MDY")
            return ms + "/" + ds + "/" + ys;

        return ds + "/" + ms + "/" + ys;
    }

    function _parseDateObj(dStr) {
        if (!dStr)
            return null;

        const parts = String(dStr).trim().split(/[-/]/).map(Number);
        if (parts.length < 3 || parts.some(isNaN))
            return null;

        let y, m, d;
        if (parts[0] > 1000) {
            y = parts[0];
            m = parts[1];
            d = parts[2];
        } else if (parts[2] > 1000) {
            const style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY";
            if (style === "MDY") {
                m = parts[0];
                d = parts[1];
                y = parts[2];
            } else {
                d = parts[0];
                m = parts[1];
                y = parts[2];
            }
        } else {
            return null;
        }
        const dt = new Date(y, m - 1, d);
        return isNaN(dt.getTime()) ? null : dt;
    }

    function _formatDateByConfig(dStr) {
        if (!dStr)
            return "";

        let parts = dStr.trim().split(/[-/]/).map(Number);
        if (parts.length < 3 || parts.some(isNaN))
            return dStr;

        let y, m, d;
        if (parts[0] > 1000) {
            y = parts[0];
            m = parts[1];
            d = parts[2];
        } else if (parts[2] > 1000) {
            let style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY";
            if (style === "MDY") {
                m = parts[0];
                d = parts[1];
                y = parts[2];
            } else {
                d = parts[0];
                m = parts[1];
                y = parts[2];
            }
        } else {
            return dStr;
        }
        const ys = String(y).padStart(4, '0');
        const ms = String(m).padStart(2, '0');
        const ds = String(d).padStart(2, '0');
        let style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY";
        if (style === "YMD")
            return ys + "/" + ms + "/" + ds;

        if (style === "MDY")
            return ms + "/" + ds + "/" + ys;

        return ds + "/" + ms + "/" + ys;
    }

    function _displayTime(timeStr) {
        if (!timeStr)
            return timeStr;

        const parts = String(timeStr).split(":");
        if (parts.length < 2)
            return timeStr;

        const h = parseInt(parts[0], 10);
        if (isNaN(h))
            return timeStr;

        const m = parts[1];
        const rest = parts.length > 2 ? ":" + parts.slice(2).join(":") : "";
        const style = Config.ready && Config.options.time ? Config.options.time.timeStyle : "24H";
        if (style === "24H")
            return String(h).padStart(2, "0") + ":" + m + rest;

        const upper = style === "12H_PM";
        const ap = h >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am");
        const h12 = h % 12 || 12;
        return String(h12).padStart(2, "0") + ":" + m + rest + " " + ap;
    }

    function _displayDate(dStr) {
        if (!dStr)
            return dStr;

        const style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY";
        const parts = String(dStr).trim().split(/[-/]/).map(Number);
        if (parts.length < 3 || parts.some(isNaN))
            return dStr;

        let y, m, d;
        if (parts[0] > 1000) {
            y = parts[0];
            m = parts[1];
            d = parts[2];
        } else if (style === "MDY") {
            m = parts[0];
            d = parts[1];
            y = parts[2];
        } else {
            d = parts[0];
            m = parts[1];
            y = parts[2];
        }
        if (!y || !m || !d)
            return dStr;

        const days = [I18nService.tr("Sun"), I18nService.tr("Mon"), I18nService.tr("Tue"), I18nService.tr("Wed"), I18nService.tr("Thu"), I18nService.tr("Fri"), I18nService.tr("Sat")];
        return days[new Date(y, m - 1, d).getDay()] + ", " + dStr;
    }

    function _defaultDateStr() {
        return _formatDateObj(new Date());
    }

    function _recurrenceLabel(code) {
        switch (code) {
        case "once":
            return I18nService.tr("Once");
        case "daily":
            return I18nService.tr("Daily");
        case "weekly":
            return I18nService.tr("Weekly");
        case "monthly":
            return I18nService.tr("Monthly");
        default:
            return code;
        }
    }

    function _timeFrac(t) {
        const p = String(t || "").split(":");
        if (p.length < 2 || isNaN(+p[0]) || isNaN(+p[1]))
            return null;

        return (+p[0] + +p[1] / 60) / 24;
    }

    function _isMultiDay(ev) {
        return ev.recurrence === "once" && ev.endDate && ev.endDate !== ev.date;
    }

    function _blockStartFrac(ev) {
        const multi = root._isMultiDay(ev);
        if (multi && root._dayDate !== ev.date)
            return 0;

        return root._timeFrac(ev.time) ?? 0;
    }

    function _blockEndFrac(ev) {
        const multi = root._isMultiDay(ev);
        const start = root._timeFrac(ev.time) ?? 0;
        if (multi) {
            const first = root._dayDate === ev.date;
            const last = root._dayDate === ev.endDate;
            if (first && !last)
                return 1;

            if (last && !first)
                return root._timeFrac(ev.endTime) ?? 1;

        }
        const end = root._timeFrac(ev.endTime);
        if (end === null)
            return Math.min(1, start + 1 / 24);

        if (end > start)
            return end;

        return 1;
    }

    function _overlaps(a, b) {
        const as = root._blockStartFrac(a), ae = root._blockEndFrac(a);
        const bs = root._blockStartFrac(b), be = root._blockEndFrac(b);
        if (ae <= bs || be <= as)
            return false;

        return true;
    }

    // ── View switching ──
    function openEditorNew() {
        root._editingId = "";
        root.clearForm();
        root._view = "editor";
    }

    function openEditorEdit(id) {
        const ev = ScheduleService.events.find((e) => {
            return e.id === id;
        });
        if (!ev)
            return ;

        root._editingId = id;
        root.formTitle = ev.title;
        root.formDate = root._formatDateByConfig(ev.date);
        root.formTime = ev.time;
        root.formEndTime = ev.endTime || "";
        root.formEndDate = root._formatDateByConfig(ev.endDate || "");
        root.formRecurrence = ev.recurrence;
        root.formDescription = ev.description || "";
        root.formFocus = ev.focus || false;
        root._view = "editor";
    }

    function backToTimeline() {
        if (autoSaveTimer.running)
            autoSaveTimer.stop();

        root._editingId = "";
        root._view = "timeline";
    }


    // Auto-save helper exposed to the (extracted) event-editor page.
    function requestAutoSave() {
        autoSaveTimer.restart();
    }

    function deleteEditingEvent() {
        if (!root._editingId)
            return ;

        const idx = ScheduleService.events.findIndex(e => e.id === root._editingId);
        if (idx === -1)
            return;
        const removed = ScheduleService.events[idx];

        ScheduleService.deleteEvent(root._editingId);
        root._editingId = "";
        root._view = "timeline";
        SnackbarService.show(
            I18nService.tr("Event deleted"),
            I18nService.tr("Undo"),
            () => {
                const events = ScheduleService.events.slice();
                events.splice(Math.min(idx, events.length), 0, removed);
                ScheduleService.events = events;
                ScheduleService.save();
            },
            SnackbarService.undoDuration
        );
    }

    function clearForm() {
        const now = new Date();
        let nextH = (now.getHours() + 1) % 24;
        let date = new Date(now);
        if (nextH <= now.getHours())
            date.setDate(date.getDate() + 1);

        const nextHStr = String(nextH).padStart(2, '0') + ":00";
        const endH = (nextH + 1) % 24;
        const endHStr = String(endH).padStart(2, '0') + ":00";
        let endDate = new Date(date);
        if (endH <= nextH)
            endDate.setDate(endDate.getDate() + 1);

        formTitle = "";
        formDate = _formatDateObj(date);
        formTime = nextHStr;
        formEndTime = endHStr;
        formEndDate = _formatDateObj(endDate);
        formDescription = "";
        formFocus = false;
    }

    function saveEvent() {
        if (!formTitle.trim())
            return ;

        const descVal = formDescription.trim() ? formDescription.trim() : undefined;
        const dateVal = GlobalStates.toCanonicalDateStr(formDate) || formDate;
        const endDateVal = formEndDate.trim() && formEndDate !== formDate ? (GlobalStates.toCanonicalDateStr(formEndDate) || formEndDate) : undefined;
        if (_editingId) {
            ScheduleService.updateEvent(_editingId, {
                "title": formTitle,
                "date": dateVal,
                "time": formTime,
                "endTime": formEndTime,
                "endDate": endDateVal,
                "recurrence": formRecurrence,
                "description": descVal,
                "focus": formFocus
            });
        } else {
            const newEv = {
                "id": Date.now().toString(36),
                "title": formTitle,
                "date": dateVal,
                "time": formTime,
                "endTime": formEndTime,
                "endDate": endDateVal,
                "recurrence": formRecurrence,
                "description": descVal,
                "focus": formFocus,
                "lastFired": ""
            };
            ScheduleService.addEvent(newEv);
        }
        root._editingId = "";
        root.clearForm();
        root._view = "timeline";
    }

    function openDatePicker() {
        root._datePickerTarget = "start";
        GlobalStates.datePickerCurrentDate = root.formDate;
        GlobalStates.datePickerOnSelected = function(dateStr) {
            root._datePickerTarget = "";
            root.formDate = dateStr;
            if (root._editingId)
                autoSaveTimer.restart();

        };
        GlobalStates.datePickerOnCancelled = function() {
            root._datePickerTarget = "";
        };
        GlobalStates.datePickerOpen = true;
    }

    function openEndDatePicker() {
        root._datePickerTarget = "end";
        GlobalStates.datePickerCurrentDate = root.formEndDate || root.formDate;
        GlobalStates.datePickerOnSelected = function(dateStr) {
            root._datePickerTarget = "";
            root.formEndDate = dateStr;
            if (root._editingId)
                autoSaveTimer.restart();

        };
        GlobalStates.datePickerOnCancelled = function() {
            root._datePickerTarget = "";
        };
        GlobalStates.datePickerOpen = true;
    }

    function openStartTimePicker() {
        root._timePickerTarget = "start";
        GlobalStates.openTimePicker(root.formTime || "00:00", function(timeStr) {
            root._timePickerTarget = "";
            root.formTime = timeStr;
            if (root._editingId)
                autoSaveTimer.restart();

        }, function() {
            root._timePickerTarget = "";
        }, Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false);
    }

    function openEndTimePicker() {
        root._timePickerTarget = "end";
        GlobalStates.openTimePicker(root.formEndTime || "01:00", function(timeStr) {
            root._timePickerTarget = "";
            root.formEndTime = timeStr;
            if (root._editingId)
                autoSaveTimer.restart();

        }, function() {
            root._timePickerTarget = "";
        }, Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false);
    }

    // ── Reminder editor helpers ──
    function openReminderEditorNew() {
        root._editingReminderId = "";
        root.clearReminderForm();
        root._view = "reminder-editor";
    }

    function openReminderEditorEdit(id) {
        const r = ReminderService.reminders.find(x => x.id === id);
        if (!r) return;
        root._editingReminderId = id;
        root.reminderText = r.text;
        root.reminderDate = root._formatDateByConfig(r.date);
        root.reminderTime = r.time;
        root.reminderType = r.type || "basic";
        root.reminderLinkedId = r.linkedId || "";
        root.reminderLinkedTitle = r.linkedTitle || "";
        root._view = "reminder-editor";
    }

    function backFromReminderEditor() {
        root._editingReminderId = "";
        root._view = "timeline";
    }

    function clearReminderForm() {
        const now = new Date();
        const nextH = (now.getHours() + 1) % 24;
        const date = new Date(now);
        if (nextH <= now.getHours()) date.setDate(date.getDate() + 1);
        reminderText = "";
        reminderDate = _formatDateObj(date);
        reminderTime = String(nextH).padStart(2, '0') + ":00";
        reminderType = "basic";
        reminderLinkedId = "";
        reminderLinkedTitle = "";
    }

    function saveReminder() {
        if (!reminderText.trim()) return;
        const dateVal = GlobalStates.toCanonicalDateStr(reminderDate) || reminderDate;
        if (root._editingReminderId) {
            ReminderService.updateReminder(root._editingReminderId, {
                text: reminderText.trim(),
                date: dateVal,
                time: reminderTime,
                type: reminderType,
                linkedId: reminderLinkedId,
                linkedTitle: reminderLinkedTitle
            });
        } else {
            ReminderService.addReminder({
                id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
                text: reminderText.trim(),
                date: dateVal,
                time: reminderTime,
                type: reminderType,
                linkedId: reminderLinkedId,
                linkedTitle: reminderLinkedTitle,
                fired: false,
                lastFiredDate: ""
            });
        }
        root._editingReminderId = "";
        root._view = "timeline";
    }

    function deleteEditingReminder() {
        if (!root._editingReminderId) return;

        const idx = ReminderService.reminders.findIndex(r => r.id === root._editingReminderId);
        if (idx === -1) return;
        const removed = ReminderService.reminders[idx];

        ReminderService.deleteReminder(root._editingReminderId);
        root._editingReminderId = "";
        root._view = "timeline";
        SnackbarService.show(
            I18nService.tr("Reminder deleted"),
            I18nService.tr("Undo"),
            () => {
                const reminders = ReminderService.reminders.slice();
                reminders.splice(Math.min(idx, reminders.length), 0, removed);
                ReminderService.reminders = reminders;
                ReminderService.save();
            },
            SnackbarService.undoDuration
        );
    }

    function openReminderDatePicker() {
        GlobalStates.datePickerCurrentDate = root.reminderDate;
        GlobalStates.datePickerOnSelected = function(dateStr) {
            root.reminderDate = dateStr;
        };
        GlobalStates.datePickerOnCancelled = function() {};
        GlobalStates.datePickerOpen = true;
    }

    function openReminderTimePicker() {
        GlobalStates.openTimePicker(root.reminderTime || "09:00", function(timeStr) {
            root.reminderTime = timeStr;
        }, function() {}, Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false);
    }

    onDayOffsetChanged: Qt.callLater(() => timelineView.scrollToDayStart())
    onFormEndDateChanged: {
        if (_multiDayDiff > 0 && formRecurrence !== "once")
            formRecurrence = "once";

    }
    Component.onCompleted: {
        clearForm();
        Qt.callLater(() => {
            return timelineView.scrollToDayStart();
        });
        recenterTimer.start();
    }

    // Re-center the timeline on the "now" line every time the dashboard
    // opens, so it shows the current hour instead of the startup position
    // (without this, the scroll position and now-line placement both go
    // stale between dashboard sessions).
    Connections {
        target: GlobalStates
        function onDashboardOpenChanged() {
            if (GlobalStates.dashboardOpen && root._view === "timeline" && root.dayOffset === 0)
                Qt.callLater(() => timelineView.scrollToDayStart());
        }
    }

    // Recenter once layout/panel animation has settled so the target hour
    // is centered within the timeline area (not the whole panel).
    Timer {
        id: recenterTimer

        interval: 400
        repeat: false
        onTriggered: timelineView.scrollToDayStart()
    }

    // Auto-save debounce for existing events
    Timer {
        id: autoSaveTimer

        interval: 500
        repeat: false
        onTriggered: {
            if (!root._editingId || !root.formTitle.trim())
                return ;

            const descVal = root.formDescription.trim() ? root.formDescription.trim() : undefined;
            const dateVal = GlobalStates.toCanonicalDateStr(root.formDate) || root.formDate;
            const endDateVal = root.formEndDate.trim() && root.formEndDate !== root.formDate ? (GlobalStates.toCanonicalDateStr(root.formEndDate) || root.formEndDate) : undefined;
            ScheduleService.updateEvent(root._editingId, {
                "title": root.formTitle,
                "date": dateVal,
                "time": root.formTime,
                "endTime": root.formEndTime,
                "endDate": endDateVal,
                "recurrence": root.formRecurrence,
                "description": descVal,
                "focus": root.formFocus
            });
        }
    }

    // ============================================
    //  PAGES (extracted components)
    // ============================================
    DashScheduleTimeline {
        id: timelineView
        ctrl: root
    }

    DashScheduleEventEditor {
        id: editorView
        ctrl: root
    }

    DashScheduleReminderEditor {
        id: reminderEditorView
        ctrl: root
    }
}
