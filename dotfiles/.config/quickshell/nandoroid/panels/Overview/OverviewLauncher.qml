import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"

/**
 * OverviewLauncher.qml
 * Launcher for the Hyprland Workspace Overview.
 */
PanelWindow {
    id: root
    
    // Controlled by global state
    property bool active: GlobalStates.overviewOpen
    
    // Visibility logic with fade out
    visible: active || (content && content.opacity > 0.01)
    
    // Layer and Focus
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nandoroid:overview"
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    // Fullscreen behavior
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    color: "transparent"
    
    // The actual Overview UI
    OverviewContent {
        id: content
        anchors.fill: parent
        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.98
        
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
        
        // Ensure focus goes here when opened
        focus: root.active
        
        // Handle closing
        Keys.onEscapePressed: GlobalStates.overviewOpen = false
    }
    
    // Proactive refresh on show
    onActiveChanged: {
        if (active) {
            HyprlandData.updateAll();
        }
    }
}
