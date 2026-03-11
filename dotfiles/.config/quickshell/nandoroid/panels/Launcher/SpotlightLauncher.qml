import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: panelWindow
        required property var modelData
        screen: modelData

        readonly property bool isActive: GlobalStates.activeScreen === modelData
        visible: (GlobalStates.spotlightOpen && isActive) || (content && content.opacity > 0)
        
        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        WlrLayershell.namespace: "quickshell:spotlight"
        WlrLayershell.layer: (GlobalStates.spotlightOpen && isActive) ? WlrLayer.Overlay : WlrLayer.Background
        WlrLayershell.keyboardFocus: (GlobalStates.spotlightOpen && isActive) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            id: grab
            windows: [panelWindow]
            active: GlobalStates.spotlightOpen && isActive
        }

        color: "transparent"
        
        onVisibleChanged: {
            if (visible && isActive) {
                LauncherSearch.query = "";
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.spotlightOpen = false
        }
        
        SpotlightContent {
            id: content
            
            width: Math.min(panelWindow.width * 0.5, 750) 
            height: Math.min(panelWindow.height * 0.7, 550)
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.15 
            
            opacity: 0
            scale: 1.0 
            visible: isActive

            states: [
                State {
                    name: "visible"
                    when: GlobalStates.spotlightOpen && isActive
                    PropertyChanges { target: content; opacity: 1.0; scale: 1.0 }
                }
            ]
        
            transitions: [
                Transition {
                    from: ""
                    to: "visible"
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "opacity,scale"
                            duration: 200
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: ""
                    ParallelAnimation {
                        NumberAnimation {
                            properties: "opacity,scale"
                            duration: 250
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.emphasized
                        }
                    }
                }
            ]
            
            Keys.onEscapePressed: GlobalStates.spotlightOpen = false
        }
    }
}
