pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Schedule Service — manages events and persistence.
 */
Singleton {
    id: root

    property var events: []
    readonly property string storagePath: Directories.home.replace("file://", "") + "/.cache/nandoroid/schedule.json"

    function save() {
        scheduleFile.setText(JSON.stringify(root.events, null, 2))
    }

    function deleteEvent(id) {
        root.events = root.events.filter(e => e.id !== id)
        save()
    }

    function addEvent(event) {
        root.events = [...root.events, event]
        save()
    }

    function updateEvent(id, updatedFields) {
        root.events = root.events.map(e => e.id === id ? Object.assign({}, e, updatedFields) : e)
        save()
    }

    FileView {
        id: scheduleFile
        path: root.storagePath
        onLoaded: {
            try {
                let content = scheduleFile.text()
                if (content && content.trim() !== "") {
                    let parsed = JSON.parse(content)
                    if (Array.isArray(parsed)) root.events = parsed
                }
            } catch(e) {

            }
        }
    }

    Component.onCompleted: {
        // Ensure directory exists
        const dir = storagePath.substring(0, storagePath.lastIndexOf('/'));
        Quickshell.execDetached(["mkdir", "-p", dir]);
        scheduleFile.reload();
    }
}
