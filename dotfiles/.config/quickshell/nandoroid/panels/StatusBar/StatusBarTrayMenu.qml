import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../widgets"

PopupWindow {
    id: root
    required property QsMenuHandle trayItemMenuHandle
    
    signal menuClosed()

    color: "transparent"

    implicitWidth: Math.max(120, menuLayout.implicitWidth + 8)
    implicitHeight: menuLayout.implicitHeight + 8

    onVisibleChanged: {
        if (!visible) menuClosed();
    }

    Rectangle {
        id: popupBackground
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.small
        clip: true

        ColumnLayout {
            id: menuLayout
            anchors {
                fill: parent
                margins: 4
            }
            spacing: 0

            QsMenuOpener {
                id: menuOpener
                menu: root.trayItemMenuHandle
            }

            Repeater {
                id: menuEntriesRepeater
                
                property bool iconColumnNeeded: {
                    for (var i = 0; i < menuOpener.children.length; i++) {
                        if (menuOpener.children[i].icon.length > 0) return true;
                    }
                    return false;
                }

                property bool interactionColumnNeeded: {
                    for (var i = 0; i < menuOpener.children.length; i++) {
                        if (menuOpener.children[i].buttonType !== QsMenuButtonType.None) return true;
                    }
                    return false;
                }

                model: menuOpener.children
                delegate: StatusBarTrayMenuEntry {
                    required property QsMenuEntry modelData
                    menuEntry: modelData
                    forceIconColumn: menuEntriesRepeater.iconColumnNeeded
                    forceInteractionColumn: menuEntriesRepeater.interactionColumnNeeded
                    
                    onDismiss: root.visible = false
                    onOpenSubmenu: (handle) => {
                        root.trayItemMenuHandle = handle;
                    }
                }
            }
        }
    }

    Component.onCompleted: visible = true
}
