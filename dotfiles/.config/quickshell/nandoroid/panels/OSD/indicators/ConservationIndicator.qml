import ".."
import "../../../services"

OsdToggleIndicator {
    id: osdValues

    property bool isActive: ConservationMode.active

    name: "Conservation"
    statusText: isActive ? "Battery protected" : "Charge to 100%"
    icon: "battery_saver"
}
