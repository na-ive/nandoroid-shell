import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

RowLayout {
    id: root
    spacing: 6
    implicitHeight: 16
    visible: SystemTray.items.values.length > 0

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

    Repeater {
        model: SystemTray.items.values
        delegate: StatusBarTrayItem {
            required property SystemTrayItem modelData
            item: modelData
            onMenuOpened: (menu) => root.activeMenu = menu
        }
    }
}
