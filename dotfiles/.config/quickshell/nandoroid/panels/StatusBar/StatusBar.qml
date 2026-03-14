import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
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
            
            readonly property bool autoHide: Config.ready && Config.options.statusBar ? Config.options.statusBar.autoHide : false
            property bool forceShowByHover: false
            readonly property bool barAreaHovered: barHoverHandler.hovered

            readonly property bool mustShow: !autoHide 
                || forceShowByHover
                || GlobalStates.notificationCenterOpen
                || GlobalStates.quickSettingsOpen
                || GlobalStates.dashboardOpen
                || GlobalStates.sessionOpen
                || GlobalStates.launcherOpen
                || GlobalStates.spotlightOpen
                || GlobalStates.overviewOpen
                || !!Notifications.activePopup
                || GlobalStates.mediaNotchOpen

            onBarAreaHoveredChanged: {
                if (barAreaHovered) {
                    if (mustShow) forceShowByHover = true;
                } else {
                    forceShowByHover = false;
                }
            }

            exclusiveZone: (autoHide && !mustShow) ? 0 : Appearance.sizes.statusBarHeight
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

            // ── Hover Detection Infrastructure ──────────────────
            HoverHandler {
                id: barHoverHandler
            }

            // Thin trigger zone at the top edge
            MouseArea {
                id: triggerArea
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: forceShowByHover = true
                onPressed: (mouse) => { mouse.accepted = false; }
                cursorShape: Qt.ArrowCursor
                z: 100 // Ensure trigger is accessible
            }

            // ── Background visibility ──────────────────────────────────
            readonly property int bgStyle: Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
            readonly property int cornerRadius: Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20

            // Track tiled windows for adaptive style
            readonly property int activeWorkspaceId: Hyprland.monitorFor(modelData)?.activeWorkspace?.id ?? -1
            
            readonly property bool hasTiledWindows: {
                if (bgStyle !== 2 || activeWorkspaceId === -1) return false;
                // Filter windows that are on this monitor's active workspace and NOT floating
                return HyprlandData.windowList.some(w => 
                    w.workspace.id === activeWorkspaceId && 
                    !w.floating && 
                    w.monitor === monitorIndex
                );
            }

            readonly property bool showBackground: {
                if (bgStyle === 1) return true;
                if (bgStyle === 2) return hasTiledWindows;
                return false;
            }

            readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
            readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth : 1200

            // ── Main Content Container (Animated) ──
            Item {
                id: mainContainer
                anchors.fill: parent
                anchors.topMargin: (autoHide && !mustShow) ? -Appearance.sizes.statusBarHeight - (showBackground ? cornerRadius : 5) : 0
                
                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutQuart
                    }
                }

                // ── Background Layer (Full area to prevent shadow clipping) ──
                Item {
                    id: barBackgroundLayer
                    anchors.fill: parent
                    visible: barWindow.showBackground
                    opacity: barBg.opacity

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 2
                        radius: 24
                        samples: 32
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.12)
                        transparentBorder: true
                    }

                    // ── Solid background rectangle ─────────────────────────────
                    Rectangle {
                        id: barBg
                        
                        readonly property real targetHeight: Appearance.sizes.statusBarHeight + (barWindow.isCentered ? barWindow.cornerRadius : 0)
                        readonly property real targetY: barWindow.showBackground 
                            ? (barWindow.isCentered ? -barWindow.cornerRadius : 0)
                            : -targetHeight - 10

                        y: targetY
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        width: barWindow.isCentered ? Math.min(barWindow.centeredWidth, parent.width - 40) : parent.width
                        height: targetHeight
                        color: Appearance.colors.colStatusBarSolid
                        
                        radius: barWindow.isCentered ? barWindow.cornerRadius : 0

                        Behavior on y { NumberAnimation { duration: 550; easing.type: Easing.OutQuint } }
                        Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }
                        Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }
                        Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                        // ── Standard Mode Corners (Bottom) ──
                        RoundCorner {
                            id: stdLeftCorner
                            anchors.top: parent.bottom
                            anchors.left: parent.left
                            implicitSize: barWindow.cornerRadius
                            color: parent.color
                            corner: RoundCorner.CornerEnum.TopLeft
                            opacity: !barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        RoundCorner {
                            id: stdRightCorner
                            anchors.top: parent.bottom
                            anchors.right: parent.right
                            implicitSize: barWindow.cornerRadius
                            color: parent.color
                            corner: RoundCorner.CornerEnum.TopRight
                            opacity: !barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        // ── HUD Mode Corners (Top sides of the pill) ──
                        RoundCorner {
                            id: hudLeftCorner
                            anchors.top: parent.top
                            anchors.topMargin: barWindow.cornerRadius
                            anchors.right: parent.left
                            implicitSize: barWindow.cornerRadius
                            color: parent.color
                            corner: RoundCorner.CornerEnum.TopRight
                            opacity: barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        RoundCorner {
                            id: hudRightCorner
                            anchors.top: parent.top
                            anchors.topMargin: barWindow.cornerRadius
                            anchors.left: parent.right
                            implicitSize: barWindow.cornerRadius
                            color: parent.color
                            corner: RoundCorner.CornerEnum.TopLeft
                            opacity: barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }
                    }
                }

                // ── Gradient overlay (Always full width) ─────────
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: Appearance.sizes.statusBarHeight
                    color: "transparent"
                    opacity: !barWindow.showBackground && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true) ? 1.0 : 0.0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Appearance.colors.colStatusBarGradientStart }
                        GradientStop { position: 1.0; color: Appearance.colors.colStatusBarGradientEnd }
                    }
                    
                    Behavior on opacity { NumberAnimation { duration: 300 } }
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
            } // End mainContainer
        }
    }
}
