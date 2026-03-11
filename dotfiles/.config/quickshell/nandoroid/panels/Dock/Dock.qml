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
            
            // ── Layer Logic ──
            WlrLayershell.layer: {
                if (!Config.ready) return WlrLayer.Overlay;
                if (Config.options.dock.showOnlyInDesktop || Config.options.dock.autoHide) {
                    return WlrLayer.Overlay;
                }
                return WlrLayer.Top;
            }

            WlrLayershell.namespace: "nandoroid:dock"
            
            // ── Exclusive Zone Logic ──
            // Menentukan ruang yang dipesan di bawah monitor.
            exclusiveZone: {
                if (!Config.ready) return 0;
                if (!Config.options.dock.showOnlyInDesktop && !Config.options.dock.autoHide) {
                    return dockHeight + (dockWindow.bgStyle === 2 ? 0 : Appearance.sizes.elevationMargin / 2);
                }
                return 0;
            }
            
            // KEMBALI KE ANCHOR SEDERHANA (HANYA BOTTOM)
            // Ini membuat jendela hanya selebar Dock, sehingga semua klik/hover otomatis masuk
            anchors {
                bottom: true
            }
            
            visible: Config.ready && Config.options.dock.enable && !GlobalStates.screenLocked
            color: "transparent"
            
            readonly property real dockHeight: Config.ready ? Config.options.dock.height : 70
            readonly property int bgStyle: Config.ready && Config.options.dock ? Config.options.dock.backgroundStyle : 1
            
            // Window width must follow the content
            implicitWidth: mainRowContainer.implicitWidth + 40
            implicitHeight: dockHeight + Appearance.sizes.elevationMargin

            // ── Auto Hide Logic ──
            readonly property bool hasActiveWindows: {
                if (!Config.ready || !HyprlandData.activeWorkspace) return false;
                return HyprlandData.windowList.some(w => 
                    w.monitor === dockWindow.monitorIndex && 
                    !w.floating &&
                    w.workspace.id === HyprlandData.activeWorkspace.id
                );
            }

            // ── Reveal Logic ──
            property bool reveal: {
                if (!Config.ready) return true;
                const autoHide = Config.options.dock.autoHide;
                const autoHideMode = Config.options.dock.autoHideMode;
                const showOnlyInDesktop = Config.options.dock.showOnlyInDesktop;
                
                if (root.pinned) return true;
                if (GlobalStates.launcherOpen || GlobalStates.dashboardOpen || GlobalStates.overviewOpen) return true;
                if (dockMouseArea.containsMouse) return true;
                
                if (showOnlyInDesktop) {
                    if (hasActiveWindows) return false;
                    return !autoHide; 
                }
                
                if (autoHide) {
                    if (autoHideMode === 1) return false;
                    else return !hasActiveWindows;
                }
                
                return true;
            }

            MouseArea {
                id: dockMouseArea
                anchors.fill: parent
                hoverEnabled: true
                
                // Tinggi area pemicu hover saat Dock sembunyi
                height: {
                    if (!Config.ready) return parent.height;
                    // Mati total jika showOnlyInDesktop nyala dan ada jendela
                    if (Config.options.dock.showOnlyInDesktop && hasActiveWindows && !GlobalStates.launcherOpen) return 0;
                    return dockWindow.reveal ? parent.height : 10;
                }
                // Pastikan MouseArea selalu di bawah jendela (nempel pinggir layar)
                anchors.bottom: parent.bottom

                RowLayout {
                    id: mainRowContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    
                    readonly property real bMargin: (dockWindow.bgStyle === 2) ? 0 : Appearance.sizes.elevationMargin / 2
                    
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: dockWindow.reveal ? bMargin : -height - 20
                    opacity: dockWindow.reveal ? 1 : 0
                    
                    Behavior on anchors.bottomMargin { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(mainRowContainer) }
                    Behavior on opacity { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(mainRowContainer) }

                    // ── Main Apps Island ──
                    Item {
                        id: dockBackground
                        implicitWidth: dockRowLayout.implicitWidth + 24
                        implicitHeight: dockWindow.dockHeight
                        Layout.alignment: Qt.AlignVCenter

                        StyledRectangularShadow {
                            target: dockVisualRect
                            opacity: 0.3
                            visible: dockWindow.bgStyle !== 0
                        }

                        Rectangle {
                            id: dockVisualRect
                            anchors.fill: parent
                            radius: dockWindow.bgStyle === 1 ? height / 2 : 0
                            topLeftRadius: (dockWindow.bgStyle === 1 || dockWindow.bgStyle === 2) ? (dockWindow.bgStyle === 1 ? height/2 : 24) : 0
                            topRightRadius: (dockWindow.bgStyle === 1 || dockWindow.bgStyle === 2) ? (dockWindow.bgStyle === 1 ? height/2 : 24) : 0
                            bottomLeftRadius: (dockWindow.bgStyle === 1) ? height/2 : 0
                            bottomRightRadius: (dockWindow.bgStyle === 1) ? height/2 : 0
                            color: Appearance.colors.colStatusBarSolid
                            opacity: dockWindow.bgStyle === 0 ? 0 : 1.0
                            border.width: 0
                        }

                        RowLayout {
                            id: dockRowLayout
                            anchors.centerIn: parent
                            spacing: 8
                            property real padding: 6

                            DockApps {
                                id: dockApps
                                buttonPadding: dockRowLayout.padding
                                spacing: dockRowLayout.spacing
                                height: parent.height
                            }

                            DockButton {
                                id: launcherButton
                                pointingHandCursor: true
                                onClicked: GlobalStates.launcherOpen = !GlobalStates.launcherOpen
                                toggled: GlobalStates.launcherOpen
                                dockTopInset: 6; dockBottomInset: 6
                                
                                background: Item {
                                    anchors.fill: parent
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.topMargin: 6; anchors.bottomMargin: 6
                                        radius: Appearance.rounding.button
                                        color: launcherButton.baseColor
                                        visible: !(Config.ready && Config.options.dock.monochromeIcons)
                                    }
                                    MaterialShape {
                                        anchors.fill: parent; anchors.margins: 4
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
                                        anchors.fill: launcherIcon; source: launcherIcon
                                        color: Appearance.colors.colOnPrimaryContainer
                                        visible: Config.ready && Config.options.dock.monochromeIcons
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
