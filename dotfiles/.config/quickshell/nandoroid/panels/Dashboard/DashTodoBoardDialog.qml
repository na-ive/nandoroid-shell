import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

// New / rename board dialog content (DialogService custom content).
// Shown through a wrapper Component in DashTodo.
Item {
    id: boardRoot

    property var ctrl: null

    implicitHeight: boardCol.implicitHeight

    function submitBoard() {
        const v = boardNameInput.text.trim();
        if (ctrl._boardDialogMode === "rename")
            ctrl.renameBoard(ctrl._boardDialogId, v === "" ? ctrl._boardDialogText : v);
        else
            ctrl.createBoard(v === "" ? I18nService.tr("New board") : v);
        DialogService.submit();
    }

    Timer {
        id: boardFocusTimer

        interval: 0
        onTriggered: {
            boardNameInput.forceActiveFocus();
            boardNameInput.selectAll();
        }
    }

    Component.onCompleted: {
        boardNameInput.text = ctrl._boardDialogMode === "rename" ? ctrl._boardDialogText : "";
        boardFocusTimer.restart();
    }

    ColumnLayout {
        id: boardCol

        anchors.fill: parent
        spacing: 16 * Appearance.effectiveScale

        StyledText {
            text: ctrl._boardDialogMode === "rename" ? I18nService.tr("Rename board") : I18nService.tr("New board")
            font.pixelSize: Appearance.font.pixelSize.huge
            font.family: Appearance.font.family.title
            font.weight: Font.Normal
            color: Appearance.colors.colOnLayer1
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52 * Appearance.effectiveScale
            color: "transparent"
            border.width: boardNameInput.activeFocus ? 2 * Appearance.effectiveScale : 1 * Appearance.effectiveScale
            border.color: boardNameInput.activeFocus ? ctrl.kanbanContainer : Appearance.m3colors.m3outline
            radius: 8 * Appearance.effectiveScale

            TextInput {
                id: boardNameInput

                anchors.fill: parent
                anchors.leftMargin: 12 * Appearance.effectiveScale
                anchors.rightMargin: 12 * Appearance.effectiveScale
                verticalAlignment: TextInput.AlignVCenter
                // Single-line inputs paint outside their bounds when
                // the text overflows unless clipped (cf. combo input).
                clip: true
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
                selectionColor: ctrl.kanbanContainer
                selectedTextColor: ctrl.kanbanOnContainer
                maximumLength: 60
                onAccepted: boardRoot.submitBoard()

                Text {
                    text: I18nService.tr("Board name")
                    color: Appearance.colors.colSubtext
                    visible: !parent.text && !parent.activeFocus
                    font: parent.font
                    anchors.verticalCenter: parent.verticalCenter
                }

                HoverHandler {
                    cursorShape: Qt.IBeamCursor
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            Item {
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: boardCancelText.width + 24 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: Functions.ColorUtils.applyAlpha(ctrl.kanbanContainer, 0.08)
                onClicked: DialogService.cancel()

                StyledText {
                    id: boardCancelText

                    anchors.centerIn: parent
                    text: I18nService.tr("Cancel")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: ctrl.kanbanAccent
                }
            }

            RippleButton {
                id: boardSaveBtn

                implicitWidth: boardOkText.width + 24 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: Functions.ColorUtils.applyAlpha(ctrl.kanbanContainer, 0.08)
                onClicked: boardRoot.submitBoard()

                StyledText {
                    id: boardOkText

                    anchors.centerIn: parent
                    text: ctrl._boardDialogMode === "rename" ? I18nService.tr("Rename") : I18nService.tr("Create")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: ctrl.kanbanAccent
                }
            }
        }
    }
}
