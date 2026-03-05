import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab 2: Schedule / Calendar Maker
 * Local JSON storage, recurring events, desktop reminders via notify-send.
 */
Item {
    id: root

    // ── Persistence ──
    property var events: []
    property bool loaded: false

    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    FileView {
        id: scheduleFile
        path: root.storagePath
        watchChanges: false
        onLoaded: {
            try {
                let parsed = JSON.parse(scheduleFile.text())
                if (Array.isArray(parsed)) root.events = parsed
            } catch(e) {}
            root.loaded = true
        }
    }

    function save() {
        scheduleFile.setText(JSON.stringify(root.events, null, 2))
    }

    function makeId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 5)
    }

    function deleteEvent(id) {
        root.events = root.events.filter(e => e.id !== id)
        save()
        if (selectedId === id) { selectedId = ""; clearForm() }
    }

    Component.onCompleted: {
        scheduleFile.reload()
        reminderTimer.start()
    }

    // ── Reminder Timer (checks every 60s) ──
    Timer {
        id: reminderTimer
        interval: 60000
        repeat: true
        running: false
        onTriggered: root.checkReminders()
    }

    function checkReminders() {
        const now = new Date()
        const todayStr = Qt.formatDate(now, "yyyy-MM-dd")
        const timeStr  = Qt.formatTime(now, "HH:mm")
        let changed = false

        root.events.forEach((ev, i) => {
            // Determine effective date for today
            let matches = false
            if (ev.recurrence === "daily") {
                matches = ev.time === timeStr
            } else if (ev.recurrence === "weekly") {
                const evDay = new Date(ev.date).getDay()
                matches = now.getDay() === evDay && ev.time === timeStr
            } else if (ev.recurrence === "monthly") {
                const evDayOfMonth = new Date(ev.date).getDate()
                matches = now.getDate() === evDayOfMonth && ev.time === timeStr
            } else {
                matches = ev.date === todayStr && ev.time === timeStr
            }

            if (matches && ev.lastFired !== `${todayStr}T${timeStr}`) {
                notifyProc.command = ["notify-send", "-a", "Nandoroid", "-i", "calendar", ev.title, ev.date + " " + ev.time]
                notifyProc.running = true
                root.events[i] = Object.assign({}, ev, { lastFired: `${todayStr}T${timeStr}` })
                changed = true
            }
        })

        if (changed) { root.events = root.events.slice(); save() }
    }

    Process { id: notifyProc; running: false }

    // ── State ──
    property string selectedId: ""
    property string formTitle: ""
    property string formDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string formTime: "09:00"
    property string formRecurrence: "once" // once | daily | weekly | monthly

    property string formDescription: ""

    function clearForm() {
        formTitle = ""; formDate = Qt.formatDate(new Date(), "yyyy-MM-dd")
        formTime = "09:00"; formRecurrence = "once"; formDescription = ""
    }

    function saveEvent() {
        if (!formTitle.trim()) return
        const descVal = formDescription.trim() ? formDescription.trim() : undefined
        if (selectedId) {
            root.events = root.events.map(function(e) {
                if (e.id === selectedId) {
                    return Object.assign({}, e, { title: formTitle, date: formDate, time: formTime, recurrence: formRecurrence, description: descVal })
                }
                return e
            })
        } else {
            const newEv = { id: makeId(), title: formTitle, date: formDate, time: formTime, recurrence: formRecurrence, description: descVal, lastFired: "" }
            root.events = root.events.concat([newEv])
        }
        save()
        selectedId = ""
        clearForm()
    }

    // ── Layout ──
    Row {
        id: schedRow
        anchors.fill: parent
        spacing: 12

        // ── Event List (fixed width) ──
        Item {
            id: schedSidebar
            width: 210
            height: parent.height

            // List (full height - “+ New Event” card is now first item in the list)
            Rectangle {
                anchors.fill: parent
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                clip: true

                ListView {
                    id: eventList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    // Prepend a sentinel {id:"__new__"} as the first item
                    model: {
                        let sorted = root.events.slice().sort((a, b) =>
                            (a.date + a.time).localeCompare(b.date + b.time))
                        return [{id: "__new__", title: "+ New Event", _sentinel: true}].concat(sorted)
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: eventList.width
                        height: modelData._sentinel ? 44 : (itemCol.implicitHeight + 16)
                        radius: Appearance.rounding.small

                        // Sentinel: “+ New Event” card
                        visible: true
                        color: modelData._sentinel
                            ? (newEvMouse.containsMouse
                                ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.18)
                                : Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.10))
                            : (root.selectedId === modelData.id
                                ? Appearance.colors.colPrimaryContainer
                                : (evMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent"))

                        border.color: modelData._sentinel ? Qt.rgba(Appearance.colors.colPrimary.r, Appearance.colors.colPrimary.g, Appearance.colors.colPrimary.b, 0.4) : "transparent"
                        border.width: modelData._sentinel ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        // “+ New Event” sentinel content
                        RowLayout {
                            visible: modelData._sentinel === true
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "add"; iconSize: 16; color: Appearance.colors.colPrimary }
                            StyledText { text: "New Event"; color: Appearance.colors.colPrimary; font.weight: Font.Medium; font.pixelSize: Appearance.font.pixelSize.small }
                        }

                        // Normal event content
                        ColumnLayout {
                            id: itemCol
                            visible: !modelData._sentinel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 36
                            spacing: 2

                            StyledText {
                                text: modelData._sentinel ? "" : modelData.title
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: root.selectedId === modelData.id
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                visible: !modelData._sentinel
                                text: {
                                    if (modelData._sentinel) return ""
                                    let d = modelData.date + " " + modelData.time
                                    if (modelData.recurrence !== "once") d += " · " + modelData.recurrence
                                    return d
                                }
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                Layout.fillWidth: true
                            }
                        }

                        // Delete button (not for sentinel)
                        RippleButton {
                            visible: !modelData._sentinel
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 28; implicitHeight: 28; buttonRadius: 14
                            colBackground: "transparent"
                            onClicked: root.deleteEvent(modelData.id)
                            MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colSubtext }
                        }

                        // Sentinel mouse
                        MouseArea {
                            id: newEvMouse
                            anchors.fill: parent
                            visible: modelData._sentinel === true
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.selectedId = ""; root.clearForm() }
                        }

                        // Event mouse
                        MouseArea {
                            id: evMouse
                            anchors.fill: parent
                            anchors.rightMargin: 36
                            visible: !modelData._sentinel
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData._sentinel) return
                                root.selectedId = modelData.id
                                root.formTitle = modelData.title
                                root.formDate = modelData.date
                                root.formTime = modelData.time
                                root.formRecurrence = modelData.recurrence
                                root.formDescription = modelData.description || ""
                            }
                        }
                    }

                    ScrollBar.vertical: StyledScrollBar {}
                }
            }
        }

        // ── Event Editor ──
        ColumnLayout {
            width: schedRow.width - schedSidebar.width - schedRow.spacing
            height: parent.height
            spacing: 12

            // Header
            StyledText {
                text: root.selectedId ? "Edit Event" : "New Event"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            // Title field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainer
                border.color: titleField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                border.width: titleField.activeFocus ? 2 : 1

                TextInput {
                    id: titleField
                    anchors.fill: parent
                    anchors.margins: 12
                    text: root.formTitle
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    verticalAlignment: TextInput.AlignVCenter
                    onTextChanged: root.formTitle = text

                    StyledText {
                        anchors.fill: parent
                        text: "Event title..."
                        color: Appearance.colors.colSubtext
                        visible: !parent.text && !parent.activeFocus
                        font.pixelSize: Appearance.font.pixelSize.normal
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Date + Time row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Date
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 44
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: dateField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    border.width: dateField.activeFocus ? 2 : 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 6
                        MaterialSymbol { text: "calendar_today"; iconSize: 16; color: Appearance.colors.colSubtext }
                        TextInput {
                            id: dateField
                            Layout.fillWidth: true
                            text: root.formDate
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            inputMask: "9999-99-99"
                            onTextChanged: root.formDate = text
                        }
                    }
                }

                // Time
                Rectangle {
                    Layout.preferredWidth: 110; implicitHeight: 44
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: timeField.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    border.width: timeField.activeFocus ? 2 : 1
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 6
                        MaterialSymbol { text: "schedule"; iconSize: 16; color: Appearance.colors.colSubtext }
                        TextInput {
                            id: timeField
                            Layout.fillWidth: true
                            text: root.formTime
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            inputMask: "99:99"
                            onTextChanged: root.formTime = text
                        }
                    }
                }
            }

            // Description field — fills all remaining vertical space
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainer
                border.color: descArea.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                border.width: descArea.activeFocus ? 2 : 1
                clip: true

                TextEdit {
                    id: descArea
                    anchors.fill: parent
                    anchors.margins: 12
                    text: root.formDescription
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    wrapMode: TextEdit.Wrap
                    onTextChanged: root.formDescription = text

                    StyledText {
                        anchors.fill: parent
                        text: "Description (optional)..."
                        color: Appearance.colors.colSubtext
                        visible: !descArea.text && !descArea.activeFocus
                        font.pixelSize: Appearance.font.pixelSize.small
                        verticalAlignment: Text.AlignTop
                    }
                }
            }

            // Recurrence selector
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                StyledText { text: "Repeat"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: ["once", "daily", "weekly", "monthly"]
                        delegate: RippleButton {
                            required property string modelData
                            implicitHeight: 32
                            implicitWidth: 80
                            buttonRadius: 16
                            colBackground: root.formRecurrence === modelData
                                ? Appearance.colors.colPrimary
                                : Appearance.m3colors.m3surfaceContainer
                            onClicked: root.formRecurrence = modelData
                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: root.formRecurrence === modelData
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }

            // Save button
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 44
                buttonRadius: 22
                colBackground: Appearance.colors.colPrimary
                enabled: root.formTitle.trim().length > 0
                opacity: enabled ? 1 : 0.5
                onClicked: root.saveEvent()
                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    MaterialSymbol { text: "save"; iconSize: 18; color: Appearance.colors.colOnPrimary }
                    StyledText { text: root.selectedId ? "Update Event" : "Add Event"; font.weight: Font.Medium; color: Appearance.colors.colOnPrimary }
                }
            }
        }
    }
}
