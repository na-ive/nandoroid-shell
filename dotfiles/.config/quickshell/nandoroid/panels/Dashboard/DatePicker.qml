import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../widgets"
import "calendar_layout.js" as CalendarLayout

Item {
    id: root

    property int firstDayOfWeek: Config.ready ? (Config.options.time.firstDayOfWeek ?? 1) : 1
    property string currentDateStr: ""

    signal dateSelected(string dateStr)

    property int monthShift: 0
    property date viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0, firstDayOfWeek)

    function __formatDate(year, month, day) {
        return year + "-" + String(month).padStart(2, '0') + "-" + String(day).padStart(2, '0')
    }

    implicitWidth: pickerCol.implicitWidth + 16 * Appearance.effectiveScale
    implicitHeight: pickerCol.implicitHeight + 16 * Appearance.effectiveScale

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.visible = false
            event.accepted = true
        }
    }

    function __setViewingMonth() {
        if (root.currentDateStr) {
            const parts = root.currentDateStr.split('-').map(Number)
            const target = new Date(parts[0], parts[1] - 1, 1)
            const today = new Date()
            root.monthShift = (target.getFullYear() - today.getFullYear()) * 12
                + (target.getMonth() - today.getMonth())
        } else {
            root.monthShift = 0
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.__setViewingMonth()
            root.focus = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.normal
        border.color: Appearance.colors.colOutlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
    }

    ColumnLayout {
        id: pickerCol
        anchors.fill: parent
        anchors.margins: 8 * Appearance.effectiveScale
        spacing: 6 * Appearance.effectiveScale

        // ── Header: Month navigation | Year navigation ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            RippleButton {
                implicitWidth: 28 * Appearance.effectiveScale
                implicitHeight: 28 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.monthShift--
                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            RippleButton {
                implicitWidth: 28 * Appearance.effectiveScale
                implicitHeight: 28 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.monthShift++
                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }

            Item { width: 4 * Appearance.effectiveScale }

            RippleButton {
                implicitWidth: 28 * Appearance.effectiveScale
                implicitHeight: 28 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.monthShift -= 12
                contentItem: MaterialSymbol {
                    text: "chevron_left"
                    iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }

            StyledText {
                text: root.viewingDate.getFullYear().toString()
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            RippleButton {
                implicitWidth: 28 * Appearance.effectiveScale
                implicitHeight: 28 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.monthShift += 12
                contentItem: MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // ── Week day headers ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Appearance.sizes.calendarSpacing
            Repeater {
                model: {
                    const baseDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    const offset = (root.firstDayOfWeek + 6) % 7
                    let result = []
                    for (let i = 0; i < 7; i++)
                        result.push(baseDays[(i + offset) % 7])
                    return result
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

        // ── Day grid ──
        ColumnLayout {
            spacing: Appearance.sizes.calendarSpacing
            Repeater {
                model: 6
                delegate: RowLayout {
                    required property int index
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Appearance.sizes.calendarSpacing

                    Repeater {
                        model: 7
                        delegate: CalendarDayButton {
                            required property int index
                            readonly property var cell: root.calendarLayout[parent.index][index]
                            readonly property string dateStr: cell.today === -1 ? "" : root.__formatDate(
                                root.viewingDate.getFullYear(),
                                root.viewingDate.getMonth() + 1,
                                cell.day
                            )
                            readonly property bool isSelected: dateStr.length > 0 && dateStr === root.currentDateStr

                            day: cell.day.toString()
                            isToday: isSelected ? 1 : (cell.today === -1 ? -1 : 0)
                            bold: !isSelected && cell.today === 1

                            onClicked: {
                                if (cell.today === -1) return
                                root.currentDateStr = dateStr
                                root.dateSelected(dateStr)
                                root.visible = false
                            }
                        }
                    }
                }
            }
        }

        // ── Today button ──
        RowLayout {
            Layout.fillWidth: true
            RippleButton {
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 28 * Appearance.effectiveScale
                implicitWidth: 72 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: Appearance.colors.colLayer2
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    root.monthShift = 0
                    const today = new Date()
                    const ds = root.__formatDate(today.getFullYear(), today.getMonth() + 1, today.getDate())
                    root.currentDateStr = ds
                    root.dateSelected(ds)
                    root.visible = false
                }
                StyledText {
                    anchors.centerIn: parent
                    text: "Today"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }
        }
    }
}
