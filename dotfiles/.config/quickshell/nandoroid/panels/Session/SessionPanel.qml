
import "../../core"
import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Connections {
        target: GlobalStates
        function onSessionOpenChanged() {
            if (GlobalStates.sessionOpen) panelLoader.active = true;
        }
    }

    Loader {
        id: panelLoader
        active: GlobalStates.sessionOpen
        sourceComponent: PanelWindow {
            id: sessionWindow

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nandoroid:session"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"

            // ── Blurred wallpaper ──────────────────────────────────────────
            Image {
                id: wallpaperSource
                anchors.fill: parent
                source: (Config.ready && Config.options.appearance?.background?.wallpaperPath)
                    ? Config.options.appearance.background.wallpaperPath
                    : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                smooth: true
                cache: false
            }

            GaussianBlur {
                id: blurredWallpaper
                anchors.fill: wallpaperSource
                source: wallpaperSource
                radius: 72
                samples: 145  // radius * 2 + 1
                deviation: 36
            }

            // Dark scrim on top of blur — no animation, instant appearance
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.65)
            }

            // Click outside to close
            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.sessionOpen = false
            }

            // Content centered
            SessionContent {
                anchors.centerIn: parent

                Connections {
                    target: GlobalStates
                    function onSessionOpenChanged() {
                        if (!GlobalStates.sessionOpen) panelLoader.active = false
                    }
                }
            }
        }
    }
}
