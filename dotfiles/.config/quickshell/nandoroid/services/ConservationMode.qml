pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool available: false
    readonly property string sysPath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"

    FileView {
        id: sysfsView
        path: root.sysPath
        watchChanges: true
        onFileChanged: sysfsView.reload()
        onLoaded: {
            const val = sysfsView.text().trim();
            if (val === "1") root.active = true;
            else if (val === "0") root.active = false;
        }
    }

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

    onAvailableChanged: if (available) sysfsView.reload()

    Process {
        id: toggleProc
        onExited: sysfsView.reload()
    }

    function toggle() {
        if (!available) return;
        const newState = active ? "0" : "1";
        toggleProc.exec(["pkexec", "sh", "-c", 'echo "$1" > "$2"', "sh", newState, sysPath]);
    }
}
