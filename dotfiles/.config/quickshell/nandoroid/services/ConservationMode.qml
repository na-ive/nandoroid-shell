pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool available: false
    readonly property string sysPath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

    Process {
        id: checkAvailabilityProc
        command: ["bash", "-c", "[ -f " + sysPath + " ] && echo 'yes' || echo 'no'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.available = data.trim() === "yes";
            }
        }
    }

    Process {
        id: refreshProc
        command: ["cat", sysPath]
        running: available
        stdout: SplitParser {
            onRead: data => {
                const val = data.trim();
                if (val === "1" || val === "0") {
                    root.active = val === "1";
                }
            }
        }
    }

    Process {
        id: toggleProc
        onExited: refreshProc.running = true
    }

    function toggle() {
        if (!available) return;
        const newState = active ? "0" : "1";
        toggleProc.command = ["pkexec", "bash", "-c", "echo " + newState + " > " + sysPath];
        toggleProc.running = true;
    }

    Timer {
        interval: 10000
        running: available
        repeat: true
        onTriggered: refreshProc.running = true
    }
}
