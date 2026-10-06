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
    // Cards of the active board (read by DashSchedule).
    property var items: []
    // Multi-board storage: [{ id, name, items: [] }]. Old todo.json (plain
    // array) is auto-migrated into a single board named "Default".
    property var boards: []
    property string activeBoardId: ""
    // Board dialog state: "create" | "rename"
    property string _boardDialogMode: "create"
    property string _boardDialogId: ""
    property string _boardDialogText: ""
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

    // ── Multi-board helpers ──
    function activeBoard() {
        for (let b of root.boards) {
            if (b.id === root.activeBoardId)
                return b;
        }
        return root.boards.length > 0 ? root.boards[0] : null;
    }

    function activeBoardName() {
        const b = root.activeBoard();
        return b ? b.name : I18nService.tr("Default");
    }

    function boardNames() {
        return root.boards.map((b) => {
            return b.name;
        });
    }

    function _cleanItems(arr) {
        return (arr || []).map((i) => {
            const c = {
            };
            for (const key in i) {
                if (key.startsWith("_"))
                    continue;

                c[key] = i[key];
            }
            return c;
        });
    }

    function _syncItemsFromActive() {
        const b = root.activeBoard();
        root.items = b ? (b.items || []).slice() : [];
    }

    function _uniqueBoardName(base) {
        let name = (base || "").trim();
        if (name === "")
            name = I18nService.tr("New board");
        const existing = new Set(root.boards.map((b) => {
            return b.name.toLowerCase();
        }));
        if (!existing.has(name.toLowerCase()))
            return name;
        let n = 2;
        while (existing.has((name + " " + n).toLowerCase()))
            n++;
        return name + " " + n;
    }

    function _ensureDefaultBoard() {
        if (root.boards.length === 0) {
            root.boards = [{
                "id": "default",
                "name": I18nService.tr("Default"),
                "items": []
            }];
            root.activeBoardId = "default";
        } else if (!root.activeBoard()) {
            root.activeBoardId = root.boards[0].id;
        }
    }

    function save() {
        // Persist the v2 wrapper; v1 files are read-only.
        const clean = _cleanItems(root.items);
        const b = root.activeBoard();
        if (b)
            b.items = clean;
        root.boards = root.boards.slice();
        const payload = {
            "version": 2,
            "activeId": root.activeBoardId,
            "boards": root.boards.map((board) => {
                return {
                    "id": board.id,
                    "name": board.name,
                    "items": _cleanItems(board.items)
                };
            })
        };
        todoFile.setText(JSON.stringify(payload, null, 2));
    }

    function _setBoards(list, activeId) {
        root.boards = list;
        root.activeBoardId = activeId || (list.length > 0 ? list[0].id : "");
        root._ensureDefaultBoard();
        root._syncItemsFromActive();
    }

    // ── Board Operations ──
    function switchBoard(id) {
        if (!id || id === root.activeBoardId)
            return ;
        // Flush current items into the old board.
        const cur = root.activeBoard();
        if (cur)
            cur.items = _cleanItems(root.items);
        root.activeBoardId = id;
        root._syncItemsFromActive();
        save();
    }

    function createBoard(name) {
        const cur = root.activeBoard();
        if (cur)
            cur.items = _cleanItems(root.items);
        const board = {
            "id": makeId(),
            "name": _uniqueBoardName(name),
            "items": []
        };
        root.boards = root.boards.concat([board]);
        root.activeBoardId = board.id;
        root._syncItemsFromActive();
        save();
    }

    function renameBoard(id, name) {
        const clean = (name || "").trim();
        if (clean === "")
            return ;
        for (let b of root.boards) {
            if (b.id !== id && b.name.toLowerCase() === clean.toLowerCase())
                return ;
        }
        for (let b of root.boards) {
            if (b.id === id) {
                b.name = clean;
                break;
            }
        }
        root.boards = root.boards.slice();
        save();
    }

    function deleteBoard(id) {
        if (root.boards.length <= 1)
            return ;
        const idx = root.boards.findIndex((b) => {
            return b.id === id;
        });
        if (idx === -1)
            return ;
        const removed = root.boards[idx];
        let nextBoards = root.boards.filter((b) => {
            return b.id !== id;
        });
        root.boards = nextBoards;
        if (root.activeBoardId === id)
            root.activeBoardId = nextBoards.length > 0 ? nextBoards[0].id : "";

        root._ensureDefaultBoard();
        root._syncItemsFromActive();
        save();
        SnackbarService.show(I18nService.tr("Board deleted"), I18nService.tr("Undo"), () => {
            const arr = root.boards.slice();
            arr.splice(Math.min(idx, arr.length), 0, removed);
            root.boards = arr;
            root.activeBoardId = removed.id;
            root._syncItemsFromActive();
            save();
        }, SnackbarService.undoDuration);
    }

    function openBoardDialog(mode, id, currentName) {
        root._boardDialogMode = mode;
        root._boardDialogId = id || "";
        root._boardDialogText = mode === "rename" ? (currentName || "") : "";
        DialogService.requestCustom(boardEditContent, 360);
    }

    function confirmDeleteBoard(id, name) {
        DialogService.requestConfirmation({
            "titleText": I18nService.tr("Delete board?"),
            "messageText": I18nService.tr("Board \"%1\" and its %2 tasks will be removed.").arg(name).arg((root.boards.find((b) => {
                return b.id === id;
            }) || {
                "items": []
            }).items.length),
            "confirmText": I18nService.tr("Delete"),
            "cancelText": I18nService.tr("Cancel"),
            "iconText": "delete",
            "isDestructive": true
        }, () => {
            root.deleteBoard(id);
        });
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
                root._setBoards([{
                    "id": "default",
                    "name": I18nService.tr("Default"),
                    "items": migratedTasks
                }], "default");
                save(); // Save to todo.json (v2)
                notesFile.setText(JSON.stringify(remainingNotes, null, 2)); // Remove from notes.json
            } else {
                root._setBoards([{
                    "id": "default",
                    "name": I18nService.tr("Default"),
                    "items": []
                }], "default");
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

    Component.onCompleted: {
        root._ensureDefaultBoard();
        root._syncItemsFromActive();
        todoFile.reload();
    }

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
                    if (Array.isArray(parsed)) {
                        // v1: plain array -> becomes the "Default" board
                        root._setBoards([{
                            "id": "default",
                            "name": I18nService.tr("Default"),
                            "items": parsed
                        }], "default");
                        save(); // Upgrade file to v2 wrapper
                    } else if (parsed && Array.isArray(parsed.boards)) {
                        // v2 wrapper
                        let list = parsed.boards.map((b, bi) => {
                            return {
                                "id": b.id || ("board_" + bi),
                                "name": b.name || (I18nService.tr("Default") + (bi > 0 ? " " + (bi + 1) : "")),
                                "items": Array.isArray(b.items) ? b.items : []
                            };
                        });
                        if (list.length === 0)
                            list = [{
                                "id": "default",
                                "name": I18nService.tr("Default"),
                                "items": []
                            }];

                        root._setBoards(list, parsed.activeId);
                        // Re-persist if the file was missing ids/names
                        save();
                    } else {
                        _runMigration();
                    }
                }
            } catch (e) {
                console.warn("Error loading todo.json: ", e);
                _runMigration(); // Fallback to migration if invalid/empty
            }
        }
    }

    // ── Main UI ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 12 * Appearance.effectiveScale

        // ── Board header: icon island (board menu trigger, distinct color)
        // + title island (flat title text + active-board actions) ──
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 56 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // Matches the inactive Schedule rail button.
            Rectangle {
                Layout.preferredWidth: 56 * Appearance.effectiveScale
                Layout.preferredHeight: 56 * Appearance.effectiveScale
                radius: Appearance.rounding.large
                color: Appearance.colors.colSecondaryContainer

                RippleButton {
                    id: boardMenuBtn

                    anchors.fill: parent
                    buttonRadius: Appearance.rounding.large
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    colRipple: Appearance.colors.colLayer2Active
                    // Decided on PRESS (never click): no click-through reopen.
                    downAction: () => {
                        boardSwitcher.isOpened = !boardSwitcher.isOpened;
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "view_kanban"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colOnSecondaryContainer
                    }

                    StyledToolTip {
                        text: I18nService.tr("Boards")
                    }
                }

                // Invisible stock-ComboBox engine behind the icon button; renders
                // the menu below the island. Mouse-driven (no visible input).
                StyledComboBox {
                    id: boardSwitcher

                    x: 0
                    y: 28 * Appearance.effectiveScale
                    width: 240 * Appearance.effectiveScale
                    height: 32 * Appearance.effectiveScale
                    visible: false
                    searchable: false
                    text: root.activeBoardName()
                    model: root.boardNames()
                    actionText: I18nService.tr("New board")
                    onActionTriggered: root.openBoardDialog("create", "", "")
                    onAccepted: (value) => {
                        const b = root.boards.find((x) => {
                            return x.name === value;
                        });
                        if (b)
                            root.switchBoard(b.id);
                    }
                }
            }

            Rectangle {
                id: boardHeader

                Layout.fillWidth: true
                Layout.preferredHeight: 56 * Appearance.effectiveScale
                color: root.kanbanContainer
                radius: Appearance.rounding.large

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    spacing: 8 * Appearance.effectiveScale

                // Flat title text, capped before the action buttons.
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.activeBoardName()
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: root.kanbanOnContainer
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.maximumWidth: Math.max(48 * Appearance.effectiveScale, boardHeader.width - 112 * Appearance.effectiveScale)
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 32 * Appearance.effectiveScale
                }

                // Rename active board
                RippleButton {
                    implicitWidth: 32 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: {
                        const b = root.activeBoard();
                        if (b)
                            root.openBoardDialog("rename", b.id, b.name);
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "edit"
                        iconSize: 20 * Appearance.effectiveScale
                        color: root.kanbanOnContainer
                    }

                    StyledToolTip {
                        text: I18nService.tr("Rename board")
                    }
                }

                // Delete active board (disabled when only one board left)
                RippleButton {
                    implicitWidth: 32 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    colRipple: Appearance.colors.colLayer2Active
                    enabled: root.boards.length > 1
                    opacity: enabled ? 1 : 0.35
                    onClicked: {
                        const b = root.activeBoard();
                        if (b)
                            root.confirmDeleteBoard(b.id, b.name);
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "delete"
                        iconSize: 20 * Appearance.effectiveScale
                        color: root.kanbanOnContainer
                    }

                    StyledToolTip {
                        text: I18nService.tr("Delete board")
                    }
                }
            }
        }

        }

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
                                        delegate: DashTodoCard {
                                            ctrl: root
                                        }
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
            if (!GlobalStates.dashboardOpen && (DialogService.contentComponent === taskEditContent || DialogService.contentComponent === boardEditContent))
                DialogService.cancel();

        }

        target: GlobalStates
    }

    // Dialog content lives in DashTodoTaskEditor; DialogService takes the
    // wrapper Component (same pattern as the alarm dialog).
    Component {
        id: taskEditContent

        DashTodoTaskEditor {
            ctrl: root
        }
    }

    // Dialog content lives in DashTodoBoardDialog; DialogService takes the
    // wrapper Component.
    Component {
        id: boardEditContent

        DashTodoBoardDialog {
            ctrl: root
        }
    }

}
