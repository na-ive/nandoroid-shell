import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"

PanelWindow {
    id: root
    
    visible: GlobalStates.launcherOpen || (content && content.opacity > 0)
    
    // Fill the screen with a transparent window to handle clicks outside
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: GlobalStates.launcherOpen
    }

    color: "transparent"
    
    onVisibleChanged: {
        if (visible) {
            LauncherSearch.query = "";
        }
    }
    
    // Close on click outside (on the window background)
    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.launcherOpen = false
    }
    
    readonly property var screen: Quickshell.screens[0]

    LauncherContent {
        id: content
        
        width: screen.width * 0.5
        // Added 1px to hide the bottom border off-screen
        height: screen.height * 0.7 + 1
        x: (screen.width - width) / 2
        
        // Default state: below screen
        y: screen.height
        opacity: 0
        focus: true

        states: [
            State {
                name: "active"
                when: GlobalStates.launcherOpen
                PropertyChanges {
                    target: content
                    // Pushed 2px below screen to hide the border and avoid gaps
                    y: screen.height - height + 2
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
                        property: "y"
                        duration: 250
                        easing.type: Easing.BezierSpline
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
                        property: "y"
                        to: screen.height
                        duration: 300
                        easing.type: Easing.BezierSpline
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
        
        // Capture Escape key to close
        Keys.onEscapePressed: GlobalStates.launcherOpen = false
    }
}
