pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../core"
import "../../../services"

/** Shared OSD icon/text/width for the island pills (desktop + lock). */
Singleton {
    id: root

    // Island OSD pill width — single source of truth used by PcDynamicIsland
    // (desktop) and LockSurface (lock pill) so both always match.
    readonly property real pillWidth: 132

    function osdIcon() {
        switch (GlobalStates.osdIndicatorType) {
            case "brightness": return "light_mode"
            case "gamma":      return "wb_twilight"
            case "layout":     return "view_compact"
            case "microphone": return "mic"
            case "charging":   return "battery_charging_full"
            case "powerMode":  return "bolt"
            case "conservation": return "energy_savings_leaf"
            case "playerVolume": return "volume_up"
            default:           return "volume_up"
        }
    }

    function osdText() {
        switch (GlobalStates.osdIndicatorType) {
            case "brightness": {
                const mon = Brightness.getMonitorForScreen ? Brightness.getMonitorForScreen(Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)) : null
                return `${Math.round((mon?.brightness ?? 0.5) * 100)}`
            }
            case "gamma":      return `${Math.round((Hyprsunset.gamma ?? 50))}`
            case "layout": {
                const raw = GlobalStates.hyprlandLayout ?? HyprlandData.layout ?? "dwindle"
                return raw.charAt(0).toUpperCase() + raw.slice(1)
            }
            case "microphone": return `${Math.round((Audio.source?.audio?.volume ?? 0) * 100)}`
            case "charging":   return `${Math.round(Battery.percentage * 100)}%`
            case "powerMode": {
                const prof = PowerProfileService.currentProfile ?? ""
                return prof.charAt(0).toUpperCase() + prof.slice(1)
            }
            case "conservation": return ConservationMode.active ? I18nService.tr("On") : I18nService.tr("Off")
            default:           return `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}`
        }
    }
}
