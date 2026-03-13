import QtQuick
import Quickshell
import QtQuick.Layouts
import "../../widgets"
import "../../core"
import "../../core/functions" as Functions
import "../../services"

Rectangle {
    id: root
    
    // Explicitly set as spotlight
    readonly property bool isSpotlight: true
    
    color: Appearance.colors.colLayer1
    radius: 20
    
    // MD3 Outline Style
    border.width: 1
    border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
    
    readonly property var resultsProxy: LauncherSearch.results
    property int selectedIndex: 0
    property int gridColumns: 1
    readonly property bool hasQuery: LauncherSearch.query !== ""
    
    width: 700
    height: 500
    implicitHeight: 500
    
    function executeSelected() {
        if (root.resultsProxy && root.resultsProxy.length > 0 && selectedIndex >= 0 && selectedIndex < root.resultsProxy.length) {
            root.resultsProxy[selectedIndex].execute();
            GlobalStates.launcherOpen = false;
            GlobalStates.spotlightOpen = false;
        }
    }

    Connections {
        target: LauncherSearch
        function onQueryChanged() { root.selectedIndex = 0 }
    }

    // Smooth appearance animation
    Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    
    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16
        
        LauncherSearchField {
            id: searchField
            Layout.fillWidth: true
            launcherContent: root
        }
        
        // ── Spotlight / Search List ──
        ListView {
            id: pluginList
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            visible: true
            interactive: true
            clip: true
            spacing: 8
            
            model: root.resultsProxy
            delegate: LauncherListView {
                result: modelData
                selected: root.selectedIndex === index
                onHoveredChanged: if (hovered) root.selectedIndex = index
            }
            currentIndex: root.selectedIndex
            onCurrentIndexChanged: {
                if (visible && currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)
            }
        }

        // ── Vicinae Footer ──
        RowLayout {
            id: footer
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 12
            
            // Mode Indicator (Prefix-based)
            StyledText {
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                opacity: 0.6
                text: {
                    const q = LauncherSearch.query;
                    if (q.startsWith(":")) return "Emoji Search";
                    if (q.startsWith("!")) return "Web Search";
                    if (q.startsWith("=")) return "Calculator";
                    if (q.startsWith(";")) return "Clipboard History";
                    if (q.startsWith("?")) return "File Search";
                    if (q.startsWith(">")) return "Quick Commands";
                    return q ? "Spotlight Search" : "Applications";
                }
            }
            
            Item { Layout.fillWidth: true }
            
            RowLayout {
                spacing: 16
                opacity: 0.7
                
                // Navigate
                RowLayout {
                    spacing: 6
                    StyledText {
                        text: "Navigate"
                        font.pixelSize: 11
                        color: Appearance.colors.colOnLayer1
                    }
                    Row {
                        spacing: 2
                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "↑"; font.pixelSize: 10 }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { anchors.centerIn: parent; text: "↓"; font.pixelSize: 10 }
                        }
                    }
                }

                // Open
                RowLayout {
                    spacing: 6
                    StyledText {
                        text: "Open"
                        font.pixelSize: 11
                        color: Appearance.colors.colOnLayer1
                    }
                    Rectangle {
                        width: 22; height: 18; radius: 4
                        color: Appearance.m3colors.m3surfaceVariant
                        StyledText { anchors.centerIn: parent; text: "↵"; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}
