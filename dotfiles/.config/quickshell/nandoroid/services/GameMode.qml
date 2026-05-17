pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

import "." 

Singleton {
    id: root

    property bool active: false
    readonly property string persistencePath: "~/.config/hypr/nandoroid/user_persistence.conf"

    function toggle() {
        root.active = !root.active
        // Synchronize with Do Not Disturb
        Notifications.silent = root.active
        
        if (root.active) {
            // --- 1. HANDLE WALLPAPER (OPTIMIZATION) ---
            const livePath = Config.options.appearance.background.liveWallpaperPath;
            if (WallpaperEngineService.isRunning || (livePath && livePath !== "")) {
                // Store the current live wallpaper path for persistence
                Config.options.gameModeState.previousLiveWallpaperPath = livePath;
                
                // 1. Stop the process
                WallpaperEngineService.stopInternal();
                
                // 2. Clear path in Config so Background.qml displays static wallpaper
                Config.options.appearance.background.liveWallpaperPath = "";
                
                // 3. Check and apply high quality screenshot ONLY IF we were in live mode
                if (livePath && livePath !== "") {
                    screenshotCheckProc.running = true;
                }
            }

            // --- 2. HANDLE HYPRLAND (PERFORMANCE) ---
            // Store current layout to restore it later
            if (typeof HyprlandData !== "undefined" && HyprlandData.activeWorkspace) {
                Config.options.gameModeState.previousLayout = HyprlandData.activeWorkspace.tiledLayout || GlobalStates.hyprlandLayout || "dwindle";
            }

            const batchCmd = [
                HyprlandCompat.keywordStr("animations", "enabled", 0),
                HyprlandCompat.keywordStr("decoration", "shadow:enabled", 0),
                HyprlandCompat.keywordStr("decoration", "blur:enabled", 0),
                HyprlandCompat.keywordStr("general", "gaps_in", 0),
                HyprlandCompat.keywordStr("general", "gaps_out", 0),
                HyprlandCompat.keywordStr("general", "border_size", 1),
                HyprlandCompat.keywordStr("decoration", "rounding", 0),
                HyprlandCompat.keywordStr("general", "allow_tearing", 1)
            ];
            
            // Apply via hyprctl immediately
            Quickshell.execDetached(HyprlandCompat.batch(batchCmd))
            
            // Persist to file
            const persistCmd = `sed -i '/animations:enabled/d; /decoration:shadow:enabled/d; /decoration:blur:enabled/d; /general:gaps_in/d; /general:gaps_out/d; /general:border_size/d; /decoration:rounding/d; /general:allow_tearing/d' ${root.persistencePath} 2>/dev/null || true; ` +
                batchCmd.map(c => `echo "${c.replace(' ', ' = ')}" >> ${root.persistencePath}`).join('; ');
            
            Quickshell.execDetached(["bash", "-c", persistCmd]);

        } else {
            // --- 1. REVERT WALLPAPER ---
            if (Config.options.gameModeState.previousLiveWallpaperPath !== "") {
                // Restore live wallpaper path to Config
                Config.options.appearance.background.liveWallpaperPath = Config.options.gameModeState.previousLiveWallpaperPath;
                
                // Restart live wallpaper
                WallpaperEngineService.applyInternal(Config.options.gameModeState.previousLiveWallpaperPath);
            }

            // --- 2. REVERT HYPRLAND ---
            // Cleanup from persistence file BEFORE reload
            const cleanupCmd = `sed -i '/animations:enabled/d; /decoration:shadow:enabled/d; /decoration:blur:enabled/d; /general:gaps_in/d; /general:gaps_out/d; /general:border_size/d; /decoration:rounding/d; /general:allow_tearing/d' ${root.persistencePath} 2>/dev/null || true`;
            
            Quickshell.execDetached(["bash", "-c", `${cleanupCmd} && hyprctl reload`]);

            // Re-enforce other persistence (like layout) because reload wiped them
            const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 800; repeat: false; }', root);
            timer.triggered.connect(() => {
                if (typeof HyprlandData !== 'undefined') {
                    // Restore layout explicitly if we saved it
                    if (Config.options.gameModeState.previousLayout !== "") {
                        Quickshell.execDetached(HyprlandCompat.keyword("general", "layout", `"${Config.options.gameModeState.previousLayout}"`));
                    }

                    const reapplyCmd = `cat ${root.persistencePath} 2>/dev/null | sed 's/ = / /g' | xargs -I {} hyprctl keyword {} || true`;
                    Quickshell.execDetached(["bash", "-c", reapplyCmd]);
                    HyprlandData.fetchInitialLayout();
                }
                
                // Clear state after restoration
                Config.options.gameModeState.previousLiveWallpaperPath = "";
                Config.options.gameModeState.previousLayout = "";
                
                timer.destroy();
            });
            timer.start();
        }
    }

    // Helper component to check screenshot file existence
    Process {
        id: screenshotCheckProc
        command: ["test", "-s", WallpaperEngineService.screenshotPath]
        onExited: (code) => {
            const livePath = Config.options.gameModeState.previousLiveWallpaperPath;
            if (code === 0 && livePath && livePath !== "") {
                // File exists and we were using a live wallpaper, use it!
                Wallpapers.select(WallpaperEngineService.screenshotPath);
            }
        }
    }

    // Specialized check for startup to handle missing /tmp files after restart
    Process {
        id: startupWallpaperCheck
        command: ["test", "-s", WallpaperEngineService.screenshotPath]
        onExited: (code) => {
            const livePath = Config.options.gameModeState.previousLiveWallpaperPath;
            if (code === 0 && livePath && livePath !== "") {
                // Screenshot exists and we should be in WE mode (via persistence)
                Wallpapers.select(WallpaperEngineService.screenshotPath);
            } else {
                // Either no screenshot or we weren't in WE mode.
                // If livePath is empty, it means we chose a static wallpaper before.
                if (livePath && livePath !== "") {
                    recoveryTimer.start();
                }
            }
        }
    }

    Timer {
        id: recoveryTimer
        interval: 1000 // Delay to ensure Wallpaper service has loaded favorites
        repeat: false
        onTriggered: {
            if (!Wallpapers.selectRandomFavorite()) {
                const fallback = Config.options.appearance.background.autoCycleDirectory || (Directories.home + "/Pictures/Wallpapers");
                Wallpapers.selectRandomFromDirectory(fallback);
            }
        }
    }

    function fetchActiveState() {
        fetchActiveStateProc.running = true
    }

    Process {
        id: fetchActiveStateProc
        running: true
        command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -eq 0`]
        onExited: (code) => {
            root.active = (code === 0)
            if (root.active && Config.ready) {
                startupWallpaperCheck.running = true;
            }
        }
    }

    // Ensure we check startup state when config is ready if it wasn't before
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && root.active) {
                startupWallpaperCheck.running = true;
            }
        }
    }
}
