pragma Singleton

import "../core"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

/**
 * Real battery service using UPower.
 * Exposes: available, percentage, isCharging, isPluggedIn, chargeState.
 * Low/critical thresholds driven by Config.
 */
Singleton {
    id: root
    
    // Find the actual battery device (usually battery_BAT0) for detailed stats
    readonly property var batteryDevice: {
        const devices = UPower.devices.values;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].isLaptopBattery) return devices[i];
        }
        return UPower.displayDevice;
    }

    property bool available: batteryDevice?.isLaptopBattery ?? false
    property var chargeState: batteryDevice?.state ?? UPowerDeviceState.Unknown
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge || chargeState == UPowerDeviceState.FullyCharged
    property real percentage: batteryDevice?.percentage ?? 1

    // New Stats for v1.2
    property real energyRate: batteryDevice?.changeRate ?? 0
    property real timeToEmpty: batteryDevice?.timeToEmpty ?? 0
    property real timeToFull: batteryDevice?.timeToFull ?? 0
    
    // Hardware Details (Updated via Process for accuracy)
    property string vendor: "Unknown"
    property string model: "Generic Battery"
    property string technology: "Unknown"
    property real voltage: 0
    property real capacity: 0
    property real energy: 0
    property real energyFull: 0
    property real energyFullDesign: 0
    property string serial: "Not Available"
    property int cycles: 0

    property real health: {
        if (energyFullDesign > 0 && energyFull > 0) {
            return Math.min(100, (energyFull / energyFullDesign) * 100);
        }
        return 0;
    }

    // --- Data Fetcher ---
    Timer {
        id: detailUpdater
        interval: 5000 // Update every 5s
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: upowerProc.running = true
    }

    Process {
        id: upowerProc
        command: ["bash", "-c", "upower -i $(upower -e | grep 'battery' | head -n1)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n");
                lines.forEach(line => {
                    const parts = line.split(":");
                    if (parts.length < 2) return;
                    const key = parts[0].trim();
                    const val = parts[1].trim();

                    if (key === "vendor") root.vendor = val;
                    if (key === "model") root.model = val;
                    if (key === "serial") root.serial = val;
                    if (key === "technology") root.technology = val;
                    if (key === "voltage") root.voltage = parseFloat(val);
                    if (key === "energy") root.energy = parseFloat(val);
                    if (key === "energy-full") root.energyFull = parseFloat(val);
                    if (key === "energy-full-design") root.energyFullDesign = parseFloat(val);
                    if (key === "charge-cycles") root.cycles = parseInt(val);
                });
            }
        }
    }

    property bool isLow: available && (percentage <= Config.options.battery.low / 100)
    property bool isCritical: available && (percentage <= Config.options.battery.critical / 100)

    // Material symbol for status bar
    property string materialSymbol: {
        if (!available) return "battery_unknown";
        if (isCharging) return "battery_charging_full";
        if (percentage > 0.95) return "battery_full";
        if (percentage > 0.80) return "battery_6_bar";
        if (percentage > 0.65) return "battery_5_bar";
        if (percentage > 0.50) return "battery_4_bar";
        if (percentage > 0.35) return "battery_3_bar";
        if (percentage > 0.20) return "battery_2_bar";
        if (percentage > 0.10) return "battery_1_bar";
        return "battery_alert";
    }

    // Percentage text for display
    property string percentageText: available ? `${Math.round(percentage * 100)}%` : ""
}
