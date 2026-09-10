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
 * Moves to Overlay during session lock to serve as backdrop for transparent LockSurface.
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
        WlrLayershell.layer: GlobalStates.screenLocked ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.namespace: "quickshell:background"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Window level transparency is ALWAYS ON for stability.
        color: "transparent"

        // Base guard color: M3 surface (dark, not pure #000) behind the lockscreen
        // wallpaper while it loads; M3 surface on the desktop otherwise.
        Rectangle {
            id: baseColor
            anchors.fill: parent
            color: Appearance.colors.colLayer0
            z: -1
            visible: !bgRoot.liveActive || (GlobalStates.screenLocked && lockPath !== "")
        }

        readonly property string desktopPath: (Config.ready && Config.options.appearance && Config.options.appearance.background && Config.options.appearance.background.wallpaperPath) ? Config.options.appearance.background.wallpaperPath : ""
        readonly property string lockPath: Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath ? Config.options.lock.wallpaperPath : ""
        readonly property bool liveActive: WallpaperEngineService.active || MpvpaperService.active
        // Static representation of the active live wallpaper (extracted frame / screenshot)
        readonly property string liveFallbackPath: {
            if (WallpaperEngineService.active) {
                const ws = WallpaperEngineService.screenshotPath;
                if (ws && ws !== "") return "file://" + ws + "?v=" + WallpaperEngineService.screenshotVersion;
            }
            if (MpvpaperService.active) {
                const fp = MpvpaperService.framePath;
                if (fp && fp !== "") return "file://" + fp + "?v=" + MpvpaperService.frameVersion;
            }
            return "";
        }
        // While locked, fall back to desktopPath if no separate lock wallpaper is defined.
        property string currentPath: {
            if (GlobalStates.screenLocked && lockPath !== "") {
                return lockPath;
            }
            return desktopPath;
        }
        
        property var shaderList: ["materialshape", "circlePit", "circleSelect", "magic", "Doom", "Peel", "transition", "pixelate", "stripes", "crt", "dissolve", "glitch", "ripple", "shatter"]
        property string currentShader: "pixelate"
        property real transitionProgress: 1.0
        property bool useNextForEffect: false
        readonly property int maxTextureSize: 8192
        readonly property int textureWidth: Math.min(modelData.width, maxTextureSize)
        readonly property int textureHeight: Math.min(modelData.height, maxTextureSize)
        property string wallpaperTransition: Config.ready && Config.options.appearance.background ? Config.options.appearance.background.wallpaperTransition : "random"

        // Picks the shader for this transition: fixed choice from settings, or a random one
        function pickShader() {
            if (wallpaperTransition !== "random" && shaderList.includes(wallpaperTransition)) {
                return wallpaperTransition;
            }
            return shaderList[Math.floor(Math.random() * shaderList.length)];
        }

        function startTransition() {
            previousWallpaper.layer.enabled = true;
            wallpaper.layer.enabled = true;
            nextWallpaper.layer.enabled = true;
            bgRoot.useNextForEffect = true;
            transitionProgress = 0.0;
            transitionDelayTimer.start();
        }

        Timer {
            id: transitionDelayTimer
            interval: 16
            repeat: false
            onTriggered: transitionAnim.start()
        }

        onCurrentPathChanged: {
            if (currentPath === "" || currentPath === undefined) return;
            
            if (wallpaper.source.toString() === "") {
                wallpaper.source = currentPath;
                previousWallpaper.source = "";
                nextWallpaper.source = "";
                return;
            }

            var effectivePrev = wallpaper.source.toString().replace("file://", "");
            if (effectivePrev === currentPath.replace("file://", "")) return;

            var fromSource = wallpaper.source;
            if (GlobalStates.screenLocked && liveActive && liveFallbackPath !== "") {
                fromSource = liveFallbackPath;
                if (fromSource.replace("file://", "") === currentPath.replace("file://", "")) {
                    previousWallpaper.source = "";
                    wallpaper.source = currentPath;
                    nextWallpaper.source = "";
                    bgRoot.transitionProgress = 1.0;
                    return;
                }
            }

            if (bgRoot.wallpaperTransition === "") {
                previousWallpaper.source = "";
                nextWallpaper.source = "";
                wallpaper.source = currentPath;
                bgRoot.transitionProgress = 1.0;
                if (Wallpapers._pendingMatugenPath !== "") {
                    const p = Wallpapers._pendingMatugenPath; Wallpapers._pendingMatugenPath = ""; Wallpapers.runMatugen(p);
                }
                return;
            }

            previousWallpaper.source = fromSource;
            nextWallpaper.source = currentPath;

            currentShader = pickShader();

            if (currentShader === "materialshape") {
                materialShapeTransition.pickRandomShape();
            }

            if (nextWallpaper.status === Image.Ready) {
                startTransition();
            } else if (nextWallpaper.status === Image.Error) {
                wallpaper.source = currentPath;
                previousWallpaper.source = "";
                nextWallpaper.source = "";
                bgRoot.transitionProgress = 1.0;
                bgRoot.useNextForEffect = false;
                if (Wallpapers._pendingMatugenPath !== "") {
                    const p = Wallpapers._pendingMatugenPath; Wallpapers._pendingMatugenPath = ""; Wallpapers.runMatugen(p);
                }
            }
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
                wallpaper.source = nextWallpaper.source;
                previousWallpaper.source = "";
                nextWallpaper.source = "";
                bgRoot.useNextForEffect = false;
                bgRoot.transitionProgress = 1.0;
                if (Wallpapers._pendingMatugenPath !== "") {
                    const p = Wallpapers._pendingMatugenPath;
                    Wallpapers._pendingMatugenPath = "";
                    Wallpapers.runMatugen(p);
                }
            }
        }

        // --- Container for Static Wallpapers ---
        Item {
            id: staticWallpaperContainer
            anchors.fill: parent
            z: 1
            opacity: bgRoot.liveActive && !(GlobalStates.screenLocked && lockPath !== "") ? 0 : 1
            visible: opacity > 0
            
            Image {
                id: previousWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                visible: bgRoot.transitionProgress < 1.0 && bgRoot.currentShader === "materialshape"
                cache: true
                smooth: true
                asynchronous: false
                sourceSize: Qt.size(bgRoot.textureWidth, bgRoot.textureHeight)
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
                sourceSize: Qt.size(bgRoot.textureWidth, bgRoot.textureHeight)
                layer.enabled: true
                visible: bgRoot.transitionProgress >= 1.0
            }

            Image {
                id: nextWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                cache: true
                smooth: true
                asynchronous: true
                sourceSize: Qt.size(bgRoot.textureWidth, bgRoot.textureHeight)
                layer.enabled: false
                visible: false
                onStatusChanged: {
                    if (status === Image.Ready && source.toString() !== "" && bgRoot.transitionProgress === 1.0 && previousWallpaper.source.toString() !== "") {
                        bgRoot.startTransition();
                    } else if (status === Image.Error && source.toString() !== "") {
                        wallpaper.source = source;
                        previousWallpaper.source = "";
                        nextWallpaper.source = "";
                        bgRoot.transitionProgress = 1.0;
                        bgRoot.useNextForEffect = false;
                        if (Wallpapers._pendingMatugenPath !== "") {
                            const p = Wallpapers._pendingMatugenPath; Wallpapers._pendingMatugenPath = ""; Wallpapers.runMatugen(p);
                        }
                    }
                }
            }
            
            ShaderEffect {
                id: transitionEffect
                anchors.fill: parent
                visible: bgRoot.transitionProgress < 1.0 && bgRoot.currentShader !== "materialshape"
                property var fromImage: previousWallpaper
                property var toImage: bgRoot.useNextForEffect ? nextWallpaper : wallpaper
                property var source1: previousWallpaper
                property var source2: bgRoot.useNextForEffect ? nextWallpaper : wallpaper
                property real time: 0.0
                property real progress: bgRoot.transitionProgress
                property real aspectX: width / height
                property real aspectY: 1.0
                property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
                property vector2d origin: Qt.vector2d(0.5, 0.5)
                fragmentShader: Qt.resolvedUrl(`shaders/${bgRoot.currentShader}.frag.qsb`)

                Timer {
                    interval: 16
                    repeat: true
                    running: transitionEffect.visible
                    onTriggered: transitionEffect.time += interval / 1000.0
                }
                onVisibleChanged: if (!visible) transitionEffect.time = 0.0
            }
            MaterialShapeTransition {
                id: materialShapeTransition
                anchors.fill: parent
                sourceItem: bgRoot.useNextForEffect ? nextWallpaper : wallpaper
                active: bgRoot.currentShader === "materialshape"
                progress: bgRoot.transitionProgress
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
