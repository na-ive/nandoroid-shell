pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property list<int> values: []
    property int barCount: 128
    property int refCount: 0
    property bool cavaAvailable: false

    onRefCountChanged: {
        if (refCount < 0) refCount = 0;
    }

    onBarCountChanged: {
        if (cavaProcess.running) {
            cavaProcess.running = false;
            Qt.callLater(() => { if (root.refCount > 0) cavaProcess.running = true; });
        }
    }

    Process {
        id: cavaCheck
        command: ["which", "cava"]
        running: false
        onExited: exitCode => {
            root.cavaAvailable = exitCode === 0;
        }
    }

    Component.onCompleted: {
        cavaCheck.running = true;
        // Initialize values
        let arr = [];
        for (let i = 0; i < barCount; i++) arr.push(0);
        root.values = arr;
    }

    Process {
        id: cavaProcess
        // Re-evaluate running state whenever dependencies change
        running: root.cavaAvailable && root.refCount > 0
        command: ["bash", "-c", `cat <<'CAVACONF' | cava -p /dev/stdin
[general]
framerate=60
bars=${root.barCount}
autosens=1
sensitivity=75

[output]
method=raw
raw_target=/dev/stdout
data_format=ascii
channels=mono
mono_option=average

[smoothing]
noise_reduction=35
integral=80
gravity=100
ignore=0
monstercat=1
CAVACONF`]

        onRunningChanged: {
            if (!running) {
                // Clear values when stopped to prevent "frozen" look
                let arr = [];
                for (let i = 0; i < barCount; i++) arr.push(0);
                root.values = arr;
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!data || data.length === 0) return;
                
                const parts = data.split(";");
                if (parts.length >= root.barCount) {
                    let points = [];
                    for (let i = 0; i < root.barCount; i++) {
                        const val = parseInt(parts[i], 10);
                        points.push(isNaN(val) ? 0 : val);
                    }
                    root.values = points;
                }
            }
        }
    }
}
