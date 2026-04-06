pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

Singleton {
    id: root

    property bool loading: false
    property string errorMessage: ""
    
    readonly property ListModel results: ListModel { id: resultsModel }

    // Steam Workshop path for Wallpaper Engine
    readonly property string workshopPath: Directories.home.replace("file://", "") + "/.local/share/Steam/steamapps/workshop/content/431960"

    function fetch() {
        if (loading) return;
        loading = true;
        errorMessage = "";
        results.clear();
        
        scanProcess.running = true;
    }

    Process {
        id: scanProcess
        command: ["python3", "-c", `
import os
import json

base_path = os.path.expanduser("${root.workshopPath}")
wallpapers = []

if not os.path.exists(base_path):
    print("[]")
    exit()
    
for folder in sorted(os.listdir(base_path)):
    folder_path = os.path.join(base_path, folder)
    if not os.path.isdir(folder_path):
        continue
    
    project_json = os.path.join(folder_path, "project.json")
    if os.path.exists(project_json):
        try:
            with open(project_json, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                # Handle potential BOM
                if content.startswith("\ufeff"):
                    content = content[1:]
                data = json.loads(content)
                
                wallpapers.append({
                    "id": folder,
                    "title": data.get("title", folder),
                    "preview": "file://" + os.path.join(folder_path, data.get("preview", "")),
                    "folder": folder_path,
                    "metadata": data
                })
        except:
            pass
print(json.dumps(wallpapers))
        `]
        
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    const data = JSON.parse(this.text);
                    if (data.length === 0) {
                        root.errorMessage = "No wallpapers found";
                    } else {
                        for (let item of data) {
                            root.results.append(item);
                        }
                    }
                } catch (e) {
                    root.errorMessage = "Error parsing wallpaper data";
                    console.error("[WallpaperEngine] JSON Parse Error:", e);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() !== "") {
                    console.error("[WallpaperEngine] Scan Error:", this.text);
                }
            }
        }
    }

    function apply(id, folder) {
        console.log("[WallpaperEngine] Applying wallpaper:", id, "from", folder);
    }
}
