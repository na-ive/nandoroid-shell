pragma Singleton
import "../core"
import "../services"
import Quickshell
import QtQuick

Singleton {
    id: root

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
    }

    function launchTaskManager() {
        Quickshell.execDetached(["bash", "-c", "missioncenter || gnome-system-monitor || plasma-systemmonitor"]);
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", "systemctl hibernate || loginctl hibernate"]);
    }

    function poweroff() {
        Quickshell.execDetached(["bash", "-c", "systemctl poweroff || loginctl poweroff"]);
    }

    function reboot() {
        Quickshell.execDetached(["bash", "-c", "reboot || loginctl reboot"]);
    }

    function rebootToFirmware() {
        Quickshell.execDetached(["bash", "-c", "systemctl reboot --firmware-setup || loginctl reboot --firmware-setup"]);
    }
}
