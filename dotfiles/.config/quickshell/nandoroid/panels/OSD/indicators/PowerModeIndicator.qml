import ".."
import "../../../services"

OsdToggleIndicator {
    id: osdValues

    property string profile: PowerProfileService.currentProfile

    name: "Power Mode"
    statusText: profile === "performance" ? "Performance" : (profile === "balanced" ? "Balanced" : "Power Saver")
    icon: profile === "performance" ? "speed" : (profile === "balanced" ? "balance" : "eco")
}
