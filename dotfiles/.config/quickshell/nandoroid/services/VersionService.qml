pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property string version: "..."

    Process {
        id: verProc
        command: ["bash", "-c", `
            f="$HOME/.config/nandoroid/install_state.json"
            [ ! -f "$f" ] && { echo "unknown"; exit; }
            d=$(python3 -c "import json,sys; print(json.load(open('$f')).get('install_dir',''))" 2>/dev/null)
            [ -z "$d" ] && { echo "unknown"; exit; }
            git -C "$d" describe --tags --always 2>/dev/null || echo "unknown"
        `]
        stdout: StdioCollector { id: verOut }
        running: true
        onExited: {
            const v = verOut.text.trim()
            if (v) root.version = v
        }
    }
}
