import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Quick Settings panel — positioned top-right, directly below the status bar.
 * Uses HyprlandFocusGrab for click-outside-to-close (same pattern as NotificationCenter).
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: (GlobalStates.quickSettingsOpen && isActive) || content.opacity > 0
        
        exclusiveZone: (GlobalStates.quickSettingsOpen && isActive) ? content.implicitWidth : 0
        WlrLayershell.namespace: "nandoroid:quicksettings"
        WlrLayershell.layer: ((GlobalStates.quickSettingsOpen || content.opacity > 0) && isActive) ? WlrLayer.Top : WlrLayer.Background
        WlrLayershell.keyboardFocus: (GlobalStates.quickSettingsOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        readonly property bool isCentered: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.layoutStyle === "centered" : false
        readonly property real centeredWidth: (Config.ready && Config.options.statusBar) ? Config.options.statusBar.centeredWidth : 1200
        readonly property real sidePadding: isCentered ? Math.round((modelData.width - Math.min(centeredWidth, modelData.width - 40)) / 2) : 0

        anchors {
            top: true
            right: true
        }

        WlrLayershell.margins {
            right: panelWindow.sidePadding
        }

        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.quickSettingsOpen && !GlobalStates.isPickingFile && isActive
            windows: [panelWindow]
            onCleared: {
                if (!GlobalStates.isPickingFile) {
                    content.close();
                }
            }
        }

        Connections {
            target: GlobalStates
            function onQuickSettingsOpenChanged() {
                if (!GlobalStates.quickSettingsOpen) content.close();
            }
        }

        QuickSettingsContent {
            id: content
            anchors.fill: parent
            visible: (opacity > 0 && isActive) // Only visible (and animating) when actually opening/open
            enabled: GlobalStates.quickSettingsOpen && isActive
            
            transform: Translate {
                id: contentTransform
            }

            states: [
                State {
                    name: "open"
                    when: GlobalStates.quickSettingsOpen && isActive
                    PropertyChanges { target: content; opacity: 1 }
                    PropertyChanges { target: contentTransform; x: 0; y: 0 }
                },
                State {
                    name: "closed"
                    when: (!GlobalStates.quickSettingsOpen || !isActive)
                    PropertyChanges { target: content; opacity: 0 }
                    PropertyChanges { target: contentTransform; 
                        x: panelWindow.isCentered ? 0 : content.width + 40;
                        y: panelWindow.isCentered ? -content.height - 40 : 0;
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
                            target: content
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
                            target: content
                            property: "opacity"
                            duration: Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }
                }
            ]

            onClosed: {
                GlobalStates.quickSettingsOpen = false;
                GlobalStates.quickSettingsEditMode = false;
            }
        }
    }
}
