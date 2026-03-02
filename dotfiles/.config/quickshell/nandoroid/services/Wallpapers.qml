pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import "../core"

Singleton {
    id: root
    
    // Directory to scan for wallpapers
    property url directory: Qt.resolvedUrl(Directories.home + "/Pictures/Wallpapers")
    property string searchQuery: ""
    
    readonly property list<string> imagePatterns: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.avif"]

    // Helper process to generate material colors
    Process {
        id: matugenProc
        command: ["bash", "-c", `matugen -t "${scheme}" -m ${Config.options.appearance.background.darkmode ? "dark" : "light"} image "${filePath}" --source-color-index 0`]
        property string filePath
        property string scheme: Config.options.appearance.background.matugenScheme || "scheme-tonal-spot"
    }

    Process {
        id: matugenColorProc
        command: ["bash", "-c", `matugen -t "${scheme}" -m ${Config.options.appearance.background.darkmode ? "dark" : "light"} color hex "${hexColor}" --source-color-index 0`]
        property string hexColor
        property string scheme: "scheme-tonal-spot"
    }

    function toggleDarkMode() {
        if (!Config.ready) return;
        Config.options.appearance.background.darkmode = !Config.options.appearance.background.darkmode;
        
        // Re-run colors generation
        if (Config.options.appearance.background.matugen) {
            const source = Config.options.appearance.background.matugenSource || "desktop"
            const path = source === "lockscreen" ? Config.options.lock.wallpaperPath : Config.options.appearance.background.wallpaperPath
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
            if (cleanPath !== "") {
                matugenProc.filePath = cleanPath
                matugenProc.running = true
            }
        } else {
            const hex = Config.options.appearance.background.matugenCustomColor
            if (hex) applyColor(hex)
        }
    }

    function select(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        Config.options.appearance.background.wallpaperPath = "file://" + cleanPath
        
        // Sync to lockscreen if separate wallpapers are disabled
        if (Config.options.lock && !Config.options.lock.useSeparateWallpaper) {
            Config.options.lock.wallpaperPath = "file://" + cleanPath
        }
        
        if (Config.options.appearance.background.matugen) {
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }
    }

    function applyScheme(scheme, source = "") {
        if (source === "") source = Config.options.appearance.background.matugenSource || "desktop"
        Config.options.appearance.background.matugenScheme = scheme
        Config.options.appearance.background.matugenSource = source
        
        if (Config.options.appearance.background.matugen) {
            const path = source === "lockscreen" ? Config.options.lock.wallpaperPath : Config.options.appearance.background.wallpaperPath
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
            if (cleanPath === "") return
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }
    }

    function applyColor(hex) {
        if (!Config.ready) return;
        Config.options.appearance.background.matugen = false // Disable wallpaper-based matugen
        Config.options.appearance.background.matugenCustomColor = hex
        matugenColorProc.hexColor = hex
        matugenColorProc.running = true
        
        // We don't save single colors to the material theme file yet 
        // because we don't have a full Material 3 JSON for a single color 
        // in a simple way without running matugen.
    }

    Process {
        id: themeWriteProc
        command: ["bash", "-c", `cat "${sourcePath}" > "${targetPath}"`]
        property string sourcePath
        property string targetPath: Directories.generatedMaterialThemePath
    }

    Process {
        id: themeReadProc
        command: ["cat", filePath]
        property string filePath
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    MaterialThemeLoader.applyColors(this.text);
                } catch(e) {
                    console.error("[Wallpapers] Theme Load Error:", e);
                }
            }
        }
    }

    function applyTheme(fileName) {
        if (!Config.ready) return;
        const themesDir = Qt.resolvedUrl("../assets/themes/").toString();
        const cleanDir = themesDir.startsWith("file://") ? themesDir.substring(7) : themesDir;
        const fullPath = cleanDir + fileName;
        
        // 1. apply immediately to UI
        themeReadProc.filePath = fullPath;
        themeReadProc.running = true;
        
        // 2. Save for persistence (MaterialThemeLoader watches this)
        themeWriteProc.sourcePath = fullPath;
        themeWriteProc.running = true;
        
        // Update config for persistent matching and automatic mode switching
        const theme = root.findBasicThemeByFile(fileName);
        if (theme) {
            Config.options.appearance.background.matugen = false;
            Config.options.appearance.background.matugenCustomColor = theme.colors[0];
            Config.options.appearance.background.matugenThemeFile = fileName; // Unique identifier
            
            // Automatic mode switching based on theme file
            const lowerFile = fileName.toLowerCase();
            const isLight = lowerFile.includes("latte") || lowerFile.includes("_light") || lowerFile.includes("mercury") || lowerFile.includes("github");
            
            if (isLight && Config.options.appearance.background.darkmode) {
                Config.options.appearance.background.darkmode = false;
            } else if (!isLight && !Config.options.appearance.background.darkmode) {
                Config.options.appearance.background.darkmode = true;
            }
        }
    }
    
    function initializeMatugen() {
        if (!Config.ready) {
            console.log("[Wallpapers] Config not ready, delaying initialization...");
            configWaitTimer.start();
            return;
        }
        
        if (Config.options.appearance.background.matugen) {
            console.log("[Wallpapers] Triggering initial theme generation from default wallpaper...");
            const path = Config.options.appearance.background.wallpaperPath;
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
            if (cleanPath !== "") {
                matugenProc.filePath = cleanPath;
                matugenProc.running = true;
            }
        }
    }

    Timer {
        id: configWaitTimer
        interval: 500
        repeat: false
        onTriggered: root.initializeMatugen()
    }

    function findBasicThemeByFile(fileName) {
        const basicThemes = [
            { file: "angel.json", colors: ["#5682A3"] },
            { file: "angel_light.json", colors: ["#5682A3"] },
            { file: "ayu.json", colors: ["#ffb454"] },
            { file: "cobalt2.json", colors: ["#ffc600"] },
            { file: "cursor.json", colors: ["#2DD5B7"] },
            { file: "dracula.json", colors: ["#bd93f9"] },
            { file: "flexoki.json", colors: ["#ceb3a2"] },
            { file: "frappe.json", colors: ["#ca9ee6"] },
            { file: "github.json", colors: ["#d73a49"] },
            { file: "gruvbox.json", colors: ["#fab387"] },
            { file: "kanagawa.json", colors: ["#7e9cd8"] },
            { file: "latte.json", colors: ["#8839ef"] },
            { file: "macchiato.json", colors: ["#c6a0f6"] },
            { file: "material_ocean.json", colors: ["#89ddff"] },
            { file: "matrix.json", colors: ["#00FF41"] },
            { file: "mercury.json", colors: ["#E0E0E0"] },
            { file: "mocha.json", colors: ["#cba6f7"] },
            { file: "nord.json", colors: ["#88c0d0"] },
            { file: "open_code.json", colors: ["#2DD5B7"] },
            { file: "orng.json", colors: ["#FF9500"] },
            { file: "osaka_jade.json", colors: ["#00A676"] },
            { file: "rose_pine.json", colors: ["#c4a7e7"] },
            { file: "sakura.json", colors: ["#d4869c"] },
            { file: "samurai.json", colors: ["#c41e3a"] },
            { file: "synthwave84.json", colors: ["#36f9f6"] },
            { file: "vercel.json", colors: ["#0070F3"] },
            { file: "vesper.json", colors: ["#FFC799"] },
            { file: "zen_burn.json", colors: ["#8cd0d3"] },
            { file: "zen_garden.json", colors: ["#7a9a7a"] }
        ];
        return basicThemes.find(t => t.file === fileName);
    }

    function selectForLockscreen(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        Config.options.lock.wallpaperPath = "file://" + cleanPath
    }

    // Model for grid view
    property alias folderModel: model
    FolderListModel {
        id: model
        folder: root.directory
        nameFilters: {
            if (root.searchQuery === "") return root.imagePatterns;
            const query = root.searchQuery.toLowerCase();
            return root.imagePatterns.map(p => `*${query}*${p.substring(1)}`);
        }
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }
}
