pragma ComponentBehavior: Bound

import "../core"
import "../services"
import QtQuick
import Quickshell

/**
 * Scrollable window for notifications.
 * 100% Adapted from the 'ii' source port.
 */
StyledListView { 
    id: root
    property bool popup: false

    spacing: 4

    model: ScriptModel {
        values: root.popup ? Notifications.popupAppNameList : Notifications.appNameList
    }
    delegate: NotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        width: ListView.view.width
        
        isFirst: index === 0
        isLast: index === ListView.view.count - 1
        
        notificationGroup: popup ? 
            Notifications.popupGroupsByAppName[modelData] :
            Notifications.groupsByAppName[modelData]
    }
}
