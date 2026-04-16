import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions"

/**
 * High-performance image component with persistent disk caching.
 * Adapted from 'dms' approach with improvements:
 * - Uses .webp for smaller cache size.
 * - djb2 hashing for fast identification.
 * - Transparent fallback to original file.
 */
Item {
    id: root

    property string imagePath: ""
    property int maxCacheSize: 512
    property int fillMode: Image.PreserveAspectCrop
    property int status: staticImg.status

    readonly property string cacheDir: Directories.home.replace("file://", "") + "/.cache/nandoroid/thumbnails"
    
    // Fast hash function (djb2)
    function generateHash(str) {
        if (!str) return "";
        let hash = 5381;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) + hash) + str.charCodeAt(i);
            hash = hash & 0x7FFFFFFF;
        }
        return hash.toString(16).padStart(8, '0');
    }

    readonly property string normalizedPath: {
        if (!imagePath) return "";
        let p = imagePath;
        if (p.startsWith("file://")) p = p.substring(7);
        return p;
    }

    readonly property string imageHash: normalizedPath ? generateHash(normalizedPath) : ""
    // We use .webp for better compression
    readonly property string cacheFilePath: imageHash ? cacheDir + "/" + imageHash + "@" + maxCacheSize + ".webp" : ""
    
    readonly property string encodedSourcePath: {
        if (!normalizedPath) return "";
        return "file://" + normalizedPath.split('/').map(s => encodeURIComponent(s)).join('/');
    }

    Image {
        id: staticImg
        anchors.fill: parent
        asynchronous: true
        cache: true
        fillMode: root.fillMode
        sourceSize.width: root.maxCacheSize
        sourceSize.height: root.maxCacheSize
        smooth: true

        onStatusChanged: {
            // If cache fails to load, fallback to original
            if (source.toString().includes(root.cacheDir) && status === Image.Error) {
                source = root.encodedSourcePath;
                return;
            }

            // If original loaded successfully and we don't have a cache yet, create it
            if (source == root.encodedSourcePath && status === Image.Ready && root.cacheFilePath !== "") {
                // Ensure directory exists
                Quickshell.execDetached(["mkdir", "-p", root.cacheDir]);
                
                // Only grab if we are visible and valid
                if (width > 0 && height > 0) {
                    grabToImage(res => {
                        res.saveToFile(root.cacheFilePath);
                    });
                }
            }
        }
    }

    onImagePathChanged: {
        if (!imagePath) {
            staticImg.source = "";
            return;
        }
        
        // Initial attempt: Load from cache
        staticImg.source = "file://" + root.cacheFilePath;
    }
}
