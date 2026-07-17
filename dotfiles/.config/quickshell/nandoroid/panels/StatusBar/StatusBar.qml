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
 * Refactored for global scaling with edge gap fixes.
 */
Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: barWindow
            required property var modelData
            property int monitorIndex: modelData.index !== undefined ? modelData.index : 0
            readonly property bool isM3: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle === "m3"

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

            readonly property real actualStatusBarHeight: isM3 ? 48 * Appearance.effectiveScale : Appearance.sizes.statusBarHeight

            // Track special workspace to raise layer above it
            readonly property bool specialWorkspaceActive: {
                var mon = Hyprland.monitorFor(barWindow.modelData);
                if (!mon) return false;
                var swState = HyprlandData.monitorSpecialWorkspace;
                return swState[mon.name] !== undefined && swState[mon.name] !== "";
            }

            exclusiveZone: (autoHide && !mustShow) ? 0 : actualStatusBarHeight
            WlrLayershell.namespace: "nandoroid:statusbar"
            WlrLayershell.layer: specialWorkspaceActive ? WlrLayer.Overlay : WlrLayer.Top

            anchors {
                left: true
                right: true
                top: true
            }

            color: "transparent"
            implicitHeight: actualStatusBarHeight + (showBackground ? cornerRadius : 0)

            // Define clickable area mask
            mask: Region {
                item: maskItem
            }

            Item {
                id: maskItem
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: (autoHide && !mustShow) ? 3 * Appearance.effectiveScale : parent.height
            }

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
                height: 3 * Appearance.effectiveScale
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: forceShowByHover = true
                onPressed: (mouse) => { mouse.accepted = false; }
                cursorShape: Qt.ArrowCursor
                z: 100 
            }

            // ── Background visibility ──────────────────────────────────
            readonly property int bgStyle: Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundStyle !== undefined ? Config.options.statusBar.backgroundStyle : 0) : 0
            readonly property int cornerRadius: Math.round((Config.ready && Config.options.statusBar
                ? (Config.options.statusBar.backgroundCornerRadius !== undefined ? Config.options.statusBar.backgroundCornerRadius : 20) : 20) * Appearance.effectiveScale)

            readonly property bool hasTiledWindows: {
                if (bgStyle !== 2 || !Hyprland.monitorFor(modelData) || !Hyprland.monitorFor(modelData).activeWorkspace || Hyprland.monitorFor(modelData).activeWorkspace.id === -1) return false;
                const wsId = Hyprland.monitorFor(modelData).activeWorkspace.id;
                return HyprlandData.windowList.some(w => 
                    w.workspace.id === wsId && !w.floating && w.monitor === monitorIndex
                );
            }

            readonly property bool showBackground: {
                if (isM3) return false;
                if (bgStyle === 1) return true;
                if (bgStyle === 2) return hasTiledWindows;
                return false;
            }

            readonly property bool isCentered: (!isM3 && Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
            readonly property real centeredWidth: Math.round((Config.ready && Config.options.statusBar ? Config.options.statusBar.centeredWidth : 1200) * Appearance.effectiveScale)

            // ── Main Content Container (Animated) ──
            Item {
                id: mainContainer
                anchors.fill: parent
                anchors.topMargin: (autoHide && !mustShow) ? -actualStatusBarHeight - (showBackground ? cornerRadius : 5 * Appearance.effectiveScale) : 0
                
                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutQuart
                    }
                }

                // ── Background Layer ──
                Item {
                    id: barBackgroundLayer
                    anchors.fill: parent
                    visible: barWindow.showBackground
                    opacity: barBg.opacity

                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 0
                        verticalOffset: 2 * Appearance.effectiveScale
                        radius: 24 * Appearance.effectiveScale
                        samples: 32
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.12)
                        transparentBorder: true
                    }

                    Rectangle {
                        id: barBg
                        
                        readonly property real targetHeight: actualStatusBarHeight + (barWindow.isCentered ? barWindow.cornerRadius : 0)
                        readonly property real targetY: barWindow.showBackground 
                            ? (barWindow.isCentered ? -barWindow.cornerRadius : 0)
                            : -targetHeight - (10 * Appearance.effectiveScale)

                        y: targetY
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        // Overlap logic: In standard mode, make it 2px wider to eliminate screen edge gaps
                        readonly property real overlap: 1.0
                        width: barWindow.isCentered 
                            ? Math.min(barWindow.centeredWidth, parent.width - (40 * Appearance.effectiveScale)) 
                            : parent.width + (overlap * 2)
                        
                        height: targetHeight
                        color: Appearance.colors.colStatusBarSolid
                        opacity: isM3 ? 0.0 : 1.0
                        visible: opacity > 0
                        
                        radius: barWindow.isCentered ? barWindow.cornerRadius : 0

                        Behavior on y { NumberAnimation { duration: 550; easing.type: Easing.OutQuint } }
                        Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }
                        Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.OutQuint } }
                        Behavior on radius { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                        // Standard Mode Corners (Bottom) - Pull OUT and UP
                        RoundCorner {
                            id: stdLeftCorner
                            anchors.top: parent.bottom; anchors.left: parent.left
                            anchors.topMargin: -barBg.overlap; anchors.leftMargin: -barBg.overlap
                            implicitSize: barWindow.cornerRadius; color: parent.color; corner: RoundCorner.CornerEnum.TopLeft
                            opacity: !barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0; visible: opacity > 0
                        }
                        RoundCorner {
                            id: stdRightCorner
                            anchors.top: parent.bottom; anchors.right: parent.right
                            anchors.topMargin: -barBg.overlap; anchors.rightMargin: -barBg.overlap
                            implicitSize: barWindow.cornerRadius; color: parent.color; corner: RoundCorner.CornerEnum.TopRight
                            opacity: !barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0; visible: opacity > 0
                        }
                        // HUD Mode Corners (Top sides) - Pull IN and UP
                        RoundCorner {
                            id: hudLeftCorner
                            anchors.top: parent.top; anchors.topMargin: barWindow.cornerRadius - barBg.overlap; anchors.right: parent.left
                            anchors.rightMargin: -barBg.overlap
                            implicitSize: barWindow.cornerRadius; color: parent.color; corner: RoundCorner.CornerEnum.TopRight
                            opacity: barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0; visible: opacity > 0
                        }
                        RoundCorner {
                            id: hudRightCorner
                            anchors.top: parent.top; anchors.topMargin: barWindow.cornerRadius - barBg.overlap; anchors.left: parent.right
                            anchors.leftMargin: -barBg.overlap
                            implicitSize: barWindow.cornerRadius; color: parent.color; corner: RoundCorner.CornerEnum.TopLeft
                            opacity: barWindow.isCentered && barWindow.showBackground ? 1.0 : 0.0; visible: opacity > 0
                        }
                    }
                }

                // ── Gradient overlay ──
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: actualStatusBarHeight
                    color: "transparent"
                    // User explicitly requested to disable gradient in M3 style
                    opacity: !barWindow.showBackground && !isM3 && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true) ? 1.0 : 0.0
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Appearance.colors.colStatusBarGradientStart }
                        GradientStop { position: 1.0; color: Appearance.colors.colStatusBarGradientEnd }
                    }
                }

                // ── Content ──
                Loader {
                    id: contentLoader
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    width: parent.width
                    height: actualStatusBarHeight
                    sourceComponent: isM3 ? m3Content : baseContent
                    
                    Component {
                        id: baseContent
                        StatusBarContent {
                            height: Appearance.sizes.statusBarHeight
                            monitorIndex: barWindow.monitorIndex
                        }
                    }
                    
                    Component {
                        id: m3Content
                        StatusBarM3Style {
                            height: 48 * Appearance.effectiveScale
                            monitorIndex: barWindow.monitorIndex
                        }
                    }
                }
            }
        }
    }
}
