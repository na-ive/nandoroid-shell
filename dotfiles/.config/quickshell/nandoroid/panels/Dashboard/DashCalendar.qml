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
    spacing: 12

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

    // Build a flat list of all dates this event applies to (expand recurring)
    readonly property var eventDates: {
        let dates = []
        for (let ev of root.scheduledEvents) {
            if (!ev.date) continue
            dates.push(ev.date)
            if (ev.recurrence === "daily") {
                let d = new Date(ev.date); d.setDate(d.getDate() + 1)
                for (let i = 0; i < 60; i++) {
                    const s = d.toISOString().slice(0, 10)
                    dates.push(s); d.setDate(d.getDate() + 1)
                }
            } else if (ev.recurrence === "weekly") {
                let d = new Date(ev.date); d.setDate(d.getDate() + 7)
                for (let i = 0; i < 8; i++) {
                    const s = d.toISOString().slice(0, 10)
                    dates.push(s); d.setDate(d.getDate() + 7)
                }
            } else if (ev.recurrence === "monthly") {
                let d = new Date(ev.date)
                for (let i = 0; i < 12; i++) {
                    d.setMonth(d.getMonth() + 1)
                    dates.push(d.toISOString().slice(0, 10))
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
            width: Math.min(parent.width - 24, implicitWidth)
            height: parent.height - 24
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
            anchors.margins: 16
            spacing: 14

            // ── Circular Arc Timer ──
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: arcSize
                implicitHeight: arcSize
                readonly property int arcSize: Math.min(parent.width ?? 180, 180)

                // Background ring
                Canvas {
                    id: bgRing
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        const cx = width/2, cy = height/2
                        const r  = Math.min(cx, cy) - 10
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.strokeStyle = Appearance.m3colors.m3outlineVariant
                        ctx.lineWidth = 7
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
                        const r  = Math.min(cx, cy) - 10
                        const start = -Math.PI / 2
                        const end   = start + progress * Math.PI * 2
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, start, end)
                        ctx.strokeStyle = Appearance.m3colors.m3primary
                        ctx.lineWidth = 7
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
                        font.pixelSize: 32
                        font.weight: Font.Bold
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
                    anchors.rightMargin: 8; anchors.bottomMargin: 8
                    visible: PomodoroService.rotations > 0
                    width: 22; height: 22; radius: 11
                    color: Appearance.m3colors.m3secondaryContainer
                    StyledText {
                        anchors.centerIn: parent
                        text: PomodoroService.rotations
                        font.pixelSize: 10; font.weight: Font.Bold
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }

            // ── Mode selector ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                    model: [
                        { icon: "alarm", name: "Focus", mode: 0 },
                        { icon: "coffee", name: "Short", mode: 1 },
                        { icon: "self_improvement", name: "Long", mode: 2 }
                    ]
                    delegate: SegmentedButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        isHighlighted: PomodoroService.mode === modelData.mode
                        iconName: modelData.icon
                        iconSize: 18
                        spacing: 5
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
                spacing: 12

                M3IconButton {
                    iconName: "stop"
                    onClicked: PomodoroService.stop()
                    StyledToolTip { text: "Stop & Reset" }
                }

                RippleButton {
                    id: startPill
                    implicitWidth: 140; implicitHeight: 44; buttonRadius: 22
                    colBackground: Appearance.m3colors.m3primary
                    onClicked: PomodoroService.active ? PomodoroService.pause() : PomodoroService.start()
                    contentItem: RowLayout {
                        spacing: 8; Layout.alignment: Qt.AlignHCenter
                        MaterialSymbol {
                            text: PomodoroService.active ? "pause" : "play_arrow"
                            iconSize: 20; color: Appearance.m3colors.m3onPrimary
                        }
                        StyledText {
                            text: PomodoroService.active ? "Pause" : "Start"
                            font.pixelSize: 13; font.weight: Font.DemiBold
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
                spacing: 6

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
                        implicitWidth: 40; implicitHeight: 22; buttonRadius: 11
                        colBackground: PomodoroService.autoContinue
                            ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: PomodoroService.autoContinue = !PomodoroService.autoContinue
                        Rectangle {
                            x: PomodoroService.autoContinue ? parent.width - width - 3 : 3
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16; radius: 8
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
                        spacing: 4
                        Repeater {
                            model: [
                                { icon: "coffee", name: "Short", mode: 1 },
                                { icon: "self_improvement", name: "Long", mode: 2 }
                            ]
                            delegate: SegmentedButton {
                                implicitWidth: 72; implicitHeight: 24
                                isHighlighted: PomodoroService.nextBreakMode === modelData.mode
                                iconName: modelData.icon; buttonText: modelData.name; iconSize: 11
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
