    Process {
        id: setVolumeProc
        property real value: 0.5
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${Math.round(value * 100)}%`]
    }
    Process {
        id: getVolumeProc
        running: true
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"]
        stdout: SplitParser {
            onRead: data => { /* set volume slider value if needed */ }
        }
    }
