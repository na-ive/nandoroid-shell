pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property list<int> values: []
    property int barCount: Config.ready ? Config.options.appearance.background.cavaBars : 32
    property bool _internalRestart: true
    property int refCount: 0
    property bool cavaAvailable: false
    property bool pausedBySystem: false

    onRefCountChanged: {
        if (refCount < 0) refCount = 0;
    }

    onBarCountChanged: {
        if (root.cavaAvailable) root.restart();
        let arr = [];
        for (let i = 0; i < root.barCount; i++) arr.push(0);
        root.values = arr;
    }

    function restart() {
        root.updateCavaConfig();
        if (cavaProcess.running) {
            cavaProcess.running = false;
            Qt.callLater(() => { cavaProcess.running = true; });
        }
    }

    function stop() {
        pausedBySystem = true;
    }

    function start() {
        pausedBySystem = false;
    }

    Process {
        id: cavaCheck
        command: ["which", "cava"]
        running: false
        onExited: exitCode => {
            root.cavaAvailable = exitCode === 0;
        }
    }

    // Write a physical config file to avoid bash-heredoc overhead and orphan processes
    FileView {
        id: cavaConfigWriter
        path: "/tmp/nandoroid_cava.conf"
    }

    function updateCavaConfig() {
        const config = `
[general]
framerate=30
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
`;
        cavaConfigWriter.setText(config);
    }

    Component.onCompleted: {
        // Initial cleanup and setup
        root.updateCavaConfig();
        
        // Wait for system audio to stabilize
        startupTimer.start();
        
        let arr = [];
        for (let i = 0; i < barCount; i++) arr.push(0);
        root.values = arr;
    }

    Timer {
        id: startupTimer
        interval: 1500 // Reduced from 2.5s since new logic is cleaner
        repeat: false
        onTriggered: cavaCheck.running = true;
    }

    Process {
        id: cavaProcess
        // Directly call cava with config file - more stable than bash pipe
        running: root.cavaAvailable && root.refCount > 0 && !root.pausedBySystem
        command: ["cava", "-p", "/tmp/nandoroid_cava.conf"]

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
