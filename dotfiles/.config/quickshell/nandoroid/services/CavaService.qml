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

    onBarCountChanged: {
        if (cavaProcess.running) {
            cavaProcess.running = false;
            Qt.callLater(() => { cavaProcess.running = true; });
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
                let arr = [];
                for (let i = 0; i < barCount; i++) arr.push(0);
                root.values = arr;
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parts = data.split(";");
                if (parts.length >= root.barCount) {
                    let points = [];
                    for (let i = 0; i < root.barCount; i++) {
                        points.push(parseInt(parts[i], 10));
                    }
                    root.values = points;
                } else if (data.length > 0) {

                }
            }
        }
    }
}
