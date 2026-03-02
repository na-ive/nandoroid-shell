import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../services"
import "../../widgets"
import Quickshell.Hyprland
import QtQuick.Controls

/**
 * Universal Dynamic Island container for the status bar.
 * "Coordinate-Based" Architecture:
 * - root.width 0 is the true notch center.
 * - backgroundPill sizes itself by distance between ears.
 * - Eliminates anchor loops and "missing text" bugs.
 */
Item {
    id: root
    
    property HyprlandMonitor monitor
    property bool pomodoroActive: PomodoroService.isSessionRunning
    property real indicatorWidth: 52 
    
    width: 0 
    height: 28

    // Expose the background pill for absolute anchoring
    property alias pill: backgroundPill

    // --- State Logic ---
    property bool mediaShowing: false
    Timer { id: mediaTimer; interval: 5000; onTriggered: root.mediaShowing = false }

    Connections {
        target: MprisController
        function onTrackTitleChanged() {
            if (MprisController.isPlaying && MprisController.trackTitle !== "No media") {
                root.mediaShowing = true; mediaTimer.restart()
            }
        }
        function onIsPlayingChanged() {
            if (MprisController.isPlaying && MprisController.trackTitle !== "No media") {
                root.mediaShowing = true; mediaTimer.restart()
            }
        }
    }

    readonly property string islandState: {
        if (Notifications.activePopup) return "notification"
        if (mediaShowing && MprisController.activePlayer) return "media"
        if (pomodoroActive) return "pomodoro"
        return "idle"
    }

    // Gap width: 4px in idle, tight 2px in active states.
    readonly property real gapHalf: (indicatorWidth / 2) + (islandState === "idle" ? 4 : 2)

    // --- LEFT EAR (Artist / Pomodoro Mode / Notif App) ---
    Item {
        id: leftEar
        anchors.right: root.left
        anchors.rightMargin: root.gapHalf
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        clip: true
        
        width: {
            if (islandState === "notification") {
                let w = 0
                if (notifLogo.visible) w += 20 + 6
                if (notifAppNameLabel.visible) w += Math.min(notifAppNameLabel.implicitWidth, 100) + 4
                return w > 0 ? w + 4 : 0
            }
            if (islandState === "media") {
                let w = 0
                if (mediaLogo.visible) w += 20 + 6 // Icon + margin
                if (mediaArtistLabel.visible) w += Math.min(mediaArtistLabel.implicitWidth, 150) + 4
                return w > 0 ? w + 4 : 0
            }
            if (islandState === "pomodoro") return pomoModeLabel.implicitWidth + 8
            return 0
        }

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 300 } }

        // Notification Icon
        NotificationAppIcon {
            id: notifLogo
            anchors.right: notifAppNameLabel.visible ? notifAppNameLabel.left : parent.right
            anchors.rightMargin: notifAppNameLabel.visible ? 6 : 4
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18
            implicitSize: 18 // Paksa ukuran aslinya biar gak default ke 38
            visible: islandState === "notification"
            opacity: parent.width > 24 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            appIcon: Notifications.activePopup?.appIcon || Notifications.activePopup?.appName || ""
            image: Notifications.activePopup?.image || ""
            summary: Notifications.activePopup?.summary || ""
            urgency: Notifications.activePopup?.urgency || "normal"
            color: "transparent"
        }

        StyledText {
            id: notifAppNameLabel
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: Notifications.activePopup?.appName || "Notification"
            visible: islandState === "notification"
            opacity: parent.width > 30 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.Medium
            color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, 100)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }

        // Application Icon with Fallback
        Loader {
            id: mediaLogo
            anchors.right: mediaArtistLabel.visible ? mediaArtistLabel.left : parent.right
            anchors.rightMargin: mediaArtistLabel.visible ? 6 : 4
            anchors.verticalCenter: parent.verticalCenter
            width: 18; height: 18
            visible: islandState === "media"
            opacity: parent.width > 24 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            property string activeEntryStr: {
                if (!MprisController.activePlayer) return ""
                let entry = MprisController.activePlayer.desktopEntry
                return entry ? entry.toString() : ""
            }

            property string activeDbusName: {
                if (!MprisController.activePlayer) return ""
                let dbusArgs = MprisController.activePlayer.dbusName
                return dbusArgs ? dbusArgs.toLowerCase() : ""
            }

            property bool useFallback: {
                if (activeEntryStr === "") return true;
                if (activeDbusName.indexOf("plasma-browser-integration") !== -1) return true;
                if (activeDbusName.indexOf("brave") !== -1 || activeEntryStr === "brave-browser") return true;
                return false;
            }

            sourceComponent: useFallback ? fallbackIconComp : imageIconComp

            Component {
                id: imageIconComp
                CustomIcon {
                    width: 18; height: 18
                    source: {
                        let icon = Quickshell.iconPath(mediaLogo.activeEntryStr)
                        return icon ? icon.toString() : ""
                    }
                }
            }

            Component {
                id: fallbackIconComp
                MaterialSymbol {
                    text: "music_note"
                    iconSize: 18
                    color: Appearance.colors.colNotchText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        StyledText {
            id: mediaArtistLabel
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: (MprisController.trackArtist && MprisController.trackArtist.toString().trim() !== "") 
                  ? MprisController.trackArtist.toString().trim() : "Unknown Artist"
            visible: islandState === "media"
            opacity: parent.width > 30 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.Medium
            color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, 150)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignRight
        }

        StyledText {
            id: pomoModeLabel
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: PomodoroService.modeName
            opacity: parent.width > 20 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold
            color: Appearance.colors.colNotchText
            visible: islandState === "pomodoro"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (islandState === "notification" && Notifications.activePopup) {
                    Notifications.attemptInvokeAction(Notifications.activePopup.notificationId, "default")
                }
            }
        }
    }

    // --- RIGHT EAR (Title / Pomodoro Timer / Notif Summary) ---
    Item {
        id: rightEar
        anchors.left: root.right
        anchors.leftMargin: root.gapHalf
        anchors.verticalCenter: parent.verticalCenter
        height: 28
        clip: true
        
        width: {
            if (islandState === "notification") return notifSummaryLabel.visible ? Math.min(notifSummaryLabel.implicitWidth, 200) + 8 : 0
            if (islandState === "media") return mediaTitleLabel.visible ? Math.min(mediaTitleLabel.implicitWidth, 150) + 8 : 0
            if (islandState === "pomodoro") return pomoTimeLabel.implicitWidth + 8
            return 0
        }

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on anchors.leftMargin { NumberAnimation { duration: 300 } }

        StyledText {
            id: notifSummaryLabel
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: Notifications.activePopup?.summary || ""
            visible: islandState === "notification"
            opacity: parent.width > 20 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold
            color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, 200)
            elide: Text.ElideRight
        }

        StyledText {
            id: mediaTitleLabel
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: (MprisController.trackTitle && MprisController.trackTitle !== "No media") 
                  ? MprisController.trackTitle.toString().trim() : ""
            visible: text !== "" && islandState === "media"
            opacity: parent.width > 20 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold
            color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, 150)
            elide: Text.ElideRight
        }

        StyledText {
            id: pomoTimeLabel
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: PomodoroService.timeString
            opacity: parent.width > 10 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.Bold
            color: Appearance.colors.colNotchText
            font.family: Appearance.font.family.numbers
            visible: islandState === "pomodoro"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (islandState === "notification" && Notifications.activePopup) {
                    Notifications.discardNotification(Notifications.activePopup.notificationId)
                }
            }
        }
    }

    // --- BACKGROUND PILL ---
    // Fix: Size by absolute coordinate distance between the ears
    Rectangle {
        id: backgroundPill
        color: "black"
        radius: height/2
        height: parent.height
        z: -1
        
        // Manual Coordinate Calculation for robust centering
        readonly property real margin: (islandState === "idle") ? 10 : 8
        
        x: leftEar.x - margin
        width: (rightEar.x + rightEar.width) - leftEar.x + (2 * margin)
        
        // Click and Scroll handler for the notch
        FocusedScrollMouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) {
                    HyprlandData.cycleLayout();
                    return;
                }
                if (islandState === "notification" && Notifications.activePopup) {
                    Notifications.activePopup.expanded = !Notifications.activePopup.expanded
                } else if (islandState === "media") {
                    MprisController.raisePlayer()
                    GlobalStates.closeAllPanels()
                } else if (islandState === "pomodoro") {
                    GlobalStates.calendarOpen = true
                }
            }

            onScrollUp: Hyprland.dispatch("workspace r-1")
            onScrollDown: Hyprland.dispatch("workspace r+1")
        }
    }
}
