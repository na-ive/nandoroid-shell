pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../core"
import "../widgets"
import "../panels/Dashboard/calendar_layout.js" as CalendarLayout

Item {
    id: root

    property int firstDayOfWeek: Config.ready ? (Config.options.time.firstDayOfWeek ?? 1) : 1
    property string currentDateStr: ""

    signal dateSelected(string dateStr)
    signal cancelled()

    property bool yearMode: false
    property int monthShift: 0

    property date viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0, firstDayOfWeek)
    property string pendingDateStr: root.currentDateStr

    readonly property real cellSize: 40 * Appearance.effectiveScale
    readonly property int yearRangeStart: new Date().getFullYear() - 49
    readonly property real __monthGridTotal: root.cellSize * 0.7 + Appearance.sizes.calendarSpacing + 6 * root.cellSize + 5 * Appearance.sizes.calendarSpacing
    implicitWidth: Math.max(300 * Appearance.effectiveScale,
        7 * root.cellSize + 6 * Appearance.sizes.calendarSpacing + 48 * Appearance.effectiveScale)
    implicitHeight: contentCol.implicitHeight

    Component.onCompleted: root.__setViewingMonth()

    function __formatDate(year, month, day) {
        return year + "-" + String(month).padStart(2, '0') + "-" + String(day).padStart(2, '0')
    }

    function __formatDisplay(dateStr) {
        if (!dateStr || dateStr.length < 10) return ""
        const parts = dateStr.split('-').map(Number)
        const d = new Date(parts[0], parts[1] - 1, parts[2])
        return Qt.formatDate(d, "MMM dd, yyyy")
    }

    function __setViewingMonth() {
        if (root.pendingDateStr) {
            const parts = root.pendingDateStr.split('-').map(Number)
            const target = new Date(parts[0], parts[1] - 1, 1)
            const today = new Date()
            root.monthShift = (target.getFullYear() - today.getFullYear()) * 12
                + (target.getMonth() - today.getMonth())
        } else {
            root.monthShift = 0
        }
    }

    MouseArea {
        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.card
        color: Appearance.m3colors.m3surfaceContainerHigh
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        spacing: 8 * Appearance.effectiveScale

        StyledText {
            text: "Select Date"
            Layout.leftMargin: 32 * Appearance.effectiveScale
            Layout.topMargin: 24 * Appearance.effectiveScale
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colSubtext
        }

        StyledText {
            text: root.__formatDisplay(root.pendingDateStr)
            Layout.leftMargin: 32 * Appearance.effectiveScale
            Layout.topMargin: 16 * Appearance.effectiveScale
            font.pixelSize: Math.round(32 * Appearance.effectiveScale)
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOutlineVariant
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24 * Appearance.effectiveScale
            Layout.rightMargin: 24 * Appearance.effectiveScale
            spacing: 4 * Appearance.effectiveScale

            RippleButton {
                implicitHeight: 32 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.yearMode = !root.yearMode
                contentItem: RowLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    MaterialSymbol {
                        text: "arrow_drop_down"
                        iconSize: 18 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"; colBackgroundHover: Appearance.colors.colLayer2Hover
                enabled: !root.yearMode
                onClicked: root.monthShift--
                contentItem: MaterialSymbol {
                    text: "chevron_left"; iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter; color: Appearance.colors.colOnLayer1
                }
            }
            RippleButton {
                implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"; colBackgroundHover: Appearance.colors.colLayer2Hover
                enabled: !root.yearMode
                onClicked: root.monthShift++
                contentItem: MaterialSymbol {
                    text: "chevron_right"; iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter; color: Appearance.colors.colOnLayer1
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24 * Appearance.effectiveScale
            Layout.rightMargin: 24 * Appearance.effectiveScale
            spacing: Appearance.sizes.calendarSpacing

            RowLayout {
                visible: !root.yearMode
                spacing: Appearance.sizes.calendarSpacing
                Repeater {
                    model: {
                        const baseDays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        const offset = (root.firstDayOfWeek + 6) % 7
                        let r = []
                        for (let i = 0; i < 7; i++) r.push(baseDays[(i + offset) % 7])
                        return r
                    }
                    delegate: Item {
                        required property string modelData
                        implicitWidth: root.cellSize; implicitHeight: root.cellSize * 0.7
                        StyledText {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            ColumnLayout {
                visible: !root.yearMode
                Layout.fillWidth: true
                spacing: Appearance.sizes.calendarSpacing

                Repeater {
                    model: 6
                    delegate: RowLayout {
                        required property int index
                        Layout.fillWidth: true
                        spacing: Appearance.sizes.calendarSpacing

                        Repeater {
                            model: 7
                            delegate: RippleButton {
                                required property int index
                                padding: 0
                                implicitWidth: root.cellSize; implicitHeight: root.cellSize
                                buttonRadius: implicitHeight / 2

                                readonly property int row: parent.index
                                readonly property var cell: root.calendarLayout[row][index]
                                readonly property string dateStr: cell.today === -1 ? "" :
                                    root.__formatDate(root.viewingDate.getFullYear(), root.viewingDate.getMonth() + 1, cell.day)
                                readonly property bool isCurrent: cell.today === 1
                                readonly property bool isPending: dateStr.length > 0 && dateStr === root.pendingDateStr
                                readonly property bool isSelected: dateStr.length > 0 && dateStr === root.currentDateStr

                                colBackground: isPending ? Appearance.colors.colPrimary : "transparent"
                                colBackgroundHover: isPending ? Appearance.colors.colPrimary : Appearance.colors.colLayer2Hover

                                onClicked: {
                                    if (cell.today === -1) return
                                    root.pendingDateStr = dateStr
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    border.width: 2 * Appearance.effectiveScale
                                    border.color: Appearance.colors.colPrimary
                                    color: "transparent"
                                    visible: isSelected && !isPending
                                }

                                contentItem: StyledText {
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    text: cell.day.toString()
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: isCurrent ? Font.DemiBold : Font.Normal
                                    color: isPending ? Appearance.m3colors.m3onPrimary
                                        : cell.today === -1 ? Appearance.colors.colOutlineVariant
                                        : Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }

            Item {
                visible: root.yearMode
                Layout.fillWidth: true
                implicitHeight: root.__monthGridTotal + 48 * Appearance.effectiveScale

                Flickable {
                    id: yearFlickable
                    anchors.fill: parent
                    contentHeight: yearFlow.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    onVisibleChanged: if (visible) {
                        const cy = new Date().getFullYear()
                        const row = Math.floor((cy - root.yearRangeStart) / 4)
                        const rowY = row * (root.cellSize + yearFlow.spacing)
                        contentY = Math.max(0, rowY - (height - root.cellSize) / 2)
                    }

                    Flow {
                        id: yearFlow
                        width: parent.width
                        spacing: 4 * Appearance.effectiveScale

                        Repeater {
                            model: 100

                            delegate: RippleButton {
                                required property int index
                                implicitWidth: (yearFlow.width - 3 * yearFlow.spacing) / 4
                                implicitHeight: root.cellSize
                                buttonRadius: implicitHeight / 2

                                readonly property int year: root.yearRangeStart + index
                                readonly property bool isCurrent: year === new Date().getFullYear()

                                colBackground: isCurrent ? Appearance.colors.colPrimary : "transparent"
                                colBackgroundHover: isCurrent ? Appearance.colors.colPrimary : Appearance.colors.colLayer2Hover

                                onClicked: {
                                    const target = new Date(year, root.viewingDate.getMonth(), 1)
                                    const today = new Date()
                                    root.monthShift = (target.getFullYear() - today.getFullYear()) * 12
                                        + (target.getMonth() - today.getMonth())
                                    root.yearMode = false
                                }

                                contentItem: StyledText {
                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                    text: year.toString()
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: isCurrent ? Font.DemiBold : Font.Normal
                                    color: isCurrent ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            Layout.rightMargin: 24 * Appearance.effectiveScale
            Layout.bottomMargin: 24 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"; colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.cancelled()
                contentItem: StyledText {
                    text: "Cancel"; font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium; color: Appearance.colors.colPrimary
                }
            }

            RippleButton {
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"; colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: {
                    if (root.pendingDateStr) {
                        root.currentDateStr = root.pendingDateStr
                        root.dateSelected(root.pendingDateStr)
                    }
                }
                contentItem: StyledText {
                    text: "OK"; font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium; color: Appearance.colors.colPrimary
                }
            }
        }
    }
}
