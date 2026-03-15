import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

/**
 * Dashboard Tab 3: Notepad
 * Notes stored in ~/.cache/nandoroid/notes.json
 */
Item {
    id: root

    property var notes: []
    property string selectedId: ""
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/notes.json"

    function makeId() { return Date.now().toString(36) + Math.random().toString(36).substr(2,5) }

    function stripHtml(html) {
        if (!html) return "";
        return html.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
    }

    function save() {
        notesFile.setText(JSON.stringify(root.notes, null, 2))
    }

    function selectNote(id) {
        selectedId = id
        const n = root.notes.find(n => n.id === id)
        if (n) {
            titleInput.text = n.title
            bodyArea.text = n.body
        }
    }

    function newNote() {
        const n = { id: makeId(), title: "Untitled", body: "", updatedAt: new Date().toISOString() }
        root.notes = root.notes.concat([n])
        save()
        selectNote(n.id)
    }

    function deleteSelected() {
        if (!selectedId) return
        root.notes = root.notes.filter(n => n.id !== selectedId)
        save()
        selectedId = ""
        titleInput.text = ""
        bodyArea.text = ""
    }

    FileView {
        id: notesFile
        path: root.storagePath
        watchChanges: false
        onLoaded: {
            try {
                let parsed = JSON.parse(notesFile.text())
                if (Array.isArray(parsed)) root.notes = parsed
            } catch(e) {}
        }
    }

    Component.onCompleted: notesFile.reload()

    // Auto-save debounce
    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.selectedId) return
            root.notes = root.notes.map(n => n.id === root.selectedId
                ? Object.assign({}, n, { title: titleInput.text, body: bodyArea.text, updatedAt: new Date().toISOString() })
                : n)
            root.save()
        }
    }

    // Fixed-width sidebar + flexible editor side-by-side
    Row {
        id: mainRow
        anchors.fill: parent
        spacing: 12

        // ── Note List Sidebar (fixed width, always same) ──
        ColumnLayout {
            id: sidebar
            width: 200
            height: parent.height
            spacing: 8

            // New note button
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40
                buttonRadius: 20
                colBackground: Appearance.colors.colPrimary
                onClicked: root.newNote()
                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    MaterialSymbol { text: "add"; iconSize: 18; color: Appearance.colors.colOnPrimary }
                    StyledText { text: "New Note"; color: Appearance.colors.colOnPrimary; font.weight: Font.Medium }
                }
            }

            // Note list
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                clip: true

                ListView {
                    id: noteList
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2
                    model: root.notes.slice().sort((a, b) =>
                        new Date(b.updatedAt) - new Date(a.updatedAt))

                    delegate: Rectangle {
                        required property var modelData
                        width: noteList.width
                        height: 52
                        radius: Appearance.rounding.small
                        color: root.selectedId === modelData.id
                            ? Appearance.colors.colPrimaryContainer
                            : (nMouse.containsMouse ? Appearance.colors.colLayer2 : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            spacing: 2

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.title || "Untitled"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: root.selectedId === modelData.id
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            StyledText {
                                Layout.fillWidth: true
                                property string plainBody: root.stripHtml(modelData.body)
                                text: plainBody.split("\n")[0] || (modelData.body && modelData.body.trim() !== "" ? "Rich content" : "Empty note")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                opacity: 0.8
                            }
                        }

                        MouseArea {
                            id: nMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectNote(modelData.id)
                        }
                    }
                }
            }
        }

        // ── Note Editor ──
        Item {
            id: editorArea
            width: mainRow.width - sidebar.width - mainRow.spacing
            height: parent.height

            // Show placeholder when nothing is selected
            Item {
                anchors.fill: parent
                visible: root.selectedId === ""

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "edit_note"; iconSize: 48; color: Appearance.colors.colSubtext }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Select or create a note"
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                }
            }

            // Editor (only when a note is selected)
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                visible: root.selectedId !== ""

            // Title bar + delete button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: titleInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2

                    TextInput {
                        id: titleInput
                        anchors.fill: parent; anchors.margins: 10
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer1
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: saveTimer.restart()

                        StyledText {
                            anchors.fill: parent
                            text: "Note title..."
                            color: Appearance.colors.colSubtext
                            visible: !parent.text && !parent.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Bold
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
                    colBackground: Appearance.m3colors.m3surfaceContainer
                    onClicked: root.deleteSelected()
                    MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 20; color: Appearance.colors.colError }
                    StyledToolTip { text: "Delete note" }
                }
            }

            // Body editor
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                border.color: bodyArea.activeFocus ? Appearance.colors.colPrimary : "transparent"
                border.width: 2
                clip: true

                Flickable {
                    id: bodyFlickable
                    anchors.fill: parent
                    anchors.margins: 12
                    contentHeight: bodyArea.height
                    clip: true

                    TextEdit {
                        id: bodyArea
                        width: bodyFlickable.width
                        // Always fill at least the visible Flickable height so
                        // clicking anywhere in the empty area starts typing
                        height: Math.max(implicitHeight, bodyFlickable.height)
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        wrapMode: TextEdit.Wrap
                        selectionColor: Appearance.colors.colPrimaryContainer
                        selectedTextColor: Appearance.colors.colOnPrimaryContainer
                        onTextChanged: saveTimer.restart()

                        onCursorRectangleChanged: {
                            const margin = 20 // Extra padding to keep cursor comfortable
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
                            text: "Start typing your note..."
                            color: Appearance.colors.colSubtext
                            visible: !parent.text && !parent.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.normal
                            wrapMode: Text.Wrap
                        }
                    }

                    ScrollBar.vertical: StyledScrollBar {}
                }
            }

            } // end inner editor ColumnLayout
        }
    }
}
