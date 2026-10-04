pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    readonly property var matugenSchemes: [
        { id: "scheme-content",     name: "Content",     colors: [] },
        { id: "scheme-expressive",  name: "Expressive",  colors: [] },
        { id: "scheme-fidelity",    name: "Fidelity",    colors: [] },
        { id: "scheme-fruit-salad", name: "Fruit Salad", colors: [] },
        { id: "scheme-monochrome",  name: "Monochrome",  colors: [] },
        { id: "scheme-neutral",     name: "Neutral",     colors: [] },
        { id: "scheme-rainbow",     name: "Rainbow",     colors: [] },
        { id: "scheme-tonal-spot",  name: "Tonal Spot",  colors: [] }
    ]

    // Theme list, read live from the theme files themselves (the single
    // source of truth) via scripts/colors/apply_theme.py --index-stdout.
    // {name, file, colors: [primary, secondary, tertiary], isDark}.
    // Empty until the scan completes shortly after shell start.
    property var basicColors: []

    Process {
        id: themeIndexProc
        command: ["python3", `${Quickshell.shellPath("scripts")}/colors/apply_theme.py`, "--index-stdout"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text);
                    if (Array.isArray(parsed)) root.basicColors = parsed;
                } catch (e) {
                    console.warn("[MatugenPreview] cannot parse theme index:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.warn("[MatugenPreview] theme scan:", this.text);
                }
            }
        }
    }

    property var previews: ({})
    property var pendingPreviews: ({})
    property string desktopSourceHex: ""
    property bool loading: previewIterateTimer.running || previewMatugen.running

    Timer {
        id: batchUpdateTimer
        interval: 200
        repeat: false
        onTriggered: {
            let newPreviews = Object.assign({}, root.previews);
            for (let key in root.pendingPreviews) newPreviews[key] = root.pendingPreviews[key];
            root.previews = newPreviews;
            root.pendingPreviews = {};
        }
    }

    function sendNotification(title, body) {
        const iconPath = Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg";
        Quickshell.execDetached(["notify-send", "-a", "NAnDoroid", "-i", iconPath, title, body]);
    }

    Process {
        id: previewMatugen
        command: root.desktopSourceHex === ""
            ? ["bash", "-c", `[ -f "$3" ] && matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" image "$3" --dry-run -j hex --old-json-output --source-color-index 0`, "matugen", currentScheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), currentPath]
            : ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" color hex "$3" --dry-run -j hex --old-json-output`, "matugen", currentScheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), root.desktopSourceHex]
        property string currentScheme: ""
        property string currentPath: ""
        property string currentSource: ""
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 50 && (this.text.includes("Failed to generate base16 color schemes") || this.text.includes("Invalid PNG signature"))) {
                    root.sendNotification("Preview Error", "Failed to generate preview for this wallpaper.");
                }
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rawText = this.text.trim();
                    const jsonStart = rawText.indexOf("{");
                    const jsonEnd = rawText.lastIndexOf("}");
                    if (jsonStart === -1 || jsonEnd === -1) throw "No JSON";
                    const data = JSON.parse(rawText.substring(jsonStart, jsonEnd + 1));
                    if (root.desktopSourceHex === "" && data.colors && data.colors.source_color) {
                        const sc = data.colors.source_color;
                        let extracted = sc.default || (sc.light ? sc.light : (sc.dark ? sc.dark : ""));
                        if (typeof extracted === 'object') extracted = extracted.color || "";
                        if (typeof extracted === 'string' && extracted.startsWith("#")) root.desktopSourceHex = extracted;
                    }
                    const mode = Config.options.appearance.background.darkmode ? "dark" : "light";
                    let colors = [];
                    if (data.colors) {
                        if (data.colors.primary && typeof data.colors.primary === 'object') {
                            const tone = (node) => (node && (node[mode] || node.default)) || "";
                            const useContainer = (mode === "light");
                            const container = (key) => {
                                const node = data.colors[key + "_container"];
                                return tone(node);
                            };
                            colors = [
                                (useContainer && container("primary"))   || tone(data.colors.primary),
                                (useContainer && container("secondary")) || tone(data.colors.secondary),
                                (useContainer && container("tertiary"))  || tone(data.colors.tertiary)
                            ];
                        } else if (data.colors.light) {
                             colors = [data.colors.light.primary, data.colors.light.surface_container_high, data.colors.light.secondary];
                        }
                    }
                    if (colors.length > 0) {
                        root.pendingPreviews[previewMatugen.currentSource + "_" + previewMatugen.currentScheme] = colors;
                        batchUpdateTimer.restart();
                    }
                } catch(e) {}
                previewIterateTimer.start();
            }
        }
    }

    property int previewIndex: 0
    property string previewSource: "desktop"
    Timer {
        id: previewIterateTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (!Config.ready || !Config.options.lock || !Config.options.appearance || WallpaperEngineService.isApplying) {
                previewIterateTimer.start();
                return;
            }
            if (previewIndex >= matugenSchemes.length) return;
            const scheme = matugenSchemes[previewIndex].id;
            let path = Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.wallpaperPath : "";
            if (WallpaperEngineService.active) path = WallpaperEngineService.screenshotPath;
            else if (MpvpaperService.active) path = MpvpaperService.framePath;
            if (!path) { previewIndex++; previewIterateTimer.start(); return; }
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
            if (cleanPath === "") { previewIndex++; previewIterateTimer.start(); return; }
            previewMatugen.currentScheme = scheme;
            previewMatugen.currentPath = cleanPath;
            previewMatugen.currentSource = previewSource;
            previewMatugen.running = true;
            previewIndex++;
        }
    }

    function refreshPreviews() {
        if (!Config.ready || previewIterateTimer.running || previewMatugen.running || WallpaperEngineService.isApplying) return;
        previewIndex = 0;
        previewSource = "desktop";
        root.pendingPreviews = {};
        root.desktopSourceHex = "";
        previewIterateTimer.restart();
    }

    Timer {
        id: initTimer
        interval: 500
        repeat: false
        running: true
        onTriggered: refreshPreviews()
    }

    property bool currentDarkMode: Appearance.m3colors.darkmode
    onCurrentDarkModeChanged: refreshPreviews()

    Connections {
        target: Config.ready ? Config.options.appearance.background : null
        function onWallpaperPathChanged() { refreshPreviews() }
    }
    Connections {
        target: WallpaperEngineService
        function onScreenshotVersionChanged() { refreshPreviews() }
    }
}
