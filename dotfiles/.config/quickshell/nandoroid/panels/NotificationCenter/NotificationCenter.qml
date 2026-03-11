import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Notification Center panel — slides down from the left side of the status bar.
 * Contains: Media controls, Weather widget, Notification list.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: (GlobalStates.notificationCenterOpen && isActive) || contentLoader.opacity > 0
        
        exclusiveZone: (GlobalStates.notificationCenterOpen && isActive) && contentLoader.item ? contentLoader.item.implicitWidth : 0
        WlrLayershell.namespace: "nandoroid:notificationCenter"
        WlrLayershell.layer: ((GlobalStates.notificationCenterOpen || contentLoader.opacity > 0) && isActive) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.keyboardFocus: (GlobalStates.notificationCenterOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
        readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth : 1200
        readonly property real sidePadding: isCentered ? Math.round((modelData.width - Math.min(centeredWidth, modelData.width - 40)) / 2) : 0

        anchors {
            top: true
            left: true
        }

        WlrLayershell.margins {
            left: panelWindow.sidePadding
        }

        implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.notificationCenterOpen && isActive
            windows: [panelWindow]
            onCleared: {
                if (contentLoader.item) contentLoader.item.close();
                else GlobalStates.notificationCenterOpen = false;
            }
        }

        Connections {
            target: GlobalStates
            function onNotificationCenterOpenChanged() {
                if (!GlobalStates.notificationCenterOpen && contentLoader.item) contentLoader.item.close();
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: true 
            visible: (opacity > 0 && isActive) // Only visible (and animating) when actually opening/open
            enabled: GlobalStates.notificationCenterOpen && isActive
            
            transform: Translate {
                id: contentTransform
            }

            states: [
                State {
                    name: "open"
                    when: GlobalStates.notificationCenterOpen && isActive
                    PropertyChanges { target: contentLoader; opacity: 1 }
                    PropertyChanges { target: contentTransform; x: 0; y: 0 }
                },
                State {
                    name: "closed"
                    when: (!GlobalStates.notificationCenterOpen || !isActive)
                    PropertyChanges { target: contentLoader; opacity: 0 }
                    PropertyChanges { target: contentTransform; 
                        x: panelWindow.isCentered ? 0 : -contentLoader.width - 40;
                        y: panelWindow.isCentered ? -contentLoader.height - 40 : 0;
                    }
                }
            ]

            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation {
                            target: contentTransform
                            properties: "x,y"
                            duration: Appearance.animation.elementMove.duration
                            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                        }
                        NumberAnimation {
                            target: contentLoader
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
                            target: contentTransform
                            properties: "x,y"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                        NumberAnimation {
                            target: contentLoader
                            property: "opacity"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }
                }
            ]

            sourceComponent: NotificationCenterContent {
                onClosed: {
                    GlobalStates.notificationCenterOpen = false;
                }
            }
        }
    }
}
