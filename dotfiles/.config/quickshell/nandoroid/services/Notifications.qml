pragma Singleton
pragma ComponentBehavior: Bound

import "../core"
import "../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
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
            const name = n.isRestartRequired ? "System" : (n.appName || "Unknown");
            if (!groups[name]) {
                groups[name] = {
                    appName: name,
                    appIcon: n.isRestartRequired ? "restart_alt" : n.appIcon, 
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
            const name = n.isRestartRequired ? "System" : (n.appName || "Unknown");
            if (!groups[name]) {
                groups[name] = {
                    appName: name,
                    appIcon: n.isRestartRequired ? "restart_alt" : n.appIcon, 
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
            const anyRestartA = groups[a]?.notifications.some(n => n.isRestartRequired) || false;
            const anyRestartB = groups[b]?.notifications.some(n => n.isRestartRequired) || false;
            
            if (anyRestartA && !anyRestartB) return -1;
            if (!anyRestartA && anyRestartB) return 1;

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
        property bool isRestartRequired: false

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

            const summaryLower = (notification.summary || "").toLowerCase();
            const bodyLower = (notification.body || "").toLowerCase();
            const appNameLower = (notification.appName || "").toLowerCase();
            
            const restartKeywords = ["restart", "reboot", "kernel update", "needs to be restarted"];
            const isRestart = restartKeywords.some(kw => summaryLower.includes(kw) || bodyLower.includes(kw));

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
                "isRestartRequired": isRestart
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
            
            if (actionIdentifier === "default") {
                // --- Smart Focus Logic (Enhanced with Overview-style Fuzzy Matching) ---
                const appName = (notif.appName || "").toLowerCase();
                const summary = (notif.summary || "").toLowerCase();
                const body = (notif.body || "").toLowerCase();
                
                // ── NANDOROID INTERNAL ROUTING ──
                if (appName === "nandoroid") {
                    if (summary.includes("update") || body.includes("update")) {
                        GlobalStates.settingsPageIndex = 6; // About page
                        GlobalStates.settingsAboutView = "update"; // Directly to Update sub-page
                        GlobalStates.settingsOpen = true;
                    } else if (summary.includes("schedule") || summary.includes("event") || body.includes("schedule") || body.includes("event")) {
                        GlobalStates.dashboardOpen = true;
                    } else if (summary.includes("wallpaper") || summary.includes("theming") || body.includes("wallpaper") || body.includes("theming")) {
                        GlobalStates.settingsPageIndex = 4; // Wallpaper & Style
                        GlobalStates.settingsOpen = true;
                    } else if (summary.includes("audio") || summary.includes("sound") || body.includes("audio") || body.includes("sound")) {
                        GlobalStates.settingsPageIndex = 2; // Audio
                        GlobalStates.settingsOpen = true;
                    } else if (summary.includes("settings") || body.includes("settings") || summary.includes("system") || body.includes("system")) {
                        GlobalStates.settingsOpen = true;
                    }
                    
                    GlobalStates.notificationCenterOpen = false;
                    root.discardNotification(id);
                    return;
                }

                if (appName !== "" || summary !== "") {
                    let bestMatch = null;
                    let highestScore = -1;

                    const fuzzyScore = (query, target) => {
                        if (!query || !target) return -1;
                        const lowQuery = query.toLowerCase();
                        const lowTarget = target.toLowerCase();
                        
                        if (lowTarget === lowQuery) return 2000; // Perfect match
                        if (lowTarget.includes(lowQuery)) return 1000 + (100 - lowTarget.length); // Substring match
                        
                        let queryIndex = 0, consecutiveMatches = 0, maxConsecutive = 0, score = 0;
                        for (let i = 0; i < lowTarget.length && queryIndex < lowQuery.length; i++) {
                            if (lowTarget[i] === lowQuery[queryIndex]) {
                                queryIndex++; consecutiveMatches++;
                                maxConsecutive = Math.max(maxConsecutive, consecutiveMatches);
                                if (i === 0 || lowTarget[i - 1] === ' ' || lowTarget[i - 1] === '-' || lowTarget[i - 1] === '_') score += 50;
                            } else { consecutiveMatches = 0; }
                        }
                        return queryIndex === lowQuery.length ? score + maxConsecutive * 5 : -1;
                    };

                    for (let i = 0; i < Hyprland.toplevels.values.length; i++) {
                        const tl = Hyprland.toplevels.values[i];
                        const cClass = tl.class || "";
                        const cTitle = tl.title || "";
                        const cInitial = tl.initialClass || "";

                        // Calculate scores for various properties
                        const classScore = fuzzyScore(appName, cClass);
                        const initialScore = fuzzyScore(appName, cInitial);
                        const titleScore = Math.max(fuzzyScore(appName, cTitle), fuzzyScore(summary, cTitle) * 0.8);
                        
                        const currentMax = Math.max(classScore, initialScore, titleScore);

                        if (currentMax > highestScore) {
                            highestScore = currentMax;
                            bestMatch = tl;
                        }
                    }

                    if (bestMatch && highestScore > 0) {
                        Hyprland.dispatch(HyprlandCompat.dspFocusWindow(`address:0x${bestMatch.address}`));
                        GlobalStates.notificationCenterOpen = false;
                        GlobalStates.dashboardOpen = false;
                    }
                }

                if (typeof notif.invokeDefaultAction === "function") {
                    notif.invokeDefaultAction();
                } else {
                    const action = notif.actions.find(a => a.identifier === "default" || a.identifier === "");
                    if (action) action.invoke();
                }
            } else {
                const action = notif.actions.find(a => a.identifier === actionIdentifier);
                if (action) action.invoke();
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
            isRestartRequired: n.isRestartRequired
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
                    "isRestartRequired": n.isRestartRequired ?? false
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
