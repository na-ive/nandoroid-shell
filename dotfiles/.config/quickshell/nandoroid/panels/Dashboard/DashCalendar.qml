import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

/**
 * Dashboard Tab 1: Calendar (left) + Pomodoro with arc ring (right)
 */
RowLayout {
    id: root
    spacing: 12 * Appearance.effectiveScale

    // Load schedule to mark days on the calendar
    property var scheduledEvents: []
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    function reloadSchedule() {
        scheduleFile.reload()
    }

    FileView {
        id: scheduleFile
        path: root.storagePath
        onLoaded: {
            try {
                let parsed = JSON.parse(scheduleFile.text())
                if (Array.isArray(parsed)) root.scheduledEvents = parsed
            } catch(e) {}
        }
    }

    Component.onCompleted: scheduleFile.reload()

    function _fmtDate(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, '0') + "-" + String(d.getDate()).padStart(2, '0')
    }

    // Build a flat list of all dates this event applies to (expand recurring)
    readonly property var eventDates: {
        let dates = []
        for (let ev of root.scheduledEvents) {
            if (!ev.date) continue

            // Once multi-day: every day from date to endDate
            if (ev.recurrence === "once" && ev.endDate) {
                let d = new Date(ev.date + "T00:00:00")
                const end = new Date(ev.endDate + "T00:00:00")
                for (; d <= end; d.setDate(d.getDate() + 1))
                    dates.push(root._fmtDate(d))
                continue
            }

            dates.push(ev.date)
            const limit = ev.endDate ? new Date(ev.endDate + "T00:00:00") : null

            if (ev.recurrence === "daily") {
                let d = new Date(ev.date); d.setDate(d.getDate() + 1)
                for (let i = 0; i < 60; i++) {
                    if (limit && d > limit) break
                    dates.push(root._fmtDate(d)); d.setDate(d.getDate() + 1)
                }
            } else if (ev.recurrence === "weekly") {
                let d = new Date(ev.date); d.setDate(d.getDate() + 7)
                for (let i = 0; i < 8; i++) {
                    if (limit && d > limit) break
                    dates.push(root._fmtDate(d)); d.setDate(d.getDate() + 7)
                }
            } else if (ev.recurrence === "monthly") {
                let d = new Date(ev.date)
                for (let i = 0; i < 12; i++) {
                    d.setMonth(d.getMonth() + 1)
                    if (limit && d > limit) break
                    dates.push(root._fmtDate(d))
                }
            }
        }
        return dates
    }

    // ── Calendar ──
    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.normal

        CalendarWidget {
            anchors.centerIn: parent
            width: Math.min(parent.width - 24 * Appearance.effectiveScale, implicitWidth)
            height: parent.height - 24 * Appearance.effectiveScale
            eventDates: root.eventDates
            scheduledEvents: root.scheduledEvents
        }
    }

    // ── Pomodoro with circle ring ──
    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        color: Appearance.m3colors.m3surfaceContainer
        radius: Appearance.rounding.normal
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 14 * Appearance.effectiveScale

            // ── Circular Arc Timer ──
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: arcSize
                implicitHeight: arcSize
                readonly property int arcSize: Math.min(parent.width ?? 180 * Appearance.effectiveScale, 180 * Appearance.effectiveScale)

                // Background ring
                Canvas {
                    id: bgRing
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        const cx = width/2, cy = height/2
                        const r  = Math.min(cx, cy) - 10 * Appearance.effectiveScale
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.strokeStyle = Appearance.m3colors.m3outlineVariant
                        ctx.lineWidth = 7 * Appearance.effectiveScale
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                    Connections {
                        target: Appearance
                        function onM3colorsChanged() { bgRing.requestPaint() }
                    }
                }

                // Progress arc
                Canvas {
                    id: arcCanvas
                    anchors.fill: parent
                    readonly property real progress: PomodoroService.progress

                    onProgressChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        if (progress <= 0) return
                        const cx = width/2, cy = height/2
                        const r  = Math.min(cx, cy) - 10 * Appearance.effectiveScale
                        const start = -Math.PI / 2
                        const end   = start + progress * Math.PI * 2
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, start, end)
                        ctx.strokeStyle = Appearance.m3colors.m3primary
                        ctx.lineWidth = 7 * Appearance.effectiveScale
                        ctx.lineCap = "round"
                        ctx.stroke()
                    }
                    Connections {
                        target: Appearance
                        function onM3colorsChanged() { arcCanvas.requestPaint() }
                    }
                }

                // Centre text
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: PomodoroService.timeString
                        font.pixelSize: Math.round(32 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: PomodoroService.modeName
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                // Cycle badge
                Rectangle {
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.rightMargin: 8 * Appearance.effectiveScale; anchors.bottomMargin: 8 * Appearance.effectiveScale
                    visible: PomodoroService.rotations > 0
                    width: 22 * Appearance.effectiveScale; height: 22 * Appearance.effectiveScale; radius: 11 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3secondaryContainer
                    StyledText {
                        anchors.centerIn: parent
                        text: PomodoroService.rotations
                        font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            // ── Mode selector ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                Repeater {
                    model: [
                        { icon: "alarm", name: "Focus", mode: 0 },
                        { icon: "coffee", name: "Short", mode: 1 },
                        { icon: "self_improvement", name: "Long", mode: 2 }
                    ]
                    delegate: SegmentedButton {
                        Layout.fillWidth: true
                        implicitHeight: 32 * Appearance.effectiveScale
                        isHighlighted: PomodoroService.mode === modelData.mode
                        iconName: modelData.icon
                        iconSize: 18 * Appearance.effectiveScale
                        spacing: 5 * Appearance.effectiveScale
                        buttonText: modelData.name
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: PomodoroService.setMode(modelData.mode)
                        StyledToolTip { text: modelData.name }
                    }
                }
            }

            // ── Controls ──
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12 * Appearance.effectiveScale

                M3IconButton {
                    iconName: "stop"
                    onClicked: PomodoroService.stop()
                    StyledToolTip { text: "Stop & Reset" }
                }

                RippleButton {
                    id: startPill
                    implicitWidth: 140 * Appearance.effectiveScale; implicitHeight: 44 * Appearance.effectiveScale; buttonRadius: 22 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3primary
                    onClicked: PomodoroService.active ? PomodoroService.pause() : PomodoroService.start()
                    contentItem: RowLayout {
                        spacing: 8 * Appearance.effectiveScale; Layout.alignment: Qt.AlignHCenter
                        MaterialSymbol {
                            text: PomodoroService.active ? "pause" : "play_arrow"
                            iconSize: 20 * Appearance.effectiveScale; color: Appearance.m3colors.m3onPrimary
                        }
                        StyledText {
                            text: PomodoroService.active ? "Pause" : "Start"
                            font.pixelSize: Appearance.font.pixelSize.small; font.weight: Font.DemiBold
                            color: Appearance.m3colors.m3onPrimary
                        }
                    }
                }

                M3IconButton {
                    iconName: "refresh"
                    onClicked: { PomodoroService.reset(); PomodoroService.rotations = 0 }
                    StyledToolTip { text: "Reset Everything" }
                }
            }

            // ── Auto-continue toggle + next-break selector ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * Appearance.effectiveScale

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        Layout.fillWidth: true
                        text: "Auto-continue"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        verticalAlignment: Text.AlignVCenter
                    }
                    RippleButton {
                        implicitWidth: 40 * Appearance.effectiveScale; implicitHeight: 22 * Appearance.effectiveScale; buttonRadius: 11 * Appearance.effectiveScale
                        colBackground: PomodoroService.autoContinue
                            ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: PomodoroService.autoContinue = !PomodoroService.autoContinue
                        Rectangle {
                            x: PomodoroService.autoContinue ? parent.width - width - 3 * Appearance.effectiveScale : 3 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16 * Appearance.effectiveScale; height: 16 * Appearance.effectiveScale; radius: 8 * Appearance.effectiveScale
                            color: PomodoroService.autoContinue
                                ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 180 } }
                        }
                    }
                }

                // Next break selector (shown when auto-continue is on)
                RowLayout {
                    Layout.fillWidth: true
                    visible: PomodoroService.autoContinue
                    StyledText {
                        Layout.fillWidth: true
                        text: "Next Break"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        verticalAlignment: Text.AlignVCenter
                    }
                    RowLayout {
                        spacing: 4 * Appearance.effectiveScale
                        Repeater {
                            model: [
                                { icon: "coffee", name: "Short", mode: 1 },
                                { icon: "self_improvement", name: "Long", mode: 2 }
                            ]
                            delegate: SegmentedButton {
                                implicitWidth: 72 * Appearance.effectiveScale; implicitHeight: 24 * Appearance.effectiveScale
                                isHighlighted: PomodoroService.nextBreakMode === modelData.mode
                                iconName: modelData.icon; buttonText: modelData.name; iconSize: 11 * Appearance.effectiveScale
                                colInactive: Appearance.m3colors.m3surfaceContainerHigh
                                colActive: Appearance.m3colors.m3secondary
                                colActiveText: Appearance.m3colors.m3onSecondary
                                onClicked: PomodoroService.nextBreakMode = modelData.mode
                            }
                        }
                    }
                }
            }
        }
    }
}
