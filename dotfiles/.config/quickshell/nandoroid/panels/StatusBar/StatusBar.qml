import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Full-width top status bar panel.
 * Android 16 tablet style: left cluster (notifications), center (clock), right cluster (quick settings).
 *
 * backgroundStyle:
 *   0 = None      – fully transparent (wallpaper shows through)
 *   1 = Always    – solid colLayer0 background with rounded bottom corners
 *   2 = Adaptive  – solid background only when a non-floating window occupies the workspace
 */
Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: barWindow
            required property var modelData
            property int monitorIndex: modelData.index ?? 0

            screen: modelData
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: Appearance.sizes.statusBarHeight
            WlrLayershell.namespace: "nandoroid:statusbar"
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                left: true
                right: true
                top: true
            }

            color: "transparent"
            implicitHeight: Appearance.sizes.statusBarHeight
                + (showBackground ? cornerRadius : 0)

            // ── Background visibility ──────────────────────────────────
            readonly property int bgStyle: Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
            readonly property int cornerRadius: Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20

            property bool hasActiveWindows: false
            readonly property bool showBackground: {
                if (bgStyle === 1) return true;
                if (bgStyle === 2) return hasActiveWindows;
                return false;
            }

            // Track tiled windows for adaptive style
            Connections {
                enabled: barWindow.bgStyle === 2
                target: HyprlandData
                function onWindowListChanged() {
                    const monitor = HyprlandData.monitors.find(m => m.id === barWindow.monitorIndex);
                    const wsId = monitor?.activeWorkspace?.id;
                    barWindow.hasActiveWindows = wsId
                        ? HyprlandData.windowList.some(w => w.workspace.id === wsId && !w.floating)
                        : false;
                }
            }

            // ── Solid background rectangle ─────────────────────────────
            Rectangle {
                id: barBg
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: Appearance.sizes.statusBarHeight
                color: barWindow.showBackground ? Appearance.colors.colStatusBarSolid : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
            }

            // ── Gradient overlay (when not in background mode) ─────────
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: Appearance.sizes.statusBarHeight
                color: "transparent"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Appearance.colors.colStatusBarGradientStart }
                    GradientStop { position: 1.0; color: Appearance.colors.colStatusBarGradientEnd }
                }
            }

            // ── Bottom-left round corner decorator ─────────────────────
            RoundCorner {
                anchors {
                    left: parent.left
                    top: barBg.bottom
                }
                implicitSize: barWindow.cornerRadius
                color: barWindow.showBackground ? Appearance.colors.colStatusBarSolid : "transparent"
                corner: RoundCorner.CornerEnum.TopLeft
                visible: barWindow.showBackground

                Behavior on color {
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
            }

            // ── Bottom-right round corner decorator ────────────────────
            RoundCorner {
                anchors {
                    right: parent.right
                    top: barBg.bottom
                }
                implicitSize: barWindow.cornerRadius
                color: barWindow.showBackground ? Appearance.colors.colStatusBarSolid : "transparent"
                corner: RoundCorner.CornerEnum.TopRight
                visible: barWindow.showBackground

                Behavior on color {
                    ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
                }
            }

            // ── Content ────────────────────────────────────────────────
            StatusBarContent {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: Appearance.sizes.statusBarHeight
                monitorIndex: barWindow.monitorIndex
            }
        }
    }
}
