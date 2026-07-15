import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../Dashboard"
import "../NotificationCenter"
import "../QuickSettings"
import "../QuickActions"

/**
 * Unified Overlay Panel
 * Hosts Dashboard, Notification Center, Quick Settings, and Quick Actions
 * in a single transparent fullscreen window to allow them to be opened simultaneously.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        readonly property bool anyOpen: GlobalStates.dashboardOpen || GlobalStates.notificationCenterOpen || GlobalStates.quickSettingsOpen || GlobalStates.quickActionsOpen
        
        readonly property bool isAnimating: dashboard.panelOpacity > 0 || ncLoader.opacity > 0 || qsLoader.opacity > 0 || qaLoader.opacity > 0
        
        Timer {
            id: hideDelayTimer
            interval: 100
            running: !panelWindow.anyOpen && !panelWindow.isAnimating
        }
        
        visible: (anyOpen && isActive) || isAnimating || hideDelayTimer.running
        
        exclusiveZone: 0
        WlrLayershell.namespace: "nandoroid:overlay"
        WlrLayershell.layer: ((anyOpen || isAnimating) && isActive) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.keyboardFocus: (anyOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Close on click outside (consumes click on desktop background)
        MouseArea {
            anchors.fill: parent
            onClicked: {
                GlobalStates.dashboardOpen = false;
                GlobalStates.notificationCenterOpen = false;
                GlobalStates.quickSettingsOpen = false;
                GlobalStates.quickActionsOpen = false;
            }
            z: -1
        }

        // --- Dashboard Content (Centered) ---
        DashboardContent {
            id: dashboard
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            visible: isActive
            onClosed: GlobalStates.dashboardOpen = false
        }

        // --- Notification Center Content (Top Left) ---
        Loader {
            id: ncLoader
            active: true 
            visible: (opacity > 0 && isActive)
            enabled: GlobalStates.notificationCenterOpen && isActive
            
            readonly property bool isM3: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.moduleStyle === "m3" : false
            readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
            readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200 * Appearance.effectiveScale
            readonly property real sidePadding: isCentered ? Math.round((panelWindow.width - Math.min(centeredWidth, panelWindow.width - 40 * Appearance.effectiveScale)) / 2) : 0

            anchors {
                top: parent.top
                left: parent.left
                topMargin: 0
                leftMargin: sidePadding
            }
            
            transform: Translate {
                id: ncTransform
            }

            states: [
                State {
                    name: "open"
                    when: GlobalStates.notificationCenterOpen && isActive
                    PropertyChanges { target: ncLoader; opacity: 1 }
                    PropertyChanges { target: ncTransform; x: 0; y: 0 }
                },
                State {
                    name: "closed"
                    when: (!GlobalStates.notificationCenterOpen || !isActive)
                    PropertyChanges { target: ncLoader; opacity: 0 }
                    PropertyChanges { target: ncTransform; 
                        x: ncLoader.isCentered ? 0 : -ncLoader.width - 40 * Appearance.effectiveScale;
                        y: ncLoader.isCentered ? -ncLoader.height - 40 * Appearance.effectiveScale : 0;
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation {
                            target: ncTransform
                            properties: "x,y"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                        }
                        NumberAnimation {
                            target: ncLoader
                            property: "opacity"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.standard
                        }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation {
                            target: ncTransform
                            properties: "x,y"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                        NumberAnimation {
                            target: ncLoader
                            property: "opacity"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }
                }
            ]

            sourceComponent: NotificationCenterContent {
                onClosed: GlobalStates.notificationCenterOpen = false
            }
        }

        // --- Quick Settings Content (Top Right) ---
        Loader {
            id: qsLoader
            active: true
            visible: (opacity > 0 && isActive)
            enabled: GlobalStates.quickSettingsOpen && isActive
            
            readonly property bool isM3: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.moduleStyle === "m3" : false
            readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
            readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth * Appearance.effectiveScale : 1200 * Appearance.effectiveScale
            readonly property real sidePadding: isCentered ? Math.round((panelWindow.width - Math.min(centeredWidth, panelWindow.width - 40 * Appearance.effectiveScale)) / 2) : 0

            anchors {
                top: parent.top
                right: parent.right
                topMargin: 0
                rightMargin: sidePadding
            }

            transform: Translate {
                id: qsTransform
            }

            states: [
                State {
                    name: "open"
                    when: GlobalStates.quickSettingsOpen && isActive
                    PropertyChanges { target: qsLoader; opacity: 1 }
                    PropertyChanges { target: qsTransform; x: 0; y: 0 }
                },
                State {
                    name: "closed"
                    when: (!GlobalStates.quickSettingsOpen || !isActive)
                    PropertyChanges { target: qsLoader; opacity: 0 }
                    PropertyChanges { target: qsTransform; 
                        x: qsLoader.isCentered ? 0 : qsLoader.width + 40 * Appearance.effectiveScale;
                        y: qsLoader.isCentered ? -qsLoader.height - 40 * Appearance.effectiveScale : 0;
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation {
                            target: qsTransform
                            properties: "x,y"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                        }
                        NumberAnimation {
                            target: qsLoader
                            property: "opacity"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.standard
                        }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation {
                            target: qsTransform
                            properties: "x,y"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                        NumberAnimation {
                            target: qsLoader
                            property: "opacity"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }
                }
            ]

            sourceComponent: QuickSettingsContent {
                onClosed: {
                    GlobalStates.quickSettingsOpen = false;
                    GlobalStates.quickSettingsEditMode = false;
                }
            }
        }

        // --- Quick Actions Content (Bottom) ---
        Loader {
            id: qaLoader
            active: true
            visible: (opacity > 0 && isActive)
            enabled: GlobalStates.quickActionsOpen && isActive

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            
            // Initial state: pushed down by its own height
            anchors.bottomMargin: -height
            opacity: 0

            states: [
                State {
                    name: "active"
                    when: GlobalStates.quickActionsOpen && isActive
                    PropertyChanges {
                        target: qaLoader
                        anchors.bottomMargin: 0
                        opacity: 1
                    }
                }
            ]

            transitions: [
                Transition {
                    from: ""
                    to: "active"
                    ParallelAnimation {
                        NumberAnimation {
                            target: qaLoader
                            property: "anchors.bottomMargin"
                            duration: 300
                            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                        }
                        NumberAnimation {
                            target: qaLoader
                            property: "opacity"
                            duration: 200
                        }
                    }
                },
                Transition {
                    from: "active"
                    to: ""
                    ParallelAnimation {
                        NumberAnimation {
                            target: qaLoader
                            property: "anchors.bottomMargin"
                            to: -qaLoader.height
                            duration: 300
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                        NumberAnimation {
                            target: qaLoader
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                    }
                }
            ]
            
            sourceComponent: QuickActionsContent {
                onClosed: GlobalStates.quickActionsOpen = false
                
                Connections {
                    target: GlobalStates
                    function onQuickActionsOpenChanged() {
                        if (GlobalStates.quickActionsOpen && isActive && qaLoader.item) {
                            qaLoader.item.reset();
                            qaLoader.item.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
