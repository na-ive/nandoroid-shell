import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../widgets"

/**
 * NAnDoroid Ported Dock
 * A minimalist Material You dock adapted from Illogical Impulse.
 * Supports multiple background styles, auto-hide and themed icons.
 */
Scope {
    id: root
    property bool pinned: Config.ready ? (Config.options.dock.pinnedOnStartup ?? false) : false

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: dockWindow
            required property var modelData
            property int monitorIndex: modelData.index ?? 0
            
            screen: modelData
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "nandoroid:dock"
            exclusionMode: ExclusionMode.Ignore
            
            // Only show if enabled in config
            visible: Config.ready && Config.options.dock.enable && !GlobalStates.screenLocked
            
            // ── Background Style Config ────────────────────────────────
            readonly property int bgStyle: Config.ready && Config.options.dock ? Config.options.dock.backgroundStyle : 1
            
            // ── Auto Hide Logic ────────────────────────────────────────
            readonly property bool hasActiveWindows: {
                if (!Config.ready || !HyprlandData.activeWorkspace) return false;
                return HyprlandData.windowList.some(w => 
                    w.monitor === dockWindow.monitorIndex && 
                    !w.floating &&
                    w.workspace.id === HyprlandData.activeWorkspace.id
                );
            }

            // ── Reveal Logic ───────────────────────────────────────────
            property bool reveal: {
                if (!Config.ready) return true;
                const autoHide = Config.options.dock.autoHide;
                const autoHideMode = Config.options.dock.autoHideMode;
                const showOnlyInDesktop = Config.options.dock.showOnlyInDesktop;
                
                if (root.pinned) return true;
                if (GlobalStates.launcherOpen || GlobalStates.dashboardOpen || GlobalStates.overviewOpen) return true;
                if (dockMouseArea.containsMouse) return true;
                if (showOnlyInDesktop && hasActiveWindows) return false;
                
                if (autoHide) {
                    if (autoHideMode === 1) return false; 
                    else return !hasActiveWindows;
                }
                return true;
            }

            anchors {
                bottom: true
            }

            color: "transparent"
            
            implicitHeight: (Config.ready ? Config.options.dock.height : 70) + Appearance.sizes.elevationMargin
            implicitWidth: dockBackground.implicitWidth + 40

            mask: Region {
                item: dockMouseArea
            }

            MouseArea {
                id: dockMouseArea
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                
                height: dockWindow.reveal ? parent.height : (Config.ready && (Config.options.dock.autoHide || Config.options.dock.showOnlyInDesktop) ? 10 : 0)
                width: dockBackground.implicitWidth + 20
                hoverEnabled: true

                Behavior on height { 
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(dockMouseArea)
                }

                Item {
                    id: dockBackground
                    anchors.bottom: parent.bottom
                    
                    // attached mode (2) has 0 margin, floating (1) has elevationMargin
                    anchors.bottomMargin: dockWindow.bgStyle === 2 ? 0 : Appearance.sizes.elevationMargin / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    implicitWidth: dockRowLayout.implicitWidth + 20
                    height: Config.ready ? Config.options.dock.height : 70

                    y: dockWindow.reveal ? 0 : height + Appearance.sizes.elevationMargin
                    opacity: dockWindow.reveal ? 1 : 0
                    
                    Behavior on y { 
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(dockBackground)
                    }
                    Behavior on opacity { 
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(dockBackground)
                    }

                    // ── Dock Background Visuals ──
                    StyledRectangularShadow {
                        target: dockVisualRect
                        opacity: 0.3
                        visible: dockWindow.bgStyle !== 0
                    }

                    Rectangle {
                        id: dockVisualRect
                        anchors.fill: parent
                        
                        // Floating: fully rounded. Attached: only top corners rounded.
                        radius: dockWindow.bgStyle === 1 ? height / 2 : 0
                        topLeftRadius: dockWindow.bgStyle === 2 ? 24 : radius
                        topRightRadius: dockWindow.bgStyle === 2 ? 24 : radius
                        
                        color: Appearance.colors.colStatusBarSolid
                        opacity: dockWindow.bgStyle === 0 ? 0 : 0.95
                        
                        // No border as requested to match status bar
                        border.width: 0
                    }

                    // ── Dock Content ──
                    RowLayout {
                        id: dockRowLayout
                        anchors.centerIn: parent
                        spacing: 8
                        property real padding: 6

                        // ── Apps Section ──
                        DockApps {
                            id: dockApps
                            buttonPadding: dockRowLayout.padding
                            spacing: dockRowLayout.spacing
                            height: parent.height
                        }

                        // ── Launcher Trigger ──
                        DockButton {
                            id: launcherButton
                            onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
                            toggled: GlobalStates.launcherOpen
                            
                            dockTopInset: dockRowLayout.padding
                            dockBottomInset: dockRowLayout.padding
                            
                            background: Item {
                                anchors.fill: parent
                                
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.topMargin: launcherButton.dockTopInset
                                    anchors.bottomMargin: launcherButton.dockBottomInset
                                    radius: launcherButton.buttonRadius
                                    color: launcherButton.baseColor
                                    visible: !(Config.ready && Config.options.dock.monochromeIcons)
                                }

                                MaterialShape {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    visible: Config.ready && Config.options.dock.monochromeIcons
                                    shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"
                                    color: launcherButton.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
                                }
                            }

                            contentItem: Item {
                                anchors.fill: parent
                                MaterialSymbol {
                                    id: launcherIcon
                                    anchors.centerIn: parent
                                    text: "apps"
                                    iconSize: Config.ready && Config.options.dock.monochromeIcons ? 24 : 28
                                    color: launcherButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                    
                                    visible: !(Config.ready && Config.options.dock.monochromeIcons)
                                }

                                ColorOverlay {
                                    anchors.fill: launcherIcon
                                    source: launcherIcon
                                    color: Appearance.colors.colOnPrimaryContainer
                                    visible: Config.ready && Config.options.dock.monochromeIcons
                                }
                            }

                            StyledToolTip {
                                text: "Launcher"
                                visible: launcherButton.hovered
                            }
                        }
                    }
                }
            }
        }
    }
}
