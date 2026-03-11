import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

/**
 * DockContextMenu.qml
 * A premium full-screen overlay context menu.
 * Supports Desktop Actions (Jump Lists).
 */
PanelWindow {
    id: root
    visible: false
    
    anchors {
        top: true; bottom: true; left: true; right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nandoroid:dock-context-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    property var appToplevel: null
    property string appId: appToplevel ? appToplevel.appId : ""
    property bool isPinned: TaskbarApps.isPinned(appId)
    property int windowCount: appToplevel ? appToplevel.toplevels.length : 0
    
    // Fetch the desktop entry to get its actions (Jump List)
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(root.appId)

    property real targetX: 0
    property real targetY: 0
    property real _mouseX: 0
    property real _mouseY: 0

    color: "transparent"

    MouseArea { anchors.fill: parent; onPressed: root.close() }

    Rectangle {
        id: menuContainer
        x: root.targetX; y: root.targetY
        implicitWidth: Appearance.sizes.contextMenuWidth
        implicitHeight: menuLayout.implicitHeight + 12
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1
        opacity: 0; scale: 0.95

        Behavior on opacity { NumberAnimation { duration: root.isClosing ? Appearance.animation.elementMoveExit.duration : Appearance.animation.elementMoveEnter.duration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.isClosing ? Appearance.animation.elementMoveExit.duration : Appearance.animation.elementMoveEnter.duration; easing.type: Easing.OutBack } }

        MouseArea { anchors.fill: parent; onPressed: (mouse) => mouse.accepted = true }

        ColumnLayout {
            id: menuLayout
            anchors.fill: parent; anchors.margins: 6; spacing: 2

            // Header
            RowLayout {
                Layout.fillWidth: true; Layout.margins: 8; spacing: 12
                IconImage {
                    Layout.preferredWidth: 24; Layout.preferredHeight: 24
                    source: Quickshell.iconPath(AppSearch.guessIcon(root.appId), "application-x-executable")
                }
                StyledText {
                    text: root.appId.charAt(0).toUpperCase() + root.appId.slice(1)
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Bold; color: Appearance.colors.colOnLayer0
                    elide: Text.ElideRight; Layout.fillWidth: true
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.margins: 8; color: Appearance.colors.colOutlineVariant; opacity: 0.2 }

            // --- Desktop Actions (Jump List) ---
            Repeater {
                model: root.desktopEntry ? root.desktopEntry.actions : []
                delegate: MenuItem {
                    menuText: modelData.name
                    menuIcon: "bolt" // Generic action icon
                    onClicked: {
                        modelData.execute();
                        root.close();
                    }
                }
            }

            // Separator if there were actions
            Rectangle { 
                visible: root.desktopEntry && root.desktopEntry.actions.length > 0
                Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.margins: 8; color: Appearance.colors.colOutlineVariant; opacity: 0.2 
            }

            // --- Standard Actions ---
            MenuItem {
                menuText: root.isPinned ? "Unpin from Dock" : "Pin to Dock"
                menuIcon: root.isPinned ? "keep_off" : "keep"
                onClicked: { TaskbarApps.togglePin(root.appId); root.close() }
            }

            MenuItem {
                // Only show "New Window" if it's not already covered by Desktop Actions
                visible: root.appId !== "" && (!root.desktopEntry || root.desktopEntry.actions.length === 0)
                menuText: "New Window"; menuIcon: "add_box"
                onClicked: { if (root.desktopEntry) root.desktopEntry.execute(); root.close() }
            }

            Rectangle { visible: root.windowCount > 0; Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.margins: 8; color: Appearance.colors.colOutlineVariant; opacity: 0.2 }

            MenuItem {
                visible: root.windowCount > 0
                menuText: root.windowCount > 1 ? "Close All Windows" : "Close Window"; menuIcon: "close"
                onClicked: { for (let i = 0; i < root.appToplevel.toplevels.length; i++) root.appToplevel.toplevels[i].close(); root.close() }
            }

            MenuItem {
                visible: root.appId !== ""
                menuText: "Force Close"; menuIcon: "gavel"
                onClicked: {
                    if (root.appToplevel && root.appToplevel.toplevels) {
                        for (let i = 0; i < root.appToplevel.toplevels.length; i++) {
                            const tl = root.appToplevel.toplevels[i];
                            if (tl.pid && tl.pid > 0) killProc.exec(["kill", "-9", tl.pid.toString()]);
                        }
                    }
                    if (root.appId !== "") killProc.exec(["pkill", "-9", "-f", root.appId]);
                    root.close();
                }
            }
        }
    }

    Process { id: killProc }

    component MenuItem : RippleButton {
        id: itemRoot
        property string menuText: ""; property string menuIcon: ""
        Layout.fillWidth: true; Layout.preferredHeight: Appearance.sizes.contextMenuItemHeight
        buttonRadius: Appearance.rounding.small; colBackground: "transparent"
        contentItem: RowLayout {
            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
            MaterialSymbol {
                text: itemRoot.menuIcon; iconSize: Appearance.sizes.iconSize * 0.8
                color: (itemRoot.menuIcon === "close" || itemRoot.menuIcon === "gavel") ? Appearance.colors.colError : Appearance.colors.colOnLayer0
            }
            StyledText {
                text: itemRoot.menuText; font.pixelSize: Appearance.font.pixelSize.small
                color: (itemRoot.menuIcon === "close" || itemRoot.menuIcon === "gavel") ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
        }
    }

    property bool isClosing: false
    Timer {
        id: hideTimer; interval: Appearance.animation.elementMoveExit.duration
        onTriggered: { root.visible = false; root.isClosing = false; GlobalStates.dockMenuOpen = false }
    }

    function openAt(mouseX, mouseY, appData) {
        hideTimer.stop();
        isClosing = false;
        appToplevel = appData;
        root._mouseX = mouseX;
        root._mouseY = mouseY;
        
        root.visible = true;
        GlobalStates.dockMenuOpen = true;
        
        Qt.callLater(() => {
            const screenWidth = root.screen.width;
            const screenHeight = root.screen.height;
            const menuWidth = Appearance.sizes.contextMenuWidth;
            const menuHeight = menuLayout.implicitHeight + 12;
            
            root.targetX = Math.min(Math.max(10, root._mouseX - 15), screenWidth - menuWidth - 10);
            root.targetY = Math.min(Math.max(10, root._mouseY - menuHeight - 45), screenHeight - menuHeight - 10);
            
            menuContainer.opacity = 0.98;
            menuContainer.scale = 1;
        });
    }

    function close() {
        if (!visible || isClosing) return;
        isClosing = true;
        menuContainer.opacity = 0;
        menuContainer.scale = 0.95;
        hideTimer.restart();
    }

    HyprlandFocusGrab {
        active: root.visible && !root.isClosing
        windows: [root]
        onCleared: root.close()
    }
}
