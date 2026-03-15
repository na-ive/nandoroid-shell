//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import "core"
import "services"
import "widgets"
import "panels/StatusBar"
import "panels/NotificationCenter"
import "panels/QuickSettings"
import "panels/WallpaperSelector"
import "panels/Background"
import "panels/NotificationPopup"
import "panels/OSD"
import "panels/Lock"
import "panels/Session"
import "panels/Launcher"
import "panels/Dashboard"
import "panels/SystemMonitor"
import "panels/Polkit"
import "panels/RegionSelector"
import "panels/ScreenCorners"
import "panels/Overview"
import "panels/Dock"

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Wallpapers.syncSettings() // Ensure Wallpapers service is active and synced
        SmartAutomation.runAutomationCycle() // Kickstart smart automation
        if (Caffeine.active) console.log("Caffeine active on startup")
    }

    // ── Phase 0: Lock Screen ──
    Lock {}

    // ── Phase 1: Background ──
    Background {}

    // ── Phase 2: Status Bar ──
    StatusBar {}
    StatusBarTrayOverflow { id: trayOverflow }
    MediaNotchPopup {}

    // ── Phase 3: Popups ──
    NotificationPopup {}

    // ── Phase 4: Notification Center ──
    NotificationCenter {}

    // ── Phase 5: Quick Settings ──
    QuickSettings {}

    // ── Phase 5.5: Quick Wallpaper ──
    QuickWallpaper {}

    // ── Phase 6: Wallpaper Selector & Screen Decor ──
    WallpaperSelector {}
    ScreenCorners {}

    IpcHandler {
        target: "wallpaper"
        function openDesktop() {

            GlobalStates.wallpaperSelectorTarget = "desktop";
            GlobalStates.wallpaperSelectorOpen = true;
        }

        function openLock() {

            GlobalStates.wallpaperSelectorTarget = "lock";
            GlobalStates.wallpaperSelectorOpen = true;
        }
    }

    // ── Phase 7: OSD ──
    OSD {}

    // ── Phase 8: Session Menu ──
    SessionPanel {}

    // ── Phase 8.5: Dock ──
    Dock {}

    // ── Phase 9: Launcher & Overview ──
    Launcher {}
    OverviewPopup {}

    SpotlightLauncher {}

    // ── Phase 10: Settings ──
    Settings {}

    // ── Phase 11: Dashboard ──
    Dashboard {}

    // ── Phase 12: System Monitor ──
    SystemMonitorPanel {}

    // ── Phase 13: Polkit Agent ──
    PolkitPanel {}

    IpcHandler {
        target: "launcher"
        function open() { GlobalStates.launcherOpen = true }
        function close() { GlobalStates.launcherOpen = false }
        function toggle() { GlobalStates.launcherOpen = !GlobalStates.launcherOpen }
    }

    IpcHandler {
        target: "spotlight"
        function open() { 
            GlobalStates.initialSpotlightQuery = ""; 
            GlobalStates.spotlightOpen = true 
        }
        function close() { GlobalStates.spotlightOpen = false }
        function toggle() { 
            GlobalStates.initialSpotlightQuery = ""; 
            GlobalStates.spotlightOpen = !GlobalStates.spotlightOpen 
        }

        function browse_avatar() {
            avatarPickerProc.running = true;
        }
    }

    Process {
        id: avatarPickerProc
        command: ["zenity", "--file-selection", "--title=Select Avatar", "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.svg"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    Config.options.bar.avatar_path = path;
                }
            }
        }
    }

    IpcHandler {
        target: "settings"
        function open() { GlobalStates.activateSettings() }
        function open_direct() { GlobalStates.settingsOpen = true }
        function close() { GlobalStates.settingsOpen = false }
        function toggle() { GlobalStates.activateSettings() }
    }

    IpcHandler {
        target: "notifications"
        function open() { GlobalStates.notificationCenterOpen = true }
        function close() { GlobalStates.notificationCenterOpen = false }
        function toggle() { GlobalStates.notificationCenterOpen = !GlobalStates.notificationCenterOpen }
    }

    IpcHandler {
        target: "quicksettings"
        function open() { GlobalStates.quickSettingsOpen = true }
        function close() { GlobalStates.quickSettingsOpen = false }
        function toggle() { GlobalStates.quickSettingsOpen = !GlobalStates.quickSettingsOpen }
    }

    IpcHandler {
        target: "overview"
        function open() { GlobalStates.overviewOpen = true }
        function close() { GlobalStates.overviewOpen = false }
        function toggle() { GlobalStates.overviewOpen = !GlobalStates.overviewOpen }
    }

    IpcHandler {
        target: "quickwallpaper"
        function open() { GlobalStates.quickWallpaperOpen = true }
        function close() { GlobalStates.quickWallpaperOpen = false }
        function toggle() { GlobalStates.quickWallpaperOpen = !GlobalStates.quickWallpaperOpen }
    }

    IpcHandler {
        target: "dashboard"
        function open() { GlobalStates.dashboardOpen = true }
        function close() { GlobalStates.dashboardOpen = false }
        function toggle() { GlobalStates.dashboardOpen = !GlobalStates.dashboardOpen }
    }

    // ==========================================
    // Native Wayland Global Shortcuts
    // ==========================================
    GlobalShortcut {
        name: "spotlightEmoji"
        description: "Open Spotlight in Emoji mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = ":"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightFiles"
        description: "Open Spotlight in File search mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = "/"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightCommand"
        description: "Open Spotlight in Command mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = ">"
            GlobalStates.spotlightOpen = true
        }
    }

    GlobalShortcut {
        name: "spotlightClipboard"
        description: "Open Spotlight in Clipboard mode"
        onPressed: {
            GlobalStates.initialSpotlightQuery = ";"
            GlobalStates.spotlightOpen = true
        }
    }

    IpcHandler {
        target: "session"
        function open() { GlobalStates.sessionOpen = true }
        function close() { GlobalStates.sessionOpen = false }
        function toggle() { GlobalStates.sessionOpen = !GlobalStates.sessionOpen }
    }

    IpcHandler {
        target: "pomodoro"
        function start() { PomodoroService.start() }
        function pause() { PomodoroService.pause() }
        function stop() { PomodoroService.stop() }
        function reset() { 
            PomodoroService.reset();
            PomodoroService.rotations = 0;
        }
    }

    IpcHandler {
        target: "systemmonitor"
        function open() { GlobalStates.activateSystemMonitor() }
        function open_direct() { GlobalStates.systemMonitorOpen = true }
        function close() { GlobalStates.systemMonitorOpen = false }
        function toggle() { GlobalStates.activateSystemMonitor() }
    }

    // ── Phase 14: Region Selector ──
    RegionSelector { id: regionSelector }
    RecordingMarker {}

    GlobalShortcut {
        name: "regionScreenshot"
        description: "Takes a screenshot of the selected region"
        onPressed: regionSelector.screenshot()
    }
    GlobalShortcut {
        name: "regionSearch"
        description: "Searches the selected region"
        onPressed: regionSelector.search()
    }
    GlobalShortcut {
        name: "regionOcr"
        description: "Recognizes text in the selected region"
        onPressed: regionSelector.ocr()
    }
    GlobalShortcut {
        name: "regionRecord"
        description: "Records the selected region"
        onPressed: regionSelector.record()
    }
    GlobalShortcut {
        name: "regionRecordWithSound"
        description: "Records the selected region with sound"
        onPressed: regionSelector.recordWithSound()
    }
}
