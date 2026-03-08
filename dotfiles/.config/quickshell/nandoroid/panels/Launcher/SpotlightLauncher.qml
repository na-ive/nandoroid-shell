import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../widgets"

PanelWindow {
    id: root
    
    visible: GlobalStates.spotlightOpen || (content && content.opacity > 0)
    
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.namespace: "quickshell:spotlight"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.spotlightOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: GlobalStates.spotlightOpen
    }

    color: "transparent"
    
    onVisibleChanged: {
        if (visible) {
            LauncherSearch.query = "";
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.spotlightOpen = false
    }
    
    readonly property var screen: Quickshell.screens[0]

    SpotlightContent {
        id: content
        
        width: Math.min(root.width * 0.5, 750) 
        height: Math.min(root.height * 0.7, 550)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.15 
        
        opacity: 0
        scale: 1.0 

        states: [
            State {
                name: "visible"
                when: GlobalStates.spotlightOpen
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
