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
    radius: 32 * Appearance.effectiveScale
    bottomLeftRadius: 0
    bottomRightRadius: 0
    
    // MD3 Outline Style
    border.width: 1 * Appearance.effectiveScale
    border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
    
    readonly property var resultsProxy: LauncherSearch.results
    property int selectedIndex: 0
    // Fixed to 9 to match the precise width in Launcher.qml
    readonly property int gridColumns: 9

    onSelectedIndexChanged: {
        if (!GlobalStates.launcherOpen) return;
        
        if (root.hasQuery) {
            pluginList.positionViewAtIndex(selectedIndex, ListView.Contain)
        } else {
            // Manual positioning only if index is significantly changed
            if (selectedIndex >= gridColumns) {
                appGrid.positionViewAtIndex(selectedIndex, GridView.Contain)
            } else if (selectedIndex === 0) {
                appGrid.contentY = 0
            }
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
        target: Appearance
        function onEffectiveScaleChanged() {
            // Force layout update when scale changes to fix grid column calculation lag
            Qt.callLater(() => {
                if (appGrid.visible) {
                    appGrid.forceLayout();
                }
            });
        }
    }

    Connections {
        target: GlobalStates
        function onLauncherOpenChanged() {
            if (GlobalStates.launcherOpen) {
                root.selectedIndex = 0
                // Reset scroll to top immediately and then again after layout stabilizes
                appGrid.contentY = 0
                Qt.callLater(() => {
                    appGrid.forceLayout();
                    appGrid.contentY = 0;
                });
            } else {
                root.selectedIndex = 0
            }
        }
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 24 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        LauncherSearchField {
            id: searchField
            Layout.fillWidth: true
            launcherContent: root
        }

        // ── Category Switcher ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36 * Appearance.effectiveScale
            visible: !root.hasQuery && Config.ready && Config.options.search && Config.options.search.enableGrouping
            
            ListView {
                id: categoryList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 8 * Appearance.effectiveScale
                model: LauncherSearch.categories
                boundsBehavior: Flickable.StopAtBounds
                delegate: RippleButton {
                    height: 36 * Appearance.effectiveScale
                    implicitWidth: catText.implicitWidth + 32 * Appearance.effectiveScale
                    buttonRadius: 18 * Appearance.effectiveScale
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
                        font.pixelSize: 12 * Appearance.effectiveScale
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
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: parent.height
                visible: !root.hasQuery
                interactive: true
                clip: true
                
                cellWidth: 100 * Appearance.effectiveScale
                cellHeight: (110 + 24) * Appearance.effectiveScale
                
                // Simplified margin calculation to be more robust
                leftMargin: Math.max(0, (width - (gridColumns * cellWidth)) / 2)
                rightMargin: leftMargin
                
                model: visible ? root.resultsProxy : []
                delegate: Item {
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight
                    AppIcon {
                        anchors.centerIn: parent
                        app: modelData
                        selected: root.selectedIndex === index
                        onHoveredChanged: if (hovered && GlobalStates.launcherOpen) root.selectedIndex = index
                    }
                }
                // currentIndex is REMOVED to prevent automatic scrolling artifacts
            }

            ListView {
                id: pluginList
                anchors.fill: parent
                visible: root.hasQuery
                interactive: true
                clip: true
                spacing: 8 * Appearance.effectiveScale
                
                model: visible ? root.resultsProxy : []
                delegate: LauncherListView {
                    result: modelData
                    selected: root.selectedIndex === index
                    onHoveredChanged: if (hovered && GlobalStates.launcherOpen) root.selectedIndex = index
                }
                // currentIndex is REMOVED to prevent automatic scrolling artifacts
            }
        }
    }
}
