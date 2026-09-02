import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../widgets"
import "../../core"
import "../../services"

Rectangle {
    id: root
    height: 40 * Appearance.effectiveScale
    implicitHeight: height
    Layout.preferredHeight: height
    radius: height / 2
    
    readonly property bool isSpotlightMode: root.launcherContent && root.launcherContent.isSpotlight
    
    color: Appearance.m3colors.m3surfaceContainerHigh
    
    // Removed the separator line as it was causing visual issues.
    
    property var launcherContent

    Row {
        anchors.fill: parent
        anchors.leftMargin: 20 * Appearance.effectiveScale
        anchors.rightMargin: 20 * Appearance.effectiveScale
        spacing: 8 * Appearance.effectiveScale
        
        TextInput {
            id: input
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - searchIcon.width - parent.spacing
            font.pixelSize: Appearance.font.pixelSize.normal
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

            Connections {
                target: LauncherSearch
                function onQueryChanged() {
                    if (input && input.text !== LauncherSearch.query) {
                        input.text = LauncherSearch.query;
                        if (input.cursorPosition < input.length) input.cursorPosition = input.length;
                        input.forceActiveFocus();
                    }
                }
            }

            Text {
                text: root.isSpotlightMode ? I18nService.tr("Search for anything...") : I18nService.tr("Search apps, files or commands...")
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
                
                const isEmojiGrid = LauncherSearch.isEmojiMode;
                const isWallGrid = LauncherSearch.isWallMode;
                const emojiFlat = isEmojiGrid && root.launcherContent && root.launcherContent.emojiView ? root.launcherContent.emojiView.flat : null;
                const navResults = isEmojiGrid ? emojiFlat : LauncherSearch.results;
                const total = navResults ? navResults.length : 0;
                if (total <= 0) return;

                const isGrid = (!root.isSpotlightMode && !LauncherSearch.isPluginSearch && !LauncherSearch.query) || isEmojiGrid || isWallGrid;
                let cols = 1;
                if (isGrid) {
                    if (isEmojiGrid) cols = root.launcherContent.emojiColumns;
                    else if (isWallGrid) cols = root.launcherContent.wallColumns || 2;
                    else cols = root.launcherContent.gridColumns || 5;
                }
                const lc = root.launcherContent;

                if (event.key === Qt.Key_Up) {
                    lc.isKeyboardNavigation = true;
                    if (isEmojiGrid) lc.selectedIndex = lc.emojiNavigate(0, -1);
                    else if (isWallGrid) lc.selectedIndex = lc.wallNavigate(0, -1);
                    else lc.selectedIndex = Math.max(0, lc.selectedIndex - cols);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    lc.isKeyboardNavigation = true;
                    if (isEmojiGrid) lc.selectedIndex = lc.emojiNavigate(0, 1);
                    else if (isWallGrid) lc.selectedIndex = lc.wallNavigate(0, 1);
                    else lc.selectedIndex = Math.min(Math.max(0, total - 1), lc.selectedIndex + cols);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left) {
                    if (isGrid) {
                        lc.isKeyboardNavigation = true;
                        if (isEmojiGrid) lc.selectedIndex = lc.emojiNavigate(-1, 0);
                        else if (isWallGrid) lc.selectedIndex = lc.wallNavigate(-1, 0);
                        else lc.selectedIndex = Math.max(0, lc.selectedIndex - 1);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Right) {
                    if (isGrid) {
                        lc.isKeyboardNavigation = true;
                        if (isEmojiGrid) lc.selectedIndex = lc.emojiNavigate(1, 0);
                        else if (isWallGrid) lc.selectedIndex = lc.wallNavigate(1, 0);
                        else lc.selectedIndex = Math.min(total - 1, lc.selectedIndex + 1);
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Delete) {
                    if (LauncherSearch.isClipboardMode && lc.selectedIndex >= 0 && lc.selectedIndex < total) {
                        LauncherSearch.deleteClipboardItem(LauncherSearch.results[lc.selectedIndex]);
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
            iconSize: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3onSurfaceVariant
            visible: !root.isSpotlightMode
        }
    }
}
