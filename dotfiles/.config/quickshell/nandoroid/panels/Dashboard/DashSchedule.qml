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
        id: layoutRow
        anchors.fill: parent
        spacing: 12 * Appearance.effectiveScale

        // ── Event List (fixed width) ──
        ColumnLayout {
            id: schedSidebar
            Layout.preferredWidth: 200 * Appearance.effectiveScale
            Layout.fillHeight: true
            spacing: 8 * Appearance.effectiveScale

            // New event button
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.colors.colPrimary
                onClicked: { root.selectedId = ""; root.clearForm() }
                RowLayout {
                    anchors.centerIn: parent; spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol { text: "add"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.colors.colOnPrimary }
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
                    anchors.margins: 6 * Appearance.effectiveScale
                    spacing: 4 * Appearance.effectiveScale
                    model: ScheduleService.events.slice().sort((a, b) =>
                            (a.date + a.time).localeCompare(b.date + b.time))

                    delegate: Rectangle {
                        required property var modelData
                        width: eventList.width
                        height: (itemCol.implicitHeight + (16 * Appearance.effectiveScale))
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
                            anchors.leftMargin: 12 * Appearance.effectiveScale
                            anchors.rightMargin: 36 * Appearance.effectiveScale
                            spacing: 2 * Appearance.effectiveScale

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4 * Appearance.effectiveScale
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
                                    iconSize: 14 * Appearance.effectiveScale
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
                            anchors.rightMargin: 6 * Appearance.effectiveScale
                            anchors.verticalCenter: parent.verticalCenter
                            implicitWidth: 28 * Appearance.effectiveScale; implicitHeight: 28 * Appearance.effectiveScale; buttonRadius: 14 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: root.deleteEvent(modelData.id)
                            MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        }

                        // Event mouse
                        MouseArea {
                            id: evMouse
                            anchors.fill: parent
                            anchors.rightMargin: 36 * Appearance.effectiveScale
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
            spacing: 12 * Appearance.effectiveScale

            // Header row with Focus toggle
            RowLayout {
                Layout.fillWidth: true
                spacing: 12 * Appearance.effectiveScale
                StyledText {
                    text: root.selectedId ? "Edit Event" : "New Event"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "do_not_disturb_on"
                        iconSize: 18 * Appearance.effectiveScale
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
                implicitHeight: 44 * Appearance.effectiveScale
                radius: Appearance.rounding.small
                color: Appearance.m3colors.m3surfaceContainer
                border.color: titleField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                border.width: 2 * Appearance.effectiveScale

                TextInput {
                    id: titleField
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    clip: true
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
                spacing: 8 * Appearance.effectiveScale

                // Date
                Rectangle {
                    id: dateFieldRect
                    Layout.fillWidth: true; implicitHeight: 44 * Appearance.effectiveScale
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: dateField.activeFocus || GlobalStates.datePickerOpen ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2 * Appearance.effectiveScale
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10 * Appearance.effectiveScale; spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol { text: "calendar_today"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
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
                        RippleButton {
                            implicitWidth: 28 * Appearance.effectiveScale
                            implicitHeight: 28 * Appearance.effectiveScale
                            buttonRadius: 14 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: root.openDatePicker()
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "date_range"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }

                // Start Time
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 44 * Appearance.effectiveScale
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: timeField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2 * Appearance.effectiveScale
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10 * Appearance.effectiveScale; spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol { text: "schedule"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
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
                    Layout.fillWidth: true; implicitHeight: 44 * Appearance.effectiveScale
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: endTimeField.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2 * Appearance.effectiveScale
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10 * Appearance.effectiveScale; spacing: 6 * Appearance.effectiveScale
                        MaterialSymbol { text: "event_busy"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
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
                border.width: 2 * Appearance.effectiveScale
                clip: true

                Flickable {
                    id: descFlickable
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    contentHeight: descArea.height
                    clip: true

                    TextEdit {
                        id: descArea
                        width: descFlickable.width
                        height: Math.max(implicitHeight, descFlickable.height)
                        text: root.formDescription
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer1
                        wrapMode: TextEdit.Wrap
                        onTextChanged: { root.formDescription = text; if(root.selectedId && descArea.activeFocus) autoSaveTimer.restart() }

                        onCursorRectangleChanged: {
                            const margin = 20 * Appearance.effectiveScale;
                            if (cursorRectangle.y < descFlickable.contentY)
                                descFlickable.contentY = cursorRectangle.y;
                            else if (cursorRectangle.y + cursorRectangle.height + margin > descFlickable.contentY + descFlickable.height)
                                descFlickable.contentY = cursorRectangle.y + cursorRectangle.height - descFlickable.height + margin;
                        }

                        StyledText {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            text: "Description (optional)..."
                            color: Appearance.colors.colSubtext
                            visible: !descArea.text && !descArea.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.small
                            wrapMode: Text.Wrap
                        }
                    }

                    ScrollBar.vertical: StyledScrollBar {}
                }
            }

            // Recurrence selector
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                StyledText { text: "Repeat"; font.pixelSize: Appearance.font.pixelSize.small; color: Appearance.colors.colSubtext }
                RowLayout {
                    spacing: 6 * Appearance.effectiveScale
                    Repeater {
                        model: ["once", "daily", "weekly", "monthly"]
                        delegate: RippleButton {
                            required property string modelData
                            implicitHeight: 32 * Appearance.effectiveScale
                            implicitWidth: 80 * Appearance.effectiveScale
                            buttonRadius: 16 * Appearance.effectiveScale
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
                implicitHeight: 44 * Appearance.effectiveScale
                buttonRadius: 22 * Appearance.effectiveScale
                colBackground: Appearance.colors.colPrimary
                enabled: root.formTitle.trim().length > 0
                opacity: enabled ? 1 : 0.5
                onClicked: root.saveEvent()
                RowLayout {
                    anchors.centerIn: parent; spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol { text: "save"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.colors.colOnPrimary }
                    StyledText { text: root.selectedId ? "Update Event" : "Add Event"; font.weight: Font.Medium; color: Appearance.colors.colOnPrimary }
                }
            }
        }
    }

    // ── Date picker ──
    function openDatePicker() {
        GlobalStates.datePickerCurrentDate = root.formDate
        GlobalStates.datePickerOnSelected = function(dateStr) {
            root.formDate = dateStr
            if (root.selectedId) autoSaveTimer.restart()
        }
        GlobalStates.datePickerOnCancelled = null
        GlobalStates.datePickerOpen = true
    }
}
