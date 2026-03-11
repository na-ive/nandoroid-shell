pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property string currentProfile: "daily"
    property bool hasPowerProfilesCtl: false

    readonly property bool useCustomProfile: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.enabled : false
    readonly property string customPath: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.customPath : "/tmp/ryzen_mode"

    onUseCustomProfileChanged: statusProc.running = true
    onCustomPathChanged: statusProc.running = true

    Component.onCompleted: {
        checkToolsProc.running = true;
    }

    Process {
        id: checkToolsProc
        command: ["which", "powerprofilesctl"]
        onExited: (code) => {
            root.hasPowerProfilesCtl = (code === 0);
        }
    }

    function setProfile(profile) {
        if (root.currentProfile === profile) return;
        
        // Optimistic update for UI feel
        root.currentProfile = profile;
        
        // Write to custom file if enabled
        if (useCustomProfile) {
            Quickshell.execDetached(["bash", "-c", `echo "${profile}" > "${customPath}"`]);
        }

        // Powerprofilesctl fallback/sync
        if (hasPowerProfilesCtl) {
            let mapping = {
                "daily": "power-saver",
                "balanced": "balanced",
                "performance": "performance"
            };
            Quickshell.execDetached(["powerprofilesctl", "set", mapping[profile] || "balanced"]);
        }
    }

    function cycle() {
        if (currentProfile === "daily") setProfile("balanced");
        else if (currentProfile === "balanced") setProfile("performance");
        else setProfile("daily");
    }

    // ── Status Polling (Near-instants sync) ──
    Process {
        id: statusProc
        command: ["bash", "-c", useCustomProfile ? `cat "${customPath}" 2>/dev/null || echo "error"` : "powerprofilesctl get 2>/dev/null || echo 'balanced'"]
        stdout: SplitParser {
            onRead: data => {
                const val = data.trim().toLowerCase();
                
                if (useCustomProfile) {
                    if (["daily", "balanced", "performance"].includes(val)) {
                        if (root.currentProfile !== val) root.currentProfile = val;
                    }
                } else {
                    // Match active profile from powerprofilesctl output
                    let active = val;
                    if (val.includes("*")) {
                        const lines = val.split("\n");
                        for (let line of lines) {
                            if (line.trim().startsWith("*")) {
                                active = line.replace("*", "").split(":")[0].trim().toLowerCase();
                                break;
                            }
                        }
                    }
                    
                    let translated = "balanced";
                    if (active.includes("power-saver")) translated = "daily";
                    else if (active.includes("performance")) translated = "performance";
                    
                    if (root.currentProfile !== translated) root.currentProfile = translated;
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }
}
