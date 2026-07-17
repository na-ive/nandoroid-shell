pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../core"

Singleton {
    id: root

    property string currentProfile: "daily"

    readonly property bool useCustomProfile: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.enabled : false
    readonly property string customPath: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.customPath : "/tmp/ryzen_mode"

    // Reactive: PowerProfiles.profileChanged fires on D-Bus signal
    property var _ppProfile: useCustomProfile ? null : PowerProfiles.profile
    on_PpProfileChanged: {
        if (!useCustomProfile && _ppProfile !== null) {
            const map = ["daily", "balanced", "performance"];
            const val = map[_ppProfile] || "balanced";
            if (root.currentProfile !== val) root.currentProfile = val;
        }
    }

    // Reactive: custom path file changes via inotify
    FileView {
        id: customFileView
        path: root.useCustomProfile ? root.customPath : ""
        watchChanges: true
        onFileChanged: customFileView.reload()
        onLoaded: {
            const val = customFileView.text().trim().toLowerCase();
            if (root.useCustomProfile && ["daily", "balanced", "performance"].includes(val)) {
                if (root.currentProfile !== val) root.currentProfile = val;
            }
        }
    }

    onUseCustomProfileChanged: {
        if (useCustomProfile) {
            customFileView.path = root.customPath;
            customFileView.reload();
        } else {
            customFileView.path = "";
            // Read from PowerProfiles immediately
            const map = ["daily", "balanced", "performance"];
            const val = map[PowerProfiles.profile] || "balanced";
            if (root.currentProfile !== val) root.currentProfile = val;
        }
    }

    onCustomPathChanged: {
        if (useCustomProfile) {
            customFileView.path = root.customPath;
            customFileView.reload();
        }
    }

    function setProfile(profile) {
        if (root.currentProfile === profile) return;
        
        // Optimistic update for UI feel
        root.currentProfile = profile;
        
        // Write to custom file if enabled
        if (useCustomProfile) {
            Quickshell.execDetached(["bash", "-c", `echo "${profile}" > "${customPath}"`]);
        } else {
            // Use PowerProfiles D-Bus API
            const map = { "daily": "PowerSaver", "balanced": "Balanced", "performance": "Performance" };
            PowerProfiles.profile = map[profile] || "Balanced";
        }
    }

    function cycle() {
        if (currentProfile === "daily") setProfile("balanced");
        else if (currentProfile === "balanced") setProfile("performance");
        else setProfile("daily");
    }
}
