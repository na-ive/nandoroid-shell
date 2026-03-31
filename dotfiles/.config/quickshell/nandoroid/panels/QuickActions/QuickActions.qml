import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Quick Actions panel — floating HUD at the bottom.
 * Uses a full-screen PanelWindow for reliable centering and slide animation.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: (GlobalStates.quickActionsOpen && isActive) || content.opacity > 0
        
        // Fill the screen
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        WlrLayershell.namespace: "nandoroid:quickactions"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.quickActionsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        // Handle focus
        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.quickActionsOpen && isActive
            windows: [panelWindow]
            onCleared: {
                GlobalStates.quickActionsOpen = false;
            }
        }

        // Close on click outside
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.quickActionsOpen = false
        }

        QuickActionsContent {
            id: content
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
                        target: content
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
                            target: content
                            property: "anchors.bottomMargin"
                            duration: 300
                            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                        }
                        NumberAnimation {
                            target: content
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
                            target: content
                            property: "anchors.bottomMargin"
                            to: -content.height
                            duration: 300
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                        NumberAnimation {
                            target: content
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                    }
                }
            ]

            onClosed: {
                GlobalStates.quickActionsOpen = false;
            }
            
            Connections {
                target: GlobalStates
                function onQuickActionsOpenChanged() {
                    if (GlobalStates.quickActionsOpen && isActive) {
                        content.reset();
                        content.forceActiveFocus();
                    }
                }
            }
        }
    }
}
