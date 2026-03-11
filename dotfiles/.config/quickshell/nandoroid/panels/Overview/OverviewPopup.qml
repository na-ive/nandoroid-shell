import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../core"
import "../../services"
import "../../widgets"
import "../../core"
import "."

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: overviewPopup
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: GlobalStates.overviewOpen && isActive

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"

        WlrLayershell.layer: (GlobalStates.overviewOpen && isActive) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.keyboardFocus: (GlobalStates.overviewOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Get this screen's visibility state
        readonly property bool overviewOpen: GlobalStates.overviewOpen && isActive

        exclusionMode: ExclusionMode.Ignore

        // Mask to capture input on the entire window when open
        mask: Region {
            item: (GlobalStates.overviewOpen && isActive) ? fullMask : emptyMask
        }

        // Full screen mask when open
        Item {
            id: fullMask
            anchors.fill: parent
        }

        // Empty mask when hidden
        Item {
            id: emptyMask
            width: 0
            height: 0
        }

        HyprlandFocusGrab {
            id: focusGrab
            windows: [overviewPopup]
            active: GlobalStates.overviewOpen && isActive

            onCleared: {
                // Use Qt.callLater to avoid potential race conditions
                Qt.callLater(() => {
                    if (GlobalStates.overviewOpen && isActive) {
                        GlobalStates.closeAllPanels();
                    }
                });
            }
        }

        // Semi-transparent backdrop
        Rectangle {
            id: backdrop
            anchors.fill: parent
            color: Appearance.colors.colScrim
            opacity: (GlobalStates.overviewOpen && isActive) ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutQuart
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    GlobalStates.closeAllPanels();
                }
            }
        }

        // Main content column (search + overview)
        Item {
            id: mainContainer
            anchors.centerIn: parent
            width: Math.max(searchContainer.width, overviewContainer.width)
            height: searchContainer.height + 16 + overviewContainer.height

            opacity: (GlobalStates.overviewOpen && isActive) ? 1 : 0
            scale: (GlobalStates.overviewOpen && isActive) ? 1 : 0.9

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutQuart
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }

            // Search input container - Android Pill Style
            Rectangle {
                id: searchContainer
                color: Appearance.m3colors.m3surfaceContainerHigh
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(480, Math.max(300, overviewContainer.width * 0.6))
                height: 56
                radius: 28

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    // Icon container
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignVCenter
                        text: "search"
                        iconSize: 22
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }

                    // Search input
                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        
                        font.pixelSize: 18
                        color: Appearance.m3colors.m3onSurface
                        focus: true

                        Timer {
                            id: focusTimer
                            interval: 50
                            repeat: false
                            onTriggered: searchInput.forceActiveFocus()
                        }

                        Component.onCompleted: {
                            if (GlobalStates.overviewOpen && isActive) focusTimer.start();
                        }

                        Connections {
                            target: GlobalStates
                            function onOverviewOpenChanged() {
                                if (GlobalStates.overviewOpen && isActive) {
                                    if (searchInput) searchInput.text = "";
                                    if (overviewLoader.item) overviewLoader.item.searchQuery = "";
                                    focusTimer.start();
                                }
                            }
                        }

                        Text {
                            text: "Search windows..."
                            visible: !searchInput.text
                            color: Appearance.m3colors.m3onSurfaceVariant
                            opacity: 0.6
                            font: searchInput.font
                        }

                        // Match counter suffix
                        Text {
                            id: matchCounter
                            visible: overviewLoader.item && overviewLoader.item.searchQuery.length > 0
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (!overviewLoader.item) return "0";
                                const matches = overviewLoader.item.matchingWindows.length;
                                if (matches > 0) {
                                    return `${overviewLoader.item.selectedMatchIndex + 1}/${matches}`;
                                }
                                return "0";
                            }
                            font: searchInput.font
                            color: (overviewLoader.item && overviewLoader.item.matchingWindows.length > 0) ? Appearance.colors.colPrimary : Appearance.m3colors.m3error
                            opacity: 0.8
                        }

                        onTextChanged: {
                            debounceTimer.restart()
                        }

                        Timer {
                            id: debounceTimer
                            interval: 20
                            onTriggered: {
                                if (overviewLoader.item) {
                                    overviewLoader.item.searchQuery = searchInput.text;
                                }
                            }
                        }

                        onAccepted: {
                            if (overviewLoader.item) {
                                overviewLoader.item.navigateToSelectedWindow();
                            }
                        }

                        Keys.onTabPressed: event => {
                            if (searchInput.text.length === 0) {
                                const current = Hyprland.focusedWorkspace?.id || 1;
                                const next = current + 1;
                                if (next > Config.workspaces.shown) {
                                    Hyprland.dispatch("workspace 1");
                                } else {
                                    Hyprland.dispatch("workspace r+1");
                                }
                            } else if (overviewLoader.item) {
                                overviewLoader.item.selectNextMatch();
                            }
                            event.accepted = true;
                        }
                        
                        Keys.onBacktabPressed: event => {
                            if (searchInput.text.length === 0) {
                                const current = Hyprland.focusedWorkspace?.id || 1;
                                const prev = current - 1;
                                if (prev < 1) {
                                    Hyprland.dispatch("workspace " + Config.workspaces.shown);
                                } else {
                                    Hyprland.dispatch("workspace r-1");
                                }
                            } else if (overviewLoader.item) {
                                overviewLoader.item.selectPrevMatch();
                            }
                            event.accepted = true;
                        }

                        Keys.onDownPressed: event => {
                            if (overviewLoader.item) {
                                overviewLoader.item.selectNextMatch();
                            }
                            event.accepted = true;
                        }

                        Keys.onUpPressed: event => {
                            if (overviewLoader.item) {
                                overviewLoader.item.selectPrevMatch();
                            }
                            event.accepted = true;
                        }

                        Keys.onEscapePressed: event => {
                            if (searchInput.text.length > 0) {
                                searchInput.text = "";
                                if (overviewLoader.item) {
                                    overviewLoader.item.searchQuery = "";
                                }
                            } else {
                                GlobalStates.closeAllPanels();
                            }
                            event.accepted = true;
                        }

                        Keys.onLeftPressed: event => {
                            if (searchInput.text.length === 0) {
                                const current = Hyprland.focusedWorkspace?.id || 1;
                                const prev = current - 1;
                                if (prev < 1) {
                                    Hyprland.dispatch("workspace " + Config.workspaces.shown);
                                } else {
                                    Hyprland.dispatch("workspace r-1");
                                }
                            } else if (overviewLoader.item) {
                                overviewLoader.item.selectPrevMatch();
                            }
                            event.accepted = true;
                        }

                        Keys.onRightPressed: event => {
                            if (searchInput.text.length === 0) {
                                const current = Hyprland.focusedWorkspace?.id || 1;
                                const next = current + 1;
                                if (next > Config.workspaces.shown) {
                                    Hyprland.dispatch("workspace 1");
                                } else {
                                    Hyprland.dispatch("workspace r+1");
                                }
                            } else if (overviewLoader.item) {
                                overviewLoader.item.selectNextMatch();
                            }
                            event.accepted = true;
                        }
                        
                        function focusInput() {
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }

            // Overview container
            Item {
                id: overviewContainer
                anchors.top: searchContainer.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                property real loaderWidth: overviewLoader.item ? overviewLoader.item.implicitWidth : 368
                property real loaderHeight: overviewLoader.item ? overviewLoader.item.implicitHeight : 300
                property bool showScrollbar: overviewLoader.item && overviewLoader.item.needsScrollbar
                
                width: loaderWidth + 32 + (showScrollbar ? 16 : 0)
                height: loaderHeight + 32

                // Background panel
                Rectangle {
                    id: overviewBackground
                    color: Appearance.colors.colLayer1
                    anchors.fill: parent
                    radius: Appearance.rounding.panel
                }

                // Loader for Overview to prevent issues during destruction
                Loader {
                    id: overviewLoader
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: item ? item.implicitWidth : 0
                    height: item ? item.implicitHeight : 0
                    active: GlobalStates.overviewOpen && isActive

                    sourceComponent: OverviewView {
                        currentScreen: overviewPopup.screen
                    }
                }

                // Internal scrollbar for scrolling mode (anchored to the right of overview)
                Rectangle {
                    id: scrollbarContainer
                    visible: overviewContainer.showScrollbar
                    color: "transparent"
                    anchors.left: overviewLoader.right
                    anchors.leftMargin: 12
                    anchors.top: overviewLoader.top
                    anchors.bottom: overviewLoader.bottom
                    width: 8

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        onWheel: wheel => {
                            if (overviewLoader.item && overviewLoader.item.flickable) {
                                const flickable = overviewLoader.item.flickable;
                                const delta = wheel.angleDelta.y > 0 ? -150 : 150;
                                flickable.contentY = Math.max(0, Math.min(flickable.contentY + delta, flickable.contentHeight - flickable.height));
                            }
                        }
                    }

                    ScrollBar {
                        id: externalScrollBar
                        anchors.centerIn: parent
                        height: parent.height
                        width: 8
                        orientation: Qt.Vertical
                        policy: ScrollBar.AlwaysOn
                        padding: 0

                        position: overviewLoader.item && overviewLoader.item.flickable ? overviewLoader.item.flickable.visibleArea.yPosition : 0
                        size: overviewLoader.item && overviewLoader.item.flickable ? overviewLoader.item.flickable.visibleArea.heightRatio : 1

                        // Notify flickable when manually scrolling to disable animation
                        onActiveChanged: {
                            if (overviewLoader.item) {
                                overviewLoader.item.isManualScrolling = active;
                            }
                        }

                        onPositionChanged: {
                            if (active && overviewLoader.item && overviewLoader.item.flickable) {
                                overviewLoader.item.flickable.contentY = position * overviewLoader.item.flickable.contentHeight;
                            }
                        }

                        contentItem: Rectangle {
                            implicitWidth: 8
                            radius: 4
                            color: Appearance.colors.colPrimary

                            Behavior on color {
                                ColorAnimation {
                                    duration: 250 / 2
                                }
                            }
                        }

                        background: Rectangle {
                            implicitWidth: 8
                            radius: 4
                            color: Appearance.colors.colLayer0
                            opacity: 0.5
                        }
                    }
                }
            }
        }

        // Ensure focus when overview opens
        onOverviewOpenChanged: {
            if (GlobalStates.overviewOpen && isActive) {
                Qt.callLater(() => {
                    searchInput.clear();
                    if (overviewLoader.item) {
                        overviewLoader.item.resetSearch();
                    }
                    searchInput.focusInput();
                });
            }
        }
    }
}
