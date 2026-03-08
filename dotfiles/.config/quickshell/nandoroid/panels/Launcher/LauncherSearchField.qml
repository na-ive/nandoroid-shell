import QtQuick
import Quickshell
import "../../widgets"
import "../../core"
import "../../services"

Rectangle {
    id: root
    height: 48
    radius: 12
    
    readonly property bool isSpotlightMode: root.launcherContent && root.launcherContent.isSpotlight
    
    color: Appearance.m3colors.m3surfaceContainerHigh
    
    // Removed the separator line as it was causing visual issues.
    
    property var launcherContent

    Row {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 8
        
        TextInput {
            id: input
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - searchIcon.width - parent.spacing
            font.pixelSize: root.isSpotlightMode ? 18 : 16
            color: Appearance.m3colors.m3onSurface
            focus: true

            Timer {
                id: focusTimer
                interval: 100
                repeat: false
                onTriggered: input.forceActiveFocus()
            }

            Component.onCompleted: {
                if (GlobalStates.launcherOpen || GlobalStates.spotlightOpen) {
                    focusTimer.start();
                }
            }

            Connections {
                target: GlobalStates
                function onLauncherOpenChanged() {
                    if (GlobalStates.launcherOpen) {
                        if (input) input.text = "";
                        focusTimer.start();
                    } else {
                        if (input) input.text = "";
                    }
                }
            }

            Connections {
                target: GlobalStates
                function onSpotlightOpenChanged() {
                    if (GlobalStates.spotlightOpen) {
                        if (input) {
                            input.text = ""; // Force text change signal
                            input.text = GlobalStates.initialSpotlightQuery;
                        }
                        focusTimer.start();
                    } else {
                        if (input) input.text = "";
                    }
                }
            }

            Text {
                text: root.isSpotlightMode ? "Search for anything..." : "Search apps, files or commands..."
                visible: !input.text
                color: Appearance.m3colors.m3onSurfaceVariant
                opacity: 0.6
                font: input.font
            }
            
            onTextChanged: {
                debounceTimer.restart()
            }

            Timer {
                id: debounceTimer
                interval: 20
                onTriggered: LauncherSearch.query = input.text
            }

            Keys.onPressed: (event) => {
                if (!root.launcherContent) return;
                
                const results = LauncherSearch.results;
                const total = results.length;
                const isGrid = !root.isSpotlightMode && !LauncherSearch.isPluginSearch && !LauncherSearch.query;
                const cols = isGrid ? (root.launcherContent.gridColumns || 5) : 1;

                if (event.key === Qt.Key_Up) {
                    root.launcherContent.selectedIndex = Math.max(0, root.launcherContent.selectedIndex - cols);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    root.launcherContent.selectedIndex = Math.min(total - 1, root.launcherContent.selectedIndex + cols);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    if (isGrid) {
                        root.launcherContent.selectedIndex = Math.max(0, root.launcherContent.selectedIndex - 1);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Right) {
                    if (isGrid) {
                        root.launcherContent.selectedIndex = Math.min(total - 1, root.launcherContent.selectedIndex + 1);
                        event.accepted = true;
                    }
                }
            }

            onAccepted: {
                if (root.launcherContent) root.launcherContent.executeSelected();
            }
        }

        MaterialSymbol {
            id: searchIcon
            anchors.verticalCenter: parent.verticalCenter
            text: "search"
            iconSize: 20
            color: Appearance.m3colors.m3onSurfaceVariant
            visible: !root.isSpotlightMode
        }
    }
}
