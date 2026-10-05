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
 * Dashboard Tab 1: Schedule - event editor (CRUD form).
 * State and actions live on the controller (`ctrl` = DashSchedule).
 */
Item {
    id: rootView
    property var ctrl: null
    anchors.fill: parent
    visible: ctrl._view === "editor"

    ColumnLayout {
        anchors.fill: parent
        spacing: 12 * Appearance.effectiveScale

        // ── Header island ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60 * Appearance.effectiveScale
            color: Appearance.colors.colSecondaryContainer
            radius: Appearance.rounding.large

        // ── Header: back + title + focus toggle + delete ──
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
                onClicked: ctrl.backToTimeline()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3onSurface
                }

                StyledToolTip {
                    text: I18nService.tr("Back to schedule")
                }

            }

            StyledText {
                Layout.fillWidth: true
                text: ctrl._editingId ? I18nService.tr("Edit Event") : I18nService.tr("New Event")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }

            RowLayout {
                spacing: 8 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "do_not_disturb_on"
                    iconSize: 18 * Appearance.effectiveScale
                    color: ctrl.formFocus ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                }

                StyledText {
                    text: I18nService.tr("Focus Mode")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: ctrl.formFocus ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }

                AndroidToggle {
                    checked: ctrl.formFocus
                    color: checked ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerHigh
                    onToggled: {
                        ctrl.formFocus = !ctrl.formFocus;
                        if (ctrl._editingId)
                            ctrl.requestAutoSave();

                    }
                }

            }

            RippleButton {
                visible: ctrl._editingId !== ""
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: "transparent"
                onClicked: ctrl.deleteEditingEvent()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "delete"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colError
                }

                StyledToolTip {
                    text: I18nService.tr("Delete event")
                }

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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

        // ── Title field ──
        StyledTextInput {
            id: titleField

            Layout.fillWidth: true
            implicitHeight: 44 * Appearance.effectiveScale
            inputRadius: Appearance.rounding.small / Appearance.effectiveScale
            backgroundColor: Appearance.m3colors.m3surfaceContainerHighest
            placeholder: I18nService.tr("Event title...")
            text: ctrl.formTitle
            onTextChanged: {
                ctrl.formTitle = text;
                if (ctrl._editingId && titleField.input.activeFocus)
                    ctrl.requestAutoSave();

            }
        }

        // ── Start row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            StyledText {
                text: I18nService.tr("Start:")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredWidth: 44 * Appearance.effectiveScale
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 44 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.m3colors.m3surfaceContainerHighest
                colBackgroundHover: Functions.ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHighest, Appearance.m3colors.m3onSurface, 0.92)
                colText: "transparent"
                onClicked: ctrl.openDatePicker()

                StyledText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10 * Appearance.effectiveScale
                    text: ctrl._displayDate(ctrl.formDate)
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignLeft
                }

            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 44 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.m3colors.m3surfaceContainerHighest
                colBackgroundHover: Functions.ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHighest, Appearance.m3colors.m3onSurface, 0.92)
                colText: "transparent"
                onClicked: ctrl.openStartTimePicker()

                StyledText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 10 * Appearance.effectiveScale
                    text: ctrl._displayTime(ctrl.formTime)
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignRight
                }

            }

        }

        // ── End row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            StyledText {
                text: I18nService.tr("End:")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                Layout.preferredWidth: 44 * Appearance.effectiveScale
            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 44 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.m3colors.m3surfaceContainerHighest
                colBackgroundHover: Functions.ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHighest, Appearance.m3colors.m3onSurface, 0.92)
                colText: "transparent"
                onClicked: ctrl.openEndDatePicker()

                StyledText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10 * Appearance.effectiveScale
                    text: ctrl._displayDate(ctrl.formEndDate)
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignLeft
                }

            }

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 44 * Appearance.effectiveScale
                buttonRadius: Appearance.rounding.small
                colBackground: Appearance.m3colors.m3surfaceContainerHighest
                colBackgroundHover: Functions.ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHighest, Appearance.m3colors.m3onSurface, 0.92)
                colText: "transparent"
                onClicked: ctrl.openEndTimePicker()

                StyledText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 10 * Appearance.effectiveScale
                    text: ctrl._displayTime(ctrl.formEndTime)
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    horizontalAlignment: Text.AlignRight
                }

            }

        }

        StyledText {
            visible: ctrl.formEndDate.trim() && !ctrl.formDatesValid
            text: I18nService.tr("End must be later than start")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colError
        }

        // ── Description field ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHighest
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
                    text: ctrl.formDescription
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    wrapMode: TextEdit.Wrap
                    onTextChanged: {
                        ctrl.formDescription = text;
                        if (ctrl._editingId && descArea.activeFocus)
                            ctrl.requestAutoSave();

                    }
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
                        text: I18nService.tr("Description (optional)...")
                        color: Appearance.colors.colSubtext
                        visible: !descArea.text && !descArea.activeFocus
                        font.pixelSize: Appearance.font.pixelSize.small
                        wrapMode: Text.Wrap
                    }

                }

                ScrollBar.vertical: StyledScrollBar {
                }

            }

        }

        // ── Recurrence selector ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            StyledText {
                text: I18nService.tr("Repeat")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }

            Row {
                spacing: 2 * Appearance.effectiveScale

                Repeater {
                    model: ["once", "daily", "weekly", "monthly"]

                    delegate: SegmentedButton {
                        required property string modelData
                        readonly property bool _hidden: ctrl._multiDayDiff > 0 && modelData !== "once"

                        visible: !_hidden
                        implicitHeight: 32 * Appearance.effectiveScale
                        checked: ctrl.formRecurrence === modelData
                        buttonText: ctrl._recurrenceLabel(modelData)
                        font.pixelSize: Appearance.font.pixelSize.small
                        leftPadding: 16 * Appearance.effectiveScale
                        rightPadding: 16 * Appearance.effectiveScale

                        onClicked: {
                            ctrl.formRecurrence = modelData;
                            if (ctrl._editingId)
                                ctrl.requestAutoSave();

                        }
                    }

                }

            }

        }
            }
        }

        // ── Save button ──
        RippleButton {
            Layout.fillWidth: true
            implicitHeight: 44 * Appearance.effectiveScale
            buttonRadius: 22 * Appearance.effectiveScale
            colBackground: Appearance.colors.colPrimary
            enabled: ctrl.formTitle.trim().length > 0 && ctrl.formDatesValid
            opacity: enabled ? 1 : 0.5
            onClicked: ctrl.saveEvent()

            RowLayout {
                anchors.centerIn: parent
                spacing: 6 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "save"
                    iconSize: 18 * Appearance.effectiveScale
                    color: Appearance.colors.colOnPrimary
                }

                StyledText {
                    text: ctrl._editingId ? I18nService.tr("Update Event") : I18nService.tr("Add Event")
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnPrimary
                }

            }

        }

    }
}
