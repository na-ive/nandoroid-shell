pragma Singleton
pragma ComponentBehavior: Bound

import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

/**
 * Notification service — wraps NotificationServer for real D-Bus notifications.
 * Persistent storage, unread counter, popup management.
 *
 * IMPORTANT: No other notification daemon (Dunst/Mako/Swaync) should be running.
 */
Singleton {
    id: root

    property int unread: 0
    property var filePath: Directories.notificationsPath
    property list<QtObject> list: []
    property var activePopup: null
    property var popupList: list.filter(n => n.popup) // Still used for sidebar/history logic
    property bool silent: false
    property int idOffset: 0

    onListChanged: if (list.length === 0) activePopup = null;

    // ── Grouping Logic ──
    property var groupsByAppName: {
        const groups = {};
        for (let i = 0; i < list.length; i++) {
            const n = list[i];
            const name = n.appName || "Unknown";
            if (!groups[name]) {
                groups[name] = {
                    appName: name,
                    appIcon: n.appIcon, 
                    time: n.time,
                    notifications: []
                };
            }
            groups[name].notifications.push(n);
            if (n.time > groups[name].time) groups[name].time = n.time;
        }
        return groups;
    }

    property var popupGroupsByAppName: {
        const groups = {};
        const popupList = list.filter(n => n.popup);
        for (let i = 0; i < popupList.length; i++) {
            const n = popupList[i];
            const name = n.appName || "Unknown";
            if (!groups[name]) {
                groups[name] = {
                    appName: name,
                    appIcon: n.appIcon, 
                    time: n.time,
                    notifications: []
                };
            }
            groups[name].notifications.push(n);
            if (n.time > groups[name].time) groups[name].time = n.time;
        }
        return groups;
    }

    property var priorityApps: ["Telegram", "WhatsApp", "Discord", "Signal", "Messenger", "Instagram", "Messages"]
    
    function sortApps(apps, groups) {
        return apps.sort((a, b) => {
            const timeA = groups[a]?.time || 0;
            const timeB = groups[b]?.time || 0;
            return timeB - timeA; // Newest first
        });
    }

    property var appNameList: sortApps(Object.keys(groupsByAppName), groupsByAppName)
    property var popupAppNameList: sortApps(Object.keys(popupGroupsByAppName), popupGroupsByAppName)

    function getCountForApp(appId) {
        if (!appId) return 0;
        let count = 0;
        const lowerId = appId.toLowerCase();
        
        for (let i = 0; i < list.length; i++) {
            const n = list[i];
            const name = (n.appName || "").toLowerCase();
            // Fuzzy match: check if appName is in appId or vice versa
            if (name !== "" && (lowerId.includes(name) || name.includes(lowerId))) {
                count++;
            }
        }
        return count;
    }

    // ── Notification wrapper component ──
    // ── Notification wrapper component ──
    component Notif: QtObject {
        required property int notificationId
        property Notification notification
        property bool popup: false
        property bool isTransient: notification?.hints?.transient ?? false
        
        // Stored fields - bindings allow auto-update from live notification. 
        // When loaded from file, these will be overwritten by direct assignment.
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property string urgency: notification?.urgency?.toString() ?? "normal"
        property double time
        property Timer timer
        property bool expanded: false

        property list<var> actions: {
            if (notification && notification.actions) {
                 return notification.actions.map(a => ({identifier: a.identifier, text: a.text}))
            }
            return []
        }

        // Sync from live notification when it arrives/changes
        onNotificationChanged: {
            if (notification === null) {
                // Live notification closed — remove from list
                root.discardNotification(notificationId);
            }
        }
    }



    // ── Popup timeout timer component ──
    component NotifTimer: Timer {
        required property int notificationId
        interval: Config.options.notifications.timeout_ms
        running: true
        onTriggered: {
            const index = root.list.findIndex(n => n.notificationId === notificationId);
            const notif = root.list[index];
            if (notif?.isTransient) root.discardNotification(notificationId);
            else root.timeoutNotification(notificationId);
            Qt.callLater(() => destroy());
        }
    }

    Component { id: notifComponent; Notif {} }
    Component { id: notifTimerComponent; NotifTimer {} }

    // ── D-Bus Notification Server ──
    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true;
            
            // Strictly clear existing popup state before adding a new one
            if (root.activePopup) {
                root.activePopup.popup = false;
                root.activePopup = null;
            }

            const newNotif = notifComponent.createObject(root, {
                "notificationId": notification.id + root.idOffset,
                "notification": notification,
                "appIcon":  notification.appIcon  ?? "",
                "appName":  notification.appName  ?? "",
                "body":     notification.body     ?? "",
                "image":    notification.image    ?? "",
                "summary":  notification.summary  ?? "",
                "urgency":  notification.urgency?.toString() ?? "normal",
                "time":     Date.now(),
            });
            
            // Add to list and handle popup state
            root.list = [...root.list, newNotif];

            if (!root.silent) {
                newNotif.popup = true;
                root.activePopup = newNotif;
                if (notification.expireTimeout !== 0) {
                    newNotif.timer = notifTimerComponent.createObject(root, {
                        "notificationId": newNotif.notificationId,
                        "interval": notification.expireTimeout < 0
                            ? Config.options.notifications.timeout_ms
                            : notification.expireTimeout,
                    });
                }
                root.unread++;
            }


            notifFileView.setText(stringifyList(root.list));
        }
    }

    // ── Public API ──
    function markAllRead() { root.unread = 0; }

    function discardNotification(id) {
        const index = root.list.findIndex(n => n.notificationId === id);
        if (index === -1) return;

        if (root.unread > 0) root.unread--;
        const notif = root.list[index];
        if (notif.timer) { 
            notif.timer.stop(); 
            let t = notif.timer; 
            Qt.callLater(() => { if(t) t.destroy(); }); 
        }

        // Dismiss from D-Bus server
        const serverId = notif.notificationId - root.idOffset;
        const serverNotif = notifServer.trackedNotifications.values.find(n => n.id === serverId);
        if (serverNotif) serverNotif.dismiss();

        notif.popup = false; 
        if (root.activePopup && root.activePopup.notificationId === id) {
            root.activePopup = null;
        }
        
        root.list.splice(index, 1);
        root.list = [...root.list]; // Direct trigger
        notifFileView.setText(stringifyList(root.list));
    }

    function discardAllNotifications() {
        root.activePopup = null;
        root.list.forEach(n => { if (n.timer) n.timer.stop(); });
        root.list = [];
        notifFileView.setText(stringifyList(root.list));
        notifServer.trackedNotifications.values.forEach(n => n.dismiss());
        root.unread = 0;
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex(n => n.notificationId === id);
        if (root.list[index] != null) {
            root.list[index].popup = false;
            if (root.activePopup && root.activePopup.notificationId === id) {
                root.activePopup = null;
            }
        }
    }

    function attemptInvokeAction(id, actionIdentifier) {
        const serverIndex = notifServer.trackedNotifications.values.findIndex(
            n => n.id + root.idOffset === id
        );
        if (serverIndex !== -1) {
            const notif = notifServer.trackedNotifications.values[serverIndex];
            let invoked = false;
            
            if (actionIdentifier === "default") {
                if (typeof notif.invokeDefaultAction === "function") {
                    notif.invokeDefaultAction();
                    invoked = true;
                }
            }
            
            if (!invoked && typeof notif.invokeAction === "function") {
                notif.invokeAction(actionIdentifier);
                invoked = true;
            }
            
            if (!invoked) {
                const action = notif.actions.find(a => a.identifier === actionIdentifier);
                if (action && typeof action.invoke === "function") {
                    action.invoke();
                }
            }
        }
        root.discardNotification(id);
    }

    // ── Serialization ──
    function stringifyList(list) {
        return JSON.stringify(list.map(n => ({
            notificationId: n.notificationId,
            appIcon: n.appIcon,
            appName: n.appName,
            body: n.body,
            image: n.image,
            summary: n.summary,
            time: n.time,
            urgency: n.urgency,
        })), null, 2);
    }

    // ── Persistent storage ──
    Component.onCompleted: notifFileView.reload()

    FileView {
        id: notifFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                const fileContents = notifFileView.text();
                const parsed = JSON.parse(fileContents);
                root.list = parsed.map(n => notifComponent.createObject(root, {
                    "notificationId": n.notificationId,
                    "appIcon": n.appIcon ?? "",
                    "appName": n.appName ?? "",
                    "body": n.body ?? "",
                    "image": n.image ?? "",
                    "summary": n.summary ?? "",
                    "time": n.time ?? 0,
                    "urgency": n.urgency ?? "normal",
                }));
                // Find max ID to avoid collisions
                let maxId = 0;
                root.list.forEach(n => { maxId = Math.max(maxId, n.notificationId); });
                root.idOffset = maxId;

            } catch (e) {

                root.list = [];
            }
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {

                root.list = [];
                notifFileView.setText("[]");
            } else {

            }
        }
    }
}
