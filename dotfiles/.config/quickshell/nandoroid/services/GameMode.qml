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
    readonly property string persistencePath: HyprlandCompat.isLua
        ? "~/.config/hypr/nandoroid/user_persistence.lua"
        : "~/.config/hypr/nandoroid/user_persistence.conf"

    function toggle() {
        root.active = !root.active
        // Auto behaviors are user-configurable in Settings > System > Game Mode
        const autoDnd = Config.ready ? (Config.options.gameModeState.autoDnd ?? true) : true;
        const keepAwake = Config.ready ? (Config.options.gameModeState.keepAwake ?? true) : true;
        const autoPerformance = Config.ready ? (Config.options.gameModeState.autoPerformance ?? true) : true;

        if (root.active) {
            if (Config.ready) {
                Config.options.gameModeState.prevSilent = Notifications.silent;
                Config.options.gameModeState.prevCaffeine = Config.options.quickSettings.caffeineActive;
                Config.options.gameModeState.prevPowerProfile = PowerProfileService.currentProfile;
            }
            // Synchronize with Do Not Disturb (optional)
            if (autoDnd) {
                Notifications.silent = true;
            }
            // Keep display awake (optional, via Caffeine idle inhibitor)
            if (keepAwake && Config.ready) {
                Config.options.quickSettings.caffeineActive = true;
            }
            // Switch to Performance power profile (optional)
            if (autoPerformance) {
                PowerProfileService.setProfile("performance");
            }
            // --- 1. PAUSE LIVE WALLPAPER (keeps frozen frame, near-zero GPU) ---
            // Do NOT stop the process: the paused frame stays visible as a static
            // wallpaper, so there is no wallpaper transition and nothing to restore.
            pauseEnforceTimer.start();
            root.tryPauseWallpaper();

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
            const realPath = root.persistencePath.replace(/^~/, Directories.home.replace("file://", ""));
            if (HyprlandCompat.isLua) {
                const luaBlock = `-- GAMEMODE_START\n` +
                                 `hl.config({\n` +
                                 `    animations = { enabled = false },\n` +
                                 `    decoration = {\n` +
                                 `        shadow = { enabled = false },\n` +
                                 `        blur = { enabled = false },\n` +
                                 `        rounding = 0\n` +
                                 `    },\n` +
                                 `    general = {\n` +
                                 `        gaps_in = 0,\n` +
                                 `        gaps_out = 0,\n` +
                                 `        border_size = 1,\n` +
                                 `        allow_tearing = true\n` +
                                 `    }\n` +
                                 `})\n` +
                                 `-- GAMEMODE_END`;
                const pyCmd = `import sys\n` +
                              `path = sys.argv[1]\n` +
                              `new_block = sys.argv[2]\n` +
                              `try:\n` +
                              `    content = open(path).read()\n` +
                              `except Exception:\n` +
                              `    content = ""\n` +
                              `import re\n` +
                              `content = re.sub(r"-- GAMEMODE_START.*?-- GAMEMODE_END\\\\s*", "", content, flags=re.DOTALL)\n` +
                              `content = content.strip()\n` +
                              `if content:\n` +
                              `    content += chr(10) + chr(10)\n` +
                              `content += new_block + chr(10)\n` +
                              `open(path, "w").write(content)`
                Quickshell.execDetached(["python3", "-c", pyCmd, realPath, luaBlock]);
            } else {
                const persistCmd = `sed -i '/animations:enabled/d; /decoration:shadow:enabled/d; /decoration:blur:enabled/d; /general:gaps_in/d; /general:gaps_out/d; /general:border_size/d; /decoration:rounding/d; /general:allow_tearing/d' ${realPath} 2>/dev/null || true; ` +
                    batchCmd.map(c => `echo "${c.replace(' ', ' = ')}" >> ${realPath}`).join('; ');
                Quickshell.execDetached(["bash", "-c", persistCmd]);
            }

        } else {
            // Restore auto behaviors to pre-game-mode state
            if (Config.ready) {
                if (autoDnd) {
                    Notifications.silent = Config.options.gameModeState.prevSilent ?? false;
                }
                if (keepAwake) {
                    Config.options.quickSettings.caffeineActive = Config.options.gameModeState.prevCaffeine ?? false;
                }
                if (autoPerformance) {
                    PowerProfileService.setProfile(Config.options.gameModeState.prevPowerProfile ?? "daily");
                }
            } else {
                Notifications.silent = false;
            }

            // --- 1. RESUME LIVE WALLPAPER ---
            // We only paused it on entry, so a simple resume brings it back.
            pauseEnforceTimer.stop();
            root.resumeWallpaper();

            // --- 2. REVERT HYPRLAND ---
            // Cleanup from persistence file BEFORE reload
            const realPath = root.persistencePath.replace(/^~/, Directories.home.replace("file://", ""));
            const cleanupCmd = HyprlandCompat.isLua
                ? `sed -i '/-- GAMEMODE_START/,/-- GAMEMODE_END/d' ${realPath} 2>/dev/null || true`
                : `sed -i '/animations:enabled/d; /decoration:shadow:enabled/d; /decoration:blur:enabled/d; /general:gaps_in/d; /general:gaps_out/d; /general:border_size/d; /decoration:rounding/d; /general:allow_tearing/d' ${realPath} 2>/dev/null || true`;
            
            Quickshell.execDetached(["bash", "-c", `${cleanupCmd} && hyprctl reload`]);

            // Re-enforce other persistence (like layout) because reload wiped them
            const timer = Qt.createQmlObject('import QtQuick; Timer { interval: 800; repeat: false; }', root);
            timer.triggered.connect(() => {
                if (typeof HyprlandData !== 'undefined') {
                    // Restore layout explicitly if we saved it
                    if (Config.options.gameModeState.previousLayout !== "") {
                        Quickshell.execDetached(HyprlandCompat.keyword("general", "layout", `"${Config.options.gameModeState.previousLayout}"`));
                    }

                    if (!HyprlandCompat.isLua) {
                        const reapplyCmd = `cat ${realPath} 2>/dev/null | sed 's/ = / /g' | xargs -I {} hyprctl keyword {} || true`;
                        Quickshell.execDetached(["bash", "-c", reapplyCmd]);
                    }
                    HyprlandData.fetchInitialLayout();
                }
                
                // Clear state after restoration
                Config.options.gameModeState.previousLayout = "";
                
                timer.destroy();
            });
            timer.start();
        }
    }

    function tryPauseWallpaper() {
        // Pause whichever backend is currently running. Both pause() methods are
        // no-ops if the backend is not running or already paused.
        MpvpaperService.pause();
        WallpaperEngineService.pause();
    }

    function resumeWallpaper() {
        MpvpaperService.resume();
        WallpaperEngineService.resume();
    }

    // When a live wallpaper (re)starts while game mode is active, make sure it
    // stays paused so the shown frame is static.
    Timer {
        id: pauseEnforceTimer
        interval: 1000
        repeat: true
        onTriggered: {
            // Ignore while an apply is in flight; the service's own apply flow
            // will not run (processes are being launched) and finishes itself.
            if (MpvpaperService.isApplying || WallpaperEngineService.isApplying) return;
            root.tryPauseWallpaper();
        }
    }

    function runStartupCheck() {
        if (root.active) {
            pauseEnforceTimer.start();
            root.tryPauseWallpaper();
        }
    }

    function fetchActiveState() {
        fetchActiveStateProc.running = true
    }

    Process {
        id: fetchActiveStateProc
        running: true
        command: ["bash", "-c", "hyprctl getoption animations:enabled -j | jq -e '.int == 0 or .bool == false' >/dev/null"]
        onExited: (code) => {
            root.active = (code === 0)
            if (root.active && Config.ready) {
                root.runStartupCheck();
            }
        }
    }

    // Ensure we check startup state when config is ready if it wasn't before
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && root.active) {
                root.runStartupCheck();
            }
        }
    }
}
