pragma Singleton
pragma ComponentBehavior: Bound

import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property int seconds: 0
    property string stateFile: "/tmp/nandoroid_states.json"

    function toggle(region) {
        let args = [Quickshell.shellPath("scripts/videos/record.sh")];
        if (region) {
            args.push("--region");
            args.push(region);
        }
        Quickshell.execDetached(args);
    }

    function stop() {
        Quickshell.execDetached([Quickshell.shellPath("scripts/videos/record.sh")]);
    }

    Process {
        id: stateProc
        command: ["bash", "-c", `[ -f "${root.stateFile}" ] && cat "${root.stateFile}" || echo '{"screenRecord": {"active": false, "seconds": 0}}'`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const trimmed = this.text.trim();
                    if (!trimmed || trimmed.indexOf("{") !== 0) return;
                    let data = JSON.parse(trimmed);
                    if (data && data.screenRecord) {
                        root.active = data.screenRecord.active === true;
                        root.seconds = parseInt(data.screenRecord.seconds) || 0;
                    }
                } catch(e) {
                    console.error("[ScreenRecord] Failed to parse state:", e);
                }
            }
        }
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            if (!stateProc.running) stateProc.running = true
        }
    }

    Component.onCompleted: {
        // Create initial state file if not exists
        Quickshell.execDetached(["bash", "-c", `[ -f ${stateFile} ] || echo '{"screenRecord": {"active": false, "seconds": 0}}' > ${stateFile}`]);
        stateProc.running = true;
    }
}
