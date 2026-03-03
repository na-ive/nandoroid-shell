pragma Singleton
pragma ComponentBehavior: Bound

// From https://github.com/caelestia-dots/shell with modifications.
// License: GPLv3

import "../core"
import "../core/functions"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

/**
 * For managing brightness of monitors. Supports both brightnessctl and ddcutil.
 */
Singleton {
    id: root
    signal brightnessUpdated()

    property var ddcMonitors: []
    readonly property list<BrightnessMonitor> monitors: Quickshell.screens.map(screen => monitorComp.createObject(root, {
        screen
    }))

    function getMonitorForScreen(screen: ShellScreen): var {
        return monitors.find(m => m.screen === screen);
    }

    function getMonitorByName(name: string): var {
        return monitors.find(m => m.screen.name === name);
    }

    function increaseBrightness(): void {
        const focusedName = Hyprland.focusedMonitor.name;
        const monitor = monitors.find(m => focusedName === m.screen.name);
        if (monitor)
            monitor.setBrightness(monitor.brightness + 0.05);
    }

    function decreaseBrightness(): void {
        const focusedName = Hyprland.focusedMonitor.name;
        const monitor = monitors.find(m => focusedName === m.screen.name);
        if (monitor)
            monitor.setBrightness(monitor.brightness - 0.05);
    }

    reloadableId: "brightness"

    onMonitorsChanged: {
        ddcMonitors = [];
        ddcProc.running = true;
    }

    function initializeMonitor(i: int): void {
        if (i >= monitors.length)
            return;
        monitors[i].initialize();
    }

    function ddcDetectFinished(): void {
        initializeMonitor(0);
    }

    Process {
        id: ddcProc

        command: ["ddcutil", "detect", "--brief"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (data.startsWith("Display ")) {
                    const lines = data.split("\n").map(l => l.trim());
                    const name = lines.find(l => l.startsWith("DRM connector:")).split("-").slice(1).join('-');
                    const bus = lines.find(l => l.startsWith("I2C bus:")).split("/dev/i2c-")[1];
                    // console.log("DEBUG: Found DDC monitor: " + name + " on bus " + bus);
                    root.ddcMonitors.push({
                        name: name,
                        busNum: bus
                    });
                }
            }
        }
        onExited: root.ddcDetectFinished()
    }

    Process {
        id: setProc
    }

    component BrightnessMonitor: QtObject {
        id: monitor

        required property ShellScreen screen
        property bool isDdc
        property string busNum
        property int rawMaxBrightness: 100
        property real brightness

        property real multipliedBrightness: Math.max(0, Math.min(1, brightness))
        property bool ready: false
        property bool animateChanges: false // set in initialize
        property bool internalUpdate: false

        onBrightnessChanged: {
            if (!monitor.ready) return;
            root.brightnessUpdated();
        }

        Behavior on multipliedBrightness {
            enabled: monitor.animateChanges
            NumberAnimation {
                duration: 200
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
        }
        onMultipliedBrightnessChanged: {
            if (monitor.animateChanges) syncBrightness();
            else setTimer.restart();
        }

        function initialize() {
            monitor.ready = false;
            const match = root.ddcMonitors.find(m => m.name === screen.name && !root.monitors.slice(0, root.monitors.indexOf(this)).some(mon => mon.busNum === m.busNum));
            isDdc = !!match;
            busNum = match?.busNum ?? "";
            animateChanges = !isDdc;
            // Try to find backlight device name
            // brightnessctl -l returns "Device 'name' ..."
            // We can just trust `brightnessctl -m` which gives: name,class,current,max_percent,max_absolute
            // e.g. amdgpu_bl1,backlight,38211,59%,64764
            // Wait, output format of -m: `name,class,current,max,percent`
            initProc.command = isDdc ? ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"] : ["sh", "-c", `brightnessctl -m | head -n 1`];
            // initProc.command = isDdc ? ["ddcutil", "-b", busNum, "getvcp", "10", "--brief"] : ["sh", "-c", `echo "a b c $(brightnessctl g) $(brightnessctl m)"`];
            initProc.running = true;
        }

        readonly property Process initProc: Process {
            stdout: SplitParser {
                onRead: data => {
                    // DDC: VCP 10 C 50 100
                    // Non-DDC (brightnessctl -m): name,class,current,max_percent,max_abs
                    // e.g. amdgpu_bl1,backlight,38211,59%,64764
                    
                    if (monitor.isDdc) {
                         const parts = data.split(" ");
                         // VCP 10 C <current> <max>
                         if (parts.length >= 5) {
                             monitor.animateChanges = false; // Snap
                             monitor.internalUpdate = true;
                             monitor.rawMaxBrightness = parseInt(parts[4]);
                             monitor.brightness = parseInt(parts[3]) / monitor.rawMaxBrightness;
                             monitor.internalUpdate = false;
                             monitor.animateChanges = !monitor.isDdc; // Restore
                         }
                    } else {
                        // brightnessctl -m
                        const parts = data.split(",");
                        if (parts.length >= 5) {
                            const name = parts[0];
                            const current = parseInt(parts[2]);
                            const max = parseInt(parts[4]);
                            
                            monitor.busNum = name; // misuse busNum to store device name for watcher
                            monitor.animateChanges = false; // Snap
                            monitor.internalUpdate = true;
                            monitor.rawMaxBrightness = max;
                            monitor.brightness = current / max;
                            monitor.internalUpdate = false;
                            monitor.animateChanges = !monitor.isDdc; // Restore
                        } else {
                            // Fallback for old parsing if needed, but we changed the command
                        }
                    }

                    monitor.internalUpdate = true; // Set flag before updating brightness
                    monitor.ready = true;
                    monitor.internalUpdate = false; // Reset flag
                }
            }
            onExited: (exitCode, exitStatus) => {
                initializeMonitor(root.monitors.indexOf(monitor) + 1);
            }
        }
        
        property var watcher: Timer {
            id: brightnessTimer
            interval: 100
            repeat: true
            running: false // DISABLING WATCHER: This causes jitter with UI animations
            onTriggered: {
                // Poll brightness
                if (!monitor.initProc.running) {
                     monitor.initProc.running = true
                }
            }
        }


        // We need a delay for DDC monitors because they can be quite slow and might act weird with rapid changes
        property var setTimer: Timer {
            id: setTimer
            interval: monitor.isDdc ? 300 : 0
            onTriggered: {
                syncBrightness();
            }
        }

        function syncBrightness() {
            if (monitor.internalUpdate) return; // Don't write back if we just read from system
            
            const brightnessValue = Math.max(monitor.multipliedBrightness, 0);
            if (isDdc) {
                const rawValueRounded = Math.max(Math.floor(brightnessValue * monitor.rawMaxBrightness), 1);
                setProc.exec(["ddcutil", "-b", busNum, "setvcp", "10", rawValueRounded]);
            } else {
                const valuePercentNumber = Math.round(brightnessValue * 100); // Use round to avoid drift
                let valuePercent = `${valuePercentNumber}%`;
                if (valuePercentNumber == 0) valuePercent = "1"; // Prevent fully black
                setProc.exec(["brightnessctl", "--class", "backlight", "s", valuePercent, "--quiet"])
            }
        }

        function setBrightness(value: real): void {
            value = Math.max(0, Math.min(1, value));
            monitor.brightness = value;
        }


    }

    Component {
        id: monitorComp

        BrightnessMonitor {}
    }



    // External trigger points

    IpcHandler {
        target: "brightness"

        function increment() {
            root.increaseBrightness()
        }

        function decrement() {
            root.decreaseBrightness()
        }

        function show() {
            root.brightnessUpdated()
        }
    }

    GlobalShortcut {
        name: "brightnessIncrease"
        description: "Increase brightness"
        onPressed: root.increaseBrightness()
    }

    GlobalShortcut {
        name: "brightnessDecrease"
        description: "Decrease brightness"
        onPressed: root.decreaseBrightness()
    }
}
