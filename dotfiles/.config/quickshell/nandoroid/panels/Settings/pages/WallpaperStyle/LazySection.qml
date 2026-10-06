import QtQuick
import QtQuick.Layouts
import "../../../../core"
import "../../../../services"

// Lazy section: builds content on scroll proximity, keeps it afterwards.
Loader {
    id: root

    property Component content
    property real estimate: 500 * Appearance.effectiveScale
    property real viewportY: 0
    property real viewportH: 0
    // [[canonical, [aliases]]] mirrored from the section's SearchHandler.
    property var searchEntries: []

    asynchronous: true
    Layout.preferredHeight: item ? item.implicitHeight : estimate

    property bool _done: false
    property bool _navLoad: false
    readonly property bool _near: visible && Math.abs(y - viewportY) < viewportH * 1.5
    on_NearChanged: if (_near) _done = true
    Component.onCompleted: if (_near) _done = true
    active: _done
    sourceComponent: root.content

    // Navigation hit while unloaded: load, then re-fire so the section's
    // own SearchHandler does the precise scroll + highlight.
    onLoaded: {
        if (!_navLoad) return
        _navLoad = false
        const q = SearchRegistry.currentSearch
        if (q !== "") { SearchRegistry.currentSearch = ""; SearchRegistry.currentSearch = q }
    }

    Connections {
        target: SearchRegistry
        function onCurrentSearchChanged() {
            const q = SearchRegistry.currentSearch
            if (!q || root.item) return
            const lq = q.toLowerCase()
            for (const pair of root.searchEntries) {
                const hit = pair[0].toLowerCase().includes(lq)
                    || (pair[1] || []).some(a => a.toLowerCase().includes(lq))
                if (hit) { root._navLoad = true; root._done = true; break }
            }
        }
    }
}
