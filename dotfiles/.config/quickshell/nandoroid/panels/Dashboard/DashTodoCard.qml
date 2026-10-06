import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

// Single Kanban card with press-drag reordering. State and actions live on
// the controller (`ctrl` = DashTodo), mirroring DashScheduleTimeline.
Item {
    id: delegateRoot

    property var ctrl: null
    required property var modelData
    property bool dragging: false
    property var pressPos: Qt.point(0, 0)
    property int dragThreshold: 5
    property Item originalParent: null
    // Slide the first visible card down when the column header is hovered
    property bool headerGap: {
        if (!ctrl.isTopDropZone(modelData.status)) return false;
        const col = ctrl.items.filter(i => i.status === modelData.status);
        const firstVisible = col.find(i => i.id !== ctrl.draggedTaskId);
        return firstVisible !== undefined && firstVisible.id === modelData.id;
    }

    Layout.fillWidth: true
    visible: !dragging
    // Auto collapse when dragged, and expand when hovered
    implicitHeight: dragging ? 0 : (cardRect.implicitHeight + ((cardDropArea.dragEntered && delegateRoot.modelData.id !== ctrl.draggedTaskId) || delegateRoot.headerGap ? ctrl.gapHeight : 0))

    DropArea {
        id: cardDropArea

        property bool dragEntered: containsDrag

        enabled: !delegateRoot.dragging
        anchors.fill: parent
        keys: ["task"]
        onEntered: {
            if (delegateRoot.modelData.id !== ctrl.draggedTaskId) {
                ctrl.hoveredTargetId = delegateRoot.modelData.id;
                ctrl.hoveredStatus = delegateRoot.modelData.status;
            }
        }
        // hoveredTargetId intentionally NOT cleared here: it is replaced
        // by the next onEntered / colDrop zone update, so the drop target
        // survives the DropArea exit events that fire when the drag ends.

        Rectangle {
            y: 44 * Appearance.effectiveScale
            anchors.left: parent.left
            anchors.right: parent.right
            height: 4 * Appearance.effectiveScale
            color: ctrl.kanbanContainer
            visible: (cardDropArea.dragEntered && delegateRoot.modelData.id !== ctrl.draggedTaskId) || delegateRoot.headerGap
            radius: Appearance.rounding.small
        }

    }

    Rectangle {
        id: cardRect

        width: delegateRoot.width
        implicitHeight: cardCol.implicitHeight + 32 * Appearance.effectiveScale
        radius: Appearance.rounding.small
        color: Appearance.m3colors.m3surfaceContainerHigh
        // Highlight while dragging
        border.width: delegateRoot.dragging ? Math.max(1, 2 * Appearance.effectiveScale) : 0
        border.color: ctrl.kanbanContainer
        scale: delegateRoot.dragging ? 1.02 : 1
        opacity: delegateRoot.dragging ? 0.9 : 1
        Drag.active: delegateRoot.dragging
        Drag.source: delegateRoot
        Drag.keys: ["task"]
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        MouseArea {
            id: cardDragArea

            anchors.fill: parent
            onClicked: ctrl.openEditor(delegateRoot.modelData.id, delegateRoot.modelData.content)
            cursorShape: delegateRoot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: delegateRoot.dragging ? cardRect : null
            drag.threshold: 0
            onPressed: (mouse) => {
                delegateRoot.pressPos = Qt.point(mouse.x, mouse.y);
                ctrl.draggedTaskId = delegateRoot.modelData.id;
                ctrl.hoveredStatus = "";
                ctrl.hoveredTargetId = "";
            }
            onPositionChanged: (mouse) => {
                if (!delegateRoot.dragging) {
                    const dx = mouse.x - delegateRoot.pressPos.x;
                    const dy = mouse.y - delegateRoot.pressPos.y;
                    if (Math.sqrt(dx * dx + dy * dy) > delegateRoot.dragThreshold) {
                        delegateRoot.originalParent = cardRect.parent;
                        const globalPos = cardRect.mapToItem(ctrl.dragOverlay, 0, 0);
                        cardRect.parent = ctrl.dragOverlay;
                        cardRect.x = globalPos.x;
                        cardRect.y = globalPos.y;
                        delegateRoot.dragging = true;
                    }
                }
            }
            onReleased: {
                if (delegateRoot.dragging) {
                    const targetStatus = ctrl.hoveredStatus;
                    const targetId = ctrl.hoveredTargetId;
                    const currentId = delegateRoot.modelData.id;
                    delegateRoot.dragging = false;
                    ctrl.draggedTaskId = "";
                    ctrl.hoveredTargetId = "";
                    if (cardRect) {
                        cardRect.parent = delegateRoot.originalParent;
                        cardRect.x = 0;
                        cardRect.y = 0;
                    }
                    if (targetStatus !== "")
                        ctrl.moveTaskBefore(currentId, targetStatus, targetId);

                } else {
                    ctrl.draggedTaskId = "";
                }
            }
        }

        ColumnLayout {
            id: cardCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16 * Appearance.effectiveScale

            StyledText {
                Layout.fillWidth: true
                text: delegateRoot.modelData.content
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
                wrapMode: Text.Wrap
            }

        }

        // Slide down to create a gap when hovered
        transform: Translate {
            y: ((cardDropArea.dragEntered && delegateRoot.modelData.id !== ctrl.draggedTaskId) || delegateRoot.headerGap) ? ctrl.gapHeight : 0

            Behavior on y {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }

        }

    }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }

    }

}
