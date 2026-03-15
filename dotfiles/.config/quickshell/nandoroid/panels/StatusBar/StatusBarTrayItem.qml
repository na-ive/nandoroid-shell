import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"

MouseArea {
    id: root
    required property SystemTrayItem item
    
    signal menuOpened(var menu)

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    
    implicitWidth: 16
    implicitHeight: 16

    onPressed: (event) => {
        if (event.button === Qt.LeftButton) {
            item.activate();
        } else if (event.button === Qt.RightButton) {
            if (item.hasMenu) menuLoader.active = true;
        }
        event.accepted = true;
    }

    IconImage {
        id: trayIcon
        source: (root.item && root.item.icon) ? root.item.icon : ""
        visible: source !== ""
        anchors.centerIn: parent
        width: 16
        height: 16
        asynchronous: true
    }

    Loader {
        id: menuLoader
        active: false
        onLoaded: {
            root.menuOpened(item);
        }
        sourceComponent: StatusBarTrayMenu {
            trayItemMenuHandle: root.item.menu
            
            anchor {
                window: root.QsWindow.window
                rect: {
                    var pos = root.mapToItem(null, 0, 0); 
                    return Qt.rect(pos.x, pos.y + root.height + 4, root.width, root.height);
                }
                edges: Edges.Top | Edges.Center
                gravity: Edges.Bottom
            }

            onMenuClosed: menuLoader.active = false
        }
    }
}
