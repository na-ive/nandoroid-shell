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
    property string geometry: ""
    property int recordingMode: 0 // 0: Region (no audio), 1: Region (with audio), 2: Fullscreen (with audio)
    property string stateFile: "/tmp/nandoroid_states.json"

    readonly property string modeLabel: {
        if (recordingMode === 0) return "Region";
        if (recordingMode === 1) return "Region + Audio";
        if (recordingMode === 2) return "Screen + Audio";
        return "Unknown";
    }

    function cycleMode() {
        recordingMode = (recordingMode + 1) % 3;
    }

    function toggle(region, sound, fullscreen) {
        root.active = true;

        let args = [Quickshell.shellPath("scripts/videos/record.sh")];
        if (region) {
            args.push("--region");
            args.push(region);
        }
        if (sound) args.push("--sound");
        if (fullscreen) args.push("--fullscreen");
        
        Quickshell.execDetached(args);
    }

    function stop() {
        Quickshell.execDetached([Quickshell.shellPath("scripts/videos/record.sh")]);
    }

    FileView {
        id: stateFileView
        path: root.stateFile
        watchChanges: true
        onFileChanged: stateFileView.reload()
        onLoaded: {
            try {
                const trimmed = stateFileView.text().trim();
                if (!trimmed || trimmed.indexOf("{") !== 0) return;
                let data = JSON.parse(trimmed);
                if (data && data.screenRecord) {
                    root.active = data.screenRecord.active === true;
                    root.geometry = data.screenRecord.geometry || "";
                    if (!root.active) root.seconds = 0;
                }
            } catch(e) {
                console.error("[ScreenRecord] Failed to parse state:", e);
            }
        }
    }

    Timer {
        interval: 1000
        running: root.active
        repeat: true
        onTriggered: root.seconds++
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", `[ -f ${stateFile} ] || echo '{"screenRecord": {"active": false, "seconds": 0}}' > ${stateFile}`]);
        stateFileView.reload();
    }
}
