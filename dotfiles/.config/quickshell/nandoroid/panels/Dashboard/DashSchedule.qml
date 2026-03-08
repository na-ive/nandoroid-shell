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
 * Local JSON storage, recurring events.
 */
Item {
    id: root

    // ── State ──
    property string selectedId: ""
    property string formTitle: ""
    property string formDate: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property string formTime: "09:00"
    property string formEndTime: "10:00"
    property string formRecurrence: "once" // once | daily | weekly | monthly
    property string formDescription: ""
    property bool formFocus: false

    function clearForm() {
        formTitle = ""; formDate = Qt.formatDate(new Date(), "yyyy-MM-dd")
        formTime = "09:00"; formEndTime = "10:00"; formRecurrence = "once"; formDescription = ""; formFocus = false
    }

    function deleteEvent(id) {
        ScheduleService.deleteEvent(id)
        if (selectedId === id) { selectedId = ""; clearForm() }
    }

    // Auto-save debounce for existing events
    Timer {
        id: autoSaveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.selectedId || !root.formTitle.trim()) return
            const descVal = root.formDescription.trim() ? root.formDescription.trim() : undefined
            ScheduleService.updateEvent(root.selectedId, {
                title: root.formTitle, 
                date: root.formDate, 
                time: root.formTime, 
                endTime: root.formEndTime,
                recurrence: root.formRecurrence, 
                description: descVal,
                focus: root.formFocus
            })
        }
    }

    function saveEvent() {
        if (!formTitle.trim()) return
        const descVal = formDescription.trim() ? formDescription.trim() : undefined
        if (selectedId) {
            ScheduleService.updateEvent(selectedId, { 
                title: formTitle, 
                date: formDate, 
                time: formTime, 
                endTime: formEndTime,
                recurrence: formRecurrence, 
                description: descVal,
                focus: formFocus
            })
        } else {
            const newEv = { 
                id: Date.now().toString(36), 
                title: formTitle, 
                date: formDate, 
                time: formTime, 
                endTime: formEndTime,
                recurrence: formRecurrence, 
                description: descVal, 
                focus: formFocus,
                lastFired: "" 
            }
            ScheduleService.addEvent(newEv)
        }
        selectedId = ""
        clearForm()
    }

    // ── Layout ──
    RowLayout {
        id: schedRow
        anchors.fill: parent
        spacing: 12

        // ── Event List (fixed width) ──
        ColumnLayout {
            id: schedSidebar
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            spacing: 8

            // New event button
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40
                buttonRadius: 20
                colBackground: Appearance.colors.colPrimary
                onClicked: { root.selectedId = ""; root.clearForm() }
                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    MaterialSymbol { text: "add"; iconSize: 18; color: Appearance.colors.colOnPrimary }
                    StyledText { text: "New Event"; color: Appearance.colors.colOnPrimary; font.weight: Font.Medium }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                clip: true

                ListView {
                    id: eventList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4
                    model: ScheduleService.events.slice().sort((a, b) =>
                            (a.date + a.time).localeCompare(b.date + b.time))

                    delegate: Rectangle {
                        required property var modelData
                        width: eventList.width
                        height: (itemCol.implicitHeight + 16)
                        radius: Appearance.rounding.small

                        color: root.selectedId === modelData.id
                                ? Appearance.colors.colPrimaryContainer
                                : (evMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        // Normal event content
                        ColumnLayout {
                            id: itemCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.rightMargin: 36
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                StyledText {
                                    text: modelData.title
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: root.selectedId === modelData.id
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                MaterialSymbol {
                                    visible: modelData.focus || false
                                    text: "do_not_disturb_on"
                                    iconSize: 14
                                    color: root.selectedId === modelData.id
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colPrimary
                                }
                            }
                            StyledText {
                                text: {
                                    let d = modelData.date + " " + modelData.time
                                    if (modelData.endTime) d += " - " + modelData.endTime
                                    if (modelData.recurrence !== "once") d += " · " + modelData.recurrence
                                    return d
                                }
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                Layout.fillWidth: true
                            }
                        }

                        // Delete button
                        RippleButton {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 28; implicitHeight: 28; buttonRadius: 14
                            colBackground: "transparent"
                            onClicked: root.deleteEvent(modelData.id)
                            MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colSubtext }
                        }

                        // Event mouse
                        MouseArea {
                            id: evMouse
                            anchors.fill: parent
                            anchors.rightMargin: 36
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // Temporarily disable autosave triggers while populating fields
                                let oldSelectedId = root.selectedId
                                root.selectedId = ""
                                root.formTitle = modelData.title
                                root.formDate = modelData.date
                                root.formTime = modelData.time
                                root.formEndTime = modelData.endTime || ""
                                root.formRecurrence = modelData.recurrence
                                root.formDescription = modelData.description || ""
                                root.formFocus = modelData.focus || false
                                root.selectedId = modelData.id
                            }
                        }
                    }

                    ScrollBar.vertical: StyledScrollBar {}
                }
            }
        }

        // ── Event Editor ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Header row with Focus toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                StyledText {
                    text: root.selectedId ? "Edit Event" : "New Event"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 8
                    MaterialSymbol {
                        text: "do_not_disturb_on"
                        iconSize: 18
                        color: root.formFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: "Focus Mode"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.formFocus ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                    }
                    AndroidToggle {
                        checked: root.formFocus
                        color: checked ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                        onToggled: {
                            root.formFocus = !root.formFocus
                            if (root.selectedId) autoSaveTimer.restart()
                        }
                    }
                }
            }

            // Title field
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 44
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainer
                border.color: titleField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                border.width: 2

                TextInput {
                    id: titleField
                    anchors.fill: parent
                    anchors.margins: 12
                    text: root.formTitle
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    verticalAlignment: TextInput.AlignVCenter
                    onTextChanged: { root.formTitle = text; if(root.selectedId && titleField.activeFocus) autoSaveTimer.restart() }

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
                    border.color: dateField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2
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
                            onTextChanged: { root.formDate = text; if(root.selectedId && dateField.activeFocus) autoSaveTimer.restart() }
                        }
                    }
                }

                // Start Time
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 44
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: timeField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2
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
                            onTextChanged: { root.formTime = text; if(root.selectedId && timeField.activeFocus) autoSaveTimer.restart() }
                        }
                    }
                }

                // End Time
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 44
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: endTimeField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 6
                        MaterialSymbol { text: "event_busy"; iconSize: 16; color: Appearance.colors.colSubtext }
                        TextInput {
                            id: endTimeField
                            Layout.fillWidth: true
                            text: root.formEndTime
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            inputMask: "99:99"
                            onTextChanged: { root.formEndTime = text; if(root.selectedId && endTimeField.activeFocus) autoSaveTimer.restart() }
                        }
                    }
                }
            }

            // Description field — fills all remaining vertical space
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Appearance.rounding.normal
                color: Appearance.m3colors.m3surfaceContainer
                border.color: descArea.activeFocus ? Appearance.colors.colPrimary : "transparent"
                border.width: 2
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
                    onTextChanged: { root.formDescription = text; if(root.selectedId && descArea.activeFocus) autoSaveTimer.restart() }

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
                            colBackgroundHover: root.formRecurrence === modelData
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer2
                            onClicked: {
                                root.formRecurrence = modelData
                                if (root.selectedId) autoSaveTimer.restart()
                            }
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
