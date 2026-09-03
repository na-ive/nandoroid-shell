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

    readonly property var basicColors: [
        { name: "Angel", file: "angel.json", colors: ["#e8b882", "#d4c4aa", "#b8c4d8"], isDark: true },
        { name: "Angel Light", file: "angel_light.json", colors: ["#9a6830", "#7a6a50", "#506478"], isDark: false },
        { name: "Ayu", file: "ayu.json", colors: ["#e6b450", "#aad94c", "#39bae6"], isDark: true },
        { name: "Cobalt2", file: "cobalt2.json", colors: ["#0088ff", "#9a5feb", "#2affdf"], isDark: true },
        { name: "Cursor", file: "cursor.json", colors: ["#88c0d0", "#81a1c1", "#82D2CE"], isDark: true },
        { name: "Dracula", file: "dracula.json", colors: ["#bd93f9", "#ff79c6", "#8be9fd"], isDark: true },
        { name: "Eldritch", file: "eldritch.json", colors: ["#37f499", "#04d1f9", "#a48cf2"], isDark: true },
        { name: "Everforest", file: "everforest.json", colors: ["#a7c080", "#d3c6aa", "#9da9a0"], isDark: true },
        { name: "Flexoki", file: "flexoki.json", colors: ["#DA702C", "#4385BE", "#8B7EC8"], isDark: true },
        { name: "Frappe", file: "frappe.json", colors: ["#ef9f76", "#e5c890", "#babbf1"], isDark: true },
        { name: "Github", file: "github.json", colors: ["#58a6ff", "#bc8cff", "#39c5cf"], isDark: true },
        { name: "Gruvbox", file: "gruvbox.json", colors: ["#b8bb26", "#fabd2f", "#83a598"], isDark: true },
        { name: "Kanagawa", file: "kanagawa.json", colors: ["#76946a", "#c0a36e", "#7e9cd8"], isDark: true },
        { name: "Latte", file: "latte.json", colors: ["#8839ef", "#ea76cb", "#179299"], isDark: false },
        { name: "Macchiato", file: "macchiato.json", colors: ["#f5a97f", "#eed49f", "#b7bdf8"], isDark: true },
        { name: "Material Ocean", file: "material_ocean.json", colors: ["#82aaff", "#c792ea", "#89ddff"], isDark: true },
        { name: "Matrix", file: "matrix.json", colors: ["#00ff41", "#008f11", "#ffffff"], isDark: true },
        { name: "Mercury", file: "mercury.json", colors: ["#8da4f5", "#a7b6f8", "#77becf"], isDark: true },
        { name: "Mocha", file: "mocha.json", colors: ["#cba6f7", "#f5c2e7", "#94e2d5"], isDark: true },
        { name: "NAnDoroid", file: "nandoroid.json", colors: ["#477ad6", "#7ea0d6", "#b479d6"], isDark: true },
        { name: "Nord", file: "nord.json", colors: ["#8fbcbb", "#88c0d0", "#5e81ac"], isDark: true },
        { name: "One Dark", file: "one_dark.json", colors: ["#61afef", "#c678dd", "#98c379"], isDark: true },
        { name: "Open Code", file: "open_code.json", colors: ["#fab283", "#5c9cf5", "#9d7cd8"], isDark: true },
        { name: "Orng", file: "orng.json", colors: ["#EC5B2B", "#EE7948", "#FFF7F1"], isDark: true },
        { name: "Osaka Jade", file: "osaka_jade.json", colors: ["#2DD5B7", "#D2689C", "#549e6a"], isDark: true },
        { name: "Oxocarbon", file: "oxocarbon.json", colors: ["#33b1ff", "#42be65", "#be95ff"], isDark: true },
        { name: "Rose Pine", file: "rose_pine.json", colors: ["#ebbcba", "#9ccfd8", "#31748f"], isDark: true },
        { name: "Sakura", file: "sakura.json", colors: ["#d4869c", "#c9a0a0", "#8faa8f"], isDark: false },
        { name: "Samurai", file: "samurai.json", colors: ["#c41e3a", "#8b8589", "#d4af37"], isDark: true },
        { name: "Solarized", file: "solarized.json", colors: ["#b58900", "#d33682", "#cb4b16"], isDark: true },
        { name: "Synthwave84", file: "synthwave84.json", colors: ["#36f9f6", "#ff7edb", "#b084eb"], isDark: true },
        { name: "Tokyo Night", file: "tokyo_night.json", colors: ["#7aa2f7", "#bb9af7", "#9ece6a"], isDark: true },
        { name: "Vercel", file: "vercel.json", colors: ["#0070F3", "#52A8FF", "#8E4EC6"], isDark: true },
        { name: "Vesper", file: "vesper.json", colors: ["#FFC799", "#99FFE4", "#A0A0A0"], isDark: true },
        { name: "Zen Burn", file: "zen_burn.json", colors: ["#8cd0d3", "#dc8cc3", "#93e0e3"], isDark: true },
        { name: "Zen Garden", file: "zen_garden.json", colors: ["#7a9a7a", "#9a9080", "#8a9aa0"], isDark: true }
    ]

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
