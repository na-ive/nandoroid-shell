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

PanelWindow {
    id: overviewPopup

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Get this screen's visibility state
    readonly property var screenVisibilities: GlobalStates
    readonly property bool overviewOpen: GlobalStates.overviewOpen

    visible: overviewOpen
    exclusionMode: ExclusionMode.Ignore

    // Mask to capture input on the entire window when open
    mask: Region {
        item: overviewOpen ? fullMask : emptyMask
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
        active: overviewOpen

        onCleared: {
            // Use Qt.callLater to avoid potential race conditions
            Qt.callLater(() => {
                if (overviewOpen) {
                    GlobalStates.closeAllPanels();
                }
            });
        }
    }

    // Semi-transparent backdrop
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#80000000"
        opacity: overviewOpen ? 0.5 : 0

        Behavior on opacity {
            enabled: 250 > 0
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
        width: Math.max(searchContainer.width, overviewContainer.width + (scrollbarContainer.visible ? scrollbarContainer.width + 8 : 0))
        height: searchContainer.height + 8 + overviewContainer.height

        opacity: overviewOpen ? 1 : 0
        scale: overviewOpen ? 1 : 0.9

        Behavior on opacity {
            enabled: 250 > 0
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuart
            }
        }

        Behavior on scale {
            enabled: 250 > 0
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.2
            }
        }

        // Search input container
        Rectangle {
            id: searchContainer
            color: Appearance.colors.colLayer1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(400, overviewContainer.width)
            height: 80
            radius: (24)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Icon container
                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "grid_view"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 24
                        color: Appearance.colors.colPrimary
                    }
                }

                // Search input
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter

                    placeholderText: qsTr("Search windows...")
                    color: Appearance && Appearance.colors && Appearance.colors.colOnLayer1 ? Appearance.colors.colOnLayer1 : "white"
                    placeholderTextColor: Appearance && Appearance.m3colors && Appearance.m3colors.m3onSurfaceVariant ? Appearance.m3colors.m3onSurfaceVariant : "gray"
                    font.pixelSize: Appearance && Appearance.font && Appearance.font.pixelSize && Appearance.font.pixelSize.medium ? Appearance.font.pixelSize.medium : 14
                    font.family: Appearance && Appearance.font && Appearance.font.family && Appearance.font.family.main ? Appearance.font.family.main : "sans-serif"

                    background: Rectangle {
                        color: "transparent"
                    }

                    // Match counter suffix
                    Text {
                        id: matchCounter
                        visible: overviewLoader.item && overviewLoader.item.searchQuery.length > 0
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            if (!overviewLoader.item)
                                return "0";
                            const matches = overviewLoader.item.matchingWindows.length;
                            if (matches > 0) {
                                return `${overviewLoader.item.selectedMatchIndex + 1}/${matches}`;
                            }
                            return "0";
                        }
                        font.family: Appearance && Appearance.font && Appearance.font.family && Appearance.font.family.main ? Appearance.font.family.main : "sans-serif"
                        font.pixelSize: Appearance && Appearance.font && Appearance.font.pixelSize && Appearance.font.pixelSize.small ? Appearance.font.pixelSize.small : 12
                        color: (overviewLoader.item && overviewLoader.item.matchingWindows.length > 0) ? (Appearance && Appearance.colors && Appearance.colors.colPrimary ? Appearance.colors.colPrimary : "blue") : (Appearance && Appearance.m3colors && Appearance.m3colors.m3error ? Appearance.m3colors.m3error : "red")
                        opacity: 0.8
                    }

                    onTextEdited: {
                        if (overviewLoader.item) {
                            overviewLoader.item.searchQuery = text;
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
                            searchInput.clear();
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
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: overviewLoader.item ? overviewLoader.item.implicitWidth + 48 : 400
            height: overviewLoader.item ? overviewLoader.item.implicitHeight + 48 : 300

            // Background panel
            Rectangle {
                id: overviewBackground
                color: Appearance.colors.colLayer1
                anchors.fill: parent
                radius: (20)
            }

            // Loader for Overview to prevent issues during destruction
            Loader {
                id: overviewLoader
                anchors.centerIn: parent
                active: overviewOpen

                sourceComponent: OverviewView {
                    currentScreen: overviewPopup.screen
                }
            }
        }

        // External scrollbar for scrolling mode (to the right of overview)
        Rectangle {
            id: scrollbarContainer
            visible: overviewLoader.item && overviewLoader.item.needsScrollbar
            color: Appearance.colors.colLayer1
            anchors.left: overviewContainer.right
            anchors.leftMargin: 8
            anchors.verticalCenter: overviewContainer.verticalCenter
            width: 32
            height: Math.max(overviewContainer.height * 0.6, 200)
            radius: (0)

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
                height: parent.height - 16
                width: 12
                orientation: Qt.Vertical
                policy: ScrollBar.AlwaysOn

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
                    implicitWidth: 12
                    radius: (-10)
                    color: externalScrollBar.pressed ? Appearance.colors.colPrimary : (externalScrollBar.hovered ? Qt.lighter(Appearance.colors.colPrimary, 1.2) : Appearance.colors.colPrimary)

                    Behavior on color {
                        enabled: 250 > 0
                        ColorAnimation {
                            duration: 250 / 2
                        }
                    }
                }

                background: Rectangle {
                    implicitWidth: 12
                    radius: (-10)
                    color: Appearance.m3colors.m3surfaceContainer
                    opacity: 0.3
                }
            }
        }
    }

    // Ensure focus when overview opens
    onOverviewOpenChanged: {
        if (overviewOpen) {
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
