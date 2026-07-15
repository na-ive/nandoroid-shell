import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: (GlobalStates.trayOverflowOpen && isActive) || content.opacity > 0
        
        WlrLayershell.namespace: "nandoroid:trayoverflow"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        property var activeMenu: null

        HyprlandFocusGrab {
            id: focusGrab
            active: panelWindow.activeMenu !== null
            windows: [panelWindow.activeMenu]
            onCleared: {
                if (panelWindow.activeMenu) panelWindow.activeMenu.visible = false;
                panelWindow.activeMenu = null;
            }
        }

        // PanelWindow supports anchors in this project
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Background click area to close
        MouseArea {
            anchors.fill: parent
            onPressed: GlobalStates.trayOverflowOpen = false
        }

        readonly property var overflowModel: {
            const items = SystemTray.items.values;
            const style = Config.ready && Config.options.statusBar ? Config.options.statusBar.trayStyle : "adaptive";
            if (style === "all") return [];
            if (style === "hide") return items;
            if (items.length <= 3) return [];
            return items.slice(2);
        }

        onOverflowModelChanged: {
            if (overflowModel.length === 0 && GlobalStates.trayOverflowOpen) {
                GlobalStates.trayOverflowOpen = false;
            }
        }

        Rectangle {
            id: content
            // Position it exactly below the expand arrow
            // We subtract half width of content and add half width of arrow (8) to center it
            // but align it within screen bounds (20 margin)
            x: Math.max(20 * Appearance.effectiveScale, Math.min(parent.width - width - 20 * Appearance.effectiveScale, GlobalStates.trayPosX - (width / 2) + 8 * Appearance.effectiveScale))
            
            readonly property bool isM3: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.moduleStyle === "m3" : false
            readonly property real actualStatusBarHeight: isM3 ? 48 * Appearance.effectiveScale : (Config.ready ? Config.options.statusBar.height * Appearance.effectiveScale : 40 * Appearance.effectiveScale)
            
            y: actualStatusBarHeight + 2 * Appearance.effectiveScale
            
            width: contentLayout.implicitWidth + 24 * Appearance.effectiveScale
            height: contentLayout.implicitHeight + 24 * Appearance.effectiveScale
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer0
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
            border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

            opacity: GlobalStates.trayOverflowOpen ? 1 : 0
            scale: GlobalStates.trayOverflowOpen ? 1 : 0.9
            
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

            // Prevent clicks inside from closing the popup
            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => mouse.accepted = true
            }

            GridLayout {
                id: contentLayout
                anchors.centerIn: parent
                columns: Math.max(3, Math.ceil(Math.sqrt(overflowRepeater.count)))
                columnSpacing: 12 * Appearance.effectiveScale
                rowSpacing: 12 * Appearance.effectiveScale

                Repeater {
                    id: overflowRepeater
                    model: panelWindow.overflowModel
                    delegate: StatusBarTrayItem {
                        id: trayItem
                        required property SystemTrayItem modelData
                        item: modelData
                        implicitWidth: 24 * Appearance.effectiveScale
                        implicitHeight: 24 * Appearance.effectiveScale
                        
                        property var currentMenu: null

                        onMenuOpened: (menu) => {
                            panelWindow.activeMenu = menu;
                            trayItem.currentMenu = menu;
                        }
                        onMenuClosed: () => {
                            if (panelWindow.activeMenu === trayItem.currentMenu) panelWindow.activeMenu = null;
                            trayItem.currentMenu = null;
                        }
                    }
                }
            }
        }
    }
}
