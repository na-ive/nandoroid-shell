pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions" as Functions

/**
 * Service for interacting with Wallhaven API.
 * Uses secure process execution with positional parameters.
 */
Singleton {
    id: root

    property string wallpaperDir: Functions.FileUtils.trimFileProtocol(Directories.pictures) + "/Wallpapers"
    readonly property string nandoroidIcon: Directories.home.replace("file://", "") + "/.config/quickshell/nandoroid/assets/icons/NAnDoroid.svg"
    readonly property alias results: wallhavenModel
    property bool loading: false
    property string lastQuery: ""
    property int totalResults: 0
    property int currentPage: 1
    property string errorMessage: ""

    ListModel {
        id: wallhavenModel
    }

    signal searchFinished()

    function search(query, isMoreLikeThis = false, page = 1) {
        root.loading = true;
        root.lastQuery = query;
        root.currentPage = page;
        root.errorMessage = "";

        if (page === 1) {
            wallhavenModel.clear();
        }

        let sorting = (query === "" && !isMoreLikeThis) ? "random" : "relevance";
        let url = "https://wallhaven.cc/api/v1/search?purity=100&sorting=" + sorting + "&page=" + page;
        
        if (isMoreLikeThis) {
            url += "&q=like:" + query;
        } else if (query !== "") {
            const safeQuery = query + " -people -portrait";
            url += "&q=" + encodeURIComponent(safeQuery);
        } else {
            url += "&categories=110"; 
        }

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false;
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (response.data && Array.isArray(response.data)) {
                            const newItems = response.data.map(item => ({
                                "id": item.id || "",
                                "preview": (item.thumbs ? (item.thumbs.large || item.thumbs.original || item.thumbs.small) : ""),
                                "full": item.path || "",
                                "resolution": (item.dimension_x && item.dimension_y) ? (item.dimension_x + "x" + item.dimension_y) : "Unknown",
                                "file_type": item.file_type || "image/jpeg"
                            }));
                            
                            for (let i = 0; i < newItems.length; i++) {
                                wallhavenModel.append(newItems[i]);
                            }
                            
                            root.totalResults = response.meta ? response.meta.total : wallhavenModel.count;
                        }
                    } catch (e) {
                        console.error("[Wallhaven] Parse error:", e);
                        root.errorMessage = "Failed to parse response";
                    }
                } else if (xhr.status === 429) {
                    root.errorMessage = "Too many requests. Please wait...";
                } else {
                    root.errorMessage = "Server error (" + xhr.status + ")";
                }
                root.searchFinished();
            }
        };
        xhr.onerror = function() {
            root.loading = false;
            root.errorMessage = "Network error. Check connection.";
            root.searchFinished();
        };
        xhr.send();
    }

    function download(url, id, fileType, apply = false) {
        const ext = fileType === "image/png" ? "png" : "jpg";
        const fileName = "wallhaven-" + id + "." + ext;
        const fullPath = root.wallpaperDir + "/" + fileName;

        Quickshell.execDetached(["mkdir", "-p", root.wallpaperDir]);

        // Check if file exists first to save bandwidth and time
        const checkProc = createProcess.createObject(null, {
            command: ["sh", "-c", 'if [ -f "$1" ]; then exit 0; else exit 1; fi', "sh", fullPath]
        });
        
        checkProc.exited.connect((exitCode) => {
            if (exitCode === 0) {
                // File exists
                if (apply) {
                    Wallpapers.select("file://" + fullPath);
                    root.sendNotification("Wallhaven", "Already exists. Applied!");
                } else {
                    root.sendNotification("Wallhaven", "Already downloaded: " + fileName);
                }
                checkProc.destroy();
            } else {
                // File does not exist, proceed to download
                checkProc.destroy();
                if (apply) {
                    const p = createProcess.createObject(null, {
                        command: ["sh", "-c", 'curl -L "$1" -o "$2"', "sh", url, fullPath]
                    });
                    p.exited.connect((exitCode) => {
                        if (exitCode === 0) {
                            Wallpapers.select("file://" + fullPath);
                            root.sendNotification("Wallhaven", "Wallpaper applied successfully!");
                        } else {
                            root.sendNotification("Wallhaven", "Download failed.");
                        }
                        p.destroy();
                    });
                    p.running = true;
                } else {
                    Quickshell.execDetached([
                        "sh", "-c", 
                        'curl -L "$1" -o "$2" && notify-send -a "NAnDoroid" -i "$3" -- "Wallhaven" "Downloaded: $4"',
                        "sh", url, fullPath, root.nandoroidIcon, fileName
                    ]);
                }
            }
        });
        checkProc.running = true;
    }

    function sendNotification(title, body) {
        Quickshell.execDetached([
            "notify-send", 
            "-a", "NAnDoroid", 
            "-i", root.nandoroidIcon, 
            "--", title, body
        ]);
    }

    Component {
        id: createProcess
        Process {}
    }
}
