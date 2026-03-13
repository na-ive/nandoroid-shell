import QtQuick
import Quickshell
import QtQuick.Layouts
import "../../widgets"
import "../../core"
import "../../core/functions" as Functions
import "../../services"

Rectangle {
    id: root
    
    // Explicitly set as classic launcher
    readonly property bool isSpotlight: false
    
    color: Appearance.colors.colLayer1
    radius: 32
    bottomLeftRadius: 0
    bottomRightRadius: 0
    
    // MD3 Outline Style
    border.width: 1
    border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
    
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
        spacing: 16
        
        LauncherSearchField {
            id: searchField
            Layout.fillWidth: true
            launcherContent: root
        }

        // ── Category Switcher ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            visible: !root.hasQuery && Config.ready && Config.options.search && Config.options.search.enableGrouping
            
            ListView {
                id: categoryList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 8
                model: LauncherSearch.categories
                boundsBehavior: Flickable.StopAtBounds
                delegate: RippleButton {
                    height: 36
                    implicitWidth: catText.implicitWidth + 32
                    buttonRadius: 18
                    colBackground: LauncherSearch.selectedCategory === modelData ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                    colRipple: Appearance.m3colors.m3onPrimary
                    
                    onClicked: {
                        LauncherSearch.selectedCategory = modelData;
                        root.selectedIndex = 0;
                    }

                    StyledText {
                        id: catText
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 12
                        font.weight: LauncherSearch.selectedCategory === modelData ? Font.Bold : Font.Normal
                        color: LauncherSearch.selectedCategory === modelData ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                    }
                }
            }
        }
        
        // ── Main Content Container (Grid or List) ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            GridView {
                id: appGrid
                anchors.fill: parent
                visible: !root.hasQuery
                interactive: true
                clip: true
                
                cellWidth: 100
                cellHeight: 110 + 24
                
                leftMargin: (width % cellWidth) / 2
                rightMargin: leftMargin
                
                model: visible ? root.resultsProxy : []
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

            ListView {
                id: pluginList
                anchors.fill: parent
                visible: root.hasQuery
                interactive: true
                clip: true
                spacing: 8
                
                model: visible ? root.resultsProxy : []
                delegate: LauncherListView {
                    result: modelData
                    selected: root.selectedIndex === index
                    onHoveredChanged: if (hovered) root.selectedIndex = index
                }
                currentIndex: root.selectedIndex
            }
        }
    }
}
