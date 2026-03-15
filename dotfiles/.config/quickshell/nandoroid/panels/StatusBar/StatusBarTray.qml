import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../core"
import "../../widgets"

RowLayout {
    id: root
    spacing: 6
    implicitHeight: 16
    visible: SystemTray.items.values.length > 0

    readonly property string trayStyle: Config.options.statusBar.trayStyle
    readonly property var allItems: SystemTray.items.values
    
    readonly property var mainModel: {
        const items = allItems;
        if (trayStyle === "all") return items;
        if (trayStyle === "hide") return [];
        // adaptive
        if (items.length <= 3) return items;
        return items.slice(0, 2);
    }

    readonly property var overflowModel: {
        const items = allItems;
        if (trayStyle === "all") return [];
        if (trayStyle === "hide") return items;
        // adaptive
        if (items.length <= 3) return [];
        return items.slice(2);
    }

    property var activeMenu: null

    HyprlandFocusGrab {
        id: focusGrab
        active: root.activeMenu !== null
        windows: [root.activeMenu]
        onCleared: {
            if (root.activeMenu) root.activeMenu.visible = false;
            root.activeMenu = null;
        }
    }

    // Expand / Collapse Button
    MouseArea {
        id: expandButton
        visible: overflowModel.length > 0
        implicitWidth: 16
        implicitHeight: 16
        cursorShape: Qt.PointingHandCursor
        
        function updateGlobalPos() {
            if (visible) {
                const pos = mapToItem(null, 0, 0);
                GlobalStates.trayPosX = pos.x;
            }
        }

        onXChanged: updateGlobalPos()
        onVisibleChanged: updateGlobalPos()
        Component.onCompleted: updateGlobalPos()

        MaterialSymbol {
            anchors.centerIn: parent
            text: GlobalStates.trayOverflowOpen ? "expand_less" : "expand_more"
            iconSize: 20
        }

        onClicked: {
            updateGlobalPos();
            GlobalStates.trayOverflowOpen = !GlobalStates.trayOverflowOpen
        }
    }

    Repeater {
        model: mainModel
        delegate: StatusBarTrayItem {
            required property SystemTrayItem modelData
            item: modelData
            onMenuOpened: (menu) => root.activeMenu = menu
        }
    }
}

