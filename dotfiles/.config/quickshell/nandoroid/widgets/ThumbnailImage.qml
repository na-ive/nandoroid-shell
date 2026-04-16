import QtQuick
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../core"
import "../core/functions"

/**
 * Robust Thumbnail image component.
 * Uses CachingImage for persistent disk cache (~/.cache/nandoroid/thumbnails).
 */
Item {
    id: root

    required property string sourcePath
    property int fillMode: Image.PreserveAspectCrop
    property real radius: 10 * Appearance.effectiveScale
    
    CachingImage {
        id: internalImage
        anchors.fill: parent
        imagePath: root.sourcePath
        fillMode: root.fillMode
        maxCacheSize: 512 * Appearance.effectiveScale
        
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }
        
        layer.enabled: root.radius > 0
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: internalImage.width
                height: internalImage.height
                radius: root.radius
            }
        }
    }
}
