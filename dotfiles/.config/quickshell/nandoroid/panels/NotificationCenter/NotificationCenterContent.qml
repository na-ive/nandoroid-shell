import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * Notification Center: Media/Weather + Notification Island.
 * Refactored to match "island" style with grouped notifications.
 */
FocusScope {
    id: root
    signal closed()
    implicitWidth: Appearance.sizes.notificationCenterWidth
    implicitHeight: contentColumn.implicitHeight + 24 * Appearance.effectiveScale // Padding for bottom

    focus: true

    property bool _triggeredByClear: false

    function close() {
        root.closed();
    }

    property bool cheatsheetOpen: false

    // ── Keyboard navigation ──
    property bool navEngaged: false  // true once any nav key is pressed
    property bool navInGroup: false  // true when the cursor is inside an expanded group
    property bool navInButtons: false // true when the cursor is on a notification's action buttons
    property int navButtonIndex: 0

    readonly property bool mediaZoneAvailable: mediaCard.visible
    readonly property bool listZoneAvailable: Notifications.list.length > 0
    readonly property bool navActive: root.activeFocus && GlobalStates.notificationCenterOpen

    function currentGroup() {
        return listview.count > 0 ? listview.currentItem : null;
    }

    function currentNotif() {
        var g = root.currentGroup();
        if (!g || !g.notifList || g.notifList.count === 0) return null;
        return g.notifList.currentItem;
    }

    function setButtonIndex(idx) {
        var item = root.currentNotif();
        if (!item) return;
        item.keyboardButtonIndex = idx;
        if (item.ensureButtonVisible) item.ensureButtonVisible();
    }

    function scrollToCurrent() {
        if (listview.count > 0 && listview.currentIndex >= 0 && listview.currentIndex < listview.count)
            listview.positionViewAtIndex(listview.currentIndex, ListView.Contain);
    }

    // Scroll the outer list so the focused notification (inside an expanded
    // group) stays visible — positionViewAtIndex only positions the group.
    function ensureInnerVisible(g) {
        if (!g || !g.notifList || listview.count === 0) return;
        var item = g.notifList.currentItem;
        if (!item) return;
        var p = item.mapToItem(listview, 0, 0);
        var margin = 4 * Appearance.effectiveScale;
        var dy = 0;
        if (p.y + item.height > listview.height - margin)
            dy = (p.y + item.height) - (listview.height - margin);
        else if (p.y < margin)
            dy = p.y - margin;
        if (dy !== 0) {
            var maxY = Math.max(0, listview.contentHeight - listview.height);
            listview.contentY = Math.max(0, Math.min(listview.contentY + dy, maxY));
        }
    }

    function enterGroup() {
        var g = root.currentGroup();
        if (!g) return;
        root.navInButtons = false;
        if (!g.expanded) g.toggleExpanded();
        root.navInGroup = true;
        root.syncNavHighlight();
        Qt.callLater(() => {
            if (!g || !g.notifList || g.notifList.count === 0) return;
            // Expanding rebuilds the inner model; validate the selection
            // before positioning or it may remain stale/reset mid-rebuild.
            if (g.notifList.currentIndex < 0 || g.notifList.currentIndex >= g.notifList.count)
                g.notifList.currentIndex = 0;
            g.notifList.positionViewAtIndex(g.notifList.currentIndex, ListView.Contain);
            root.ensureInnerVisible(g);
            // A single-notification group gains nothing from the
            // text-focus level — jump straight to its action buttons.
            if (root.navInGroup && g.notificationCount === 1)
                root.enterButtons();
            else
                root.syncNavHighlight();
        });
    }

    function enterButtons() {
        var item = root.currentNotif();
        if (!item || !item.keyboardButtons || item.keyboardButtons().length === 0) {
            root.syncNavHighlight();
            return;
        }
        root.navInButtons = true;
        root.navButtonIndex = 0;
        Qt.callLater(() => {
            root.setButtonIndex(0);
            root.syncNavHighlight();
        });
    }

    // Leaving the buttons level: single-notification groups have no useful
    // text-focus level either, so collapse straight back to the list.
    function leaveButtonsOrGroup() {
        root.navInButtons = false;
        var g = root.currentGroup();
        if (g && g.notificationCount === 1) {
            root.navInGroup = false;
            if (g.expanded) g.toggleExpanded();
        }
        root.syncNavHighlight();
    }

    function actNotification(n) {
        if (!n) return;
        var hasDefault = false;
        for (var i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default") { hasDefault = true; break; }
        }
        if (hasDefault) Notifications.attemptInvokeAction(n.notificationId, "default");
        Notifications.discardNotification(n.notificationId);
    }

    function clearAll() {
        if (Notifications.list.length === 0) return;
        root._triggeredByClear = true;
        clearDelayTimer.restart();
    }

    function cycleMode() {
        Notifications.mode = (Notifications.mode + 1) % 3;
        root.syncNavHighlight();
    }

    function seekBy(deltaSec) {
        var player = MprisController.activePlayer;
        if (player && player.canSeek && player.length > 0) {
            var deltaMicroseconds = deltaSec * 1000000;
            player.position = Math.max(0, Math.min(player.length, player.position + deltaMicroseconds));
        }
    }

    function navActivate() {
        root.navEngaged = true;
        var g = root.currentGroup();
        if (root.navInButtons) {
            var b = root.currentNotif();
            if (b && b.kbButton) b.kbButton.clicked();
        } else if (root.navInGroup) {
            var item = g && g.notifList ? g.notifList.currentItem : null;
            root.actNotification(item ? item.notificationObject : null);
        } else if (g && g.multipleNotifications) {
            root.enterGroup();
        } else if (g && g.notificationCount === 1 && g.notifications.length > 0) {
            root.actNotification(g.notifications[0]);
        }
        root.syncNavHighlight();
    }

    function navUp() {
        root.navEngaged = true;
        if (root.navInButtons) {
            root.leaveButtonsOrGroup();
        } else if (root.navInGroup) {
            var gu = root.currentGroup();
            var innerCountU = (gu && gu.notifList)
                ? Math.max(gu.notifList.count, gu.notificationCount ?? 0) : 0;
            if (innerCountU > 0) {
                var idxU = gu.notifList.currentIndex;
                if (idxU < 0 || idxU >= innerCountU) idxU = innerCountU - 1; // repair stale selection
                if (idxU > 0) {
                    gu.notifList.currentIndex = idxU - 1;
                    gu.notifList.positionViewAtIndex(gu.notifList.currentIndex, ListView.Contain);
                    root.ensureInnerVisible(gu);
                } else {
                    root.navInGroup = false;
                    if (gu.expanded) gu.toggleExpanded();
                }
                root.syncNavHighlight();
            }
        } else if (listview.count > 0 && listview.currentIndex > 0) {
            listview.currentIndex--;
            root.scrollToCurrent();
            root.syncNavHighlight();
        }
    }

    function navDown() {
        root.navEngaged = true;
        if (root.navInButtons) {
            root.leaveButtonsOrGroup();
        } else if (root.navInGroup) {
            var g = root.currentGroup();
            // Use the group's real data count: notifList.count can lag behind
            // during the expand animation's model rebuild, which used to make
            // the first Down/Up look like "skip to the next app".
            var innerCount = (g && g.notifList)
                ? Math.max(g.notifList.count, g.notificationCount ?? 0) : 0;
            if (innerCount > 0) {
                var idx = g.notifList.currentIndex;
                if (idx < 0 || idx >= innerCount) idx = 0; // repair stale selection
                if (idx < innerCount - 1) {
                    g.notifList.currentIndex = idx + 1;
                    g.notifList.positionViewAtIndex(g.notifList.currentIndex, ListView.Contain);
                    root.ensureInnerVisible(g);
                    root.syncNavHighlight();
                } else {
                    root.navInGroup = false;
                    if (g.expanded) g.toggleExpanded();
                    if (listview.count > 0 && listview.currentIndex < listview.count - 1) {
                        listview.currentIndex++;
                        root.scrollToCurrent();
                    }
                    root.syncNavHighlight();
                }
            }
        } else if (listview.count > 0 && listview.currentIndex < listview.count - 1) {
            listview.currentIndex++;
            root.scrollToCurrent();
            root.syncNavHighlight();
        }
    }

    function navLeft() {
        root.navEngaged = true;
        if (root.navInButtons) {
            if (root.navButtonIndex > 0) {
                root.navButtonIndex--;
                root.setButtonIndex(root.navButtonIndex);
                root.syncNavHighlight();
            } else {
                root.leaveButtonsOrGroup();
            }
        } else if (root.navInGroup) {
            var g = root.currentGroup();
            root.navInGroup = false;
            if (g && g.expanded) g.toggleExpanded();
            root.syncNavHighlight();
        } else {
            var grp = root.currentGroup();
            if (grp && grp.expanded) grp.toggleExpanded();
            else if (grp) grp.destroyWithAnimation(true);
            root.syncNavHighlight();
        }
    }

    function navRight() {
        root.navEngaged = true;
        if (root.navInButtons) {
            var nb = root.currentNotif();
            var ncount = nb && nb.keyboardButtons ? nb.keyboardButtons().length : 0;
            if (root.navButtonIndex < ncount - 1) {
                root.navButtonIndex++;
                root.setButtonIndex(root.navButtonIndex);
                root.syncNavHighlight();
            }
        } else if (root.navInGroup) {
            root.enterButtons();
        } else {
            root.enterGroup();
        }
    }

    function syncNavHighlight() {
        var engaged = root.navEngaged;
        var inner = engaged && root.navInGroup && !root.navInButtons;
        var innerButtons = engaged && root.navInGroup && root.navInButtons;
        listview.keyboardSelected = engaged && !root.navInGroup;
        for (var i = 0; i < listview.count; i++) {
            var it = listview.itemAtIndex(i);
            if (!it) continue;
            it.keyboardSelectedInner = inner && it === listview.currentItem;
            it.keyboardSelectedInnerButtons = innerButtons && it === listview.currentItem;
        }
        var item = root.currentNotif();
        if (item) item.keyboardButtonIndex = innerButtons ? root.navButtonIndex : -1;
    }

    function resetNav() {
        root.navEngaged = false;
        root.navInGroup = false;
        root.navInButtons = false;
        root.navButtonIndex = 0;
        if (listview.count > 0) listview.currentIndex = 0;
        Qt.callLater(() => { root.scrollToCurrent(); root.syncNavHighlight(); });
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Slash) {
            root.cheatsheetOpen = !root.cheatsheetOpen;
            event.accepted = true;
        } else if (root.cheatsheetOpen && event.key === Qt.Key_Escape) {
            root.cheatsheetOpen = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.navUp();
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.navDown();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.navLeft();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.navRight();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.navActivate();
            event.accepted = true;
        } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            var g = root.currentGroup();
            if (root.navInGroup) {
                var item = g && g.notifList ? g.notifList.currentItem : null;
                var n = item ? item.notificationObject : null;
                if (n) Notifications.discardNotification(n.notificationId);
            } else if (g && g.destroyWithAnimation) {
                g.destroyWithAnimation();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_C && !(event.modifiers & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier))) {
            root.clearAll();
            event.accepted = true;
        } else if (event.key === Qt.Key_V && !(event.modifiers & (Qt.ControlModifier | Qt.MetaModifier | Qt.AltModifier))) {
            root.cycleMode();
            event.accepted = true;
        } else if (root.mediaZoneAvailable) {
            if (event.key === Qt.Key_A) {
                MprisController.previous();
                event.accepted = true;
            } else if (event.key === Qt.Key_S) {
                root.seekBy(-5);
                event.accepted = true;
            } else if (event.key === Qt.Key_D) {
                root.seekBy(5);
                event.accepted = true;
            } else if (event.key === Qt.Key_F) {
                MprisController.next();
                event.accepted = true;
            } else if (event.key === Qt.Key_Z) {
                MprisController.togglePlaying();
                event.accepted = true;
            } else if (event.key === Qt.Key_X) {
                Config.options.appearance.lyrics.showFloatingLyrics = !Config.options.appearance.lyrics.showFloatingLyrics;
                event.accepted = true;
            }
        }
        
        if (!event.accepted && event.key === Qt.Key_Home) {
            if (root.navInButtons) {
                root.navButtonIndex = 0;
                root.setButtonIndex(0);
            } else if (root.navInGroup) {
                var gh = root.currentGroup();
                if (gh && gh.notifList && gh.notifList.count > 0) {
                    gh.notifList.currentIndex = 0;
                    gh.notifList.positionViewAtIndex(0, ListView.Contain);
                    root.ensureInnerVisible(gh);
                }
            } else if (listview.count > 0) {
                listview.currentIndex = 0;
                root.scrollToCurrent();
            }
            root.syncNavHighlight();
            event.accepted = true;
        } else if (!event.accepted && event.key === Qt.Key_End) {
            if (root.navInButtons) {
                var ge2 = root.currentNotif();
                root.navButtonIndex = ge2 && ge2.keyboardButtons ? ge2.keyboardButtons().length - 1 : 0;
                if (root.navButtonIndex < 0) root.navButtonIndex = 0;
                root.setButtonIndex(root.navButtonIndex);
            } else if (root.navInGroup) {
                var ge = root.currentGroup();
                if (ge && ge.notifList && ge.notifList.count > 0) {
                    ge.notifList.currentIndex = ge.notifList.count - 1;
                    ge.notifList.positionViewAtIndex(ge.notifList.currentIndex, ListView.Contain);
                    root.ensureInnerVisible(ge);
                }
            } else if (listview.count > 0) {
                listview.currentIndex = listview.count - 1;
                root.scrollToCurrent();
            }
            root.syncNavHighlight();
            event.accepted = true;
        }
    }

    Connections {
        target: GlobalStates
        function onNotificationCenterOpenChanged() {
            if (GlobalStates.notificationCenterOpen) {
                root.forceActiveFocus();
                root.resetNav();
            } else {
                root.cheatsheetOpen = false;
                listview.keyboardSelected = false;
                for (var i = 0; i < listview.count; i++) {
                    var it = listview.itemAtIndex(i);
                    if (it) {
                        it.keyboardSelectedInner = false;
                        it.keyboardSelectedInnerButtons = false;
                    }
                }
            }
        }
    }

    Connections {
        target: Notifications
        function onListChanged() {
            if (listview.count > 0) {
                if (listview.currentIndex < 0) listview.currentIndex = 0;
                if (listview.currentIndex >= listview.count) {
                    listview.currentIndex = listview.count - 1;
                    root.scrollToCurrent();
                }
                if (root.navInGroup) {
                    // Transient inner-model rebuilds (e.g. right after expand)
                    // can report an empty/short list — never drop the group
                    // state over that, just clamp once data is available.
                    var g = root.currentGroup();
                    if (g && g.notifList && g.notifList.count > 0) {
                        if (g.notifList.currentIndex >= g.notifList.count)
                            g.notifList.currentIndex = g.notifList.count - 1;
                        else if (g.notifList.currentIndex < 0)
                            g.notifList.currentIndex = 0;
                    }
                }
            } else {
                listview.currentIndex = -1;
                root.navInGroup = false;
                root.navInButtons = false;
            }
            root.syncNavHighlight();
        }
    }

    Component.onCompleted: {
        if (GlobalStates.notificationCenterOpen) {
            root.forceActiveFocus();
            root.resetNav();
        }
    }

    onActiveFocusChanged: {
        if (root.activeFocus && GlobalStates.notificationCenterOpen) root.syncNavHighlight();
        else {
            listview.keyboardSelected = false;
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.panel
        
        
        // Prevent clicks inside the panel from falling through to the Overlay background closer
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12 * Appearance.effectiveScale
            topMargin: 12 * Appearance.effectiveScale
        }
        spacing: 12 * Appearance.effectiveScale

        // ── Media Card ──
        MediaCard {
            id: mediaCard
            Layout.fillWidth: true
            visible: (Config.options.media?.showMediaCard ?? true) && MprisController.activePlayer !== null
            // This panel is hosted in an always-active Loader and collapsed via
            // opacity, so the card's `visible` stays true while closed. Bind the
            // wavy Canvas lifecycle to the real open-state to avoid 60fps
            // off-screen repaints.
            wavyVisible: GlobalStates.notificationCenterOpen
        }

        // ── Weather Card ──
        WeatherCard {
            Layout.fillWidth: true
            visible: (Config.options.weather?.enable ?? true)
                && (Config.options.weather?.showInNotificationCenter ?? true)
        }

        // ── Notification Island ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.sizes.notificationIslandMaxHeight
            
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.large
            
            ColumnLayout {
                id: islandColumn
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                // ── Main Content (List or Placeholder) ──
                Item {
                    id: listContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // Placeholder (No Notifications)
                    ColumnLayout {
                        id: placeholder
                        anchors.centerIn: parent
                        visible: opacity > 0
                        opacity: Notifications.list.length === 0 ? 1 : 0
                        spacing: 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 250; easing.type: Easing.OutSine }
                        }
                        
                        MaterialShape { 
                            Layout.alignment: Qt.AlignCenter
                            implicitWidth: 100 * Appearance.effectiveScale
                            implicitHeight: 100 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            shape: MaterialShape.Shape.Ghostish 
                            
                            MaterialSymbol {
                                id: bellIcon
                                anchors.centerIn: parent
                                text: "notifications"
                                iconSize: 56 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3onSurfaceVariant 
                                
                                transform: Rotation { origin.x: bellIcon.width / 2; origin.y: 0; angle: 0; id: bellRotation }

                                SequentialAnimation {
                                    id: bellSwingAnim
                                    
                                    NumberAnimation { target: bellRotation; property: "angle"; from: 0; to: 20; duration: 250; easing.type: Easing.OutBack }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: 20; to: -20; duration: 400; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: -20; to: 15; duration: 300; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: 15; to: -10; duration: 250; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: -10; to: 0; duration: 200; easing.type: Easing.OutSine }
                                }

                                Connections {
                                    target: Notifications
                                    function onListChanged() {
                                        // Only trigger if empty and not from the Clear All button (which handles its own animation timing)
                                        if (Notifications.list.length === 0 && !root._triggeredByClear) {
                                            bellSwingAnim.restart()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Notification List
                    NotificationListView {
                        id: listview
                        anchors.fill: parent
                        visible: Notifications.list.length > 0 || opacity > 0
                        clip: true

                        opacity: root._triggeredByClear ? 0 : 1
                        Behavior on opacity {
                            NumberAnimation { duration: 250; easing.type: Easing.OutSine }
                        }
                    }
                }

                // ── Bottom Action Row ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4 * Appearance.effectiveScale
                    visible: true 

                    SegmentedButton {
                        id: modeButton
                        isHighlighted: Notifications.mode > 0
                        forcePill: true
                        implicitWidth: 56 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        iconName: Notifications.mode === 2 ? "notifications_off" : (Notifications.mode === 1 ? "vibration" : "notifications_active")
                        iconSize: 20 * Appearance.effectiveScale
                        
                        colActive: Appearance.m3colors.m3primaryContainer
                        colActiveText: Appearance.m3colors.m3onPrimaryContainer
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                        
                        onClicked: Notifications.mode = (Notifications.mode + 1) % 3
                    }

                    // Notification Count Wrapper
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40 * Appearance.effectiveScale
                        forcePill: true
                        smallRadius: 4 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: Notifications.list.length > 0 ? Notifications.list.length + " " + I18nService.tr("notifications") : I18nService.tr("No notifications")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }
                    }

                    SegmentedButton {
                        id: clearButton
                        implicitWidth: 56 * Appearance.effectiveScale
                        implicitHeight: 40 * Appearance.effectiveScale
                        forcePill: true
                        iconName: "delete_sweep"
                        iconSize: 20 * Appearance.effectiveScale
                        enabled: Notifications.list.length > 0
                        opacity: enabled ? 1 : 0.5
                        
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: {
                            root._triggeredByClear = true
                            // Give time for list to fade out before actually clearing
                            clearDelayTimer.restart()
                        }
                    }

                    Timer {
                        id: clearDelayTimer
                        interval: 250
                        repeat: false
                        onTriggered: {
                            Notifications.discardAllNotifications()
                            if (root._triggeredByClear) {
                                bellSwingAnim.restart()
                                root._triggeredByClear = false
                            }
                        }
                    }
                }
            }
        }
    }

    DialogCheatsheet {
        visible: root.cheatsheetOpen
        onClosed: root.cheatsheetOpen = false
        shortcuts: [
            { key: "↑ ↓", action: "Navigate Items" },
            { key: "← →", action: "Expand/Collapse" },
            { key: "Enter / Space", action: "Activate" },
            { key: "A", action: "Media Previous" },
            { key: "S", action: "Media -5s" },
            { key: "D", action: "Media +5s" },
            { key: "F", action: "Media Next" },
            { key: "Z", action: "Media Play/Pause" },
            { key: "X", action: "Toggle Floating Lyric" },
            { key: "C", action: "Clear All Notifications" },
            { key: "V", action: "Toggle Notification Mode" }
        ]
    }
}
