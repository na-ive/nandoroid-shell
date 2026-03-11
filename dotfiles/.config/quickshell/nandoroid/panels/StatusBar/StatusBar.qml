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

            readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
            readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth : 1200

            // ── Solid background rectangle ─────────────────────────────
            Rectangle {
                id: barBg
                anchors.top: parent.top
                anchors.topMargin: barWindow.isCentered && barWindow.showBackground ? -barWindow.cornerRadius : 0
                anchors.horizontalCenter: parent.horizontalCenter
                
                width: barWindow.isCentered ? Math.min(barWindow.centeredWidth, parent.width - 40) : parent.width
                height: Appearance.sizes.statusBarHeight + (barWindow.isCentered && barWindow.showBackground ? barWindow.cornerRadius : 0)
                color: barWindow.showBackground ? Appearance.colors.colStatusBarSolid : "transparent"
                
                radius: barWindow.isCentered ? barWindow.cornerRadius : 0

                Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                Behavior on anchors.topMargin { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
            }

            // ── Gradient overlay (when not in background mode) ─────────
            Rectangle {
                anchors.fill: barBg
                color: "transparent"
                radius: barBg.radius
                visible: !barWindow.showBackground && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Appearance.colors.colStatusBarGradientStart }
                    GradientStop { position: 1.0; color: Appearance.colors.colStatusBarGradientEnd }
                }
            }

            // ── Left Round Corner Decorator ─────────────────────
            RoundCorner {
                anchors {
                    left: barWindow.isCentered ? barBg.right : parent.left
                    top: barWindow.isCentered ? parent.top : barBg.bottom
                }
                implicitSize: barWindow.cornerRadius
                color: barWindow.showBackground ? Appearance.colors.colStatusBarSolid : "transparent"
                // Standard mode: Bottom-left corner (inverted)
                // Centered mode: Top-left corner (inverted, adjacent to pill right side)
                corner: barWindow.isCentered ? RoundCorner.CornerEnum.TopLeft : RoundCorner.CornerEnum.TopLeft
                visible: barWindow.showBackground

                Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
            }

            // ── Right Round Corner Decorator ────────────────────
            RoundCorner {
                anchors {
                    right: barWindow.isCentered ? barBg.left : parent.right
                    top: barWindow.isCentered ? parent.top : barBg.bottom
                }
                implicitSize: barWindow.cornerRadius
                color: barWindow.showBackground ? Appearance.colors.colStatusBarSolid : "transparent"
                // Standard mode: Bottom-right corner (inverted)
                // Centered mode: Top-right corner (inverted, adjacent to pill left side)
                corner: barWindow.isCentered ? RoundCorner.CornerEnum.TopRight : RoundCorner.CornerEnum.TopRight
                visible: barWindow.showBackground

                Behavior on color { ColorAnimation { duration: Appearance.animation.elementMoveFast.duration } }
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
