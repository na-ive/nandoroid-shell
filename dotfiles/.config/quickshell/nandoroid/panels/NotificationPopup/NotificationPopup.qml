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
            anchors.horizontalCenterOffset: (listview.activeDelegate) ? listview.activeDelegate.currentXOffset : 0
            width: listview.width
            anchors.top: listview.top
            height: listview.contentHeight
        }

        color: "transparent"

        ListView {
            id: listview
            property var activeDelegate: null
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: ((Config.options?.statusBar?.height ?? 40) * Appearance.effectiveScale) + (8 * Appearance.effectiveScale)
            }
            width: Appearance.sizes.notificationCenterWidth
            implicitHeight: contentHeight
            spacing: 8 * Appearance.effectiveScale
            interactive: false
            
            model: Notifications.activePopup ? [Notifications.activePopup] : []
            delegate: NotificationPopupItem {
                id: delegateItem
                width: listview.width
                notificationObject: modelData

                Component.onCompleted: listview.activeDelegate = delegateItem
                Component.onDestruction: if (listview.activeDelegate == delegateItem) listview.activeDelegate = null
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
                NumberAnimation { property: "opacity"; to: 0; duration: 200 }
            }
        }
    }
}
