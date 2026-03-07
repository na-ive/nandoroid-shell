import QtQuick
import Quickshell
import QtQuick.Layouts
import "../../widgets"
import "../../core"
import "../../services"

Rectangle {
    id: root
    
    // Explicitly set as classic launcher
    readonly property bool isSpotlight: false
    
    color: Appearance.colors.colLayer1
    radius: 32
    bottomLeftRadius: 0
    bottomRightRadius: 0
    
    readonly property var resultsProxy: LauncherSearch.results
    property int selectedIndex: 0
    property int gridColumns: Math.max(1, Math.floor(appGrid.width / 100))

    onSelectedIndexChanged: {
        if (root.hasQuery) {
            pluginList.positionViewAtIndex(selectedIndex, ListView.Contain)
        } else {
            appGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
        }
    }

    readonly property bool hasQuery: LauncherSearch.query !== ""

    function executeSelected() {
        if (root.resultsProxy && root.resultsProxy.length > 0 && selectedIndex >= 0 && selectedIndex < root.resultsProxy.length) {
            root.resultsProxy[selectedIndex].execute();
            GlobalStates.launcherOpen = false;
        }
    }

    Connections {
        target: LauncherSearch
        function onQueryChanged() { root.selectedIndex = 0 }
    }

    Connections {
        target: GlobalStates
        function onLauncherOpenChanged() {
            if (!GlobalStates.launcherOpen) {
                root.selectedIndex = 0
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24
        
        LauncherSearchField {
            id: searchField
            Layout.fillWidth: true
            launcherContent: root
        }
        
        // ── App Grid (Main launcher view) ──
        GridView {
            id: appGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.hasQuery
            interactive: true
            clip: true
            
            cellWidth: 100
            cellHeight: 110 + 24
            
            leftMargin: (width % cellWidth) / 2
            rightMargin: leftMargin
            
            model: !root.hasQuery ? root.resultsProxy : []
            delegate: Item {
                width: appGrid.cellWidth
                height: appGrid.cellHeight
                AppIcon {
                    anchors.centerIn: parent
                    app: modelData
                    selected: root.selectedIndex === index
                    onHoveredChanged: if (hovered) root.selectedIndex = index
                }
            }
            currentIndex: root.selectedIndex
        }

        // ── Search List ──
        ListView {
            id: pluginList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.hasQuery
            interactive: true
            clip: true
            spacing: 8
            
            model: root.hasQuery ? root.resultsProxy : []
            delegate: LauncherListView {
                result: modelData
                selected: root.selectedIndex === index
                onHoveredChanged: if (hovered) root.selectedIndex = index
            }
            currentIndex: root.selectedIndex
        }
    }
}
