pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property bool loading: false
    property string errorMessage: ""
    property bool isRunning: activeProcess.running
    property bool isPaused: false
    property bool isInstalled: false
    property bool isApplying: false 
    
    readonly property bool active: (Config.ready && Config.options.appearance.background.liveWallpaperPath !== "") || isRunning
    
    property var activeProperties: ({}) 
    property var savedConfigs: ({})
    property string selectedWallpaperId: ""
    
    property int targetFps: 30
    property int volume: 15
    property bool silent: false
    property bool autoPause: true

    readonly property string cacheDir: Directories.home.replace("file://", "") + "/.cache/nandoroid"
    readonly property string cacheFile: cacheDir + "/we_configs.json"
    readonly property string workshopPath: Directories.home.replace("file://", "") + "/.local/share/Steam/steamapps/workshop/content/431960"
    readonly property string screenshotPath: "/tmp/nandoroid_live_wp.png"
    property int screenshotVersion: 0

    readonly property ListModel currentProperties: ListModel { id: propsModel }
    readonly property ListModel results: ListModel { id: resultsModel }

    // --- Persistence Logic ---

    Process {
        id: cacheLoader
        command: ["sh", "-c", `mkdir -p "${cacheDir}" && touch "${cacheFile}" && cat "${cacheFile}"`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    try { 
                        root.savedConfigs = JSON.parse(this.text);
                        console.log("[WallpaperEngine] Cache loaded");
                    } catch(e) { root.savedConfigs = {}; }
                }
                root.checkInitialApply();
            }
        }
    }

    function loadCache() { cacheLoader.running = true; }

    function saveCache() {
        if (!selectedWallpaperId) return;
        let configs = Object.assign({}, root.savedConfigs);
        configs[selectedWallpaperId] = root.activeProperties;
        root.savedConfigs = configs;
        let data = JSON.stringify(root.savedConfigs);
        Quickshell.execDetached(["python3", "-c", "import sys, os; path=sys.argv[1]; data=sys.argv[2]; os.makedirs(os.path.dirname(path), exist_ok=True); f=open(path, 'w'); f.write(data); f.close()", cacheFile, data]);
    }

    function checkInitialApply() {
        if (Config.ready) {
            const lastPath = Config.options.appearance.background.liveWallpaperPath;
            if (lastPath && lastPath !== "") {
                let parts = lastPath.split('/');
                let id = parts[parts.length - 1];
                root.fetchProperties(lastPath, id);
                root.applyInternal(lastPath);
            }
        }
    }

    // --- Property Management ---

    function fetchProperties(folderPath, wallpaperId) {
        if (!folderPath) return;
        root.selectedWallpaperId = wallpaperId || "";
        propsModel.clear();
        let saved = root.savedConfigs[root.selectedWallpaperId] || {};
        root.activeProperties = Object.assign({}, saved);
        let cleanPath = folderPath.toString();
        if (cleanPath.startsWith("file://")) cleanPath = cleanPath.substring(7);
        propsProcess.command = ["python3", "-c", propsProcess.script, cleanPath];
        propsProcess.running = true;
    }

    function resetProperties(folderPath) {
        if (!selectedWallpaperId) return;
        let configs = Object.assign({}, root.savedConfigs);
        delete configs[selectedWallpaperId];
        root.savedConfigs = configs;
        let data = JSON.stringify(root.savedConfigs);
        Quickshell.execDetached(["python3", "-c", "import sys, os; path=sys.argv[1]; data=sys.argv[2]; os.makedirs(os.path.dirname(path), exist_ok=True); f=open(path, 'w'); f.write(data); f.close()", cacheFile, data]);
        fetchProperties(folderPath, selectedWallpaperId);
    }

    Process {
        id: propsProcess
        readonly property string script: `
import os, json, sys
folder_path = sys.argv[1]
project_json = os.path.join(folder_path, "project.json")
props = []
if os.path.exists(project_json):
    try:
        with open(project_json, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
            if content.startswith("\\ufeff"): content = content[1:]
            data = json.loads(content)
            general_props = data.get("general", {}).get("properties", {})
            sorted_keys = sorted(general_props.keys(), key=lambda k: general_props[k].get("order", 999))
            for key in sorted_keys:
                if key.lower() == "schemecolor" or key.startswith("ui_browse"): continue
                val = general_props[key]
                p_type = val.get("type", "unknown")
                if p_type in ["group", "directory", "color", "text", "font", "file"]: continue
                props.append({
                    "key": key, "text": str(val.get("text", key)), "type": str(p_type),
                    "default_value": val.get("value"),
                    "min": float(val.get("min")) if val.get("min") is not None else 0.0,
                    "max": float(val.get("max")) if val.get("max") is not None else 1.0,
                    "step": float(val.get("step")) if val.get("step") is not None else 0.1,
                    "options_json": json.dumps(val.get("options", []))
                })
    except: pass
print(json.dumps(props))
        `
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    for (let prop of data) {
                        if (root.activeProperties[prop.key] === undefined) {
                            root.activeProperties[prop.key] = prop.default_value;
                        }
                        let currentVal = root.activeProperties[prop.key];
                        root.currentProperties.append({
                            "propKey": prop.key, "propText": prop.text, "propType": prop.type,
                            "valBool": (String(currentVal) === "true" || String(currentVal) === "1"),
                            "valNum": parseFloat(currentVal || 0.0),
                            "valStr": String(currentVal !== undefined ? currentVal : ""),
                            "propMin": prop.min, "propMax": prop.max, "propStep": prop.step,
                            "options_json": prop.options_json
                        });
                    }
                    root.activeProperties = Object.assign({}, root.activeProperties);
                } catch (e) { console.error("[WallpaperEngine] Props parse error:", e); }
            }
        }
    }

    function updateProperty(key, value) {
        if (root.activeProperties[key] === value) return;
        root.resume();
        let newProps = Object.assign({}, root.activeProperties);
        newProps[key] = value;
        root.activeProperties = newProps;
        for (let i = 0; i < root.currentProperties.count; i++) {
            if (root.currentProperties.get(i).propKey === key) {
                if (typeof value === "boolean") root.currentProperties.setProperty(i, "valBool", value);
                else if (typeof value === "number") root.currentProperties.setProperty(i, "valNum", value);
                else root.currentProperties.setProperty(i, "valStr", String(value));
                break;
            }
        }
        saveCache();
    }

    // --- Core Lifecycle ---

    function apply(folderPath, previewPath = "") {
        if (!folderPath) return;
        let cleanPath = folderPath.toString();
        if (cleanPath.startsWith("file://")) cleanPath = cleanPath.substring(7);
        
        root.isApplying = true;
        stopInternal();
        
        if (Config.ready) {
            Config.options.appearance.background.liveWallpaperPath = cleanPath;
            if (previewPath !== "") Config.options.appearance.background.wallpaperPath = previewPath;
        }
        applyInternal(cleanPath);
    }

    function applyInternal(path) {
        root.resume();
        applyTimer.targetFolder = path;
        applyTimer.start();
    }

    Timer {
        id: applyTimer
        property string targetFolder
        interval: 500; repeat: false
        onTriggered: {
            let monitorName = "eDP-1";
            if (HyprlandData.monitors.length > 0) {
                let primary = HyprlandData.monitors.find(m => m.focused) || HyprlandData.monitors[0];
                monitorName = primary.name;
            }
            let fpsStr = String(root.targetFps);
            let volStr = String(root.volume);
            let isSilent = root.silent;
            let sPath = root.screenshotPath;
            let props = root.activeProperties;
            
            Quickshell.execDetached(["rm", "-f", sPath]);
            Quickshell.execDetached(["hyprctl", "keyword", "windowrule", "stopanim,linux-wallpaperengine"]);
            Quickshell.execDetached(["hyprctl", "keyword", "windowrule", "noinitialfocus,linux-wallpaperengine"]);
            
            let args = ["linux-wallpaperengine", "--screen-root", monitorName, "--use-gl", "--no-pbo", "--disable-particles", "--scaling", "stretch", "--clamp", "border", "--no-fullscreen-pause"];
            args.push("--fps", fpsStr, "--volume", volStr);
            if (isSilent) args.push("--silent");
            args.push("--screenshot", sPath, "--screenshot-delay", "30");
            for (let key in props) {
                let val = props[key];
                let valStr = String(val);
                if (typeof val === "boolean") valStr = val ? "1" : "0";
                args.push("--set-property", key + "=" + valStr);
            }
            args.push(targetFolder);
            activeProcess.command = args;
            activeProcess.running = true;
            matugenWatchTimer.attempts = 0;
            matugenWatchTimer.restart();
            applyFinishTimer.restart();
        }
    }

    Timer {
        id: applyFinishTimer
        interval: 1500; repeat: false
        onTriggered: { root.isApplying = false; root.updatePauseState(); }
    }

    function fetch() {
        if (loading) return;
        loading = true; errorMessage = ""; results.clear();
        scanProcess.running = true;
    }

    Process {
        id: scanProcess
        command: ["python3", "-c", `
import os, json
base_path = os.path.expanduser("${root.workshopPath}")
wallpapers = []
if os.path.exists(base_path):
    for folder in sorted(os.listdir(base_path)):
        folder_path = os.path.join(base_path, folder)
        if os.path.isdir(folder_path):
            project_json = os.path.join(folder_path, "project.json")
            if os.path.exists(project_json):
                try:
                    with open(project_json, "r", encoding="utf-8", errors="ignore") as f:
                        content = f.read()
                        if content.startswith("\\ufeff"): content = content[1:]
                        data = json.loads(content)
                        wallpapers.append({
                            "id": folder, "title": data.get("title", folder),
                            "preview": "file://" + os.path.join(folder_path, data.get("preview", "")),
                            "folder": folder_path, "metadata": data
                        })
                except: pass
print(json.dumps(wallpapers))
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const data = JSON.parse(this.text);
                    if (data.length === 0) root.errorMessage = "No wallpapers found";
                    else { for (let item of data) root.results.append(item); }
                } catch (e) { root.errorMessage = "Error parsing wallpaper data"; }
            }
        }
    }

    Process {
        id: activeProcess
        onExited: (exitCode) => { root.isPaused = false; }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") console.warn("[WallpaperEngine] Log:", this.text.trim());
            }
        }
    }

    Process {
        id: checkFileProc
        command: ["ls", root.screenshotPath]
        onExited: (code) => {
            if (code === 0) {
                matugenWatchTimer.stop();
                root.screenshotVersion++;
                Wallpapers.generateColors(root.screenshotPath);
            }
        }
    }

    Timer {
        id: matugenWatchTimer
        interval: 1500; repeat: true; property int attempts: 0
        onTriggered: {
            attempts++;
            if (attempts > 10) { stopInternal(); return; }
            checkFileProc.running = true;
        }
    }

    function stop() {
        stopInternal();
        if (Config.ready) Config.options.appearance.background.liveWallpaperPath = "";
    }

    function stopInternal() {
        activeProcess.running = false;
        Quickshell.execDetached(["sh", "-c", "pkill -CONT -f linux-wallpaperengine; pkill -KILL -f linux-wallpaperengine"]);
        root.isPaused = false;
    }

    function pause() {
        if (root.isRunning && !root.isPaused && !root.isApplying) {
            console.log("[WallpaperEngine] Pausing (SIGSTOP)");
            Quickshell.execDetached(["pkill", "-STOP", "-f", "linux-wallpaperengine"]);
            root.isPaused = true;
        }
    }

    function resume() {
        if (root.isRunning && root.isPaused) {
            console.log("[WallpaperEngine] Resuming (SIGCONT)");
            Quickshell.execDetached(["pkill", "-CONT", "-f", "linux-wallpaperengine"]);
            root.isPaused = false;
        }
    }

    function updatePauseState() {
        if (root.isApplying || !root.autoPause || !root.isRunning || !HyprlandData.activeWorkspace) return;
        const currentWsId = HyprlandData.activeWorkspace.id;
        const shellClasses = ["Quickshell", "nandoroid-settings", "nandoroid-monitor", "wayland-dashboard", "waybar", "ags", "fuzzel"];
        const realWindows = HyprlandData.windowList.filter(win => {
            return win.workspace.id === currentWsId && !shellClasses.includes(win.class) && win.mapped && win.class !== ""; 
        });
        if (realWindows.length > 0) root.pause();
        else root.resume();
    }

    Timer { id: pauseDebounceTimer; interval: 350; repeat: false; onTriggered: updatePauseState() }

    Connections {
        target: HyprlandData; enabled: root.autoPause && root.isRunning
        function onWindowListChanged() { pauseDebounceTimer.restart(); }
        function onActiveWindowChanged() { pauseDebounceTimer.restart(); }
    }

    Connections {
        target: Config; function onReadyChanged() { if (Config.ready) root.loadCache(); }
    }

    Connections {
        target: Session; ignoreUnknownSignals: true
        function onLockedChanged() {
            if (Session.locked) {
                if (Config.ready && Config.options.lock && Config.options.lock.useSeparateWallpaper) root.pause();
            } else pauseDebounceTimer.restart();
        }
    }

    Process {
        id: checkInstallation; command: ["which", "linux-wallpaperengine"]; running: true
        onExited: (code) => { root.isInstalled = (code === 0); }
    }

    Component.onCompleted: { if (Config.ready) root.loadCache(); }
}
