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
 * Optimized for stability with reordering buttons.
 */
PanelWindow {
    id: root
    visible: false
    
    anchors { top: true; bottom: true; left: true; right: true }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nandoroid:dock-context-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    
    property var appToplevel: null
    property string appId: appToplevel ? appToplevel.appId : ""
    
    property bool isPinned: (appToplevel && appId !== "") ? (appToplevel.pinned ?? false) : false
    property int windowCount: (appToplevel && appToplevel.toplevels) ? appToplevel.toplevels.length : 0
    
    property bool isLauncher: false
    readonly property var desktopEntry: isLauncher ? null : (appId ? TaskbarApps.getDesktopEntry(appId) : null)

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
        implicitHeight: menuLayout.implicitHeight + 12 * Appearance.effectiveScale
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        opacity: root.visible ? 0.98 : 0
        scale: root.visible ? 1 : 0.95
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: root.isClosing ? Appearance.animation.elementMoveExit.duration : Appearance.animation.elementMoveEnter.duration; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.isClosing ? Appearance.animation.elementMoveExit.duration : Appearance.animation.elementMoveEnter.duration; easing.type: Easing.OutBack } }

        MouseArea { anchors.fill: parent; onPressed: (mouse) => mouse.accepted = true }

        ColumnLayout {
            id: menuLayout
            anchors.fill: parent; anchors.margins: 4 * Appearance.effectiveScale; spacing: 1 * Appearance.effectiveScale

            // --- APP MODE ---
            ColumnLayout {
                visible: !root.isLauncher
                Layout.fillWidth: true; spacing: 1 * Appearance.effectiveScale
                
                // Reordering Row
                RowLayout {
                    Layout.fillWidth: true; Layout.margins: 0; spacing: 1 * Appearance.effectiveScale
                    
                    RippleButton {
                        Layout.fillWidth: true; Layout.preferredHeight: 24 * Appearance.effectiveScale
                        buttonRadius: Appearance.rounding.verysmall; colBackground: "transparent"
                        contentItem: Item {
                            anchors.fill: parent
                            MaterialSymbol { 
                                text: "arrow_back"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer0; 
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 16 * Appearance.effectiveScale
                            }
                        }
                        onClicked: TaskbarApps.moveApp(root.appId, -1)
                    }
                    
                    Rectangle { Layout.preferredWidth: Math.max(1, 1 * Appearance.effectiveScale); Layout.preferredHeight: 16 * Appearance.effectiveScale; color: Appearance.colors.colOutlineVariant; opacity: 0.1 }
                    
                    RippleButton {
                        Layout.fillWidth: true; Layout.preferredHeight: 24 * Appearance.effectiveScale
                        buttonRadius: Appearance.rounding.verysmall; colBackground: "transparent"
                        contentItem: Item {
                            anchors.fill: parent
                            MaterialSymbol { 
                                text: "arrow_forward"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer0; 
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right; anchors.rightMargin: 16 * Appearance.effectiveScale
                            }
                        }
                        onClicked: TaskbarApps.moveApp(root.appId, 1)
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * Appearance.effectiveScale); Layout.margins: 4 * Appearance.effectiveScale; color: Appearance.colors.colOutlineVariant; opacity: 0.1 }

                // Header
                RowLayout {
                    Layout.fillWidth: true; Layout.leftMargin: 8 * Appearance.effectiveScale; Layout.rightMargin: 8 * Appearance.effectiveScale; Layout.topMargin: 4 * Appearance.effectiveScale; Layout.bottomMargin: 4 * Appearance.effectiveScale; spacing: 8 * Appearance.effectiveScale
                    Item {
                        Layout.preferredWidth: 20 * Appearance.effectiveScale; Layout.preferredHeight: 20 * Appearance.effectiveScale
                        IconImage {
                            anchors.fill: parent
                            source: root.appId ? Quickshell.iconPath(AppSearch.guessIcon(root.appId), "application-x-executable") : ""
                        }
                    }
                    StyledText {
                        text: root.desktopEntry ? root.desktopEntry.name : (root.appId ? (root.appId.charAt(0).toUpperCase() + root.appId.slice(1)) : "Application")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold; color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight; Layout.fillWidth: true
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * Appearance.effectiveScale); Layout.margins: 4 * Appearance.effectiveScale; color: Appearance.colors.colOutlineVariant; opacity: 0.1 }

                // Jump List
                Repeater {
                    model: (root.desktopEntry && root.desktopEntry.actions) ? root.desktopEntry.actions : []
                    delegate: MenuItem {
                        menuText: modelData.name; menuIcon: modelData.icon || "bolt"
                        isXdgIcon: modelData.icon !== undefined && modelData.icon !== ""
                        onClicked: { modelData.execute(); root.close() }
                    }
                }

                MenuItem {
                    visible: root.appId !== "" && (!root.desktopEntry || !root.desktopEntry.actions || root.desktopEntry.actions.length === 0)
                    menuText: "New Window"; menuIcon: "add_box"
                    onClicked: { 
                        if (root.desktopEntry) root.desktopEntry.execute();
                        else Quickshell.execDetached([root.appId]);
                        root.close();
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * Appearance.effectiveScale); Layout.margins: 4 * Appearance.effectiveScale; color: Appearance.colors.colOutlineVariant; opacity: 0.1 }

                MenuItem {
                    menuText: root.isPinned ? "Unpin from Dock" : "Pin to Dock"
                    menuIcon: root.isPinned ? "keep_off" : "keep"
                    onClicked: { TaskbarApps.togglePin(root.appId); root.close() }
                }

                Rectangle { visible: root.windowCount > 0; Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * Appearance.effectiveScale); Layout.margins: 4 * Appearance.effectiveScale; color: Appearance.colors.colOutlineVariant; opacity: 0.1 }

                MenuItem {
                    visible: root.windowCount > 0
                    menuText: root.windowCount > 1 ? "Close All Windows" : "Close Window"; menuIcon: "close"
                    onClicked: {
                        if (root.appToplevel && root.appToplevel.toplevels) {
                            const windows = root.appToplevel.toplevels;
                            for (let i = 0; i < windows.length; i++) { if (windows[i]) windows[i].close(); }
                        }
                        root.close();
                    }
                }

                MenuItem {
                    visible: root.windowCount > 0
                    menuText: "Force Close"; menuIcon: "gavel"
                    onClicked: {
                        if (root.appToplevel && root.appToplevel.toplevels && root.appToplevel.toplevels.length > 0) {
                            const tl = root.appToplevel.toplevels[0];
                            if (tl && tl.pid) {
                                killProc.command = ["kill", "-9", tl.pid.toString()];
                                killProc.running = true;
                            }
                        }
                        root.close();
                    }
                }
            }

            // --- LAUNCHER MODE ---
            ColumnLayout {
                visible: root.isLauncher
                Layout.fillWidth: true; spacing: 1 * Appearance.effectiveScale
                MenuItem {
                    menuText: "Restart Shell"; menuIcon: "refresh"
                    onClicked: { Quickshell.execDetached([Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/scripts/restartshell.sh"]); root.close() }
                }
                MenuItem {
                    menuText: "Restart Fix"; menuIcon: "build"
                    onClicked: { Quickshell.execDetached([Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/scripts/restart_fix.sh"]); root.close() }
                }
                MenuItem {
                    menuText: "Settings"; menuIcon: "settings"
                    onClicked: { GlobalStates.activateSettings(); root.close() }
                }
                MenuItem {
                    menuText: "System Monitor"; menuIcon: "monitoring"
                    onClicked: { GlobalStates.activateSystemMonitor(); root.close() }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: Math.max(1, 1 * Appearance.effectiveScale); Layout.margins: 4 * Appearance.effectiveScale; color: Appearance.colors.colOutlineVariant; opacity: 0.1 }
                MenuItem { menuText: "Lock Session"; menuIcon: "lock"; onClicked: { Session.lock(); root.close() } }
                MenuItem { menuText: "Logout"; menuIcon: "logout"; onClicked: { Session.logout(); root.close() } }
                MenuItem { menuText: "Reboot"; menuIcon: "restart_alt"; onClicked: { Session.reboot(); root.close() } }
                MenuItem { menuText: "Power Off"; menuIcon: "power_settings_new"; onClicked: { Session.poweroff(); root.close() } }
            }
        }
    }

    Process { id: killProc }

    component MenuItem : RippleButton {
        id: itemRoot
        property string menuText: ""; property string menuIcon: ""
        property bool isXdgIcon: false
        Layout.fillWidth: true; Layout.preferredHeight: 32 * Appearance.effectiveScale
        buttonRadius: Appearance.rounding.verysmall; colBackground: "transparent"
        contentItem: RowLayout {
            anchors.fill: parent; anchors.leftMargin: 8 * Appearance.effectiveScale; anchors.rightMargin: 8 * Appearance.effectiveScale; spacing: 8 * Appearance.effectiveScale
            Item {
                Layout.preferredWidth: 18 * Appearance.effectiveScale; Layout.preferredHeight: 18 * Appearance.effectiveScale
                MaterialSymbol {
                    anchors.fill: parent
                    visible: !itemRoot.isXdgIcon
                    text: itemRoot.menuIcon; iconSize: 18 * Appearance.effectiveScale
                    fill: (itemRoot.menuIcon === "power_settings_new" || itemRoot.menuIcon === "logout" || itemRoot.menuIcon === "restart_alt") ? 1 : 0
                    color: (itemRoot.menuIcon === "close" || itemRoot.menuIcon === "gavel" || itemRoot.menuIcon === "power_settings_new" || itemRoot.menuIcon === "logout" || itemRoot.menuIcon === "restart_alt") ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                }
                IconImage {
                    anchors.fill: parent
                    visible: itemRoot.isXdgIcon
                    source: itemRoot.isXdgIcon ? (Quickshell.iconPath(itemRoot.menuIcon, "application-x-executable") || "") : ""
                }
            }
            StyledText {
                text: itemRoot.menuText; font.pixelSize: Appearance.font.pixelSize.small
                color: (itemRoot.menuIcon === "close" || itemRoot.menuIcon === "gavel" || itemRoot.menuIcon === "power_settings_new" || itemRoot.menuIcon === "logout" || itemRoot.menuIcon === "restart_alt") ? Appearance.colors.colError : Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
        }
    }

    property bool isClosing: false
    Timer {
        id: hideTimer; interval: Appearance.animation.elementMoveExit.duration
        onTriggered: { root.visible = false; root.isClosing = false; GlobalStates.dockMenuOpen = false }
    }

    function openAt(mouseX, mouseY, appData = null) {
        hideTimer.stop();
        isClosing = false;
        appToplevel = appData;
        isLauncher = (appData === null);
        root._mouseX = mouseX; root._mouseY = mouseY;
        root.visible = true;
        GlobalStates.dockMenuOpen = true;
        
        Qt.callLater(() => {
            if (!root.visible) return;
            const screenWidth = root.screen.width;
            const screenHeight = root.screen.height;
            const menuWidth = Appearance.sizes.contextMenuWidth;
            const menuHeight = menuLayout.implicitHeight + 12 * Appearance.effectiveScale;
            root.targetX = Math.min(root._mouseX, screenWidth - menuWidth - 10 * Appearance.effectiveScale);
            if (root._mouseY + menuHeight > screenHeight - 10 * Appearance.effectiveScale) root.targetY = root._mouseY - menuHeight;
            else root.targetY = root._mouseY;
            root.targetY = Math.max(10 * Appearance.effectiveScale, root.targetY);
            menuContainer.opacity = 0.98; menuContainer.scale = 1;
        });
    }

    function close() {
        if (!visible || isClosing) return;
        isClosing = true;
        menuContainer.opacity = 0; menuContainer.scale = 0.95;
        hideTimer.restart();
    }

    HyprlandFocusGrab {
        active: root.visible && !root.isClosing
        windows: [root]
        onCleared: root.close()
    }
}
