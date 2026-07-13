pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../core"

Singleton {
    id: root

    readonly property MprisPlayer activePlayer: MprisController.activePlayer

    property var lyricsLines: []
    property int activeIndex: -1
    property string status: "loading"

    property var slots: []

    property int contextLines: (Config.ready && Config.options.appearance.lyrics) ? Config.options.appearance.lyrics.contextLines : 3
    readonly property int before: contextLines
    readonly property int after: contextLines
    readonly property int total: before + after + 1

    function getEmptySlots(centerText) {
        let arr = []
        for (let i = 0; i < root.total; i++) {
            if (i === root.before && centerText) {
                arr.push({ originalText: centerText, romajiText: centerText })
            } else {
                arr.push({ originalText: "", romajiText: "" })
            }
        }
        return arr
    }

    function buildSlots(idx) {
        let result = []
        for (let i = 0; i < root.total; i++) {
            let lineIdx = idx - root.before + i
            if (lineIdx >= 0 && lineIdx < root.lyricsLines.length) {
                let l = root.lyricsLines[lineIdx]
                result.push({ originalText: l.originalText || "♪", romajiText: l.romajiText || "♪" })
            } else {
                result.push({ originalText: "", romajiText: "" })
            }
        }
        return result
    }

    Timer {
        id: syncTimer
        interval: 300
        repeat: true
        running: root.status === "ok" && root.lyricsLines.length > 0
        onTriggered: {
            const pos = root.activePlayer?.position ?? 0
            let idx = -1
            for (let i = 0; i < root.lyricsLines.length; i++) {
                if (root.lyricsLines[i].time <= pos) idx = i
                else break
            }
            if (idx !== root.activeIndex) {
                root.activeIndex = idx
                root.slots = root.buildSlots(idx)
            }
        }
    }

    Process {
        id: lyricsProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                if (trimmed === "not_found") { 
                    root.status = "not_found"
                    root.slots = root.getEmptySlots("No lyrics found")
                    return 
                }
                if (trimmed === "no_info")   { 
                    root.status = "no_info"
                    root.slots = root.getEmptySlots("No track playing")
                    return 
                }

                const parts = trimmed.split("§")
                if (parts.length < 3) return
                if (parts[parts.length - 1].trim() !== "ok") return

                let lines = []
                // parts format: time, original, romaji, time, original, romaji...
                for (let i = 0; i < parts.length - 1; i += 3) {
                    const t = parseFloat(parts[i])
                    const orig = parts[i + 1] || ""
                    const romaji = parts[i + 2] || ""
                    if (!isNaN(t)) lines.push({ time: t, originalText: orig, romajiText: romaji })
                }

                if (lines.length === 0) { root.status = "not_found"; return }

                root.lyricsLines = lines
                root.activeIndex = -1
                root.slots = root.buildSlots(-1)
                root.status = "ok"
            }
        }
    }

    function restartLyrics() {
        lyricsProc.running = false
        root.lyricsLines = []
        root.activeIndex = -1
        root.status = "loading"
        root.slots = root.getEmptySlots("Preparing lyrics...")
        
        if (!Config.options.appearance.lyrics.showFloatingLyrics) {
            root.status = "disabled"
            return
        }

        const title    = root.activePlayer?.trackTitle  ?? ""
        const artist   = root.activePlayer?.trackArtist ?? ""
        const duration = (root.activePlayer?.length ?? 0) / 1000000.0

        if (!title || !artist) { 
            root.status = "no_info"
            root.slots = root.getEmptySlots("No track playing")
            return 
        }

        const pythonExec = Quickshell.env("HOME") + "/.local/share/nandoroid/venv/bin/python3"
        const scriptPath = Quickshell.env("HOME") + "/.config/quickshell/nandoroid/scripts/lyrics.py"

        lyricsProc.command = [
            pythonExec,
            scriptPath,
            title, artist, String(Math.floor(duration))
        ]
        lyricsProc.running = true
    }

    Connections {
        target: root.activePlayer
        function onTrackTitleChanged() { root.restartLyrics() }
    }

    Connections {
        target: Config.ready && Config.options.appearance.lyrics ? Config.options.appearance.lyrics : null
        function onShowFloatingLyricsChanged() {
            if (Config.options.appearance.lyrics.showFloatingLyrics) {
                root.restartLyrics()
            } else {
                lyricsProc.running = false
            }
        }
        function onContextLinesChanged() {
            if (root.status === "ok") {
                root.slots = root.buildSlots(root.activeIndex)
            } else if (root.status === "loading") {
                root.slots = root.getEmptySlots("Preparing lyrics...")
            } else if (root.status === "not_found") {
                root.slots = root.getEmptySlots("No lyrics found")
            } else if (root.status === "no_info") {
                root.slots = root.getEmptySlots("No track playing")
            } else {
                root.slots = root.getEmptySlots("")
            }
        }
    }

    Component.onCompleted: root.restartLyrics()
}
