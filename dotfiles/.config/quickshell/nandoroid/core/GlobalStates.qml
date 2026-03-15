pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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
    property bool dashboardOpen: false
    property bool systemMonitorOpen: false
    property bool regionSelectorOpen: false
    property bool overviewOpen: false
    property bool dockMenuOpen: false
    property bool mediaNotchOpen: false
    property bool trayOverflowOpen: false
    property real trayPosX: 0
    property var activeMediaNotchScreen: null
    property var activeScreen: Quickshell.screens[0]
    property string wallpaperSelectorTarget: "desktop" // "desktop" or "lock"
    
    // --- Media Notch Timing Logic ---
    property alias mediaNotchTimer: mediaNotchTimer
    Timer { 
        id: mediaNotchTimer
        interval: 2000 // Popup persists for 2 seconds
        onTriggered: {
            mediaNotchOpen = false;
            activeMediaNotchScreen = null;
        }
    }

    function openMediaNotch(screen = null) {
        mediaNotchTimer.stop();
        if (screen !== null) activeMediaNotchScreen = screen;
        mediaNotchOpen = true;
    }

    function stopMediaNotchTimer() {
        mediaNotchTimer.stop();
    }

    function closeMediaNotchWithDelay() {
        mediaNotchTimer.start();
    }
    // ---------------------------------

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
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onQuickSettingsOpenChanged: {
        if (quickSettingsOpen) {
            notificationCenterOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onLauncherOpenChanged: {
        if (launcherOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onSettingsOpenChanged: {
        if (settingsOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onQuickWallpaperOpenChanged: {
        if (quickWallpaperOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onDashboardOpenChanged: {
        if (dashboardOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            sessionOpen = false
        }
    }

    onSystemMonitorOpenChanged: {
        if (systemMonitorOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onSpotlightOpenChanged: {
        if (spotlightOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            quickWallpaperOpen = false
            dashboardOpen = false
            sessionOpen = false
        }
    }

    onSessionOpenChanged: {
        if (sessionOpen) {
            notificationCenterOpen = false
            quickSettingsOpen = false
            launcherOpen = false
            spotlightOpen = false
            quickWallpaperOpen = false
            dashboardOpen = false
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
            dashboardOpen = false
            sessionOpen = false
            systemMonitorOpen = false
            settingsOpen = false
        }
    }

    function closeAllPanels() {
        notificationCenterOpen = false
        quickSettingsOpen = false
        launcherOpen = false
        spotlightOpen = false
        settingsOpen = false
        quickWallpaperOpen = false
        dashboardOpen = false
        systemMonitorOpen = false
        sessionOpen = false
        overviewOpen = false
        mediaNotchOpen = false
        trayOverflowOpen = false
        // Note: wallpaperSelectorOpen and regionSelectorOpen are excluded
    }

    function activateSettings() {
        const cmd = `
            # Find settings window address
            ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "Settings" and .class == "org.quickshell") | .address')
            
            if [ -z "$ADDR" ] || [ "$ADDR" = "null" ]; then
                # Not open, so open it
                qs -c nandoroid ipc call settings open_direct
                exit 0
            fi

            # Check if it's already the active window
            ACTIVE_ADDR=$(hyprctl activewindow -j | jq -r .address)
            
            if [ "$ADDR" = "$ACTIVE_ADDR" ]; then
                # Already focused here, so close it
                qs -c nandoroid ipc call settings close
            else
                # Pull it here! Get current workspace name
                CUR_WS=$(hyprctl activeworkspace -j | jq -r .name)
                
                # Move window to current workspace silently
                hyprctl dispatch movetoworkspacesilent "name:$CUR_WS,address:$ADDR"
                
                # Micro-delay to let Hyprland update internal state, then focus
                sleep 0.05
                hyprctl dispatch focuswindow "address:$ADDR"
            fi
        `;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    function activateSystemMonitor() {
        const cmd = `
            # Find System Monitor window address
            ADDR=$(hyprctl clients -j | jq -r '.[] | select(.title == "System Monitor" and .class == "org.quickshell") | .address')
            
            if [ -z "$ADDR" ] || [ "$ADDR" = "null" ]; then
                # Not open, so open it
                qs -c nandoroid ipc call systemmonitor open_direct
                exit 0
            fi

            # Check if it's already the active window
            ACTIVE_ADDR=$(hyprctl activewindow -j | jq -r .address)
            
            if [ "$ADDR" = "$ACTIVE_ADDR" ]; then
                # Already focused here, so close it
                qs -c nandoroid ipc call systemmonitor close
            else
                # Pull it here! Get current workspace name
                CUR_WS=$(hyprctl activeworkspace -j | jq -r .name)
                
                # Move window to current workspace silently
                hyprctl dispatch movetoworkspacesilent "name:$CUR_WS,address:$ADDR"
                
                # Micro-delay
                sleep 0.05
                hyprctl dispatch focuswindow "address:$ADDR"
            fi
        `;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    // ═══════════════════════════════════════════════════════════════
    // HYPRLAND LAYOUT STATE (dynamic, not persisted)
    // ═══════════════════════════════════════════════════════════════
    property string hyprlandLayout: "dwindle"
    property bool hyprlandLayoutReady: false
    readonly property var availableLayouts: ["dwindle", "master", "scrolling"]

    function setHyprlandLayout(layout) {
        if (availableLayouts.includes(layout)) {
            hyprlandLayout = layout;
        }
    }

    function cycleHyprlandLayout() {
        const currentIndex = availableLayouts.indexOf(hyprlandLayout);
        const nextIndex = (currentIndex + 1) % availableLayouts.length;
        hyprlandLayout = availableLayouts[nextIndex];
    }

    // Query current layout from Hyprland on startup
    Process {
        id: layoutQueryProcess
        command: ["hyprctl", "getoption", "general:layout", "-j"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data);
                    if (parsed.str && root.availableLayouts.includes(parsed.str)) {
                        root.hyprlandLayout = parsed.str;

                    }
                } catch (e) {

                }
                root.hyprlandLayoutReady = true;
            }
        }
        onExited: {
            // Mark as ready even if parsing failed
            root.hyprlandLayoutReady = true;
        }
    }
}
