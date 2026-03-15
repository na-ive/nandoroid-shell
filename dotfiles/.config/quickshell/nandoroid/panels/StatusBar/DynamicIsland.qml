import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import Quickshell.Hyprland
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

/**
 * Universal Dynamic Island container for the status bar.
 * Refactored for Waterdrop Style support.
 */
Item {
    id: root
    
    property HyprlandMonitor monitor
    property bool pomodoroActive: PomodoroService.isSessionRunning
    property real indicatorWidth: 52 
    
    width: 0 
    height: 40 // Matches status bar height for safe rendering

    readonly property string islandStyle: Config.options.statusBar?.islandStyle ?? "pill"
    readonly property bool isWaterdrop: islandStyle === "waterdrop"

    // Expose the background pill for absolute anchoring
    property alias pill: backgroundPill

    // --- State Logic ---
    property bool mediaShowing: false
    Timer { id: mediaTimer; interval: 3000; onTriggered: root.mediaShowing = false }

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
        if (ScreenRecord.active) return "recording"
        if ((mediaShowing || GlobalStates.mediaNotchOpen) && MprisController.activePlayer) return "media"
        if (pomodoroActive) return "pomodoro"
        return "idle"
    }

    // Media Width Synchronization Logic
    readonly property real mediaLeftNaturalWidth: {
        let w = 0
        if (mediaLogo.visible) w += 18 + 6
        if (mediaArtistLabel.visible) w += mediaArtistLabel.implicitWidth + 4
        return w > 0 ? w + 4 : 0
    }

    readonly property real mediaRightNaturalWidth: {
        return (mediaTitleLabel.visible && mediaTitleLabel.text !== "") ? mediaTitleLabel.implicitWidth + 12 : 0
    }

    // Dynamic Max Width Logic - HUD mode is tighter because Clock/Date are centered
    readonly property real earMaxWidthNormal: 150
    readonly property real earMaxWidthHud: 100 
    readonly property real currentEarMaxWidth: (islandState === "idle") ? earMaxWidthNormal : earMaxWidthHud

    // Balanced Width Calculation - Use the LARGER side as reference, clamped by max width
    readonly property real sharedMediaWidth: {
        if (islandState !== "media") return 0
        let maxNatural = Math.max(mediaLeftNaturalWidth, mediaRightNaturalWidth)
        return Math.min(maxNatural, root.currentEarMaxWidth)
    }

    // Gap width: 4px in idle, tight 2px in active states.
    readonly property real gapHalf: (indicatorWidth / 2) + (islandState === "idle" ? 4 : 2)

    // --- LEFT EAR ---
    Item {
        id: leftEar
        anchors.right: root.left
        anchors.rightMargin: root.gapHalf
        y: 6 
        height: 28
        clip: true
        
        HoverHandler {
            enabled: islandState === "media"
            onHoveredChanged: {
                if (hovered && Config.options.media.enableMediaHover) {
                    GlobalStates.openMediaNotch(root.QsWindow.window.screen);
                } else {
                    GlobalStates.closeMediaNotchWithDelay();
                }
            }
        }
        
        width: {
            if (islandState === "notification") {
                let w = 0
                if (notifLogo.visible) w += 20 + 6
                if (notifAppNameLabel.visible) w += Math.min(notifAppNameLabel.implicitWidth, 80) + 4
                let finalW = w > 0 ? w + 4 : 0
                return Math.min(finalW, root.currentEarMaxWidth)
            }
            if (islandState === "recording") return Math.min(24, root.currentEarMaxWidth)
            if (islandState === "media") {
                let w = (Config.ready && Config.options.media && Config.options.media.balancedEars) 
                    ? root.sharedMediaWidth : root.mediaLeftNaturalWidth
                return Math.min(w, root.currentEarMaxWidth)
            }
            if (islandState === "pomodoro") return Math.min(pomoModeLabel.implicitWidth + 8, root.currentEarMaxWidth)
            return 0
        }

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        // Container for notification content - centered
        Row {
            anchors.centerIn: parent
            visible: islandState === "notification"
            spacing: 6
            NotificationAppIcon {
                id: notifLogo
                width: 18; height: 18; implicitSize: 18
                visible: islandState === "notification"
                opacity: parent.parent.width > 24 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                appIcon: Notifications.activePopup?.appIcon || Notifications.activePopup?.appName || ""
                image: Notifications.activePopup?.image || ""
                summary: Notifications.activePopup?.summary || ""
                urgency: Notifications.activePopup?.urgency || "normal"
                color: "transparent"
            }
            StyledText {
                id: notifAppNameLabel
                text: Notifications.activePopup?.appName || "Notification"
                visible: islandState === "notification"
                opacity: parent.parent.width > 30 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                font.pixelSize: 12; font.weight: Font.Medium
                color: Appearance.colors.colNotchText
                width: Math.min(implicitWidth, root.currentEarMaxWidth - (notifLogo.visible ? 28 : 8))
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Recording Icon - centered
        Item {
            anchors.centerIn: parent
            visible: islandState === "recording"
            opacity: parent.width > 12 ? 1 : 0
            width: 16; height: 16
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MaterialSymbol {
                id: recordIcon; anchors.centerIn: parent; text: "screen_record"; iconSize: 16
                color: Appearance.m3colors.m3error; fill: 1
                SequentialAnimation on opacity {
                    running: recordIcon.visible; loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.3; to: 1; duration: 800; easing.type: Easing.InOutSine }
                }
            }
        }

        // Media Group - centered
        Row {
            id: leftMediaGroup
            anchors.centerIn: parent
            visible: islandState === "media"
            spacing: 6
            Loader {
                id: mediaLogo; width: 18; height: 18; visible: islandState === "media"
                opacity: parent.parent.width > 24 ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
                property string activeEntryStr: {
                    if (!MprisController.activePlayer) return "";
                    let entry = MprisController.activePlayer.desktopEntry.toString();
                    let identity = MprisController.activePlayer.identity ? MprisController.activePlayer.identity.toString() : "";
                    return AppSearch.guessIcon(entry, "", identity);
                }
                
                sourceComponent: Component { 
                    Item {
                        width: 18; height: 18
                        IconImage { 
                            id: innerImg; anchors.fill: parent; 
                            source: mediaLogo.activeEntryStr !== "" ? Quickshell.iconPath(mediaLogo.activeEntryStr, "") : ""
                            visible: status === Image.Ready
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent; text: "music_note"; iconSize: 18
                            color: Appearance.colors.colNotchText; visible: innerImg.status !== Image.Ready
                        }
                    }
                }
            }
            StyledText {
                id: mediaArtistLabel; text: MprisController.trackArtist || "Unknown Artist"
                visible: islandState === "media"; opacity: parent.parent.width > 30 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                font.pixelSize: 12; font.weight: Font.Medium; color: Appearance.colors.colNotchText
                width: Math.min(implicitWidth, parent.parent.width - (mediaLogo.visible ? 28 : 8))
                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
            }
        }

        // Pomodoro - centered
        StyledText {
            id: pomoModeLabel; anchors.centerIn: parent
            text: PomodoroService.modeName
            opacity: parent.width > 20 ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            visible: islandState === "pomodoro"
        }
    }

    // --- RIGHT EAR ---
    Item {
        id: rightEar
        anchors.left: root.right
        anchors.leftMargin: root.gapHalf
        y: 6
        height: 28
        clip: true
        
        HoverHandler {
            enabled: islandState === "media"
            onHoveredChanged: {
                if (hovered && Config.options.media.enableMediaHover) {
                    GlobalStates.openMediaNotch(root.QsWindow.window.screen);
                } else {
                    GlobalStates.closeMediaNotchWithDelay();
                }
            }
        }
        
        width: {
            if (islandState === "notification") return notifSummaryLabel.visible ? Math.min(notifSummaryLabel.implicitWidth, root.currentEarMaxWidth - 8) + 8 : 0
            if (islandState === "recording") return Math.min(recordTimeLabel.implicitWidth + 8, root.currentEarMaxWidth)
            if (islandState === "media") {
                let w = (Config.ready && Config.options.media && Config.options.media.balancedEars) 
                    ? root.sharedMediaWidth : root.mediaRightNaturalWidth
                return Math.min(w, root.currentEarMaxWidth)
            }
            if (islandState === "pomodoro") return Math.min(pomoTimeLabel.implicitWidth + 8, root.currentEarMaxWidth)
            return 0
        }

        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        Behavior on anchors.leftMargin { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

        StyledText {
            id: notifSummaryLabel; anchors.centerIn: parent
            text: Notifications.activePopup?.summary || ""
            visible: islandState === "notification"
            opacity: parent.width > 20 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold
            color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, root.currentEarMaxWidth - 8)
            elide: Text.ElideRight
        }

        StyledText {
            id: recordTimeLabel; anchors.centerIn: parent
            text: Functions.General.formatDuration(ScreenRecord.seconds)
            opacity: parent.width > 10 ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            font.family: Appearance.font.family.numbers; visible: islandState === "recording"
        }

        StyledText {
            id: mediaTitleLabel; anchors.centerIn: parent
            text: MprisController.trackTitle || ""
            visible: text !== "" && islandState === "media"; opacity: parent.width > 20 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.DemiBold; color: Appearance.colors.colNotchText
            width: Math.min(implicitWidth, parent.width - 8)
            elide: Text.ElideRight
        }

        StyledText {
            id: pomoTimeLabel; anchors.centerIn: parent
            text: PomodoroService.timeString
            opacity: parent.width > 10 ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 200 } }
            font.pixelSize: 12; font.weight: Font.Bold; color: Appearance.colors.colNotchText
            font.family: Appearance.font.family.numbers; visible: islandState === "pomodoro"
        }
    }

    // --- BACKGROUND PILL ---
    Rectangle {
        id: backgroundPill
        color: "black"
        
        // Idle: y=6, height=28. Waterdrop: y=0, height=34.
        y: isWaterdrop ? 0 : 6
        height: isWaterdrop ? 34 : 28
        radius: height / 2
        
        z: -1
        readonly property real margin: (islandState === "idle") ? 10 : 8
        x: leftEar.x - margin
        width: (rightEar.x + rightEar.width) - leftEar.x + (2 * margin)

        // The "Flattener" - Square off the top part
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            height: parent.radius
            color: "black"
            visible: isWaterdrop
        }

        // Concave Corners
        RoundCorner {
            anchors.right: parent.left; anchors.top: parent.top
            implicitSize: 12; color: "black"; corner: RoundCorner.CornerEnum.TopRight
            visible: isWaterdrop; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        RoundCorner {
            anchors.left: parent.right; anchors.top: parent.top
            implicitSize: 12; color: "black"; corner: RoundCorner.CornerEnum.TopLeft
            visible: isWaterdrop; opacity: visible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }
        }

        Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
        
        FocusedScrollMouseArea {
            anchors.fill: parent; hoverEnabled: true; preventStealing: true; cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onEntered: { if (MprisController.activePlayer) { root.mediaShowing = true; mediaTimer.restart(); if (GlobalStates.mediaNotchOpen) GlobalStates.stopMediaNotchTimer(); } }
            onExited: GlobalStates.closeMediaNotchWithDelay();
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) { HyprlandData.cycleLayout(); return; }
                if (islandState === "recording") { if (mouse.button === Qt.LeftButton) ScreenRecord.stop(); return; }
                if (mouse.button === Qt.RightButton) { GlobalStates.overviewOpen = !GlobalStates.overviewOpen; return; }
                if (islandState === "notification" && Notifications.activePopup) { Notifications.activePopup.expanded = !Notifications.activePopup.expanded }
                else if (islandState === "media") { MprisController.raisePlayer(); GlobalStates.closeAllPanels() }
                else if (islandState === "pomodoro") { GlobalStates.dashboardOpen = true }
            }
            onScrollUp: {
                if (root.monitor && root.monitor.activeWorkspace && root.monitor.activeWorkspace.id > 1) {
                    Hyprland.dispatch("workspace r-1")
                }
            }
            onScrollDown: Hyprland.dispatch("workspace r+1")
        }
    }
}
