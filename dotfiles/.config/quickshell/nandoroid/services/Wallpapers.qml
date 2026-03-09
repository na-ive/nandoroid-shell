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
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" image "$3" --source-color-index 0 && sh -c "~/.config/quickshell/nandoroid/scripts/colors/apply_system_theme.sh"`, "matugen", scheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), filePath]
        property string filePath
        property string scheme: Config.options.appearance.background.matugenScheme || "scheme-tonal-spot"
        
        stderr: StdioCollector {
            onStreamFinished: {
                // Look for actual fatal error markers
                if (this.text.includes("Error:") || this.text.includes("Invalid")) {
                    console.log("[Wallpapers] Matugen Error:", this.text);
                    root.sendNotification("Theming Error", "Failed to process wallpaper. The file might be corrupted or invalid.");
                }
            }
        }
    }

    Process {
        id: matugenColorProc
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" color hex "$3" --source-color-index 0 && sh -c "~/.config/quickshell/nandoroid/scripts/colors/apply_system_theme.sh"`, "matugen", scheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), hexColor]
        property string hexColor
        property string scheme: "scheme-tonal-spot"

        stderr: StdioCollector {
            onStreamFinished: {
                // Only notify if it's a fatal error
                if (this.text.includes("Error:")) {
                    console.log("[Wallpapers] Matugen Color Error:", this.text);
                    root.sendNotification("Theming Error", "Failed to generate theme from color.");
                }
            }
        }
    }

    function sendNotification(title, body) {
        const iconPath = Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg";
        const cmd = [
            "notify-send",
            "-a", "NAnDoroid",
            "-i", iconPath,
            title,
            body
        ];
        Quickshell.execDetached(cmd);
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
        Config.options.appearance.background.matugen = true
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
        
        // Update config first for proper dark mode detection in matugen
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

            // Run matugen to generate full system colors (GTK, KDE, etc) from the first basic color
            matugenColorProc.hexColor = theme.colors[0];
            matugenColorProc.running = true;
        }

        // 1. apply immediately to UI (for fast feedback)
        themeReadProc.filePath = fullPath;
        themeReadProc.running = true;
        
        // 2. Save for persistence (MaterialThemeLoader watches this)
        themeWriteProc.sourcePath = fullPath;
        themeWriteProc.running = true;
    }
    
    function initializeMatugen() {
        if (!Config.ready) {
            console.log("[Wallpapers] Config not ready, delaying initialization...");
            configWaitTimer.start();
            return;
        }
        
        if (Config.options.appearance.background.matugen) {
            console.log("[Wallpapers] Triggering initial theme generation from current wallpaper...");
            const source = Config.options.appearance.background.matugenSource || "desktop"
            const path = (source === "lockscreen" && Config.options.lock) ? Config.options.lock.wallpaperPath : Config.options.appearance.background.wallpaperPath;
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

    // --- Local state for better reactivity ---
    property bool _autoCycleEnabled: false
    property string _autoCycleDirectory: ""
    property int _autoCycleInterval: 30

    // Explicit setters for the UI to call directly
    function setAutoCycle(enabled) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleEnabled = enabled;
        _autoCycleEnabled = enabled;
        console.log("[Wallpapers] setAutoCycle called:", enabled);
        if (enabled) {
            autoCycleStartTimer.restart();
        } else {
            root.autoCyclePending = false;
        }
    }

    function setAutoCycleDirectory(dir) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleDirectory = dir;
        _autoCycleDirectory = dir;
        console.log("[Wallpapers] setAutoCycleDirectory called:", dir);
    }

    function setAutoCycleInterval(interval) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleInterval = interval;
        _autoCycleInterval = interval;
        console.log("[Wallpapers] setAutoCycleInterval called:", interval);
    }

    function syncSettings() {
        if (!Config.ready) return;
        const bg = Config.options.appearance.background;
        _autoCycleEnabled = bg.autoCycleEnabled;
        _autoCycleDirectory = bg.autoCycleDirectory || "";
        _autoCycleInterval = bg.autoCycleInterval || 30;
        
        console.log("[Wallpapers] Settings synced - Enabled:", _autoCycleEnabled, "Dir:", _autoCycleDirectory);
        
        if (_autoCycleEnabled) {
            // Kickstart the cycle on startup or reload
            autoCycleStartTimer.restart();
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                console.log("[Wallpapers] Config ready, syncing...");
                root.syncSettings();
            }
        }
    }

    // Model for grid view
    property alias folderModel: model
    FolderListModel {
        id: model
        folder: {
            if (!root._autoCycleEnabled || root._autoCycleDirectory === "") return root.directory;
            let dir = root._autoCycleDirectory;
            if (!dir.startsWith("file://")) dir = "file://" + dir;
            return dir;
        }
        onFolderChanged: {
            console.log("[Wallpapers] Model folder changed to:", folder);
            if (root._autoCycleEnabled) {
                root.autoCyclePending = true;
                // If the folder changed, we might need to re-trigger the cycle
                autoCycleStartTimer.restart();
            }
        }
        nameFilters: {
            if (root.searchQuery === "") return root.imagePatterns;
            return [`*${root.searchQuery}*`, ...root.imagePatterns];
        }
        showDirs: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onCountChanged: {
            console.log("[Wallpapers] Folder count changed:", count);
            if (count > 0 && root._autoCycleEnabled && root.autoCyclePending) {
                console.log("[Wallpapers] Resolving pending cycle with newly loaded images");
                root.autoCyclePending = false;
                root.nextWallpaper();
            }
        }
    }

    property bool autoCyclePending: false

    Timer {
        id: autoCycleStartTimer
        interval: 1000 // Give it a bit more time on startup
        repeat: false
        onTriggered: {
            if (!root._autoCycleEnabled) return;
            
            if (model.count > 0) {
                console.log("[Wallpapers] Start timer triggered, count > 0, cycling...");
                root.nextWallpaper();
            } else {
                console.log("[Wallpapers] Start timer triggered but model count is 0, setting pending.");
                root.autoCyclePending = true;
            }
        }
    }

    Component.onCompleted: {
        if (Config.ready) {
            console.log("[Wallpapers] Singleton completed and config ready, syncing...");
            root.syncSettings();
        }
    }

    Connections {
        // Matugen doesn't suffer as much because it's usually called by other UI interactions
        // but we'll leave it as is or handle it similarly if needed
        target: (Config.ready && Config.options.appearance) ? Config.options.appearance.background : null
        ignoreUnknownSignals: true
        function onMatugenChanged() {
            if (!Config.ready) return;
            if (Config.options.appearance.background.matugen) {
                root.initializeMatugen();
            } else {
                const theme = Config.options.appearance.background.matugenThemeFile;
                if (theme && theme !== "") {
                    root.applyTheme(theme);
                } else {
                    root.applyTheme("mocha.json");
                }
            }
        }
    }

    // --- Wallpaper Auto-Cycle ---
    Timer {
        id: autoCycleTimer
        interval: Math.max(1, root._autoCycleInterval) * 60 * 1000
        running: root._autoCycleEnabled
        repeat: true
        onTriggered: {
            console.log("[Wallpapers] Interval reached, cycling...");
            root.nextWallpaper();
        }
    }

    function nextWallpaper() {
        if (!Config.ready) return;
        if (!root._autoCycleEnabled) return;

        const count = model.count;
        if (count <= 0) {
            console.log("[Wallpapers] No wallpapers available in", model.folder);
            root.autoCyclePending = true;
            return;
        }

        let index = Math.floor(Math.random() * count);
        let newPath = model.get(index, "fileUrl");

        if (!newPath) {
            root.autoCyclePending = true;
            return;
        }

        console.log("[Wallpapers] Cycling to:", newPath);

        if (newPath.toString() === Config.options.appearance.background.wallpaperPath.toString() && count > 1) {
            index = (index + 1) % count;
            newPath = model.get(index, "fileUrl");
        }

        root.select(newPath);
    }
}
