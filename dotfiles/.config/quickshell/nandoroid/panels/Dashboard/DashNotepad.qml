import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Properties ──
    property var items: []
    property string _view: "list" // "list" | "notepad"
    property string _editingId: ""

    readonly property string storagePath: Functions.FileUtils.trimFileProtocol(Directories.home) + "/.cache/nandoroid/notes.json"

    function _currentItem() {
        return items.find(i => i.id === _editingId)
    }

    property int _idCounter: 0
    function makeId() {
        root._idCounter++
        return Date.now().toString(36) + "_" + root._idCounter.toString(36) + Math.random().toString(36).substr(2,5)
    }

    function save() {
        const clean = root.items.map(i => {
            const c = {}
            for (const key in i) {
                if (key.startsWith("_")) continue
                c[key] = i[key]
            }
            return c
        })
        notesFile.setText(JSON.stringify(clean, null, 2))
    }

    function _flushSave() {
        if (saveTimer.running) {
            saveTimer.stop()
            _doSave()
        }
    }

    function goBack() {
        _flushSave()
        _view = "list"
        _editingId = ""
    }

    function openItem(id) {
        _flushSave()
        _editingId = id
        const item = _currentItem()
        if (!item) return
        if (item.type !== "notepad") return
        _view = "notepad"
        noteTitleInput.text = item.title
        bodyArea.text = item.body
    }

    function newNotepad() {
        const n = { type: "notepad", id: makeId(), title: I18nService.tr("Untitled"), body: "", color: "", pinned: false, updatedAt: new Date().toISOString() }
        root.items = [n].concat(root.items)
        save()
        openItem(n.id)
    }

    function deleteCurrent() {
        if (!_editingId) return
        deleteItem(_editingId)
        goBack()
    }

    function deleteItem(itemId) {
        const idx = items.findIndex(i => i.id === itemId)
        if (idx === -1) return
        const removed = items[idx]
        items = items.filter(i => i.id !== itemId)
        save()
        SnackbarService.show(
            I18nService.tr("Note deleted"),
            I18nService.tr("Undo"),
            () => {
                const arr = items.slice()
                arr.splice(Math.min(idx, arr.length), 0, removed)
                items = arr
                save()
            },
            SnackbarService.undoDuration
        )
    }

    function togglePin(itemId) {
        const item = items.find(i => i.id === itemId)
        if (item) {
            item.pinned = !item.pinned
            save()
            items = items.slice()
        }
    }

    function _distributeMasonry(itemsArray, numCols, targetIndex) {
        if (numCols <= 0) numCols = 1;
        var colHeights = [];
        var colItems = [];
        for (var c = 0; c < numCols; c++) {
            colHeights.push(0);
            colItems.push([]);
        }
        
        for (var i = 0; i < itemsArray.length; i++) {
            var itm = itemsArray[i];
            var shortestCol = 0;
            var minH = colHeights[0];
            for (var j = 1; j < numCols; j++) {
                if (colHeights[j] < minH) {
                    minH = colHeights[j];
                    shortestCol = j;
                }
            }
            colItems[shortestCol].push(itm);
            
            var estH = 80;
            if (itm.title) estH += 24 + Math.floor(itm.title.length / 25) * 24;
            if (itm.body) {
                var lines = itm.body.split('\n');
                var lc = 0;
                for (var k = 0; k < lines.length; k++) lc += 1 + Math.floor(lines[k].length / 35);
                estH += Math.min(8, lc) * 18;
            }
            colHeights[shortestCol] += estH;
        }
        return colItems[targetIndex];
    }

    // ── Date formatting helpers ──

    function _displayTime(timeStr) {
        if (!timeStr) return "";
        let d = new Date(timeStr);
        if (isNaN(d)) return timeStr;
        return Qt.formatTime(d, Config.ready ? Config.timeFormat : "hh:mm");
    }

    function _displayDate(dStr) {
        if (!dStr) return "";
        let d = new Date(dStr);
        if (isNaN(d)) return dStr;
        const style = Config.ready && Config.options.time ? (Config.options.time.dateStyle ?? "DMY") : "DMY";
        let fmt = "ddd, dd/MM/yyyy";
        if (style === "MDY") fmt = "ddd, MM/dd/yyyy";
        else if (style === "YMD") fmt = "ddd, yyyy/MM/dd";
        return Qt.formatDate(d, fmt);
    }

    // ── File I/O ──
    FileView {
        id: notesFile
        path: root.storagePath
        watchChanges: false
        onLoaded: {
            try {
                let parsed = JSON.parse(notesFile.text())
                if (Array.isArray(parsed)) {
                    parsed = parsed.map(i => {
                        if (!i.type) { i.type = "notepad"; i.color = "" }
                        if (typeof i.pinned === "undefined") i.pinned = false
                        return i
                    })
                    parsed = parsed.filter(i => i.type === "notepad")
                    root.items = parsed
                }
            } catch(e) {
                console.warn("DashNotepad: failed to parse notes.json: ", e)
            }
        }
    }

    Component.onCompleted: notesFile.reload()

    // ── Auto-save timer ──
    function _doSave() {
        if (!root._editingId) return
        const now = new Date().toISOString()
        const item = root._currentItem()
        if (!item) return

        if (item.type === "notepad") {
            item.title = noteTitleInput.text
            item.body = bodyArea.text
        }
        item.updatedAt = now

        const idx = root.items.indexOf(item)
        if (idx > 0) {
            root.items.splice(idx, 1)
            root.items.unshift(item)
        }
        root.items = root.items.slice()
        root.save()
    }

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: _doSave()
    }

    // ══════════════════════════════════════════════════
    //  UI
    // ══════════════════════════════════════════════════
    Component {
        id: noteDelegateComponent
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: contentCol.implicitHeight + 24 * Appearance.effectiveScale
            radius: Appearance.rounding.normal
            
            function getNoteColor(c) {
                if (c === "primary" || c === "primaryContainer") return Appearance.m3colors.m3primaryContainer;
                if (c === "secondary" || c === "secondaryContainer") return Appearance.m3colors.m3secondaryContainer;
                if (c === "tertiary" || c === "tertiaryContainer") return Appearance.m3colors.m3tertiaryContainer || Appearance.m3colors.m3tertiary; 
                if (c === "error" || c === "errorContainer") return Appearance.m3colors.m3errorContainer || Appearance.m3colors.m3error;
                if (c === "surfaceContainerHigh") return Appearance.m3colors.m3surfaceContainerHigh;
                if (c === "surfaceContainerLowest") return Appearance.m3colors.m3surfaceContainerLowest;
                return Appearance.m3colors.m3surfaceContainer;
            }

            property color baseColor: getNoteColor(modelData.color || "")
            color: itemMouse.containsMouse ? Functions.ColorUtils.mix(baseColor, Appearance.m3colors.m3onSurface, 0.95) : baseColor
            border.color: Appearance.m3colors.m3outlineVariant
            border.width: 1 * Appearance.effectiveScale

            MouseArea {
                id: itemMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openItem(modelData.id)
            }

            ColumnLayout {
                id: contentCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // Title & Pin
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.title || I18nService.tr("Untitled")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        wrapMode: Text.Wrap
                        visible: text.length > 0
                    }
                    
                    RippleButton {
                        id: pinBtn
                        implicitWidth: 28 * Appearance.effectiveScale
                        implicitHeight: 28 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignTop
                        buttonRadius: 14 * Appearance.effectiveScale
                        colBackground: "transparent"
                        opacity: itemMouse.containsMouse || pinBtn.realHovered || delBtn.realHovered || modelData.pinned ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        onClicked: root.togglePin(modelData.id)
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "keep"
                            iconSize: 18 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3onSurface
                            fill: modelData.pinned ? 1 : 0
                        }
                    }
                }

                // Body preview for notepad
                StyledText {
                    Layout.fillWidth: true
                    visible: modelData.type === "notepad"
                    text: (modelData.body || "").trim()
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    wrapMode: Text.Wrap
                    maximumLineCount: 8
                    elide: Text.ElideRight
                }

                // Footer (Date & Delete)
                Item {
                    Layout.fillWidth: true
                    implicitHeight: footerLayout.implicitHeight
                    Layout.topMargin: 4 * Appearance.effectiveScale
                    
                    RowLayout {
                        id: footerLayout
                        anchors.fill: parent
                        
                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.updatedAt ? root._displayDate(modelData.updatedAt) : ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        
                        RippleButton {
                            id: delBtn
                            implicitWidth: 24 * Appearance.effectiveScale
                            implicitHeight: 24 * Appearance.effectiveScale
                            buttonRadius: 12 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: root.deleteItem(modelData.id)
                            opacity: itemMouse.containsMouse || pinBtn.realHovered || delBtn.realHovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: 14 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurface
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        Item {
            id: listView
            anchors.fill: parent
            visible: root._view === "list"

            // ── List island (matches Schedule/Translate tab islands) ──
            Rectangle {
                anchors.fill: parent
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.large
            }

            // ── Item List ──
            Flickable {
                id: itemList
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                contentHeight: contentCol.implicitHeight
                bottomMargin: 80 * Appearance.effectiveScale
                clip: true

                property int columnsCount: Math.max(2, Math.floor(width / (220 * Appearance.effectiveScale)))
                
                property var pinnedItems: root.items.filter(i => i.pinned === true && i.type === "notepad").sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
                property var otherItems: root.items.filter(i => i.pinned !== true && i.type === "notepad").sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))

                ColumnLayout {
                    id: contentCol
                    width: itemList.width
                    spacing: 24 * Appearance.effectiveScale
                    
                    // Pinned Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12 * Appearance.effectiveScale
                        visible: itemList.pinnedItems.length > 0

                        StyledText {
                            text: I18nService.tr("Pinned")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colSubtext
                            Layout.leftMargin: 8 * Appearance.effectiveScale
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12 * Appearance.effectiveScale
                            Repeater {
                                model: itemList.columnsCount
                                delegate: ColumnLayout {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.fillWidth: true
                                    spacing: 12 * Appearance.effectiveScale
                                    Repeater {
                                        model: root._distributeMasonry(itemList.pinnedItems, itemList.columnsCount, index)
                                        delegate: noteDelegateComponent
                                    }
                                }
                            }
                        }
                    }

                    // Others Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12 * Appearance.effectiveScale
                        visible: itemList.otherItems.length > 0

                        StyledText {
                            text: I18nService.tr("Others")
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.Medium
                            color: Appearance.colors.colSubtext
                            Layout.leftMargin: 8 * Appearance.effectiveScale
                            visible: itemList.pinnedItems.length > 0 // Only show title if pinned exists
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12 * Appearance.effectiveScale
                            Repeater {
                                model: itemList.columnsCount
                                delegate: ColumnLayout {
                                    Layout.alignment: Qt.AlignTop
                                    Layout.fillWidth: true
                                    spacing: 12 * Appearance.effectiveScale
                                    Repeater {
                                        model: root._distributeMasonry(itemList.otherItems, itemList.columnsCount, index)
                                        delegate: noteDelegateComponent
                                    }
                                }
                            }
                        }
                    }
                }
                
                ScrollBar.vertical: StyledScrollBar {}
            }
        }

        // ── FAB (anchored to panel edge, not the inset list view, per M3 16dp) ──
        FloatingActionButton {
            anchors.fill: parent
            visible: root._view === "list"
            icon: "edit"
            label: I18nService.tr("New note")
            tooltipText: ""
            onClicked: root.newNotepad()
        }

        Rectangle {
            anchors.fill: parent
            visible: root._view === "notepad"
            radius: Appearance.rounding.normal
            clip: true
            
            onVisibleChanged: {
                if (!visible && colorPopup.opened) {
                    colorPopup.close()
                }
            }
            
            function getNoteColor(c) {
                if (c === "primary" || c === "primaryContainer") return Appearance.m3colors.m3primaryContainer;
                if (c === "secondary" || c === "secondaryContainer") return Appearance.m3colors.m3secondaryContainer;
                if (c === "tertiary" || c === "tertiaryContainer") return Appearance.m3colors.m3tertiaryContainer || Appearance.m3colors.m3tertiary; 
                if (c === "error" || c === "errorContainer") return Appearance.m3colors.m3errorContainer || Appearance.m3colors.m3error;
                if (c === "surfaceContainerHigh") return Appearance.m3colors.m3surfaceContainerHigh;
                if (c === "surfaceContainerLowest") return Appearance.m3colors.m3surfaceContainerLowest;
                return Appearance.m3colors.m3surfaceContainer;
            }
            
            color: getNoteColor(root._currentItem() ? root._currentItem().color || "" : "")

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Top bar: back + spacer + palette + pin + delete
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Appearance.effectiveScale
                    Layout.margins: 16 * Appearance.effectiveScale
                    Layout.topMargin: 16 * Appearance.effectiveScale

                    RippleButton {
                        implicitWidth: 40 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: 20 * Appearance.effectiveScale
                        colBackground: "transparent"
                        onClicked: root.goBack()
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_back"
                            iconSize: 22 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3onSurface
                        }
                    }

                    Item { Layout.fillWidth: true } // Spacer

                    // Pin Button
                    RippleButton {
                        implicitWidth: 40 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: 12 * Appearance.effectiveScale
                        colBackground: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
                        colBackgroundHover: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.16)
                        onClicked: {
                            if (root._editingId) {
                                root.togglePin(root._editingId)
                            }
                        }
                        MaterialSymbol { 
                            anchors.centerIn: parent; 
                            text: "keep"; 
                            iconSize: 22 * Appearance.effectiveScale; 
                            color: Appearance.m3colors.m3onSurface
                            fill: (root._currentItem() && root._currentItem().pinned) ? 1 : 0
                        }
                    }

                    // Palette Button
                    RippleButton {
                        id: paletteBtn
                        implicitWidth: 40 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: colorPopup.opened ? (20 * Appearance.effectiveScale) : (12 * Appearance.effectiveScale)
                        colBackground: colorPopup.opened ? Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.24) : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
                        colBackgroundHover: colorPopup.opened ? Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.32) : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.16)
                        
                        Behavior on buttonRadius { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        
                        MaterialSymbol { 
                            anchors.centerIn: parent; 
                            text: "palette"; 
                            iconSize: 22 * Appearance.effectiveScale; 
                            color: Appearance.m3colors.m3onSurface 
                            fill: colorPopup.opened ? 1 : 0
                        }
                        
                        property bool _justClosed: false
                        Timer {
                            id: blockReopenTimer
                            interval: 100
                            onTriggered: paletteBtn._justClosed = false
                        }

                        onClicked: {
                            if (colorPopup.opened) {
                                colorPopup.close()
                            } else if (!paletteBtn._justClosed) {
                                colorPopup.open()
                            }
                        }

                        Popup {
                            id: colorPopup
                            y: paletteBtn.height + 8 * Appearance.effectiveScale
                            x: -width + paletteBtn.width + 44 * Appearance.effectiveScale
                            width: colorGrid.implicitWidth + 24 * Appearance.effectiveScale
                            height: colorGrid.implicitHeight + 24 * Appearance.effectiveScale
                            
                            onClosed: {
                                paletteBtn._justClosed = true
                                blockReopenTimer.start()
                            }
                            
                            background: Rectangle {
                                color: Appearance.colors.colLayer0
                                radius: Appearance.rounding.normal
                                
                                StyledRectangularShadow {
                                    target: parent
                                    visible: true
                                    z: -1
                                }
                            }

                            GridLayout {
                                id: colorGrid
                                anchors.centerIn: parent
                                columns: 4
                                rowSpacing: 8 * Appearance.effectiveScale
                                columnSpacing: 8 * Appearance.effectiveScale
                                Repeater {
                                    model: ["", "primaryContainer", "secondaryContainer", "tertiaryContainer", "errorContainer", "surfaceContainerHigh", "surfaceContainerLowest"]
                                    delegate: ColorPickerButton {
                                        required property string modelData
                                        colorString: modelData === "" ? "surface" : modelData 
                                        isHighlighted: (root._currentItem() ? root._currentItem().color || "" : "") === modelData
                                        onClicked: {
                                            let note = root._currentItem();
                                            if (note) {
                                                note.color = modelData;
                                                root._doSave();
                                                root.items = root.items.slice();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Delete Button
                    RippleButton {
                        implicitWidth: 40 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        buttonRadius: 12 * Appearance.effectiveScale
                        colBackground: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
                        colBackgroundHover: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.16)
                        onClicked: root.deleteCurrent()
                        MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 22 * Appearance.effectiveScale; color: Appearance.m3colors.m3onSurface }
                    }
                }

                // Title Input
                StyledTextInput {
                    id: noteTitleInput
                    Layout.fillWidth: true
                    Layout.margins: 24 * Appearance.effectiveScale
                    Layout.topMargin: 0
                    Layout.bottomMargin: 24 * Appearance.effectiveScale
                    implicitHeight: 48 * Appearance.effectiveScale
                    backgroundColor: "transparent"
                    showActiveBorder: false
                    leftMargin: 0
                    rightMargin: 0
                    text: ""
                    font.weight: Font.Normal
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.family: Appearance.font.family.title
                    placeholder: I18nService.tr("Title")
                    onTextChanged: saveTimer.restart()
                }

                // Body editor
                Flickable {
                    id: bodyFlickable
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 24 * Appearance.effectiveScale
                    Layout.topMargin: 0
                    contentHeight: bodyArea.height
                    clip: true

                    TextEdit {
                        id: bodyArea
                        width: bodyFlickable.width
                        height: Math.max(implicitHeight, bodyFlickable.height)
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.large || 16 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                        wrapMode: TextEdit.Wrap
                        selectionColor: Appearance.colors.colPrimaryContainer
                        selectedTextColor: Appearance.colors.colOnPrimaryContainer
                        onTextChanged: saveTimer.restart()

                        onCursorRectangleChanged: {
                            const margin = 20 * Appearance.effectiveScale
                            if (cursorRectangle.y < bodyFlickable.contentY) {
                                bodyFlickable.contentY = cursorRectangle.y
                            } else if (cursorRectangle.y + cursorRectangle.height + margin > bodyFlickable.contentY + bodyFlickable.height) {
                                bodyFlickable.contentY = cursorRectangle.y + cursorRectangle.height - bodyFlickable.height + margin
                            }
                        }

                        StyledText {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            text: I18nService.tr("Note")
                            color: Appearance.colors.colSubtext
                            visible: !parent.text && !parent.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.large || 16 * Appearance.effectiveScale
                            font.family: Appearance.font.family.title
                            wrapMode: Text.Wrap
                        }
                    }

                    ScrollBar.vertical: StyledScrollBar {}
                }
            }
        }

    }
}
