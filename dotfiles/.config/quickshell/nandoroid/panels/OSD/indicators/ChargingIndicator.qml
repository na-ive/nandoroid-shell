import ".."
import "../../../services"

OsdToggleIndicator {
    id: osdValues

    property bool isPluggedIn: Battery.isPluggedIn

    name: "Power"
    statusText: isPluggedIn ? "Charging" : "Discharging"
    icon: Battery.materialSymbol
    // shape: "circle"
}
