import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

/**
 * NAnDoroid Ported Dock
 * Masterpiece version: "Outer Div" island masking + pristine shadow layer.
 */
Scope {
    id: root
    property bool pinned: Config.ready ? (Config.options.dock.pinnedOnStartup ?? false) : false

    Variants {
        model: Quickshell.screens
        delegate: Scope {
            id: screenScope
            required property var modelData
            readonly property int monitorIndex: modelData.index ?? 0

            PanelWindow {
                id: dockWindow
                screen: modelData
                
                WlrLayershell.layer: {
                    if (!Config.ready) return WlrLayer.Overlay;
                    if (Config.options.dock.showOnlyInDesktop || Config.options.dock.autoHide) return WlrLayer.Overlay;
                    return WlrLayer.Top;
                }

                WlrLayershell.namespace: "nandoroid:dock"
                exclusiveZone: {
                    if (!Config.ready) return 0;
                    if (!Config.options.dock.showOnlyInDesktop && !Config.options.dock.autoHide) {
                        return dockHeight + (dockWindow.bgStyle === 2 ? 0 : Appearance.sizes.elevationMargin / 2);
                    }
                    return 0;
                }
                
                anchors { bottom: true }
                color: "transparent"
                visible: Config.ready && Config.options.dock.enable && !GlobalStates.screenLocked
                mask: Region { item: dockMouseArea }
                
                readonly property real dockHeight: Config.ready ? Config.options.dock.height : 70
                readonly property int bgStyle: Config.ready && Config.options.dock ? Config.options.dock.backgroundStyle : 1
                
                implicitWidth: modelData.width
                implicitHeight: dockHeight + Appearance.sizes.elevationMargin
                readonly property real screenY: modelData.height - height

                readonly property bool hasActiveWindows: {
                    if (!Config.ready || !HyprlandData.activeWorkspace) return false;
                    const wsId = HyprlandData.activeWorkspace.id;
                    const windows = HyprlandData.windowList;
                    for (let i = 0; i < windows.length; i++) {
                        const w = windows[i];
                        if (w.monitor === screenScope.monitorIndex && !w.floating && w.workspace.id === wsId) return true;
                    }
                    return false;
                }

                property bool reveal: {
                    if (!Config.ready) return true;
                    if (GlobalStates.launcherOpen) return false;
                    if (root.pinned || GlobalStates.dashboardOpen || GlobalStates.overviewOpen || GlobalStates.dockMenuOpen || dockPreview.visible || dockPreview.hovered || dockApps.buttonHovered) return true;
                    if (dockMouseArea.containsMouse) return true;
                    if (Config.options.dock.showOnlyInDesktop) return !hasActiveWindows && !Config.options.dock.autoHide;
                    if (Config.options.dock.autoHide) return Config.options.dock.autoHideMode === 1 ? false : !hasActiveWindows;
                    return true;
                }

                Timer {
                    id: hoverGuardTimer
                    interval: Appearance.animation.elementMoveFast.duration + 50
                    repeat: false
                    onTriggered: {
                        if (dockApps.buttonHovered && dockWindow.reveal) {
                            dockPreview.show(dockApps.lastHoveredButton, dockApps.lastHoveredAppData);
                        }
                    }
                }

                onRevealChanged: {
                    if (reveal) hoverGuardTimer.restart();
                    else dockPreview.requestHide();
                }

                MouseArea {
                    id: dockMouseArea
                    width: visualContainer.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    hoverEnabled: true
                    height: {
                        if (!Config.ready) return parent.height;
                        if (dockPreview.visible || dockPreview.hovered) return parent.height;
                        if (Config.options.dock.showOnlyInDesktop && hasActiveWindows && !GlobalStates.launcherOpen && !GlobalStates.dockMenuOpen) return 0;
                        return dockWindow.reveal ? parent.height : 3;
                    }
                    anchors.bottom: parent.bottom

                    Item {
                        id: visualContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: mainRowContainer.implicitWidth + 20
                        height: dockWindow.dockHeight
                        readonly property real bMargin: (dockWindow.bgStyle === 2) ? 0 : Appearance.sizes.elevationMargin / 2
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: dockWindow.reveal ? bMargin : -height - 20
                        opacity: dockWindow.reveal ? 1 : 0

                        Behavior on anchors.bottomMargin {
                            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type }
                        }
                        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                        // 1. THE PRISTINE SHADOW (Outside the mask, never cut off)
                        StyledRectangularShadow { 
                            target: dockVisualRect
                            opacity: 0.3
                            visible: dockWindow.bgStyle !== 0 
                        }

                        // 2. THE BACKGROUND ISLAND (Determines the shape)
                        Rectangle {
                            id: dockVisualRect; anchors.fill: parent
                            radius: dockWindow.bgStyle === 1 ? height / 2 : 0
                            topLeftRadius: (dockWindow.bgStyle === 1 || dockWindow.bgStyle === 2) ? (dockWindow.bgStyle === 1 ? height/2 : 24) : 0
                            topRightRadius: (dockWindow.bgStyle === 1 || dockWindow.bgStyle === 2) ? (dockWindow.bgStyle === 1 ? height/2 : 24) : 0
                            bottomLeftRadius: (dockWindow.bgStyle === 1) ? height/2 : 0
                            bottomRightRadius: (dockWindow.bgStyle === 1) ? height/2 : 0
                            color: Appearance.colors.colStatusBarSolid; opacity: dockWindow.bgStyle === 0 ? 0 : 1.0; border.width: 0
                        }

                        // 3. THE OUTER DIV MASK (Cuts all contents to match the island shape)
                        Item {
                            id: maskedIslandContent
                            anchors.fill: parent
                            
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: maskedIslandContent.width
                                    height: maskedIslandContent.height
                                    radius: dockVisualRect.radius
                                    topLeftRadius: dockVisualRect.topLeftRadius
                                    topRightRadius: dockVisualRect.topRightRadius
                                    bottomLeftRadius: dockVisualRect.bottomLeftRadius
                                    bottomRightRadius: dockVisualRect.bottomRightRadius
                                }
                            }

                            RowLayout {
                                id: mainRowContainer
                                anchors.centerIn: parent
                                spacing: 8
                                
                                // The "Inner Div" (Apps)
                                DockApps {
                                    id: dockApps; buttonPadding: 6; spacing: 8; height: visualContainer.height
                                    onRequestContextMenu: (appData, x, y) => {
                                        dockContextMenu.openAt(x, dockWindow.screenY + y, appData);
                                    }
                                    onButtonHoverChanged: (button, appData, hovered) => {
                                        if (hovered) {
                                            dockApps.lastHoveredAppData = appData;
                                            if (!hoverGuardTimer.running && dockWindow.reveal) {
                                                dockPreview.show(button, appData);
                                            }
                                        } else {
                                            dockPreview.requestHide();
                                        }
                                    }
                                }

                                // The Launcher
                                DockButton {
                                    id: launcherButton; pointingHandCursor: true; onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen; toggled: GlobalStates.launcherOpen; dockTopInset: 6; dockBottomInset: 6
                                    altAction: (event) => {
                                        const pos = launcherButton.mapToItem(null, event.x, event.y);
                                        dockContextMenu.openAt(pos.x, dockWindow.screenY + pos.y);
                                    }
                                    background: Item {
                                        anchors.fill: parent
                                        Rectangle { anchors.fill: parent; radius: Appearance.rounding.button; color: launcherButton.baseColor; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                        MaterialShape { anchors.fill: parent; anchors.margins: 4; visible: Config.ready && Config.options.dock.monochromeIcons; shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"; color: launcherButton.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer }
                                    }
                                    contentItem: Item {
                                        anchors.fill: parent
                                        MaterialSymbol { id: launcherIcon; anchors.centerIn: parent; text: "apps"; iconSize: Config.ready && Config.options.dock.monochromeIcons ? 24 : 28; color: launcherButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                        ColorOverlay { anchors.fill: launcherIcon; source: launcherIcon; color: Appearance.colors.colOnPrimaryContainer; visible: Config.ready && Config.options.dock.monochromeIcons }
                                    }
                                }
                            }
                        }
                    }
                }

                DockContextMenu { id: dockContextMenu; screen: modelData }
                DockPreview { id: dockPreview; parentWindow: dockWindow }
            }
        }
    }
}
