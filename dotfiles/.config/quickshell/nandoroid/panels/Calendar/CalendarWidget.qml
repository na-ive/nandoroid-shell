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
    
    readonly property string currentDayShort: {
        const today = new Date();
        const todayJsDay = today.getDay(); // 0=Sun, 1=Mon...
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
                            // Check if this cell's actual calendar date has a scheduled event
                            hasEvent: {
                                if (cell.today === -1) return false  // greyed out (prev/next month)
                                const m = root.viewingDate.getMonth() + 1  // 1-based
                                const y = root.viewingDate.getFullYear()
                                return root.hasEvent(y, m, cell.day)
                            }
                        }
                    }
                }
            }
        }
    }
}
