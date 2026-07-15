pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Background panel.
 * Draws the wallpaper on the bottommost layer (WlrLayer.Background).
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: bgRoot
        required property var modelData

        // Basic positioning
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Window level transparency is ALWAYS ON for stability.
        color: "transparent"

        // Base background color (only visible when live wallpaper is OFF)
        Rectangle {
            id: baseColor
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            z: -1
            visible: !WallpaperEngineService.active
        }

        property string currentPath: (Config.ready && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.wallpaperPath) ? Config.options.appearance.background.wallpaperPath : ""
        property string previousPath: ""
        
        property var shaderList: ["circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "pixelate", "stripes"]
        property string currentShader: "pixelate"
        property real transitionProgress: 1.0

        onCurrentPathChanged: {
            if (currentPath === "" || currentPath === undefined) return;
            
            // Avoid transition on first load
            if (wallpaper.source.toString() === "") {
                wallpaper.source = currentPath;
                return;
            }
            
            previousPath = wallpaper.source.toString();
            wallpaper.source = currentPath;
            currentShader = shaderList[Math.floor(Math.random() * shaderList.length)];
            
            transitionProgress = 0.0;
            transitionAnim.restart();
        }

        NumberAnimation {
            id: transitionAnim
            target: bgRoot
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: 1200
            easing.type: Easing.InOutCubic
            onFinished: {
                previousWallpaper.source = "";
                bgRoot.previousPath = "";
                bgRoot.transitionProgress = 1.0;
            }
        }

        // --- Container for Static Wallpapers ---
        Item {
            id: staticWallpaperContainer
            anchors.fill: parent
            z: 1
            opacity: WallpaperEngineService.active ? 0 : 1
            visible: opacity > 0
            
            Image {
                id: previousWallpaper
                anchors.fill: parent
                source: bgRoot.previousPath
                fillMode: Image.PreserveAspectCrop
                visible: false
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: true
            }

            Image {
                id: wallpaper
                anchors.fill: parent
                source: bgRoot.currentPath
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                layer.enabled: true
                visible: bgRoot.transitionProgress >= 1.0
            }
            
            ShaderEffect {
                id: transitionEffect
                anchors.fill: parent
                visible: bgRoot.transitionProgress < 1.0
                property var fromImage: previousWallpaper
                property var toImage: wallpaper
                property real progress: bgRoot.transitionProgress
                property real aspectX: width / height
                property real aspectY: 1.0
                property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
                property vector2d origin: Qt.vector2d(0.5, 0.5)
                fragmentShader: Qt.resolvedUrl(`shaders/${bgRoot.currentShader}.frag.qsb`)
            }
        }

        Rectangle {
            id: overlay
            anchors.fill: parent
            color: "black"
            opacity: GlobalStates.screenLocked ? 0.3 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
    }
}
