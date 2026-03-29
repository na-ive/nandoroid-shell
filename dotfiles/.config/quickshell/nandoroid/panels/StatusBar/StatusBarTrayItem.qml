import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"

/**
 * System Tray Item with a solid halo (stroke-like) for maximum visibility.
 * Optimized with caching and fixed icon sizing to prevent Steam icon distortion.
 */
MouseArea {
    id: root
    required property SystemTrayItem item
    
    signal menuOpened(var menu)

    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    
    // STRICT 16x16 layout to keep Steam icon original
    implicitWidth: 16 * Appearance.effectiveScale
    implicitHeight: 16 * Appearance.effectiveScale

    onPressed: (event) => {
        if (event.button === Qt.LeftButton) {
            item.activate();
        } else if (event.button === Qt.RightButton) {
            if (item.hasMenu) menuLoader.active = true;
        }
        event.accepted = true;
    }

    Item {
        anchors.fill: parent
        
        IconImage {
            id: trayIcon
            source: (root.item && root.item.icon) ? root.item.icon : ""
            visible: source !== ""
            anchors.centerIn: parent
            // Keep original 16x16 size
            width: 16 * Appearance.effectiveScale
            height: 16 * Appearance.effectiveScale
            asynchronous: true
            
            // Apply a thick, solid-looking halo (stroke)
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 0
                radius: 3 * Appearance.effectiveScale // Larger radius for thickness
                samples: 12
                spread: 0.5 // Medium spread makes it look like a soft stroke
                color: Functions.ColorUtils.applyAlpha("#000000", 0.8)
                cached: true // High performance
            }
        }
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
                    return Qt.rect(pos.x, pos.y + root.height + (4 * Appearance.effectiveScale), root.width, root.height);
                }
                edges: Edges.Top | Edges.Center
                gravity: Edges.Bottom
            }

            onMenuClosed: menuLoader.active = false
        }
    }
}
