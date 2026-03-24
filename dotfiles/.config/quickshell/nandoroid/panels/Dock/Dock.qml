import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * NAnDoroid Ported Dock
 * Masterpiece version: Optimized, Stable, and Correct Layering.
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
                
                // --- LAYER FIX: Sits at 'Top' layer so 'Overlay' panels stay in front ---
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "nandoroid:dock"
                
                exclusiveZone: {
                    if (!Config.ready || !visible) return 0;
                    const scale = (Config.options.dock.scale ?? 1.0) * Appearance.effectiveScale;
                    // Only reserve space if NOT auto-hiding and NOT showOnlyInDesktop
                    if (!Config.options.dock.showOnlyInDesktop && !Config.options.dock.autoHide) {
                        return 70 * scale + (dockWindow.bgStyle === 2 ? 0 : Appearance.sizes.elevationMargin / 2);
                    }
                    return 0;
                }
                
                anchors { left: true; right: true; bottom: true }
                color: "transparent"
                
                // Define the clickable area to allow click-through on the sides
                mask: Region {
                    // Include the entire mouse area to allow trigger at bottom edge
                    item: dockMouseArea
                }
                
                // SIMPLIFIED VISIBILITY: Toggle the whole window for 'Show Only In Desktop'
                visible: {
                    if (!Config.ready || GlobalStates.screenLocked || !Config.options.dock.enable) return false;
                    
                    // If 'Show Only In Desktop' is ON, only show if no active windows on this monitor
                    if (Config.options.dock.showOnlyInDesktop) {
                        if (GlobalStates.launcherOpen || GlobalStates.dockMenuOpen || root.pinned) return true;
                        return !hasActiveWindows;
                    }
                    
                    return true;
                }

                // Removed restrictive mask to allow shadow to spread
                
                readonly property real dockHeight: 70 * Appearance.effectiveScale
                readonly property real dockScale: (Config.ready && Config.options.dock ? Config.options.dock.scale : 1.0) * Appearance.effectiveScale
                readonly property int bgStyle: Config.ready && Config.options.dock ? Config.options.dock.backgroundStyle : 1
                
                implicitWidth: modelData.width
                // Provide enough height for popups and shadows without pushing them too far up
                implicitHeight: 500 * Appearance.effectiveScale
                readonly property real screenY: modelData.height - height

                readonly property bool hasActiveWindows: {
                    if (!Config.ready || !HyprlandData.activeWorkspace) return false;
                    
                    // Get windows for THIS specific monitor on the active workspace
                    const wsId = HyprlandData.activeWorkspace.id;
                    const windows = HyprlandData.hyprlandClientsForWorkspace(wsId);
                    
                    for (let i = 0; i < windows.length; i++) {
                        const w = windows[i];
                        if (w.monitor === screenScope.monitorIndex && !w.floating && w.mapped && !w.hidden) return true;
                    }
                    return false;
                }

                property bool reveal: {
                    if (!Config.ready) return true;
                    
                    // Standard reveal logic (Menus, Hovers, Pinned)
                    if (root.pinned || GlobalStates.dockMenuOpen || dockPreview.visible || dockPreview.hovered || dockApps.buttonHovered || dockMouseArea.containsMouse) return true;
                    
                    // Auto-hide logic
                    if (Config.options.dock.autoHide) {
                        if (Config.options.dock.autoHideMode === 1) return false; // Always hide mode
                        return !hasActiveWindows; // Intelligent mode
                    }
                    
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
                    // Standard interactive area
                    width: Math.max(200 * Appearance.effectiveScale, visualContainer.width * (dockWindow.dockScale / Appearance.effectiveScale))
                    anchors.horizontalCenter: parent.horizontalCenter
                    hoverEnabled: true
                    height: {
                        if (!Config.ready) return parent.height;
                        if (dockPreview.visible || dockPreview.hovered) return parent.height;
                        return dockWindow.reveal ? parent.height : 3 * Appearance.effectiveScale;
                    }
                    anchors.bottom: parent.bottom

                    Item {
                        id: visualContainer
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(100 * Appearance.effectiveScale, mainRowContainer.implicitWidth + 20 * Appearance.effectiveScale)
                        height: dockWindow.dockHeight
                        scale: dockWindow.dockScale / Appearance.effectiveScale
                        transformOrigin: Item.Bottom
                        
                        readonly property real bMargin: (dockWindow.bgStyle === 2) ? -2 * Appearance.effectiveScale : Appearance.sizes.elevationMargin / 2
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: dockWindow.reveal ? bMargin : (-height * scale) - 20 * Appearance.effectiveScale
                        opacity: dockWindow.reveal ? 1 : 0

                        Behavior on anchors.bottomMargin {
                            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Appearance.animation.elementMoveFast.type }
                        }
                        Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration } }

                        // --- Visual Content Wrapper ---
                        Item {
                            id: shadowWrapper
                            anchors.fill: parent
                            // Removed shadow, added border to the rectangle below

                            // Actual Visual Content
                            Item {
                                anchors.centerIn: parent
                                width: visualContainer.width
                                height: visualContainer.height

                                Rectangle {
                                    id: dockVisualRect; anchors.fill: parent
                                    radius: dockWindow.bgStyle === 1 ? height / 2 : 0
                                    topLeftRadius: (dockWindow.bgStyle === 1 || dockWindow.bgStyle === 2) ? (dockWindow.bgStyle === 1 ? height/2 : 24 * Appearance.effectiveScale) : 0
                                    topRightRadius: (dockWindow.bgStyle === 1 || dockWindow.bgStyle === 2) ? (dockWindow.bgStyle === 1 ? height/2 : 24 * Appearance.effectiveScale) : 0
                                    bottomLeftRadius: (dockWindow.bgStyle === 1) ? height/2 : 0
                                    bottomRightRadius: (dockWindow.bgStyle === 1) ? height/2 : 0
                                    color: Appearance.colors.colStatusBarSolid; opacity: dockWindow.bgStyle === 0 ? 0 : 1.0; 
                                    
                                    // MD3 Outline Style
                                    border.width: dockWindow.bgStyle !== 0 ? Math.max(1, 1 * Appearance.effectiveScale) : 0
                                    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.12)
                                }

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
                                        spacing: 8 * Appearance.effectiveScale
                                        
                                        DockApps {
                                            id: dockApps; buttonPadding: 6 * Appearance.effectiveScale; spacing: 8 * Appearance.effectiveScale; height: visualContainer.height
                                            backgroundStyle: dockWindow.bgStyle
                                            onRequestContextMenu: (appData, x, y) => {
                                                dockContextMenu.openAt(x, (dockWindow.screenY + (y * (dockWindow.dockScale / Appearance.effectiveScale))), appData);
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

                                        DockButton {
                                            id: overviewButton
                                            visible: Config.ready && (Config.options.dock.showOverview ?? true)
                                            pointingHandCursor: true
                                            onClicked: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                                            toggled: GlobalStates.overviewOpen
                                            dockTopInset: 6 * Appearance.effectiveScale; dockBottomInset: 6 * Appearance.effectiveScale
                                            colBackgroundToggled: "transparent"
                                            colBackgroundToggledHover: "transparent"
                                            background: Item {
                                                anchors.fill: parent
                                                Rectangle { anchors.fill: parent; radius: Appearance.rounding.button; color: overviewButton.baseColor; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                                MaterialShape { anchors.fill: parent; anchors.margins: 4 * Appearance.effectiveScale; visible: Config.ready && Config.options.dock.monochromeIcons; shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"; color: overviewButton.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer }
                                            }
                                            contentItem: Item {
                                                anchors.fill: parent
                                                scale: overviewButton.down ? 0.92 : (overviewButton.hovered ? 1.05 : 1.0)
                                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                                MaterialSymbol { id: overviewIcon; anchors.centerIn: parent; text: "grid_view"; iconSize: (Config.ready && Config.options.dock.monochromeIcons ? 22 : 26) * Appearance.effectiveScale; color: overviewButton.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                                ColorOverlay { anchors.fill: overviewIcon; source: overviewIcon; color: Appearance.colors.colOnPrimaryContainer; visible: Config.ready && Config.options.dock.monochromeIcons }
                                            }
                                        }

                                        DockButton {
                                            id: launcherButton
                                            visible: Config.ready && (Config.options.dock.showLauncher ?? true)
                                            pointingHandCursor: true
                                            onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
                                            toggled: GlobalStates.launcherOpen
                                            dockTopInset: 6 * Appearance.effectiveScale; dockBottomInset: 6 * Appearance.effectiveScale
                                            colBackgroundToggled: "transparent"
                                            colBackgroundToggledHover: "transparent"
                                            altAction: (event) => {
                                                const pos = launcherButton.mapToItem(null, event.x, event.y);
                                                dockContextMenu.openAt(pos.x, dockWindow.screenY + pos.y);
                                            }
                                            background: Item {
                                                anchors.fill: parent
                                                Rectangle { anchors.fill: parent; radius: Appearance.rounding.button; color: launcherButton.baseColor; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                                MaterialShape { anchors.fill: parent; anchors.margins: 4 * Appearance.effectiveScale; visible: Config.ready && Config.options.dock.monochromeIcons; shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"; color: launcherButton.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer }
                                            }
                                            contentItem: Item {
                                                anchors.fill: parent
                                                scale: launcherButton.down ? 0.92 : (launcherButton.hovered ? 1.05 : 1.0)
                                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                                MaterialSymbol { id: launcherIcon; anchors.centerIn: parent; text: "apps"; iconSize: (Config.ready && Config.options.dock.monochromeIcons ? 24 : 28) * Appearance.effectiveScale; color: launcherButton.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer0; visible: !(Config.ready && Config.options.dock.monochromeIcons) }
                                                ColorOverlay { anchors.fill: launcherIcon; source: launcherIcon; color: Appearance.colors.colOnPrimaryContainer; visible: Config.ready && Config.options.dock.monochromeIcons }
                                            }
                                        }
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
