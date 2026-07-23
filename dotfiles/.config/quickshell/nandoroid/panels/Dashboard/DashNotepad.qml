import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

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
        root.notes = [n].concat(root.notes)
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

    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: {
            if (!root.selectedId) return
            var now = new Date().toISOString()
            for (var i = 0; i < root.notes.length; i++) {
                if (root.notes[i].id === root.selectedId) {
                    root.notes[i].title = titleInput.text
                    root.notes[i].body = bodyArea.text
                    root.notes[i].updatedAt = now
                    if (i > 0) {
                        var note = root.notes.splice(i, 1)[0]
                        root.notes.unshift(note)
                    }
                    break
                }
            }
            root.notes = root.notes.slice()
            root.save()
        }
    }

    Row {
        id: mainRow
        anchors.fill: parent
        spacing: 12 * Appearance.effectiveScale

        ColumnLayout {
            id: sidebar
            width: 200 * Appearance.effectiveScale
            height: parent.height
            spacing: 8 * Appearance.effectiveScale

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.colors.colPrimary
                onClicked: root.newNote()
                RowLayout {
                    anchors.centerIn: parent; spacing: 6 * Appearance.effectiveScale
                    MaterialSymbol { text: "add"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.colors.colOnPrimary }
                    StyledText { text: "New Note"; color: Appearance.colors.colOnPrimary; font.weight: Font.Medium }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                clip: true

                ListView {
                    id: noteList
                    anchors.fill: parent
                    anchors.margins: 6 * Appearance.effectiveScale
                    spacing: 2 * Appearance.effectiveScale
                    model: root.notes.slice().sort((a, b) =>
                        new Date(b.updatedAt) - new Date(a.updatedAt))

                    delegate: Item {
                        required property var modelData
                        width: noteList.width
                        height: 52 * Appearance.effectiveScale

                        readonly property bool isHovered: nMouse.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.small
                            color: root.selectedId === modelData.id
                                ? Appearance.colors.colPrimaryContainer
                                : (isHovered ? Appearance.m3colors.m3surfaceContainerHigh : "transparent")
                        }

                        ColumnLayout {
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10 * Appearance.effectiveScale; anchors.rightMargin: 10 * Appearance.effectiveScale
                            spacing: 2 * Appearance.effectiveScale

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
                                color: root.selectedId === modelData.id
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                opacity: root.selectedId === modelData.id ? 0.75 : 1.0
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

        Item {
            id: editorArea
            width: mainRow.width - sidebar.width - mainRow.spacing
            height: parent.height

            Item {
                anchors.fill: parent
                visible: root.selectedId === ""

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12 * Appearance.effectiveScale
                    MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: "edit_note"; iconSize: 48 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Select or create a note"
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8 * Appearance.effectiveScale
                visible: root.selectedId !== ""

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40 * Appearance.effectiveScale
                    radius: Appearance.rounding.small
                    color: Appearance.m3colors.m3surfaceContainer
                    border.color: titleInput.activeFocus ? Appearance.colors.colPrimary : "transparent"
                    border.width: 2 * Appearance.effectiveScale

                    TextInput {
                        id: titleInput
                        anchors.fill: parent; anchors.margins: 10 * Appearance.effectiveScale
                        clip: true
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: saveTimer.restart()

                        StyledText {
                            anchors.fill: parent
                            text: "Note title..."
                            color: Appearance.colors.colSubtext
                            visible: !parent.text && !parent.activeFocus
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 40 * Appearance.effectiveScale; implicitHeight: 40 * Appearance.effectiveScale; buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainer
                    onClicked: root.deleteSelected()
                    MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colError }
                    StyledToolTip { text: "Delete note" }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                border.color: bodyArea.activeFocus ? Appearance.colors.colPrimary : "transparent"
                border.width: 2 * Appearance.effectiveScale
                clip: true

                Flickable {
                    id: bodyFlickable
                    anchors.fill: parent
                    anchors.margins: 12 * Appearance.effectiveScale
                    contentHeight: bodyArea.height
                    clip: true

                    TextEdit {
                        id: bodyArea
                        width: bodyFlickable.width
                        height: Math.max(implicitHeight, bodyFlickable.height)
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
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
