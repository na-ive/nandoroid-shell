import QtQuick
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../core"
import "../core/functions"

/**
 * Robust Thumbnail image component.
 * Adopts the "dms" approach: Native QML scaling with sourceSize 
 * and robust URL encoding for reliability.
 */
Item {
    id: root

    property bool generateThumbnail: true
    required property string sourcePath
    property int fillMode: Image.PreserveAspectCrop
    property real radius: 10
    
    // Robust path encoding for filenames with spaces/quotes/etc.
    readonly property string encodedSourcePath: {
        if (!sourcePath) return "";
        let path = sourcePath;
        if (path.startsWith("file://")) {
            path = path.substring(7);
        }
        // Properly encode each segment
        return "file://" + path.split('/').map(s => encodeURIComponent(s)).join('/');
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.encodedSourcePath
        
        // This is the "old/reliable" way: Let QML generate the thumbnail in memory
        asynchronous: true
        smooth: true
        mipmap: true
        fillMode: root.fillMode
        
        // Efficiency: Don't load full resolution. 
        // 512px is a good balance for thumbnails in an 1100px window.
        sourceSize.width: 512
        sourceSize.height: 512

        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        
        layer.enabled: root.radius > 0
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: img.width
                height: img.height
                radius: root.radius
            }
        }

        // Error handling fallback
        onStatusChanged: {
            if (status === Image.Error) {

            }
        }
    }
}
