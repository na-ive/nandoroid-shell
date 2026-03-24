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
    radius: 20 * Appearance.effectiveScale
    
    // MD3 Outline Style
    border.width: 1 * Appearance.effectiveScale
    border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
    
    readonly property var resultsProxy: LauncherSearch.results
    property int selectedIndex: 0
    property int gridColumns: 1
    property bool isKeyboardNavigation: false
    readonly property bool hasQuery: LauncherSearch.query !== ""
    
    width: 700 * Appearance.effectiveScale
    height: 500 * Appearance.effectiveScale
    implicitHeight: 500 * Appearance.effectiveScale
    
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
        anchors.margins: 20 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
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
            spacing: 8 * Appearance.effectiveScale
            
            model: root.resultsProxy
            delegate: LauncherListView {
                result: modelData
                selected: root.selectedIndex === index
                onHoveredChanged: {
                    if (hovered) {
                        root.selectedIndex = index
                        root.isKeyboardNavigation = false
                    }
                }
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
            Layout.topMargin: 8 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale
            
            // Mode Indicator (Prefix-based)
            StyledText {
                font.pixelSize: 11 * Appearance.effectiveScale
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
                spacing: 16 * Appearance.effectiveScale
                opacity: 0.7
                
                // Navigate
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6 * Appearance.effectiveScale
                    StyledText {
                        text: "Navigate"
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2 * Appearance.effectiveScale
                        Rectangle {
                            Layout.preferredWidth: 20 * Appearance.effectiveScale
                            Layout.preferredHeight: 20 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { 
                                anchors.centerIn: parent; text: "↑"
                                font.pixelSize: 11 * Appearance.effectiveScale 
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 20 * Appearance.effectiveScale
                            Layout.preferredHeight: 20 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { 
                                anchors.centerIn: parent; text: "↓"
                                font.pixelSize: 11 * Appearance.effectiveScale 
                            }
                        }
                    }
                }

                // Open
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6 * Appearance.effectiveScale
                    StyledText {
                        text: "Open"
                        font.pixelSize: 11 * Appearance.effectiveScale
                        color: Appearance.colors.colOnLayer1
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Rectangle {
                            Layout.preferredWidth: 26 * Appearance.effectiveScale
                            Layout.preferredHeight: 20 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant
                            StyledText { 
                                anchors.centerIn: parent
                                text: "↵"
                                font.pixelSize: 11 * Appearance.effectiveScale
                            }
                        }
                    }
                }
            }
        }
    }
}
