import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab 1: Schedule - reminder editor (CRUD form).
 * State and actions live on the controller (`ctrl` = DashSchedule).
 */
Item {
    id: rootView
    property var ctrl: null
    anchors.fill: parent
    visible: ctrl._view === "reminder-editor"
    opacity: visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutQuart } }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12 * Appearance.effectiveScale

        // ── Header island ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60 * Appearance.effectiveScale
            color: Appearance.colors.colSecondaryContainer
            radius: Appearance.rounding.large

        // ── Header ──
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale

            RippleButton {
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: "transparent"
                colRipple: Appearance.colors.colLayer2Active
                onClicked: ctrl.backFromReminderEditor()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3onSurface
                }
                StyledToolTip { text: I18nService.tr("Back to schedule") }
            }

            StyledText {
                text: ctrl._editingReminderId ? I18nService.tr("Edit Reminder") : I18nService.tr("New Reminder")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
                Layout.fillWidth: true
            }

            // Delete button (only when editing)
            RippleButton {
                visible: ctrl._editingReminderId !== ""
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: "transparent"
                onClicked: ctrl.deleteEditingReminder()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colError
                }
                StyledToolTip { text: I18nService.tr("Delete reminder") }
            }
        }
        }

        // ── Form island ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.large
            clip: true

        // ── Scrollable form ──
        StyledFlickable {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            contentHeight: reminderFormLayout.implicitHeight
            clip: true

            ColumnLayout {
                id: reminderFormLayout
                width: parent.width
                spacing: 12 * Appearance.effectiveScale

                // Reminder text
                StyledTextInput {
                    id: reminderTextField
                    Layout.fillWidth: true
                    implicitHeight: 44 * Appearance.effectiveScale
                    inputRadius: Appearance.rounding.small / Appearance.effectiveScale
                    backgroundColor: Appearance.m3colors.m3surfaceContainerHighest
                    placeholder: I18nService.tr("Remind me to...")
                    text: ctrl.reminderText
                    onTextChanged: {
                        ctrl.reminderText = text
                    }
                }

                // Date row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Date:")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                        Layout.preferredWidth: 52 * Appearance.effectiveScale
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: ctrl.openReminderDatePicker()

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "calendar_today"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledText {
                                text: ctrl._displayDate(ctrl.reminderDate) || ctrl.reminderDate
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.m3colors.m3onSurface
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Time row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Time:")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                        Layout.preferredWidth: 52 * Appearance.effectiveScale
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: ctrl.openReminderTimePicker()

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            spacing: 8 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "schedule"
                                iconSize: 16 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                            StyledText {
                                text: ctrl._displayTime(ctrl.reminderTime) || ctrl.reminderTime
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.m3colors.m3onSurface
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Type row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Type:")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                        Layout.preferredWidth: 52 * Appearance.effectiveScale
                    }

                    StyledComboBox {
                        id: reminderTypeCombo
                        Layout.fillWidth: true
                        searchable: false
                        model: [I18nService.tr("Basic"), I18nService.tr("Notepad"), I18nService.tr("Todo")]
                        text: {
                            switch (ctrl.reminderType) {
                                case "notepad": return I18nService.tr("Notepad");
                                case "todo": return I18nService.tr("Todo");
                                default: return I18nService.tr("Basic");
                            }
                        }
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                        onAccepted: (val) => {
                            if (val === I18nService.tr("Notepad")) ctrl.reminderType = "notepad";
                            else if (val === I18nService.tr("Todo")) ctrl.reminderType = "todo";
                            else ctrl.reminderType = "basic";
                            ctrl.reminderLinkedId = "";
                            ctrl.reminderLinkedTitle = "";
                            reminderTypeCombo.isOpened = false;
                        }
                    }
                }

                // Linked item row (shown only for notepad/todo types)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale
                    visible: ctrl.reminderType === "notepad" || ctrl.reminderType === "todo"
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    StyledText {
                        text: ctrl.reminderType === "notepad" ? I18nService.tr("Note:") : I18nService.tr("Task:")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3onSurface
                        Layout.preferredWidth: 52 * Appearance.effectiveScale
                    }

                    StyledComboBox {
                        id: linkedItemCombo
                        Layout.fillWidth: true
                        searchable: true

                        // Model: notepad item titles or todo task contents (truncated)
                        model: {
                            if (ctrl.reminderType === "notepad") {
                                return ctrl.notepadItems.map(i => i.title || I18nService.tr("Untitled"));
                            } else if (ctrl.reminderType === "todo") {
                                const result = [];
                                for (const task of ctrl.todoItems) {
                                    if (!task || !task.content) continue;
                                    const content = task.content;
                                    result.push(content.length > 50 ? content.slice(0, 47) + "..." : content);
                                }
                                return result;
                            }
                            return [];
                        }

                        // NOTE: no live `text:` binding here — that fights with StyledComboBox
                        // internals after onAccepted and causes the popup to reopen invisibly.
                        // Text is synced imperatively below.
                        text: ""
                        placeholder: ctrl.reminderType === "notepad"
                            ? I18nService.tr("Select notepad...")
                            : I18nService.tr("Select task...")
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest

                        onAccepted: (val) => {
                            // Update the combo's own text directly (no external binding conflict)
                            linkedItemCombo.text = val;
                            // Store into ctrl
                            ctrl.reminderLinkedTitle = val;
                            // Find linked ID
                            if (ctrl.reminderType === "notepad") {
                                const item = ctrl.notepadItems.find(i =>
                                    (i.title || I18nService.tr("Untitled")) === val
                                );
                                ctrl.reminderLinkedId = item ? item.id : "";
                            } else if (ctrl.reminderType === "todo") {
                                let foundId = "";
                                for (const task of ctrl.todoItems) {
                                    if (!task || !task.content) continue;
                                    const content = task.content;
                                    const truncated = content.length > 50 ? content.slice(0, 47) + "..." : content;
                                    if (truncated === val) { foundId = task.id; break; }
                                }
                                ctrl.reminderLinkedId = foundId;
                            }
                        }

                        // Sync text from ctrl when editing an existing reminder
                        Connections {
                            target: ctrl
                            function onReminderLinkedTitleChanged() {
                                // Only sync when the combo is closed to avoid fighting with it
                                if (!linkedItemCombo.isOpened) {
                                    linkedItemCombo.text = ctrl.reminderLinkedTitle || "";
                                }
                            }
                        }
                    }
                }

                Item { implicitHeight: 8 * Appearance.effectiveScale }
            }
        }
        }

        // ── Save button — pinned at bottom (outside scrollable area) ──
        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 44 * Appearance.effectiveScale
            buttonRadius: 22 * Appearance.effectiveScale
            enabled: ctrl.reminderText.trim() !== ""
            colBackground: Appearance.colors.colSecondaryContainer
            colRipple: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnSecondaryContainer, 0.15)
            opacity: enabled ? 1 : 0.5
            onClicked: ctrl.saveReminder()

            RowLayout {
                anchors.centerIn: parent
                spacing: 8 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "alarm_add"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnSecondaryContainer
                }

                StyledText {
                    text: ctrl._editingReminderId ? I18nService.tr("Update Reminder") : I18nService.tr("Set Reminder")
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }
}
