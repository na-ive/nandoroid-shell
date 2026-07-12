pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property var all: ["Default"]
    property var mono: ["Default"]

    // --- Paths ---
    function cleanPath(p) {
        let s = p.toString();
        if (s.indexOf("file://") === 0) return s.substring(7);
        return s;
    }

    readonly property string cacheDir: cleanPath(Directories.home) + "/.cache/nandoroid"
    readonly property string cachePath: cacheDir + "/fonts.json"

    // --- Cache Builder ---
    function fetchAndCache() {
        // We use jq to convert the lines of text into JSON arrays
        const cmd = `mkdir -p "${cacheDir}" && echo '{"all":'$(fc-list : family | cut -d, -f1 | sort | uniq | jq -R . | jq -s .)',"mono":'$(fc-list :spacing=mono family | cut -d, -f1 | sort | uniq | jq -R . | jq -s .)'}' > "${cachePath}"`;
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // --- Cache Loader ---
    FileView {
        id: fontsFile
        path: root.cachePath
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.all && Array.isArray(data.all)) {
                    root.all = ["Default"].concat(data.all);
                }
                if (data.mono && Array.isArray(data.mono)) {
                    root.mono = ["Default"].concat(data.mono);
                }
            } catch (e) {
                console.error("[SystemFonts] Error parsing fonts.json:", e);
            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.fetchAndCache();
            }
        }
    }

    // Update fonts cache on startup
    Component.onCompleted: {
        root.fetchAndCache();
    }
}
