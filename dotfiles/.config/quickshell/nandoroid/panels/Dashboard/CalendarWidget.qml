import QtQuick
import QtQuick.Layouts
import "../../widgets"
import "../../core"
import "../../services"
import "calendar_layout.js" as CalendarLayout

Item {
    id: root
    property int monthShift: 0
    // List of date strings that have scheduled events, e.g. ["2026-03-08", "2026-03-15"]
    property var eventDates: []
    // Full event objects for click popup
    property var scheduledEvents: []
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0, Config.ready ? (Config.options.time.firstDayOfWeek ?? 1) : 1)

    // Build a Set of "YYYY-MM-DD" strings for O(1) lookup
    readonly property var eventDateSet: {
        let s = {}
        for (let d of root.eventDates) s[d] = true
        return s
    }

    function hasEvent(year, month, day) {
        if (day <= 0) return false
        const mm = String(month).padStart(2, '0')
        const dd = String(day).padStart(2, '0')
        return !!root.eventDateSet[year + "-" + mm + "-" + dd]
    }

    // Get events for a specific date string (YYYY-MM-DD)
    function getEventsForDate(dateStr) {
        return root.scheduledEvents.filter(ev => {
            if (!ev.date) return false
            if (ev.date === dateStr) return true
            // Check recurring
            if (ev.recurrence === "daily") return true
            if (ev.recurrence === "weekly") {
                const evDay = new Date(ev.date).getDay()
                const chkDay = new Date(dateStr).getDay()
                const evDate = new Date(ev.date)
                const chkDate = new Date(dateStr)
                return evDay === chkDay && chkDate >= evDate
            }
            if (ev.recurrence === "monthly") {
                const evD = new Date(ev.date)
                const chkD = new Date(dateStr)
                return evD.getDate() === chkD.getDate() && chkDate >= evDate
            }
            return false
        })
    }
    
    readonly property string currentDayShort: {
        const today = new Date();
        const todayJsDay = today.getDay();
        const daysShort = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];
        return daysShort[todayJsDay];
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

    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                monthShift--;
            else if (event.angleDelta.y < 0)
                monthShift++;
        }
        // Dismiss popup when clicking outside
        onClicked: eventPopup.visible = false
    }

    // ── Event click popup ──
    Rectangle {
        id: eventPopup
        visible: false
        z: 10
        width: 200
        height: popupCol.implicitHeight + 20
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerHigh
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1

        // Clip to stay within CalendarWidget bounds
        x: Math.min(Math.max(0, _popX), root.width - width)
        y: Math.min(Math.max(0, _popY), root.height - height)
        property real _popX: 0
        property real _popY: 0
        property string dateStr: ""
        property var events: []

        ColumnLayout {
            id: popupCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 6

            StyledText {
                Layout.fillWidth: true
                text: eventPopup.dateStr
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Bold
                color: Appearance.colors.colSubtext
            }

            Repeater {
                model: eventPopup.events
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }
                    ColumnLayout {
                        spacing: 0
                        StyledText {
                            text: modelData.title
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: modelData.description || ""
                            visible: Boolean(modelData.description) && String(modelData.description).trim().length > 0
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: {
                                let t = modelData.time
                                if (modelData.endTime) t += " - " + modelData.endTime
                                if (modelData.recurrence !== "once") t += " · " + modelData.recurrence
                                return t
                            }
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }

            StyledText {
                visible: eventPopup.events.length === 0
                text: "No events"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                Layout.fillWidth: true
            }
        }

        // Fade in/out
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on visible { }
    }

    ColumnLayout {
        id: calendarColumn
        anchors.fill: parent
        spacing: 12

        // Header (Month/Year + Nav)
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 8

            CalendarHeaderButton {
                clip: true
                buttonText: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                tooltipText: (root.monthShift === 0) ? "" : "Jump to current month"
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    root.monthShift = 0;
                }
            }

            Item {
                Layout.fillWidth: true
            }

            CalendarHeaderButton {
                forceCircle: true
                onClicked: {
                    root.monthShift--;
                }

                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.huge
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }

            CalendarHeaderButton {
                forceCircle: true
                onClicked: {
                    root.monthShift++;
                }

                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.huge
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // Week Days
        RowLayout {
            id: weekDaysRow
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.sizes.calendarSpacing

            Repeater {
                id: buttonRepeater
                model: {
                    const baseDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
                    const firstDay = Config.ready ? (Config.options.time.firstDayOfWeek ?? 1) : 1;
                    const offset = (firstDay + 6) % 7;
                    let result = [];
                    for (let i = 0; i < 7; i++) {
                        result.push(baseDays[(i + offset) % 7]);
                    }
                    return result;
                }
                delegate: CalendarDayButton {
                    required property string modelData
                    day: modelData
                    isToday: -1
                    isLabel: true
                    enabled: false
                }
            }
        }

        // Grid
        ColumnLayout {
            id: gridColumn
            Layout.fillWidth: true
            spacing: Appearance.sizes.calendarSpacing

            Repeater {
                id: calendarRows
                model: 6
                delegate: RowLayout {
                    required property int index
                    readonly property int weekIndex: index
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: false
                    spacing: Appearance.sizes.calendarSpacing

                    Repeater {
                        model: 7
                        delegate: CalendarDayButton {
                            required property int index
                            readonly property var cell: root.calendarLayout[weekIndex][index]
                            day: cell.day.toString()
                            isToday: cell.today
                            hasEvent: {
                                if (cell.today === -1) return false
                                const m = root.viewingDate.getMonth() + 1
                                const y = root.viewingDate.getFullYear()
                                return root.hasEvent(y, m, cell.day)
                            }

                            onClicked: {
                                if (cell.today === -1) return  // greyed out
                                const m = root.viewingDate.getMonth() + 1
                                const y = root.viewingDate.getFullYear()
                                const mm = String(m).padStart(2, '0')
                                const dd = String(cell.day).padStart(2, '0')
                                const dateStr = y + "-" + mm + "-" + dd
                                if (!root.hasEvent(y, m, cell.day)) {
                                    eventPopup.visible = false
                                    return
                                }
                                // mapToItem(root, x, y): map button's bottom-center
                                // from button-local coords → CalendarWidget root coords
                                const pos = mapToItem(root, width / 2, height + 4)
                                eventPopup._popX = pos.x - eventPopup.width / 2
                                eventPopup._popY = pos.y
                                eventPopup.dateStr = dateStr
                                eventPopup.events = root.getEventsForDate(dateStr)
                                eventPopup.visible = !eventPopup.visible
                            }


                        }
                    }
                }
            }
        }
    }
}
