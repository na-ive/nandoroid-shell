import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Properties ──
    property var items: []
    // List of Kanban cards
    property string _editingId: ""
    property string _editText: ""
    property string hoveredStatus: ""
    property string hoveredTargetId: ""
    property string draggedTaskId: ""
    property string topDropTarget: "__top__"
    property real gapHeight: 48 * Appearance.effectiveScale
    property alias dragOverlay: dragOverlayItem
    readonly property string storagePath: Functions.FileUtils.trimFileProtocol(Directories.home) + "/.cache/nandoroid/todo.json"
    readonly property string oldStoragePath: Functions.FileUtils.trimFileProtocol(Directories.home) + "/.cache/nandoroid/notes.json"
    property int _idCounter: 0

    // ── Kanban accent family (matches the Kanban rail button inactive state) ──
    readonly property color kanbanAccent: Functions.ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondary, 0.5)
    readonly property color kanbanContainer: Functions.ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colSecondaryContainer, 0.5)
    readonly property color kanbanOnContainer: Functions.ColorUtils.mix(Appearance.colors.colOnPrimaryContainer, Appearance.colors.colOnSecondaryContainer, 0.5)

    function makeId() {
        root._idCounter++;
        return Date.now().toString(36) + "_" + root._idCounter.toString(36) + Math.random().toString(36).substr(2, 5);
    }

    function isTopDropZone(status) {
        return root.hoveredStatus === status && root.hoveredTargetId === root.topDropTarget;
    }

    function save() {
        const clean = root.items.map((i) => {
            const c = {
            };
            for (const key in i) {
                if (key.startsWith("_"))
                    continue;

                c[key] = i[key];
            }
            return c;
        });
        todoFile.setText(JSON.stringify(clean, null, 2));
    }

    // ── Migration Script ──
    function _runMigration() {
        try {
            let notesText = notesFile.text();
            if (!notesText || notesText.trim() === "")
                return ;

            let allNotes = JSON.parse(notesText);
            if (!Array.isArray(allNotes))
                return ;

            let migratedTasks = [];
            let remainingNotes = [];
            for (let note of allNotes) {
                if (note.type === "todo") {
                    if (Array.isArray(note.tasks)) {
                        for (let task of note.tasks) {
                            migratedTasks.push({
                                "id": task.id || makeId(),
                                "content": task.content || "",
                                "status": task.done ? "done" : "todo",
                                "updatedAt": task.deadlineTime || note.updatedAt || new Date().toISOString()
                            });
                        }
                    }
                } else {
                    remainingNotes.push(note);
                }
            }
            if (migratedTasks.length > 0) {
                root.items = migratedTasks;
                save(); // Save to todo.json
                notesFile.setText(JSON.stringify(remainingNotes, null, 2)); // Remove from notes.json
            } else {
                root.items = [];
                save();
            }
        } catch (e) {
            console.log("Migration failed: ", e);
        }
    }

    // ── Kanban Operations ──
    function addTask(content) {
        if (!content || content.trim() === "")
            return ;

        const t = {
            "id": makeId(),
            "content": content,
            "status": "todo",
            "updatedAt": new Date().toISOString()
        };
        root.items = [t].concat(root.items);
        save();
    }

    function moveTaskBefore(taskId, newStatus, targetId) {
        let taskIndex = root.items.findIndex((i) => {
            return i.id === taskId;
        });
        if (taskIndex === -1)
            return ;

        let task = root.items[taskIndex];
        task.status = newStatus;
        task.updatedAt = new Date().toISOString();
        root.items.splice(taskIndex, 1);
        if (targetId === root.topDropTarget) {
            let firstIdx = root.items.findIndex((i) => {
                return i.status === newStatus;
            });
            if (firstIdx === -1)
                root.items.push(task);
            else
                root.items.splice(firstIdx, 0, task);
        } else if (targetId && targetId !== "") {
            let targetIndex = root.items.findIndex((i) => {
                return i.id === targetId;
            });
            if (targetIndex !== -1)
                root.items.splice(targetIndex, 0, task);
            else
                root.items.push(task);
        } else {
            root.items.push(task);
        }
        root.items = root.items.slice();
        save();
    }

    function deleteTask(id) {
        const idx = root.items.findIndex((i) => {
            return i.id === id;
        });
        if (idx === -1)
            return;
        const removed = root.items[idx];
        root.items = root.items.filter((i) => {
            return i.id !== id;
        });
        save();
        SnackbarService.show(
            I18nService.tr("Task deleted"),
            I18nService.tr("Undo"),
            () => {
                const items = root.items.slice();
                items.splice(Math.min(idx, items.length), 0, removed);
                root.items = items;
                save();
            },
            SnackbarService.undoDuration
        );
    }

    // ── Edit Dialog ──
    function openEditor(id, content) {
        root._editingId = id;
        root._editText = content;
        DialogService.requestCustom(taskEditContent, 400);
    }

    Component.onCompleted: todoFile.reload()

    // ── File I/O ──
    FileView {
        id: notesFile

        path: root.oldStoragePath
        watchChanges: false
    }

    FileView {
        id: todoFile

        path: root.storagePath
        watchChanges: false
        onLoaded: {
            try {
                let text = todoFile.text();
                if (!text || text.trim() === "") {
                    _runMigration();
                } else {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed))
                        root.items = parsed;

                }
            } catch (e) {
                console.warn("Error loading todo.json: ", e);
                _runMigration(); // Fallback to migration if invalid/empty
            }
        }
    }

    // ── UI Components ──
    Component {
        id: cardDelegate

        Item {
            id: delegateRoot

            required property var modelData
            property bool dragging: false
            property var pressPos: Qt.point(0, 0)
            property int dragThreshold: 5
            property Item originalParent: null
            // Slide the first visible card down when the column header is hovered
            property bool headerGap: {
                if (!root.isTopDropZone(modelData.status)) return false;
                const col = root.items.filter(i => i.status === modelData.status);
                const firstVisible = col.find(i => i.id !== root.draggedTaskId);
                return firstVisible !== undefined && firstVisible.id === modelData.id;
            }

            Layout.fillWidth: true
            visible: !dragging
            // Auto collapse when dragged, and expand when hovered
            implicitHeight: dragging ? 0 : (cardRect.implicitHeight + ((cardDropArea.dragEntered && delegateRoot.modelData.id !== root.draggedTaskId) || delegateRoot.headerGap ? root.gapHeight : 0))

            DropArea {
                id: cardDropArea

                property bool dragEntered: containsDrag

                enabled: !delegateRoot.dragging
                anchors.fill: parent
                keys: ["task"]
                onEntered: {
                    if (delegateRoot.modelData.id !== root.draggedTaskId) {
                        root.hoveredTargetId = delegateRoot.modelData.id;
                        root.hoveredStatus = delegateRoot.modelData.status;
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
                    color: root.kanbanContainer
                    visible: (cardDropArea.dragEntered && delegateRoot.modelData.id !== root.draggedTaskId) || delegateRoot.headerGap
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
                border.color: root.kanbanContainer
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
                    onClicked: root.openEditor(delegateRoot.modelData.id, delegateRoot.modelData.content)
                    cursorShape: delegateRoot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    drag.target: delegateRoot.dragging ? cardRect : null
                    drag.threshold: 0
                    onPressed: (mouse) => {
                        delegateRoot.pressPos = Qt.point(mouse.x, mouse.y);
                        root.draggedTaskId = delegateRoot.modelData.id;
                        root.hoveredStatus = "";
                        root.hoveredTargetId = "";
                    }
                    onPositionChanged: (mouse) => {
                        if (!delegateRoot.dragging) {
                            const dx = mouse.x - delegateRoot.pressPos.x;
                            const dy = mouse.y - delegateRoot.pressPos.y;
                            if (Math.sqrt(dx * dx + dy * dy) > delegateRoot.dragThreshold) {
                                delegateRoot.originalParent = cardRect.parent;
                                const globalPos = cardRect.mapToItem(root.dragOverlay, 0, 0);
                                cardRect.parent = root.dragOverlay;
                                cardRect.x = globalPos.x;
                                cardRect.y = globalPos.y;
                                delegateRoot.dragging = true;
                            }
                        }
                    }
                    onReleased: {
                        if (delegateRoot.dragging) {
                            const targetStatus = root.hoveredStatus;
                            const targetId = root.hoveredTargetId;
                            const currentId = delegateRoot.modelData.id;
                            delegateRoot.dragging = false;
                            root.draggedTaskId = "";
                            root.hoveredTargetId = "";
                            if (cardRect) {
                                cardRect.parent = delegateRoot.originalParent;
                                cardRect.x = 0;
                                cardRect.y = 0;
                            }
                            if (targetStatus !== "")
                                root.moveTaskBefore(currentId, targetStatus, targetId);

                        } else {
                            root.draggedTaskId = "";
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
                    y: ((cardDropArea.dragEntered && delegateRoot.modelData.id !== root.draggedTaskId) || delegateRoot.headerGap) ? root.gapHeight : 0

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

    }

    // ── Main UI ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 12 * Appearance.effectiveScale

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12 * Appearance.effectiveScale

            Repeater {
                model: [{
                    "title": I18nService.tr("To Do"),
                    "status": "todo",
                    "color": Appearance.m3colors.m3error,
                    "icon": "schedule",
                    "shape": MaterialShape.Shape.Clover4Leaf
                }, {
                    "title": I18nService.tr("Ongoing"),
                    "status": "doing",
                    "color": Appearance.colors.colWarning,
                    "icon": "hourglass_bottom",
                    "shape": MaterialShape.Shape.Cookie12Sided
                }, {
                    "title": I18nService.tr("Done"),
                    "status": "done",
                    "color": root.kanbanContainer,
                    "icon": "check_circle",
                    "shape": MaterialShape.Shape.Squircle
                }]

                delegate: DropArea {
                    id: colDrop

                    property bool dragEntered: containsDrag

                    // Top zone -> insert at top; bottom zone -> append at bottom.
                    // Between cards, target the next card below so the drop target
                    // never collapses to "" mid-column (which flashes the bottom hint).
                    function updateDropZone(y) {
                        const firstCard = cardRepeater.itemAt(0);
                        if (firstCard) {
                            const firstTop = firstCard.mapToItem(colDrop, 0, 0).y;
                            if (y < firstTop) {
                                root.hoveredTargetId = root.topDropTarget;
                                return;
                            }
                        }
                        for (let i = 0; i < cardRepeater.count; i++) {
                            const card = cardRepeater.itemAt(i);
                            if (!card || card.modelData.id === root.draggedTaskId)
                                continue;
                            if (y < card.mapToItem(colDrop, 0, 0).y) {
                                root.hoveredTargetId = card.modelData.id;
                                return;
                            }
                        }
                        root.hoveredTargetId = "";
                    }

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    keys: ["task"]
                    onEntered: (drag) => {
                        root.hoveredStatus = modelData.status;
                        colDrop.updateDropZone(drag.y);
                    }
                    onPositionChanged: (drag) => {
                        if (root.hoveredStatus === modelData.status)
                            colDrop.updateDropZone(drag.y);

                    }
                    onExited: {
                        if (root.hoveredStatus === modelData.status) {
                            root.hoveredStatus = "";
                            root.hoveredTargetId = "";
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.normal
                        color: Appearance.m3colors.m3surfaceContainer

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 52 * Appearance.effectiveScale
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12 * Appearance.effectiveScale
                                    anchors.rightMargin: 12 * Appearance.effectiveScale
                                    anchors.topMargin: 8 * Appearance.effectiveScale
                                    anchors.bottomMargin: 8 * Appearance.effectiveScale
                                    spacing: 12 * Appearance.effectiveScale

                                    Row {
                                        spacing: 4 * Appearance.effectiveScale
                                        Layout.alignment: Qt.AlignVCenter

                                        StyledText {
                                            text: modelData.title
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer1
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: `(${root.items.filter(i => i.status === modelData.status).length})`
                                            font.pixelSize: Appearance.font.pixelSize.normal
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colOnLayer1
                                            opacity: 0.5
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                    }

                                    // spacer
                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    RippleButton {
                                        implicitWidth: 32 * Appearance.effectiveScale
                                        implicitHeight: 32 * Appearance.effectiveScale
                                        buttonRadius: 8 * Appearance.effectiveScale
                                        colBackground: root.kanbanContainer
                                        onClicked: {
                                            const newId = root.makeId();
                                            const t = {
                                                "id": newId,
                                                "content": I18nService.tr("New task"),
                                                "status": modelData.status,
                                                "updatedAt": new Date().toISOString()
                                            };
                                            root.items = [t].concat(root.items);
                                            root.save();
                                            
                                            // Auto-open dialog for editing
                                            root.openEditor(newId, t.content);
                                        }

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "add"
                                            iconSize: 20 * Appearance.effectiveScale
                                            color: root.kanbanOnContainer
                                        }

                                    }

                                }

                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentHeight: cardListCol.implicitHeight
                                bottomMargin: 64 * Appearance.effectiveScale
                                clip: true

                                ColumnLayout {
                                    id: cardListCol

                                    width: parent.width
                                    spacing: 8 * Appearance.effectiveScale

                                    Repeater {
                                        id: cardRepeater

                                        model: root.items.filter((i) => {
                                            return i.status === modelData.status;
                                        })
                                        delegate: cardDelegate
                                    }

                                    Rectangle {
                                        id: bottomHintRect

                                        property int visibleCardsCount: root.items.filter((i) => {
                                            return i.status === modelData.status && i.id !== root.draggedTaskId;
                                        }).length

                                        Layout.fillWidth: true
                                        height: 4 * Appearance.effectiveScale
                                        color: root.kanbanContainer
                                        visible: colDrop.dragEntered && root.hoveredTargetId === ""
                                        radius: Appearance.rounding.small

                                        transform: Translate {
                                            y: bottomHintRect.visibleCardsCount > 0 ? -8 * Appearance.effectiveScale : 0
                                        }

                                    }

                                }

                                ScrollBar.vertical: StyledScrollBar {
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    Item {
        id: dragOverlayItem

        anchors.fill: parent
        z: 9999
    }

    Connections {
        function onDashboardOpenChanged() {
            if (!GlobalStates.dashboardOpen && DialogService.contentComponent === taskEditContent)
                DialogService.cancel();

        }

        target: GlobalStates
    }

    // ── Edit Task Dialog (DialogService custom content, like the alarm dialog) ──
    Component {
        id: taskEditContent

        Item {
            id: editRoot

            readonly property string editingId: root._editingId

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
                    border.                    color: editTaskInput.activeFocus ? root.kanbanContainer : Appearance.m3colors.m3outline
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
                        selectionColor: root.kanbanContainer
                        selectedTextColor: root.kanbanOnContainer
                            text: root._editText
                            onTextChanged: root._editText = text
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
                        colBackgroundHover: Functions.ColorUtils.applyAlpha(root.kanbanContainer, 0.08)
                        onClicked: {
                            root.deleteTask(editRoot.editingId);
                            DialogService.cancel();
                        }

                        StyledText {
                            id: deleteText
                            anchors.centerIn: parent
                            text: I18nService.tr("Delete")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: root.kanbanAccent
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
                        colBackgroundHover: Functions.ColorUtils.applyAlpha(root.kanbanContainer, 0.08)
                        onClicked: DialogService.cancel()

                        StyledText {
                            id: cancelText

                            anchors.centerIn: parent
                            text: I18nService.tr("Cancel")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: root.kanbanAccent
                        }

                    }

                    // Save (Text Button)
                    RippleButton {
                        implicitWidth: saveText.width + 24 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: 20 * Appearance.effectiveScale
                        colBackground: "transparent"
                        colBackgroundHover: Functions.ColorUtils.applyAlpha(root.kanbanContainer, 0.08)
                        onClicked: {
                            const newText = editTaskInput.text.trim() === "" ? I18nService.tr("New task") : editTaskInput.text.trim();
                            const item = root.items.find((i) => {
                                return i.id === editRoot.editingId;
                            });
                            if (item) {
                                item.content = newText;
                                item.updatedAt = new Date().toISOString();
                                root.items = root.items.slice();
                                root.save();
                            }
                            DialogService.submit();
                        }

                        StyledText {
                            id: saveText

                            anchors.centerIn: parent
                            text: I18nService.tr("Save")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: root.kanbanAccent
                        }

                    }

                }

            }

        }

    }

}
