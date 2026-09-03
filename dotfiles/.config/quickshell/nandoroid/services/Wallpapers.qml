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

    property list<string> favorites: []

    function isFavorite(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
        // Case-insensitive check for favorites
        for (let i = 0; i < favorites.length; i++) {
            if (favorites[i].toLowerCase() === cleanPath.toLowerCase()) return true;
        }
        return false;
    }

    function toggleFavorite(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString();
        let currentFavs = favorites.slice();
        
        let foundIndex = -1;
        for (let i = 0; i < currentFavs.length; i++) {
            if (currentFavs[i].toLowerCase() === cleanPath.toLowerCase()) {
                foundIndex = i;
                break;
            }
        }
        
        if (foundIndex === -1) {
            currentFavs.push(cleanPath);
        } else {
            currentFavs.splice(foundIndex, 1);
        }
        
        root.favorites = currentFavs;
        saveFavorites();
    }

    function selectRandomFavorite() {
        // Filter favorites to include only static images and exclude Wallpaper Engine paths
        const staticFavs = favorites.filter(path => {
            const p = path.toLowerCase();
            const isImage = p.endsWith(".jpg") || p.endsWith(".jpeg") || p.endsWith(".png") || p.endsWith(".webp") || p.endsWith(".avif");
            const isWE = p.includes("431960"); // Steam Workshop ID for Wallpaper Engine
            return isImage && !isWE;
        });

        if (staticFavs.length > 0) {
            const index = Math.floor(Math.random() * staticFavs.length);
            root.select(staticFavs[index]);
            return true;
        }
        return false;
    }

    function selectRandomFromDirectory(dirPath) {
        let cleanPath = dirPath.toString().startsWith("file://") ? dirPath.toString().substring(7) : dirPath.toString();
        // Use a shell command to pick a random image file from the directory
        const cmd = `find "${cleanPath}" -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.avif" \\) | shuf -n 1`;
        
        const proc = Quickshell.exec(["bash", "-c", cmd]);
        proc.finished.connect(() => {
            const result = proc.stdout.readAll().trim();
            if (result !== "") {
                root.select(result);
            }
        });
    }

    function saveFavorites() {
        const data = JSON.stringify(root.favorites);
        const path = Directories.favoritesPathRaw;
        Quickshell.execDetached(["sh", "-c", 'printf "%s" "$1" > "$2"', "sh", data, path]);
    }

    FileView {
        id: favsFile
        path: Directories.favoritesPath
        watchChanges: true
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed)) {
                    root.favorites = parsed;
                }
            } catch(e) {

            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                saveFavorites(); // Create it empty
            }
        }
    }

    // Lockscreen colors file watcher
    FileView {
        id: lockColorsFile
        path: "file://" + Directories.generatedLockColorsPath
        watchChanges: true
        onFileChanged: {
            reload()
        }
        onLoaded: {
            try {
                const content = text();
                if (content.trim() !== "") {
                    MaterialThemeLoader.applyLockColors(content);
                }
            } catch(e) {
                console.error("[Wallpapers] Failed to load lockscreen colors:", e);
            }
        }
        onLoadFailed: error => {
            if (error != FileViewError.FileNotFound) {
                console.error("[Wallpapers] Lockscreen colors load error:", error);
            }
        }
    }

    // Helper process to generate material colors
    Process {
        id: matugenProc
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" image "$3" --source-color-index 0`, "matugen", scheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), filePath]
        property string filePath
        property string scheme: Config.options.appearance.background.matugenScheme || "scheme-tonal-spot"
        
        onRunningChanged: if (running) CavaService.stop(); else CavaService.start();

        stderr: StdioCollector {
            onStreamFinished: {
                // Look for actual fatal error markers (Matugen v4 specific fatal markers)
                if (this.text.includes("Failed to generate base16 color schemes") || this.text.includes("Invalid PNG signature")) {
                    root.sendNotification("Theming Error", "Failed to process wallpaper. The file might be corrupted.");
                }
            }
        }
    }

    Process {
        id: matugenColorProc
        command: ["bash", "-c", `matugen -c ~/.config/matugen/config.toml -t "$1" -m "$2" color hex "$3"`, "matugen", scheme, (Config.options.appearance.background.darkmode ? "dark" : "light"), hexColor]
        property string hexColor
        property string scheme: {
            // When in Basic mode (using a predefined theme file), always use tonal-spot
            if (Config.ready && !Config.options.appearance.background.matugen && Config.options.appearance.background.matugenThemeFile !== "") return "scheme-tonal-spot";
            return Config.options.appearance.background.matugenScheme || "scheme-tonal-spot";
        }

        onRunningChanged: if (running) CavaService.stop(); else CavaService.start();

        stderr: StdioCollector {
            onStreamFinished: {
                // Ignore benign errors (missing unrelated files/commands)
                if (this.text.includes("Failed to generate base16 color schemes")) {
                    root.sendNotification("Theming Error", "Failed to generate theme from color.");
                }
            }
        }
    }

    // Process to generate lockscreen matugen colors (output as JSON, no config file needed)
    Process {
        id: matugenLockscreenProc
        command: [
            "bash", "-c",
            `matugen --dry-run -t "$1" -m "$2" image "$3" --source-color-index 0 -j hex --old-json-output`,
            "matugen",
            scheme,
            (Config.options.appearance.background.darkmode ? "dark" : "light"),
            filePath
        ]
        property string filePath
        property string scheme: {
            if (Config.ready && !Config.options.appearance.background.matugen && Config.options.appearance.background.matugenThemeFile !== "") return "scheme-tonal-spot";
            return Config.options.appearance.background.matugenScheme || "scheme-tonal-spot";
        }

        onRunningChanged: if (running) CavaService.stop(); else CavaService.start();

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(this.text);
                    const mode = Config.options.appearance.background.darkmode ? "dark" : "light";
                    const flat = {};
                    for (const key in json.colors) {
                        flat[key] = json.colors[key][mode] || json.colors[key]["default"];
                    }
                    const flatStr = JSON.stringify(flat, null, 2);
                    Quickshell.execDetached([
                        "sh", "-c", 'printf "%s" "$1" > "$2"',
                        "sh", flatStr, Directories.generatedLockColorsPath
                    ]);
                } catch(e) {
                    console.error("[Wallpapers] Failed to process lockscreen matugen:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.includes("Failed to generate base16 color schemes") || this.text.includes("Invalid PNG signature")) {
                    Wallpapers.sendNotification("Lockscreen Theming Error", "Failed to process lockscreen wallpaper.");
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

    function getWallpaperPath(source = "desktop") {
        if (source === "lockscreen") {
            return Config.options.lock.wallpaperPath;
        }
        
        if (WallpaperEngineService.active) {
            return WallpaperEngineService.screenshotPath;
        }
        
        if (MpvpaperService.active) {
            return MpvpaperService.framePath;
        }
        
        return Config.options.appearance.background.wallpaperPath;
    }

    function toggleDarkMode() {
        if (!Config.ready) return;
        Config.options.appearance.background.darkmode = !Config.options.appearance.background.darkmode;
        
        // Re-run colors generation
        if (Config.options.appearance.background.matugen) {
            const source = Config.options.appearance.background.matugenSource || "desktop"
            const path = root.getWallpaperPath(source)
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
            if (cleanPath !== "") {
                matugenProc.filePath = cleanPath
                matugenProc.running = true
            }
        } else {
            const hex = Config.options.appearance.background.matugenCustomColor
            if (hex) applyColor(hex)
        }

        // Also regenerate lockscreen colors if using separate wallpaper
        if (Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath) {
            const lockPath = Config.options.lock.wallpaperPath.toString().replace("file://", "");
            if (lockPath !== "") {
                matugenLockscreenProc.filePath = lockPath
                matugenLockscreenProc.running = true
            }
        }
    }

    function select(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        
        // Stop any active live wallpaper backend so the static image takes over
        WallpaperEngineService.stop();
        MpvpaperService.stop();
        
        Config.options.appearance.background.wallpaperPath = "file://" + cleanPath
        
        // Sync to lockscreen if separate wallpapers are disabled
        if (Config.options.lock && !Config.options.lock.useSeparateWallpaper) {
            Config.options.lock.wallpaperPath = "file://" + cleanPath
        }

        if (Config.options.appearance.background.matugen) {
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        } else {
            // Reset from custom accent to matugen-from-wallpaper
            Config.options.appearance.background.matugen = true
            Config.options.appearance.background.matugenCustomColor = ""
            Config.options.appearance.background.matugenThemeFile = ""
        }
    }

    function applyScheme(scheme, source = "") {
        if (source === "") source = Config.options.appearance.background.matugenSource || "desktop"
        Config.options.appearance.background.matugen = true
        Config.options.appearance.background.matugenScheme = scheme
        Config.options.appearance.background.matugenSource = source
        
        if (Config.options.appearance.background.matugen) {
            const path = root.getWallpaperPath(source)
            const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
            if (cleanPath === "") return
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }

        // Also regenerate lockscreen colors if using separate wallpaper
        if (Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath) {
            const lockPath = Config.options.lock.wallpaperPath.toString().replace("file://", "");
            if (lockPath !== "") {
                matugenLockscreenProc.filePath = lockPath
                matugenLockscreenProc.running = true
            }
        }
    }

    property bool _applyingTheme: false

    function applyColor(hex, source = "desktop") {
        if (!Config.ready) return;
        var savedApplyingTheme = root._applyingTheme;
        root._applyingTheme = false;

        Config.options.appearance.background.matugen = false // Disable wallpaper-based matugen
        Config.options.appearance.background.matugenCustomColor = hex
        Config.options.appearance.background.matugenThemeFile = ""
        Config.options.appearance.background.matugenSource = source
        
        matugenColorProc.running = false;
        matugenColorProc.hexColor = hex;
        // Small delay to ensure process state reset
        Qt.callLater(() => { matugenColorProc.running = true; });

        // Accent for desktop only — regenerate lockscreen colors only if using a different wallpaper
        if (source !== "lockscreen" && Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath) {
            const lockPath = Config.options.lock.wallpaperPath.toString().replace("file://", "");
            const desktopPath = Config.options.appearance.background.wallpaperPath.toString().replace("file://", "");
            if (lockPath !== "" && lockPath !== desktopPath) {
                matugenLockscreenProc.running = false;
                matugenLockscreenProc.filePath = lockPath;
                Qt.callLater(() => { matugenLockscreenProc.running = true; });
            }
        }

        root._applyingTheme = savedApplyingTheme;
    }

    function pickAccent(target = "desktop") {
        // Normalize target name to "lockscreen" if it's "lock"
        const finalTarget = target === "lock" ? "lockscreen" : target;
        const cmd = `
            pkill hyprpicker || true
            sleep 0.5
            HEX=$(hyprpicker --no-fancy)
            if [[ "$HEX" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
                quickshell -c nandoroid ipc call wallpaper_accent apply_accent "$HEX" "${finalTarget}"
            else
                quickshell -c nandoroid ipc call wallpaper_accent close_accent
            fi
        `;
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    IpcHandler {
        target: "wallpaper_accent"
        function apply_accent(hex: string, source: string): void {
            console.log("[Wallpapers] Accent color picked: " + hex + " for " + source);
            root.applyColor(hex, source);
            GlobalStates.accentPickerOpen = false;
        }
        function close_accent(): void {
            GlobalStates.accentPickerOpen = false;
        }
    }

    // Kill hyprpicker if the overlay is closed through other means (shortcut, launcher, etc)
    Connections {
        target: GlobalStates
        function onAccentPickerOpenChanged() {
            if (!GlobalStates.accentPickerOpen) {
                Quickshell.execDetached(["pkill", "hyprpicker"]);
            }
        }
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
        root._applyingTheme = true;
        const themesDir = Qt.resolvedUrl("../assets/themes/").toString();
        const cleanDir = themesDir.startsWith("file://") ? themesDir.substring(7) : themesDir;
        const fullPath = cleanDir + fileName;
        
        // Update config first for proper dark mode detection in matugen
        const theme = root.findBasicThemeByFile(fileName);
        if (theme) {
            Config.options.appearance.background.matugen = false;
            Config.options.appearance.background.matugenCustomColor = theme.colors[0];
            Config.options.appearance.background.matugenThemeFile = fileName; // Unique identifier
            
            // Automatic mode switching based on explicit theme property
            const isDarkTheme = theme.isDark !== undefined ? theme.isDark : true;
            
            if (!isDarkTheme && Config.options.appearance.background.darkmode) {
                Config.options.appearance.background.darkmode = false;
            } else if (isDarkTheme && !Config.options.appearance.background.darkmode) {
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

        Qt.callLater(() => {
            root._applyingTheme = false;
            if (Config.ready && Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath) {
                const lockPath = Config.options.lock.wallpaperPath.toString().replace("file://", "");
                const desktopPath = Config.options.appearance.background.wallpaperPath.toString().replace("file://", "");
                if (lockPath !== "" && lockPath !== desktopPath) {
                    matugenLockscreenProc.running = false;
                    matugenLockscreenProc.filePath = lockPath;
                    Qt.callLater(() => { matugenLockscreenProc.running = true; });
                }
            }
        });
    }
    
    function initializeMatugen() {
        if (!Config.ready) {
            configWaitTimer.start();
            return;
        }
        
        if (Config.options.appearance.background.matugen) {
            const source = Config.options.appearance.background.matugenSource || "desktop"
            const path = root.getWallpaperPath(source);
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
            { file: "angel.json", colors: ["#e8b882"], isDark: true },
            { file: "angel_light.json", colors: ["#9a6830"], isDark: false },
            { file: "ayu.json", colors: ["#e6b450"], isDark: true },
            { file: "cobalt2.json", colors: ["#0088ff"], isDark: true },
            { file: "cursor.json", colors: ["#88c0d0"], isDark: true },
            { file: "dracula.json", colors: ["#bd93f9"], isDark: true },
            { file: "eldritch.json", colors: ["#37f499"], isDark: true },
            { file: "everforest.json", colors: ["#a7c080"], isDark: true },
            { file: "flexoki.json", colors: ["#DA702C"], isDark: true },
            { file: "frappe.json", colors: ["#ef9f76"], isDark: true },
            { file: "github.json", colors: ["#58a6ff"], isDark: true },
            { file: "gruvbox.json", colors: ["#b8bb26"], isDark: true },
            { file: "kanagawa.json", colors: ["#76946a"], isDark: true },
            { file: "latte.json", colors: ["#8839ef"], isDark: false },
            { file: "macchiato.json", colors: ["#f5a97f"], isDark: true },
            { file: "material_ocean.json", colors: ["#82aaff"], isDark: true },
            { file: "matrix.json", colors: ["#00ff41"], isDark: true },
            { file: "mercury.json", colors: ["#8da4f5"], isDark: true },
            { file: "mocha.json", colors: ["#cba6f7"], isDark: true },
            { file: "nandoroid.json", colors: ["#477ad6"], isDark: true },
            { file: "nord.json", colors: ["#8fbcbb"], isDark: true },
            { file: "one_dark.json", colors: ["#61afef"], isDark: true },
            { file: "open_code.json", colors: ["#fab283"], isDark: true },
            { file: "orng.json", colors: ["#EC5B2B"], isDark: true },
            { file: "osaka_jade.json", colors: ["#2DD5B7"], isDark: true },
            { file: "oxocarbon.json", colors: ["#33b1ff"], isDark: true },
            { file: "rose_pine.json", colors: ["#ebbcba"], isDark: true },
            { file: "sakura.json", colors: ["#d4869c"], isDark: false },
            { file: "samurai.json", colors: ["#c41e3a"], isDark: true },
            { file: "solarized.json", colors: ["#b58900"], isDark: true },
            { file: "synthwave84.json", colors: ["#36f9f6"], isDark: true },
            { file: "tokyo_night.json", colors: ["#7aa2f7"], isDark: true },
            { file: "vercel.json", colors: ["#0070F3"], isDark: true },
            { file: "vesper.json", colors: ["#FFC799"], isDark: true },
            { file: "zen_burn.json", colors: ["#8cd0d3"], isDark: true },
            { file: "zen_garden.json", colors: ["#7a9a7a"], isDark: true }
        ];
        return basicThemes.find(t => t.file === fileName);
    }

    function selectForLockscreen(path, enableSeparate = true) {
        if (enableSeparate && Config.ready && Config.options.lock) {
            Config.options.lock.useSeparateWallpaper = true
        }
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        Config.options.lock.wallpaperPath = "file://" + cleanPath

        if (cleanPath === matugenProc.filePath) {
            // Same wallpaper as desktop — reuse desktop colors, skip duplicate matugen run
            Quickshell.execDetached([
                "sh", "-c", 'cp "$1" "$2"',
                "sh", Directories.generatedMaterialThemePath, Directories.generatedLockColorsPath
            ]);
        } else {
            matugenLockscreenProc.running = false;
            matugenLockscreenProc.filePath = cleanPath
            Qt.callLater(() => { matugenLockscreenProc.running = true; });
        }
    }

    function generateColors(path) {
        const cleanPath = path.toString().startsWith("file://") ? path.toString().substring(7) : path.toString()
        if (Config.options.appearance.background.matugen) {
            matugenProc.filePath = cleanPath
            matugenProc.running = true
        }
        // Also generate lockscreen colors if the lockscreen uses this path
        if (Config.options.lock.useSeparateWallpaper &&
            Config.options.lock.wallpaperPath &&
            Config.options.lock.wallpaperPath === path) {
            matugenLockscreenProc.filePath = cleanPath
            matugenLockscreenProc.running = true
        }
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
    }

    function setAutoCycleInterval(interval) {
        if (!Config.ready) return;
        Config.options.appearance.background.autoCycleInterval = interval;
        _autoCycleInterval = interval;
    }

    function syncSettings() {
        if (!Config.ready) return;
        const bg = Config.options.appearance.background;
        _autoCycleEnabled = bg.autoCycleEnabled;
        _autoCycleDirectory = bg.autoCycleDirectory || "";
        _autoCycleInterval = bg.autoCycleInterval || 30;
        
        
        // Initial theme load on startup/reload
        if (bg.matugen) {
            root.initializeMatugen();
        } else {
            const theme = bg.matugenThemeFile;
            if (theme && theme !== "") {
                root.applyTheme(theme);
            } else if (bg.matugenCustomColor && bg.matugenCustomColor !== "") {
                root.applyColor(bg.matugenCustomColor);
            } else {
                root.applyTheme("mocha.json");
            }
        }

        if (_autoCycleEnabled) {
            // Kickstart the cycle on startup or reload
            autoCycleStartTimer.restart();
        }

        // Generate lockscreen colors on startup if using separate wallpaper
        if (Config.options.lock.useSeparateWallpaper &&
            Config.options.lock.wallpaperPath &&
            Config.options.lock.wallpaperPath !== "" &&
            Config.options.appearance.background.matugen) {
            const lockPath = Config.options.lock.wallpaperPath.toString().replace("file://", "");
            if (lockPath !== "") {
                matugenLockscreenProc.filePath = lockPath;
                matugenLockscreenProc.running = true;
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) {
                root.syncSettings();
            }
        }
    }

    // --- Sorting ---
    property int sortField: FolderListModel.Name
    property bool sortReversed: false

    // --- Folder Picker ---
    Process {
        id: folderPickerProc
        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpaper Folder", "--modal"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    let current = (Config.options.appearance.background.customFolders || []).slice();
                    if (!current.includes(path)) {
                        current.push(path);
                        Config.options.appearance.background.customFolders = current;
                        root.customFoldersChanged();
                    }
                }
                // Use a timer to ensure the process has fully detached before reopening UI
                reopenTimer.start();
            }
        }
    }

    Timer {
        id: reopenTimer
        interval: 100
        repeat: false
        onTriggered: root.pickerFinished()
    }

    signal customFoldersChanged()
    signal pickerFinished()

    function browseFolder() {
        GlobalStates.wallpaperSelectorOpen = false;
        folderPickerProc.running = true;
    }

    // --- Auto-Cycle Folder Picker ---
    Process {
        id: cycleFolderPickerProc
        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpapers Directory", "--modal"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    root.setAutoCycleDirectory(path);
                }
            }
        }
    }

    function browseCycleFolder() {
        cycleFolderPickerProc.running = true;
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
            if (root._autoCycleEnabled) {
                root.autoCyclePending = true;
                // If the folder changed, we might need to re-trigger the cycle
                autoCycleStartTimer.restart();
            }
        }
        function ciGlob(text) {
            var out = ""
            for (var i = 0; i < text.length; i++) {
                var ch = text[i]
                var lo = ch.toLowerCase()
                var up = ch.toUpperCase()
                if (lo !== up)
                    out += "[" + lo + up + "]"
                else
                    out += ch
            }
            return out
        }
        nameFilters: {
            if (root.searchQuery === "") return root.imagePatterns;
            var ci = ciGlob(root.searchQuery)
            return root.imagePatterns.map(p => `*${ci}*${p.substring(1)}`);
        }
        showDirs: false
        showDotAndDotDot: false
        sortField: root.sortField
        sortReversed: root.sortReversed
        sortCaseSensitive: false
        onCountChanged: {
            if (count > 0 && root._autoCycleEnabled && root.autoCyclePending) {
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
                root.nextWallpaper();
            } else {
                root.autoCyclePending = true;
            }
        }
    }

    Component.onCompleted: {
        if (Config.ready) {
            root.syncSettings();
        }
    }

    Connections {
        // Only trigger onMatugenChanged when explicitly changed via UI toggle, not from preset script external changes
        target: (Config.ready && Config.options.appearance) ? Config.options.appearance.background : null
        ignoreUnknownSignals: true
        function onMatugenChanged() {
            if (!Config.ready) return;
            const bg = Config.options.appearance.background;
            if (bg.matugen) {
                root.initializeMatugen();
            }
        }
    }

    // --- Wallpaper Auto-Cycle ---
    Timer {
        id: autoCycleTimer
        interval: Math.max(1, root._autoCycleInterval) * 60 * 1000
        running: root._autoCycleEnabled && !GameMode.active
        repeat: true
        onTriggered: {
            root.nextWallpaper();
        }
    }

    function nextWallpaper() {
        if (!Config.ready) return;
        if (!root._autoCycleEnabled) return;

        const count = model.count;
        if (count <= 0) {
            root.autoCyclePending = true;
            return;
        }

        let index = Math.floor(Math.random() * count);
        let newPath = model.get(index, "fileUrl");

        if (!newPath) {
            root.autoCyclePending = true;
            return;
        }


        if (newPath.toString() === Config.options.appearance.background.wallpaperPath.toString() && count > 1) {
            index = (index + 1) % count;
            newPath = model.get(index, "fileUrl");
        }

        root.select(newPath);
    }
}
