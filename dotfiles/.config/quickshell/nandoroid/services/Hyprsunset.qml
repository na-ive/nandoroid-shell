pragma Singleton

// Adapted from the 'ii' example (Hyprsunset.qml)
// Manages night mode via hyprsunset with persistence in Config.

import QtQuick
import "../core"
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool ready: Config.ready
    property int colorTemperature: ready && Config.options.nightMode ? Config.options.nightMode.colorTemperature : 4000
    property bool active: ready && Config.options.nightMode ? Config.options.nightMode.active : false

    // Fetch current state from hyprctl on startup to reconcile with config
    Component.onCompleted: fetchState()

    function fetchState() {
        if (!root.ready) return;
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        running: false
        command: ["bash", "-c", "hyprctl hyprsunset temperature 2>/dev/null"]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                const output = stateCollector.text.trim();
                let systemActive = false;
                if (output.length === 0 || output.startsWith("Couldn't") || output.startsWith("Error")) {
                    systemActive = false;
                } else {
                    const temp = parseInt(output);
                    systemActive = (!isNaN(temp) && temp !== 6500);
                }
                
                // Reconcile system state with config
                if (systemActive !== root.active) {
                    if (root.active) enable();
                    else disable();
                }
            }
        }
    }

    function enable() {
        if (!root.ready) return;
        Config.options.nightMode.active = true;
        Quickshell.execDetached(["bash", "-c", `pidof hyprsunset && hyprctl hyprsunset temperature ${root.colorTemperature} || hyprsunset --temperature ${root.colorTemperature} &`]);
    }

    function disable() {
        if (!root.ready) return;
        Config.options.nightMode.active = false;
        Quickshell.execDetached(["bash", "-c", "pkill hyprsunset; hyprctl hyprsunset identity"]);
    }

    function toggle(newActive = undefined) {
        if (!root.ready) return;
        const targetActive = newActive !== undefined ? newActive : !root.active;
        if (targetActive) {
            root.enable();
        } else {
            root.disable();
        }
    }

    // When color temperature changes while active, update hyprsunset live
    onColorTemperatureChanged: {
        if (!root.active || !root.ready) return;
        Quickshell.execDetached(["bash", "-c", `hyprctl hyprsunset temperature ${root.colorTemperature} 2>/dev/null || true`]);
    }
}
