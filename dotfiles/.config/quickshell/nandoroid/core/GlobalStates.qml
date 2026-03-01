pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Central state management for all NAnDoroid panels.
 * Controls visibility of the status bar, notification center, and quick settings.
 */
Singleton {
    id: root

    property bool statusBarVisible: true
    property bool notificationCenterOpen: false
    property bool quickSettingsOpen: false
    property bool sessionOpen: false
    property bool quickSettingsEditMode: false
    property bool wallpaperSelectorOpen: false
    property bool launcherOpen: false
    property bool spotlightOpen: false
    property string initialSpotlightQuery: ""
    property bool settingsOpen: false
    property bool quickWallpaperOpen: false
    property bool calendarOpen: false
    property bool systemMonitorOpen: false
    property bool regionSelectorOpen: false
    property bool overviewOpen: false
    property string overviewStyle: "auto" // "auto", "dwindle", or "scrolling"
    property string wallpaperSelectorTarget: "desktop" // "desktop" or "lock"
    property var wallpaperSelectorWindow: null // For focus-grab synchronization
    property var activeComboBox: null

    // Settings Navigation
    property int settingsPageIndex: 0
    property bool settingsBluetoothPairMode: false

    // System Monitor Navigation
    property int systemMonitorIndex: 0
    property int performanceSubIndex: 0

    // Lock screen state
    property bool screenLocked: false
    property bool screenUnlockFailed: false
    property bool screenLockContainsCharacters: false

    onNotificationCenterOpenChanged: {
        if (notificationCenterOpen) {
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onQuickSettingsOpenChanged: {
        if (quickSettingsOpen) {
            notificationCenterOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onLauncherOpenChanged: {
        if (launcherOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onSettingsOpenChanged: {
        if (settingsOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onQuickWallpaperOpenChanged: {
        if (quickWallpaperOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onCalendarOpenChanged: {
        if (calendarOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onSystemMonitorOpenChanged: {
        if (systemMonitorOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onSpotlightOpenChanged: {
        if (spotlightOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
            overviewOpen = false
        }
    }

    onSessionOpenChanged: {
        if (sessionOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            overviewOpen = false
        }
    }

    onRegionSelectorOpenChanged: {
        if (regionSelectorOpen) {
            // Do nothing, let other panels stay open.
        }
    }

    onOverviewOpenChanged: {
        if (overviewOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            calendarOpen = false
            sessionOpen = false
        }
    }

    function closeAllPanels() {
        notificationCenterOpen = false
        quickSettingsOpen = false
        launcherOpen = false
        spotlightOpen = false
        settingsOpen = false
        quickWallpaperOpen = false
        calendarOpen = false
        systemMonitorOpen = false
        sessionOpen = false
        overviewOpen = false
        // Note: wallpaperSelectorOpen and regionSelectorOpen are excluded
    }
}
