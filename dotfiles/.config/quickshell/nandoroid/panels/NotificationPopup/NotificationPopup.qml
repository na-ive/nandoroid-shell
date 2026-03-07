pragma ComponentBehavior: Bound

import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Notification Popup panel.
 * Shows transient notifications in top-center area.
 * 100% Adapted pattern from 'ii' but centered.
 */
Scope {
    id: scope

    PanelWindow {
        id: popupWindow
        visible: Notifications.popupList.length > 0 && !GlobalStates.screenLocked

        WlrLayershell.namespace: "nandoroid:notificationPopup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        // Full width mask to allow swiping out of the center column
        mask: Region {
            item: maskItem
        }

        Item {
            id: maskItem
            anchors.horizontalCenter: parent.horizontalCenter
            width: listview.width
            anchors.top: parent.top
            anchors.topMargin: (Config.options?.statusBar?.height ?? 40) - 20
            height: listview.contentHeight + 100
        }

        color: "transparent"

        ListView {
            id: listview
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: (Config.options?.statusBar?.height ?? 40) + 8
            }
            width: Appearance.sizes.notificationCenterWidth
            implicitHeight: contentHeight
            spacing: 8
            interactive: false
            
            model: Notifications.activePopup ? [Notifications.activePopup] : []
            delegate: NotificationPopupItem {
                width: listview.width
                notificationObject: modelData
            }

            // Transitions for replacement
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }
                NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 250; easing.type: Easing.OutQuint }
            }
            displaced: Transition {
                NumberAnimation { properties: "y"; duration: 400; easing.type: Easing.OutQuint }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: 250 }
                    NumberAnimation { property: "x"; to: 500; duration: 300; easing.type: Easing.InQuint }
                }
            }
        }
    }
}
