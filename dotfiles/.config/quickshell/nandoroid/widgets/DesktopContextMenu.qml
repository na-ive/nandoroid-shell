import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../core"
import "../services"

/**
 * DesktopContextMenu.qml
 * A modern, premium right-click menu for the desktop.
 */
PopupWindow {
    id: root
    visible: false
    
    property bool isClockMenu: false
    
    color: "transparent"
    
    // Width and height based on content
    implicitWidth: menuContainer.implicitWidth
    implicitHeight: menuContainer.implicitHeight

    Rectangle {
        id: menuContainer
        anchors.fill: parent
        implicitWidth: Appearance.sizes.contextMenuWidth
        implicitHeight: menuLayout.implicitHeight + 12
        
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1
        
        // Glassmorphism effect
        opacity: 0
        scale: 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: root.isClosing ? Appearance.animation.elementMoveExit.duration : Appearance.animation.elementMoveEnter.duration
                easing.bezierCurve: root.isClosing ? Appearance.animationCurves.emphasizedAccel : Appearance.animationCurves.expressiveDefaultSpatial
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: root.isClosing ? Appearance.animation.elementMoveExit.duration : Appearance.animation.elementMoveEnter.duration
                easing.bezierCurve: root.isClosing ? Appearance.animationCurves.emphasizedAccel : Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        ColumnLayout {
            id: menuLayout
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            // --- Clock Specific Items ---
            MenuItem {
                visible: root.isClockMenu
                menuText: Config.options.appearance.clock.locked ? "Unlock Clock Position" : "Lock Clock Position"
                menuIcon: Config.options.appearance.clock.locked ? "lock_open" : "lock"
                onClicked: {
                    Config.options.appearance.clock.locked = !Config.options.appearance.clock.locked
                    root.close()
                }
            }

            MenuItem {
                visible: root.isClockMenu
                menuText: "Clock Settings"
                menuIcon: "schedule"
                onClicked: {
                    GlobalStates.settingsPageIndex = 4 // Wallpaper & Style
                    SearchRegistry.currentSearch = "Clock Style"
                    GlobalStates.settingsOpen = true
                    root.close()
                }
            }

            // --- General Desktop Items ---
            MenuItem {
                visible: !root.isClockMenu
                menuText: "Search (Spotlight)"
                menuIcon: "search"
                onClicked: {
                    GlobalStates.spotlightOpen = true
                    root.close()
                }
            }

            MenuItem {
                visible: !root.isClockMenu
                menuText: "Overview"
                menuIcon: "grid_view"
                onClicked: {
                    GlobalStates.overviewOpen = true
                    root.close()
                }
            }

            MenuItem {
                visible: !root.isClockMenu
                menuText: "Wallpaper & Styles"
                menuIcon: "palette"
                onClicked: {
                    GlobalStates.settingsPageIndex = 4 // Wallpaper & Style
                    GlobalStates.settingsOpen = true
                    root.close()
                }
            }
            
            MenuItem {
                visible: !root.isClockMenu
                menuText: "Dashboard"
                menuIcon: "dashboard"
                onClicked: {
                    GlobalStates.dashboardOpen = true
                    root.close()
                }
            }

            // Separator
            Rectangle {
                visible: !root.isClockMenu
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                color: Appearance.colors.colOutlineVariant
                opacity: 0.3
            }

            MenuItem {
                visible: !root.isClockMenu
                menuText: "System Monitor"
                menuIcon: "monitoring"
                onClicked: {
                    GlobalStates.systemMonitorOpen = true
                    root.close()
                }
            }
            
            MenuItem {
                visible: !root.isClockMenu
                menuText: "Terminal"
                menuIcon: "terminal"
                onClicked: {
                    terminalProcess.running = true
                    root.close()
                }
            }

            MenuItem {
                visible: !root.isClockMenu
                menuText: "Lock Screen"
                menuIcon: "lock"
                onClicked: {
                    GlobalStates.screenLocked = true
                    root.close() // Use animated close
                }
            }
        }
    }

    Process {
        id: terminalProcess
        command: ["kitty"]
    }

    // Helper component for menu items
    component MenuItem : RippleButton {
        id: itemRoot
        property string menuText: ""
        property string menuIcon: ""
        
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.sizes.contextMenuItemHeight
        
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            
            MaterialSymbol {
                text: itemRoot.menuIcon
                iconSize: Appearance.sizes.iconSize * 0.9
                color: Appearance.colors.colOnLayer0
            }
            
            StyledText {
                text: itemRoot.menuText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
        }
    }

    // Animation state
    property bool isClosing: false

    Timer {
        id: hideTimer
        interval: Appearance.animation.elementMoveExit.duration
        onTriggered: {
            root.visible = false;
            root.isClosing = false;
        }
    }

    function openAt(x, y, isClock) {
        hideTimer.stop();
        isClosing = false;
        isClockMenu = isClock;
        root.anchor.rect = Qt.rect(x, y, 0, 0);
        root.visible = true;
        // Use callLater to ensure properties are applied after visible = true
        Qt.callLater(() => {
            menuContainer.opacity = 0.98; // Adjusted from 1 to keep slight glass effect
            menuContainer.scale = 1;
        });
    }

    function close() {
        if (!visible || isClosing) return;
        isClosing = true;
        menuContainer.opacity = 0;
        menuContainer.scale = 0.95;
        hideTimer.start();
    }

    signal menuClosed()
    onVisibleChanged: {
        if (!visible) {
            menuContainer.opacity = 0;
            menuContainer.scale = 0.95;
            menuClosed();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.visible && !root.isClosing
        windows: [root]
        onCleared: root.close()
    }
}
