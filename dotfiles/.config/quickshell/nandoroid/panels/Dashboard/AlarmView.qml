import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import "../../services"

/**
 * Dashboard Clock Widget — Alarm tab (Android Clock style).
 * Cards per alarm (active = primaryContainer), FAB to add via TimePicker,
 * per-alarm settings in a centered dialog (DialogService custom content).
 */
Item {
    id: root

    // ── Calendar accent family (matches the Calendar rail button inactive state;
    // active accents used for controls, containers for cards) ──
    readonly property color calAccent: Functions.ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colTertiary, 0.5)
    readonly property color calOnAccent: Functions.ColorUtils.mix(Appearance.colors.colOnPrimary, Appearance.colors.colOnTertiary, 0.5)
    readonly property color calContainer: Functions.ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colTertiaryContainer, 0.5)
    readonly property color calOnContainer: Functions.ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colOnTertiaryContainer, 0.5)

    // Alarm days are stored Mon-based (0=Mon..6=Sun); chips follow the same
    // firstDayOfWeek config as the dashboard calendar
    readonly property var dayNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    readonly property var dayLetters: root.dayNames.map(d => I18nService.tr(d).charAt(0))
    readonly property int weekStartMon: {
        const fdow = (Config.ready && Config.options.time && Config.options.time.firstDayOfWeek !== undefined) ? Config.options.time.firstDayOfWeek : 1;
        return (fdow + 6) % 7;
    }
    property var settingsAlarm: null // alarm being edited in the dialog
    property date nowDate: new Date() // drives Dismiss visibility, refreshed periodically

    // Stable id-based model: delegates survive data updates so animations
    // (toggle thumb, card color) keep playing. Rebuilt only when the alarm
    // set or ordering changes — field edits are read live via alarm lookup.
    property string _alarmModelKey: ""
    property var alarmModel: []

    function _rebuildAlarmModel() {
        const sorted = AlarmService.alarms.slice().sort((a, b) => a.time.localeCompare(b.time));
        const key = sorted.map(a => a.id + ":" + a.time).join("|");
        if (key !== root._alarmModelKey) {
            root._alarmModelKey = key;
            root.alarmModel = sorted;
        }
    }

    Connections {
        target: AlarmService
        function onAlarmsChanged() { root._rebuildAlarmModel() }
    }

    // AlarmView lives inside a Loader (recreated on every tab switch) —
    // alarms may already be loaded, so seed the model on creation too
    Component.onCompleted: root._rebuildAlarmModel()

    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.nowDate = new Date()
    }

    // Next datetime this alarm will ring (null if none within 8 days).
    // Skips occurrences already dismissed via the lastFiredKey guard.
    function nextRingDate(alarm, from) {
        const now = from || new Date();
        const parts = String(alarm.time || "07:00").split(":").map(Number);
        for (let i = 0; i < 8; i++) {
            const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i, parts[0] || 0, parts[1] || 0);
            if (d <= now) continue;
            if (alarm.days && alarm.days.length > 0 && !alarm.days.includes((d.getDay() + 6) % 7)) continue;
            const key = Qt.formatDate(d, "yyyy-MM-dd") + " " + Qt.formatTime(d, "HH:mm");
            if (alarm.lastFiredKey && alarm.lastFiredKey === key) continue;
            return d;
        }
        return null;
    }

    function dayLabelFor(date) {
        const now = new Date();
        const sameDay = (a, b) => a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
        if (sameDay(date, now)) return I18nService.tr("Today");
        const tom = new Date(now); tom.setDate(tom.getDate() + 1);
        if (sameDay(date, tom)) return I18nService.tr("Tomorrow");
        return I18nService.tr(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()]);
    }

    // Dismiss: skip the next occurrence (repeating) or disable (one-shot),
    // then confirm via snackbar with Undo — like the Android Clock app.
    function dismissOccurrence(alarm) {
        const prev = { enabled: alarm.enabled, lastFiredKey: alarm.lastFiredKey || "" };
        const nr = root.nextRingDate(alarm, new Date());
        if (!alarm.days || alarm.days.length === 0) {
            AlarmService.updateAlarm(alarm.id, { enabled: false });
        } else if (nr !== null) {
            const key = Qt.formatDate(nr, "yyyy-MM-dd") + " " + Qt.formatTime(nr, "HH:mm");
            AlarmService.updateAlarm(alarm.id, { lastFiredKey: key });
        }
        const when = nr !== null ? root.dayLabelFor(nr) + ", " + root.formatAlarmTime(Qt.formatTime(nr, "HH:mm")) : "";
        SnackbarService.show(
            I18nService.tr("Alarm dismissed for") + " " + when,
            I18nService.tr("Undo"),
            () => AlarmService.updateAlarm(alarm.id, prev),
            SnackbarService.undoDuration
        );
    }

    function formatAlarmTime(t) {
        const parts = root.formatTimeParts(t);
        return parts.suffix !== "" ? parts.main + " " + parts.suffix : parts.main;
    }

    function formatTimeParts(t) {
        const style = (Config.ready && Config.options.time) ? Config.options.time.timeStyle : "24H";
        const parts = String(t || "07:00").split(":").map(Number);
        const mins = String(parts[1] || 0).padStart(2, "0");
        if (style !== "12H_pm" && style !== "12H_PM")
            return { main: String(parts[0] || 0).padStart(2, "0") + ":" + mins, suffix: "" };
        const upper = style === "12H_PM";
        const ap = parts[0] >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am");
        const h12 = parts[0] % 12 === 0 ? 12 : parts[0] % 12;
        return { main: String(h12).padStart(2, "0") + ":" + mins, suffix: ap };
    }

    function daysSummary(days) {
        if (!days || days.length === 0) return I18nService.tr("Once");
        if (days.length === 7) return I18nService.tr("Every day");
        const sorted = [...days].sort((a, b) => a - b);
        if (sorted.join(",") === "0,1,2,3,4") return I18nService.tr("Weekdays");
        if (sorted.join(",") === "5,6") return I18nService.tr("Weekend");
        const rotated = [...sorted].sort((a, b) => ((a - root.weekStartMon + 7) % 7) - ((b - root.weekStartMon + 7) % 7));
        return rotated.map(d => root.dayLetters[d]).join(" ");
    }

    // ── Add flow: FAB → TimePicker → active one-shot alarm (like Android) ──
    function openNewAlarm() {
        const now = new Date();
        const defaultTime = String(now.getHours()).padStart(2, "0") + ":" + String(now.getMinutes()).padStart(2, "0");
        const is24h = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false;
        GlobalStates.openTimePicker(defaultTime, function(timeStr) {
            AlarmService.addAlarm({
                id: Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
                label: "",
                time: timeStr,
                enabled: true,
                days: [],
                lastFiredKey: ""
            });
        }, function() {}, is24h);
    }

    function openSettings(alarm) {
        root.settingsAlarm = alarm;
        DialogService.requestCustom(alarmSettingsContent, 400);
    }

    // Standalone time picker (no editor dialog) — quick time adjustment
    function openTimePickerFor(alarm) {
        const is24h = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false;
        GlobalStates.openTimePicker(alarm.time, function(timeStr) {
            AlarmService.updateAlarm(alarm.id, { time: timeStr });
        }, function() {}, is24h);
    }

    // ── Settings dialog content (Android-style alarm options) ──
    Component {
        id: alarmSettingsContent

        Item {
            id: settingsRoot
            implicitHeight: settingsCol.implicitHeight

            // ESC closes the nested picker first, then the dialog
            function handleEscape() {
                if (settingsCol.pickingTime) settingsCol.pickingTime = false;
                else DialogService.cancel();
            }
            Component.onCompleted: DialogService.escapeHandler = settingsRoot.handleEscape
            Component.onDestruction: if (DialogService.escapeHandler === settingsRoot.handleEscape) DialogService.escapeHandler = null

            ColumnLayout {
                id: settingsCol
                anchors.fill: parent

                readonly property var alarm: root.settingsAlarm
                property bool pickingTime: false
                property string editTime: alarm ? alarm.time : "07:00"
                property string editLabel: alarm ? (alarm.label || "") : ""
                property var editDays: alarm && alarm.days ? [...alarm.days] : []
                readonly property var timeParts: root.formatTimeParts(editTime)
                // Preset pill derived from editDays — empty = once, so
                // unchecking all day chips falls back to once automatically
                readonly property string activePreset: {
                    if (!editDays || editDays.length === 0) return "once";
                    const s = [...editDays].sort((a, b) => a - b).join(",");
                    if (s === "0,1,2,3,4,5,6") return "everyday";
                    if (s === "0,1,2,3,4") return "weekdays";
                    if (s === "5,6") return "weekend";
                    return "";
                }

                function applyPreset(preset) {
                    if (preset === "once") settingsCol.editDays = [];
                    else if (preset === "weekdays") settingsCol.editDays = [0, 1, 2, 3, 4];
                    else if (preset === "weekend") settingsCol.editDays = [5, 6];
                    else if (preset === "everyday") settingsCol.editDays = [0, 1, 2, 3, 4, 5, 6];
                }

                function saveSettings() {
                    if (!alarm) return;
                    AlarmService.updateAlarm(alarm.id, {
                        time: settingsCol.editTime,
                        label: settingsCol.editLabel.trim(),
                        days: [...settingsCol.editDays].sort((a, b) => a - b)
                    });
                    DialogService.submit();
                }

                function deleteAlarm() {
                    if (!alarm) return;
                    const idx = AlarmService.alarms.findIndex(a => a.id === alarm.id);
                    if (idx === -1) return;
                    const removed = AlarmService.alarms[idx];
                    AlarmService.deleteAlarm(alarm.id);
                    DialogService.cancel();
                    SnackbarService.show(
                        I18nService.tr("Alarm deleted"),
                        I18nService.tr("Undo"),
                        () => {
                            const arr = AlarmService.alarms.slice();
                            arr.splice(Math.min(idx, arr.length), 0, removed);
                            AlarmService.alarms = arr;
                            AlarmService.save();
                        },
                        SnackbarService.undoDuration
                    );
                }

                function openTimeEdit() {
                    settingsCol.pickingTime = true;
                }

            // ── Time + Edit pill ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                Item {
                    id: timeBlock
                    implicitWidth: dlgTime.implicitWidth + (dlgAm.visible ? 4 * Appearance.effectiveScale + dlgAm.implicitWidth : 0)
                    implicitHeight: dlgTime.implicitHeight
                    Layout.fillWidth: true

                    StyledText {
                        id: dlgTime
                        anchors.left: parent.left
                        anchors.top: parent.top
                        text: settingsCol.timeParts.main
                        font.family: Appearance.font.family.numbers
                        font.pixelSize: 44 * Appearance.effectiveScale
                        font.weight: Font.DemiBold
                        font.features: { "tnum": 1 }
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        id: dlgAm
                        visible: settingsCol.timeParts.suffix !== ""
                        anchors.left: dlgTime.right
                        anchors.leftMargin: 4 * Appearance.effectiveScale
                        anchors.baseline: dlgTime.baseline
                        text: settingsCol.timeParts.suffix
                        font.pixelSize: 16 * Appearance.effectiveScale
                        font.weight: Font.Medium
                        color: Appearance.colors.colSubtext
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: settingsCol.openTimeEdit()
                    }
                }

                RippleButton {
                    implicitWidth: editText.implicitWidth + (48 * Appearance.effectiveScale)
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3secondaryContainer
                    colRipple: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSecondaryContainer, 0.12)
                    onClicked: settingsCol.openTimeEdit()

                    StyledText {
                        id: editText
                        anchors.centerIn: parent
                        text: I18nService.tr("Edit")
                        font.pixelSize: 14 * Appearance.effectiveScale
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            Item { Layout.preferredHeight: 12 * Appearance.effectiveScale }

            // ── Repeat preset pills (same chip style as day list) ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { key: "once", labelKey: "Once" },
                        { key: "weekdays", labelKey: "Weekdays" },
                        { key: "weekend", labelKey: "Weekend" },
                        { key: "everyday", labelKey: "Every day" }
                    ]

                    delegate: RippleButton {
                        id: presetPill
                        required property var modelData
                        readonly property bool selected: settingsCol.activePreset === presetPill.modelData.key
                        implicitWidth: presetText.implicitWidth + (32 * Appearance.effectiveScale)
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: selected ? root.calAccent : Appearance.m3colors.m3surfaceContainerHighest

                        onClicked: settingsCol.applyPreset(presetPill.modelData.key)

                        StyledText {
                            id: presetText
                            anchors.centerIn: parent
                            text: I18nService.tr(presetPill.modelData.labelKey)
                            font.pixelSize: 13 * Appearance.effectiveScale
                            color: presetPill.selected ? root.calOnAccent : Appearance.colors.colSubtext
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 * Appearance.effectiveScale }

            // ── Repeat day chips ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6 * Appearance.effectiveScale

                Repeater {
                    model: 7

                    delegate: RippleButton {
                        id: dayChip
                        required property int index
                        readonly property int dayValue: (root.weekStartMon + dayChip.index) % 7
                        readonly property bool selected: settingsCol.editDays.includes(dayChip.dayValue)
                        // 44×44 (1:1); selected = circle, unselected = rounded square
                        implicitWidth: 44 * Appearance.effectiveScale
                        implicitHeight: 44 * Appearance.effectiveScale
                        buttonRadius: dayChip.selected ? 22 * Appearance.effectiveScale : 12 * Appearance.effectiveScale
                        colBackground: selected ? root.calAccent : Appearance.m3colors.m3surfaceContainerHighest

                        onClicked: {
                            if (selected) settingsCol.editDays = settingsCol.editDays.filter(d => d !== dayChip.dayValue);
                            else settingsCol.editDays = [...settingsCol.editDays, dayChip.dayValue];
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: root.dayLetters[dayChip.dayValue]
                            font.pixelSize: 13 * Appearance.effectiveScale
                            font.weight: dayChip.selected ? Font.DemiBold : Font.Normal
                            color: dayChip.selected ? root.calOnAccent : Appearance.colors.colSubtext
                        }
                        StyledToolTip { text: I18nService.tr(root.dayNames[dayChip.dayValue]); extraVisibleCondition: dayChip.realHovered }
                    }
                }
            }

            Item { Layout.preferredHeight: 12 * Appearance.effectiveScale }

            // ── Alarm name (aligned with the Delete/Save text buttons: 24 = 2×12 side padding) ──
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12 * Appearance.effectiveScale
                Layout.rightMargin: 12 * Appearance.effectiveScale
                implicitHeight: 48 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "label"
                    iconSize: 22 * Appearance.effectiveScale
                    color: Appearance.colors.colSubtext
                }
                StyledTextInput {
                    Layout.fillWidth: true
                    implicitHeight: 48 * Appearance.effectiveScale
                    backgroundColor: "transparent"
                    showActiveBorder: false
                    leftMargin: 0
                    rightMargin: 0
                    placeholder: I18nService.tr("Alarm name")
                    text: settingsCol.editLabel
                    font.pixelSize: Appearance.font.pixelSize.normal
                    onTextChanged: settingsCol.editLabel = text
                }
            }

            // ── Divider-ish spacing then actions ──
            Item { Layout.preferredHeight: 8 * Appearance.effectiveScale }

            // ── Footer buttons (DashTodo dialog style: text buttons, Delete left) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                RippleButton {
                    implicitWidth: deleteText.implicitWidth + (24 * Appearance.effectiveScale)
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Functions.ColorUtils.applyAlpha(root.calAccent, 0.08)
                    onClicked: settingsCol.deleteAlarm()

                    StyledText {
                        id: deleteText
                        anchors.centerIn: parent
                            text: I18nService.tr("Delete")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: root.calAccent
                    }
                }

                Item { Layout.fillWidth: true }

                RippleButton {
                    implicitWidth: cancelText.implicitWidth + (24 * Appearance.effectiveScale)
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Functions.ColorUtils.applyAlpha(root.calAccent, 0.08)
                    onClicked: DialogService.cancel()

                    StyledText {
                        id: cancelText
                        anchors.centerIn: parent
                            text: I18nService.tr("Cancel")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: root.calAccent
                    }
                }

                RippleButton {
                    implicitWidth: saveText.implicitWidth + (24 * Appearance.effectiveScale)
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Functions.ColorUtils.applyAlpha(root.calAccent, 0.08)
                    onClicked: settingsCol.saveSettings()

                    StyledText {
                        id: saveText
                        anchors.centerIn: parent
                            text: I18nService.tr("Save")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: root.calAccent
                    }
                }
            }
            }

            // ── Nested time picker overlay — reparented to the window root so
            //    the backdrop covers the whole screen, like TimePickerPanel ──
            Rectangle {
                id: pickerScrim
                z: 90 // explicit: completion order of siblings is not guaranteed
                visible: settingsCol.pickingTime
                color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.6)

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true // consume hover so nothing below (tooltips) reacts
                    onClicked: settingsCol.pickingTime = false
                }

                Component.onCompleted: {
                    let r = settingsRoot;
                    while (r.parent) r = r.parent;
                    pickerScrim.parent = r;
                    pickerScrim.anchors.fill = r;
                }
            }

            TimePicker {
                id: nestedPicker
                z: 100 // always above the scrim
                visible: settingsCol.pickingTime
                anchors.centerIn: parent
                currentTimeStr: settingsCol.editTime
                is24Hour: Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : false

                onTimeSelected: (timeStr) => {
                    settingsCol.editTime = timeStr;
                    settingsCol.pickingTime = false;
                }
                onCancelled: settingsCol.pickingTime = false

                Component.onCompleted: {
                    let r = settingsRoot;
                    while (r.parent) r = r.parent;
                    nestedPicker.parent = r;
                }
            }
        }
    }

    // ══════════════════════════════════════════════════
    //  LIST PAGE
    // ══════════════════════════════════════════════════
    Item {
        anchors.fill: parent

        // Empty state
        ColumnLayout {
            visible: AlarmService.alarms.length === 0
            anchors.centerIn: parent
            spacing: 8 * Appearance.effectiveScale

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "access_alarms"
                iconSize: 40 * Appearance.effectiveScale
                color: Appearance.colors.colSubtext
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: I18nService.tr("No alarms")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // Alarm cards
        Flickable {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            contentHeight: cardsCol.implicitHeight
            bottomMargin: 88 * Appearance.effectiveScale
            clip: true
            visible: AlarmService.alarms.length > 0

            ScrollBar.vertical: StyledScrollBar {}

            ColumnLayout {
                id: cardsCol
                width: parent.width
                spacing: 4 * Appearance.effectiveScale

                Repeater {
                    model: root.alarmModel

                    delegate: Rectangle {
                        id: alarmCard
                        required property var modelData
                        // Live lookup — survives array replacements so animations play
                        readonly property var alarm: AlarmService.alarms.find(a => a.id === modelData.id) || modelData
                        readonly property bool isEnabled: alarm.enabled
                        readonly property bool isRinging: AlarmService.ringing && AlarmService._pendingAlarm !== null && AlarmService._pendingAlarm.id === alarm.id
                        readonly property var timeParts: root.formatTimeParts(alarm.time)
                        readonly property var nextRing: root.nextRingDate(alarm, root.nowDate)
                        // One-shot alarms get no Dismiss — the notification
                        // action handles them (dismiss = turn off)
                        readonly property bool dismissible: isEnabled && alarm.days && alarm.days.length > 0
                            && nextRing !== null
                            && (nextRing.getTime() - root.nowDate.getTime()) <= 7200000
                        Layout.fillWidth: true
                        // 24 top + summary + 2 gap + time + 24 bottom — content-driven
                        implicitHeight: (24 + 2 + 24) * Appearance.effectiveScale
                            + summaryLabel.implicitHeight + timeText.implicitHeight
                        radius: Appearance.rounding.large
                        color: isEnabled ? root.calContainer : Appearance.m3colors.m3surfaceContainerHigh
                        border.width: alarmCard.isRinging ? 2 : 0
                        border.color: root.calAccent
                        Behavior on color { ColorAnimation { duration: 200 } }

                        // Row click target (below interactive children)
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openSettings(alarmCard.alarm)
                        }

                        // ── Top-left: summary ──
                        StyledText {
                            id: summaryLabel
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: 24 * Appearance.effectiveScale
                            anchors.leftMargin: 24 * Appearance.effectiveScale
                            anchors.rightMargin: (alarmCard.dismissible ? 120 : 24) * Appearance.effectiveScale
                            text: {
                                const base = alarmCard.isEnabled ? root.daysSummary(alarmCard.alarm.days) : I18nService.tr("Not scheduled");
                                const lbl = (alarmCard.alarm.label || "").trim();
                                return lbl !== "" ? base + " • " + lbl : base;
                            }
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: alarmCard.isEnabled ? root.calOnContainer : Appearance.colors.colSubtext
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        // ── Top-right: Dismiss (only when ringing within 2h) ──
                        RippleButton {
                            visible: alarmCard.dismissible
                            anchors.right: parent.right
                            anchors.verticalCenter: summaryLabel.verticalCenter
                            anchors.rightMargin: 16 * Appearance.effectiveScale
                            implicitHeight: 30 * Appearance.effectiveScale
                            implicitWidth: dismissText.implicitWidth + (24 * Appearance.effectiveScale)
                            buttonRadius: 15 * Appearance.effectiveScale
                            colBackground: "transparent"
                            colRipple: Functions.ColorUtils.applyAlpha(root.calOnContainer, 0.12)
                            onClicked: root.dismissOccurrence(alarmCard.alarm)

                            StyledText {
                                id: dismissText
                                anchors.centerIn: parent
                                text: I18nService.tr("Dismiss")
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: alarmCard.isEnabled ? root.calOnContainer : Appearance.colors.colSubtext
                            }
                            StyledToolTip { text: I18nService.tr("Skip next occurrence"); extraVisibleCondition: parent.realHovered }
                        }

                        // ── Bottom-left: time + AM/PM (baseline-aligned) ──
                        StyledText {
                            id: timeText
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 24 * Appearance.effectiveScale
                            // Compensate font descent so digit bottoms align with the toggle
                            anchors.bottomMargin: 12 * Appearance.effectiveScale
                            text: alarmCard.timeParts.main
                            font.family: Appearance.font.family.numbers
                            font.pixelSize: 44 * Appearance.effectiveScale
                            font.weight: Font.DemiBold
                            font.features: { "tnum": 1 }
                            color: alarmCard.isEnabled ? root.calOnContainer : Appearance.colors.colSubtext
                        }
                        StyledText {
                            visible: alarmCard.timeParts.suffix !== ""
                            anchors.left: timeText.right
                            anchors.leftMargin: 4 * Appearance.effectiveScale
                            anchors.baseline: timeText.baseline
                            text: alarmCard.timeParts.suffix
                            font.pixelSize: 14 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: alarmCard.isEnabled ? root.calOnContainer : Appearance.colors.colSubtext
                        }

                        // Time click target — standalone time picker, no editor dialog
                        MouseArea {
                            anchors.fill: timeText
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openTimePickerFor(alarmCard.alarm)
                        }

                        // ── Bottom-right: toggle, aligned with the time row ──
                        AndroidToggle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 20 * Appearance.effectiveScale
                            anchors.bottomMargin: 24 * Appearance.effectiveScale
                            checked: alarmCard.alarm.enabled
                            scaleMultiplier: 1.0 * Appearance.effectiveScale
                            onToggled: AlarmService.toggleAlarm(alarmCard.alarm.id)
                        }
                    }
                }
            }
        }

        // ── FAB (Android: add alarm → time picker) ──
        FloatingActionButton {
            anchors.fill: parent
            icon: "alarm_add"
            tooltipText: I18nService.tr("Add alarm")
            colBackground: Appearance.m3colors.m3tertiaryContainer
            colOnColor: Appearance.m3colors.m3onTertiaryContainer
            onClicked: root.openNewAlarm()
        }
    }
}
