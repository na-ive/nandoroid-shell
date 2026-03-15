import "../core"
import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

/**
 * SVG icon component with optional color tinting.
 * Uses Image for original colors and ColorOverlay for tinting.
 */
Item {
    id: root

    property bool colorize: false
    property color color: Appearance.m3colors.m3primary
    property string source: ""
    property string iconFolder: "assets/icons"
    
    width: 30
    height: 30
    implicitWidth: width
    implicitHeight: height

    readonly property string resolvedSource: {
        if (!root.source) return "";
        let s = root.source;
        if (!s.includes(".") && !s.startsWith("image://")) {
            s += ".svg";
        }
        if (s.startsWith("/") || s.includes("://")) return s;

        // Fallback-friendly relative resolution
        // widgets/ -> ../ -> assets/icons/
        return Qt.resolvedUrl("../" + root.iconFolder + "/" + s);
    }

    onResolvedSourceChanged: {
        if (resolvedSource !== "") {

        }
    }

    // 1. Layer for original colors (e.g. Google Weather)
    Image {
        id: fullColorImage
        anchors.fill: parent
        source: root.resolvedSource !== "" ? root.resolvedSource : ""
        visible: !root.colorize && root.resolvedSource !== ""
        cache: true
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        
        onStatusChanged: {
            if (status === Image.Error && root.resolvedSource !== "") {
                console.error("[CustomIcon] Error loading image:", source);
            }
        }
    }

    // 2. Layer for tinted icons (e.g. Distro icon, Material Symbols)
    Item {
        anchors.fill: parent
        visible: root.colorize && root.resolvedSource !== ""
        
        // Use IconImage as a mask source for ColorOverlay
        IconImage {
            id: maskSource
            anchors.fill: parent
            source: root.resolvedSource !== "" ? root.resolvedSource : ""
            visible: false
            asynchronous: true
        }

        ColorOverlay {
            anchors.fill: parent
            source: maskSource
            color: root.color
            visible: root.colorize && maskSource.status === Image.Ready
        }
    }
}
