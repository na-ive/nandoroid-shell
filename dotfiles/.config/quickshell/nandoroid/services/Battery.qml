pragma Singleton

import "../core"
import QtQuick
import Quickshell
import Quickshell.Services.UPower

/**
 * Real battery service using UPower.
 * Exposes: available, percentage, isCharging, isPluggedIn, chargeState.
 * Low/critical thresholds driven by Config.
 */
Singleton {
    id: root
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice?.percentage ?? 1

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
