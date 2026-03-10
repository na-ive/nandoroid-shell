pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Handles EasyEffects active state and presets.
 */
Singleton {
    id: root

    property bool available: false
    property bool active: false

    function fetchAvailability() {
        fetchAvailabilityProc.running = true
    }

    function fetchActiveState() {
        fetchActiveStateProc.running = true
    }

    function disable() {
        root.active = false
        if (Config.ready && Config.options.system) {
            Config.options.system.easyeffectsEnabled = false;
        }
        Quickshell.execDetached(["bash", "-c", "pkill easyeffects || flatpak pkill com.github.wwmm.easyeffects"])
    }

    function enable() {
        root.active = true
        if (Config.ready && Config.options.system) {
            Config.options.system.easyeffectsEnabled = true;
        }
        Quickshell.execDetached(["bash", "-c", "easyeffects --hide-window --service-mode || flatpak run com.github.wwmm.easyeffects --hide-window --service-mode"])
    }

    function toggle() {
        if (root.active) {
            root.disable()
        } else {
            root.enable()
        }
    }

    // Polling timer to keep the toggle UI accurate to the system state
    Timer {
        id: pollTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.fetchActiveState()
    }

    // ENFORCEMENT: On startup, make reality match the user's last preference
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && Config.options.system) {
                const shouldBeEnabled = Config.options.system.easyeffectsEnabled;
                
                // If user wants it OFF, but exec-once (or something else) started it, KILL IT.
                if (!shouldBeEnabled) {
                    // We run pkill regardless to be sure it follows the "OFF" preference
                    Quickshell.execDetached(["bash", "-c", "pkill easyeffects || flatpak pkill com.github.wwmm.easyeffects"])
                } 
                // If user wants it ON, make sure it's running
                else if (shouldBeEnabled) {
                    root.enable();
                }
            }
        }
    }

    Process {
        id: fetchAvailabilityProc
        running: true
        command: ["bash", "-c", "command -v easyeffects || flatpak info com.github.wwmm.easyeffects > /dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.available = exitCode === 0
        }
    }

    Process {
        id: fetchActiveStateProc
        running: true
        command: ["bash", "-c", "pidof easyeffects || flatpak ps | grep com.github.wwmm.easyeffects > /dev/null 2>&1"]
        onExited: (exitCode, exitStatus) => {
            root.active = exitCode === 0
        }
    }
}
