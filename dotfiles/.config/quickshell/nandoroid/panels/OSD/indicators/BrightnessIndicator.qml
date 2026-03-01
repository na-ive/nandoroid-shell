import "../../../services"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../widgets"
import ".." 

OsdValueIndicator {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    icon: "light_mode" // Hyprsunset removed
    rotateIcon: true
    scaleIcon: true
    name: "Brightness"
    value: (root.brightnessMonitor !== undefined) ? root.brightnessMonitor.brightness : 0.5
    shape: "Burst"
}
