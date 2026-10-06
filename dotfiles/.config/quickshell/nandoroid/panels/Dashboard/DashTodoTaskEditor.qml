import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

// Edit-task dialog content (DialogService custom content, like the alarm
// dialog). Shown through a wrapper Component in DashTodo.
Item {
    id: editRoot

    property var ctrl: null
    readonly property string editingId: ctrl._editingId

    implicitHeight: editCol.implicitHeight

    // Deferred focus: DialogPanel's shell grabs focus to itself after
    // the content completes, so the input takes it back on the next
    // event loop pass.
    Timer {
        id: focusTimer

        interval: 0
        onTriggered: {
            editTaskInput.forceActiveFocus();
            editTaskInput.selectAll();
        }

    }

    Component.onCompleted: focusTimer.restart()

    ColumnLayout {
        id: editCol

        anchors.fill: parent
        spacing: 16 * Appearance.effectiveScale

        StyledText {
            text: I18nService.tr("Edit task")
            font.pixelSize: Appearance.font.pixelSize.huge
            font.family: Appearance.font.family.title
            font.weight: Font.Normal
            color: Appearance.colors.colOnLayer1
        }

        // M3 Outlined Text Field lookalike
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120 * Appearance.effectiveScale
            color: "transparent"
            border.width: editTaskInput.activeFocus ? 2 * Appearance.effectiveScale : 1 * Appearance.effectiveScale
            border.color: editTaskInput.activeFocus ? ctrl.kanbanContainer : Appearance.m3colors.m3outline
            radius: 8 * Appearance.effectiveScale

            StyledFlickable {
                id: editTaskFlickable

                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                contentHeight: editTaskInput.height
                clip: true

                TextEdit {
                    id: editTaskInput

                    width: parent.width
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    wrapMode: TextEdit.Wrap
                    selectionColor: ctrl.kanbanContainer
                    selectedTextColor: ctrl.kanbanOnContainer
                    text: ctrl._editText
                    onTextChanged: ctrl._editText = text
                    onCursorRectangleChanged: {
                        const margin = 8 * Appearance.effectiveScale;
                        if (cursorRectangle.y < editTaskFlickable.contentY)
                            editTaskFlickable.contentY = cursorRectangle.y;
                        else if (cursorRectangle.y + cursorRectangle.height + margin > editTaskFlickable.contentY + editTaskFlickable.height)
                            editTaskFlickable.contentY = cursorRectangle.y + cursorRectangle.height - editTaskFlickable.height + margin;
                    }

                    HoverHandler {
                        cursorShape: Qt.IBeamCursor
                    }

                }

            }

        }

        // Bottom Buttons (M3 Text Buttons)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            // Delete (Text Button)
            RippleButton {
                implicitWidth: deleteText.width + 24 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: Functions.ColorUtils.applyAlpha(ctrl.kanbanContainer, 0.08)
                onClicked: {
                    ctrl.deleteTask(editRoot.editingId);
                    DialogService.cancel();
                }

                StyledText {
                    id: deleteText
                    anchors.centerIn: parent
                    text: I18nService.tr("Delete")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: ctrl.kanbanAccent
                }
            }

            Item {
                Layout.fillWidth: true
            }
            // Cancel (Text Button)

            RippleButton {
                implicitWidth: cancelText.width + 24 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: Functions.ColorUtils.applyAlpha(ctrl.kanbanContainer, 0.08)
                onClicked: DialogService.cancel()

                StyledText {
                    id: cancelText

                    anchors.centerIn: parent
                    text: I18nService.tr("Cancel")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: ctrl.kanbanAccent
                }

            }

            // Save (Text Button)
            RippleButton {
                implicitWidth: saveText.width + 24 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: Functions.ColorUtils.applyAlpha(ctrl.kanbanContainer, 0.08)
                onClicked: {
                    const newText = editTaskInput.text.trim() === "" ? I18nService.tr("New task") : editTaskInput.text.trim();
                    const item = ctrl.items.find((i) => {
                        return i.id === editRoot.editingId;
                    });
                    if (item) {
                        item.content = newText;
                        item.updatedAt = new Date().toISOString();
                        ctrl.items = ctrl.items.slice();
                        ctrl.save();
                    }
                    DialogService.submit();
                }

                StyledText {
                    id: saveText

                    anchors.centerIn: parent
                    text: I18nService.tr("Save")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: ctrl.kanbanAccent
                }

            }

        }

    }

}
