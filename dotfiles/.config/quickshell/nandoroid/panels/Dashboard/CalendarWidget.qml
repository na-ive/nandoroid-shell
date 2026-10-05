import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import "../../core/functions" as Functions
import "calendar_layout.js" as CalendarLayout

Item {
    id: root

    property int monthShift: 0
    // Compact mode: slimmer header, flat (non-button) weekday labels, grid fills the card
    property bool compact: false
    // Compact sizing (dashboard keeps its own natural size; DatePicker is unaffected)
    property real cellSize: Appearance.sizes.calendarCellSize
    property real cellSpacing: Appearance.sizes.calendarSpacing
    property real sectionSpacing: 12 * Appearance.effectiveScale
    // Full event objects for click popup
    property var scheduledEvents: []
    property var viewingDate: {
        const _ = DateTime.currentDate;
        return CalendarLayout.getDateInXMonthsTime(monthShift);
    }
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0, Config.ready ? (Config.options.time.firstDayOfWeek ?? 1) : 1)
    readonly property string currentDayShort: {
        const _ = DateTime.currentDate;
        const today = new Date();
        const todayJsDay = today.getDay();
        const daysShort = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
        return daysShort[todayJsDay];
    }

    function hasEvent(year, month, day) {
        if (day <= 0)
            return false;

        const mm = String(month).padStart(2, '0');
        const dd = String(day).padStart(2, '0');
        const dateStr = year + "-" + mm + "-" + dd;
        
        for (let i = 0; i < root.scheduledEvents.length; i++) {
            if (ScheduleService.eventOccursOn(root.scheduledEvents[i], dateStr)) {
                return true;
            }
        }
        return false;
    }

    // Get events for a specific date string (YYYY-MM-DD)
    function getEventsForDate(dateStr) {
        return root.scheduledEvents.filter(ev => ScheduleService.eventOccursOn(ev, dateStr));
    }

    // ── Localized date/time display (follows SysDateTime settings) ──
    function _parseDate(str) {
        if (!str)
            return null;

        const parts = String(str).trim().split(/[-/]/).map(Number);
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
        if (y < 1000 || y > 9999 || m < 1 || m > 12 || d < 1 || d > 31)
            return null;

        return {
            "y": y,
            "m": m,
            "d": d
        };
    }

    function _displayDate(dateStr) {
        const p = root._parseDate(dateStr);
        if (!p)
            return dateStr || "";

        return Qt.formatDate(new Date(p.y, p.m - 1, p.d), Config.ready ? Config.dateFormat : "ddd, dd/MM");
    }

    function _displayTime(timeStr) {
        if (!timeStr)
            return "";

        const parts = String(timeStr).split(":");
        if (parts.length < 2)
            return timeStr;

        const h = parseInt(parts[0], 10);
        const min = parseInt(parts[1], 10);
        if (isNaN(h) || isNaN(min))
            return timeStr;

        return Qt.formatTime(new Date(2000, 0, 1, h, min), Config.ready ? Config.timeFormat : "HH:mm");
    }

    function _recurrenceLabel(code) {
        switch (code) {
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

    function getMonthYearHeader(dateObj) {
        if (!dateObj)
            return "";

        const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        const m = dateObj.getMonth();
        const y = dateObj.getFullYear();
        return I18nService.tr(monthNames[m]) + " " + y;
    }

    function closePopup() {
        eventPopup.visible = false;
    }

    implicitWidth: calendarColumn.implicitWidth
    implicitHeight: calendarColumn.implicitHeight
    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown)
                monthShift++;
            else if (event.key === Qt.Key_PageUp)
                monthShift--;
            event.accepted = true;
        }
    }
    onVisibleChanged: {
        if (!visible)
            eventPopup.visible = false;

    }

    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                monthShift--;
            else if (event.angleDelta.y < 0)
                monthShift++;
        }
        // Dismiss popup when clicking outside the grid/buttons
        onClicked: closePopup()
    }

    Connections {
        function onDashboardOpenChanged() {
            if (!GlobalStates.dashboardOpen)
                eventPopup.visible = false;

        }

        function onCloseSubPopups() {
            closePopup();
        }

        target: GlobalStates
    }

    // ── Event click popup ──
    Rectangle {
        id: eventPopup

        property real _popX: 0
        property real _popY: 0
        property string dateStr: ""
        property var events: []

        visible: false
        z: 10
        clip: true
        radius: Appearance.rounding.normal
        color: Appearance.colors.colTooltip
        opacity: visible ? 1 : 0
        // Grow from zero like the tooltip, clipped to stay within CalendarWidget bounds
        width: visible ? Math.min(popupCol.implicitWidth + 20 * Appearance.effectiveScale, root.width * 0.7) : 0
        height: visible ? popupCol.implicitHeight + 20 * Appearance.effectiveScale : 0
        x: Math.min(Math.max(0, _popX), root.width - width)
        y: Math.min(Math.max(0, _popY), root.height - height)

        TapHandler {
            onTapped: (eventPoint) => {
                return eventPoint.accepted = true;
            }
        }

        ColumnLayout {
            id: popupCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10 * Appearance.effectiveScale
            spacing: 6 * Appearance.effectiveScale

            StyledText {
                Layout.fillWidth: true
                text: root._displayDate(eventPopup.dateStr)
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnTooltip
            }

            Repeater {
                model: eventPopup.events

                delegate: ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 2 * Appearance.effectiveScale

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6 * Appearance.effectiveScale

                        Rectangle {
                            width: 6 * Appearance.effectiveScale
                            height: 6 * Appearance.effectiveScale
                            radius: width / 2
                            color: Appearance.m3colors.m3onPrimary
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 6 * Appearance.effectiveScale
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.title
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnTooltip
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                    }

                    StyledText {
                        Layout.leftMargin: 12 * Appearance.effectiveScale
                        text: modelData.description || ""
                        visible: Boolean(modelData.description) && String(modelData.description).trim().length > 0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnTooltip, 0.75)
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    StyledText {
                        Layout.leftMargin: 12 * Appearance.effectiveScale
                        text: {
                            let t = root._displayTime(modelData.time);
                            if (modelData.endTime)
                                t += " - " + root._displayTime(modelData.endTime);

                            if (modelData.endDate && modelData.endDate !== modelData.date)
                                t += " · " + I18nService.tr("End ") + root._displayDate(modelData.endDate);

                            if (modelData.recurrence !== "once")
                                t += " · " + root._recurrenceLabel(modelData.recurrence);

                            return t;
                        }
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnTooltip, 0.75)
                    }

                }

            }

            StyledText {
                visible: eventPopup.events.length === 0
                text: I18nService.tr("No events")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnTooltip, 0.75)
                Layout.fillWidth: true
            }

        }

        // Grow + fade like the tooltip
        Behavior on width {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on height {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Behavior on visible {
        }

    }

    ColumnLayout {
        id: calendarColumn

        anchors.fill: parent
        spacing: root.sectionSpacing

        // Header (Month/Year + Nav) — ii-style: pill title + circle chevrons
        RowLayout {
            id: headerRow

            Layout.fillWidth: true
            spacing: 5 * Appearance.effectiveScale

            CalendarHeaderButton {
                compact: root.compact
                buttonText: (root.monthShift !== 0 ? "• " : "") + root.getMonthYearHeader(root.viewingDate)
                tooltipText: (root.monthShift === 0) ? "" : I18nService.tr("Jump to current month")
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    root.monthShift = 0;
                    eventPopup.visible = false;
                }
            }

            Item {
                Layout.fillWidth: true
            }

            CalendarHeaderButton {
                forceCircle: true
                compact: root.compact
                colBackground: "transparent"
                onClicked: {
                    root.monthShift--;
                    eventPopup.visible = false;
                }

                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: root.compact ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.huge
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }

            }

            CalendarHeaderButton {
                forceCircle: true
                compact: root.compact
                colBackground: "transparent"
                onClicked: {
                    root.monthShift++;
                    eventPopup.visible = false;
                }

                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: root.compact ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.huge
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }

            }

        }

        // Week Days (flat text, no button/hover — aligned to grid columns)
        RowLayout {
            id: weekDaysRow

            Layout.alignment: Qt.AlignHCenter
            spacing: root.cellSpacing

            Repeater {
                id: buttonRepeater

                model: {
                    const baseDays = [I18nService.tr("Mo"), I18nService.tr("Tu"), I18nService.tr("We"), I18nService.tr("Th"), I18nService.tr("Fr"), I18nService.tr("Sa"), I18nService.tr("Su")];
                    const firstDay = Config.ready ? (Config.options.time.firstDayOfWeek ?? 1) : 1;
                    const offset = (firstDay + 6) % 7;
                    let result = [];
                    for (let i = 0; i < 7; i++) {
                        result.push(baseDays[(i + offset) % 7]);
                    }
                    return result;
                }

                delegate: StyledText {
                    required property string modelData

                    text: modelData
                    Layout.preferredWidth: root.cellSize
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: root.compact ? Appearance.font.pixelSize.smaller : Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }

            }

        }

        // Grid — always 6 rows (ii-style): trailing weeks show next-month days faded
        ColumnLayout {
            id: gridColumn

            Layout.fillWidth: true
            spacing: root.cellSpacing

            Repeater {
                id: calendarRows

                model: 6

                delegate: RowLayout {
                    required property int index
                    readonly property int weekIndex: index

                    Layout.alignment: Qt.AlignHCenter
                    spacing: root.cellSpacing

                    Repeater {
                        // greyed out

                        model: 7

                        delegate: CalendarDayButton {
                            required property int index
                            readonly property var cell: root.calendarLayout[weekIndex][index]

                            cellSize: root.cellSize
                            day: cell.day.toString()
                            isToday: cell.today
                            hasEvent: {
                                if (cell.today === -1)
                                    return false;

                                const m = root.viewingDate.getMonth() + 1;
                                const y = root.viewingDate.getFullYear();
                                return root.hasEvent(y, m, cell.day);
                            }
                            onClicked: {
                                if (cell.today === -1) {
                                    closePopup();
                                    return ;
                                }
                                const m = root.viewingDate.getMonth() + 1;
                                const y = root.viewingDate.getFullYear();
                                const mm = String(m).padStart(2, '0');
                                const dd = String(cell.day).padStart(2, '0');
                                const dateStr = y + "-" + mm + "-" + dd;
                                if (!root.hasEvent(y, m, cell.day)) {
                                    closePopup();
                                    return ;
                                }
                                const wasOpenForThisDate = eventPopup.visible && eventPopup.dateStr === dateStr;
                                closePopup();
                                if (!wasOpenForThisDate) {
                                    eventPopup.dateStr = dateStr;
                                    eventPopup.events = root.getEventsForDate(dateStr);
                                    eventPopup.visible = true;
                                    const pos = mapToItem(root, width / 2, height + 4 * Appearance.effectiveScale);
                                    eventPopup._popX = pos.x - eventPopup.width / 2;
                                    eventPopup._popY = pos.y;
                                }
                            }
                        }

                    }

                }

            }

        }

    }

}
