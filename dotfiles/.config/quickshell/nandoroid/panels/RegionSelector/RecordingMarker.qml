import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../widgets"

PanelWindow {
    id: root
    
    // Only show if recording is active and it's a region recording (not fullscreen)
    visible: ScreenRecord.active && ScreenRecord.geometry !== "" && ScreenRecord.geometry !== "fullscreen"
    
    color: "transparent"
    WlrLayershell.namespace: "quickshell:recordingMarker"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    
    // We don't want this window to ever catch mouse/keyboard
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    mask: Region {} // Empty region makes the entire window click-through

    readonly property var geomData: {
        if (!ScreenRecord.geometry || ScreenRecord.geometry === "fullscreen") return null;
        // Format: "x,y WxH" (e.g. "100,200 500x400")
        try {
            const parts = ScreenRecord.geometry.split(" ");
            const pos = parts[0].split(",");
            const size = parts[1].split("x");
            return {
                x: parseInt(pos[0]),
                y: parseInt(pos[1]),
                width: parseInt(size[0]),
                height: parseInt(size[1])
            };
        } catch(e) {
            return null;
        }
    }

    // Set window geometry based on ScreenRecord.geometry
    // Note: geometry in ScreenRecord is relative to monitor, 
    // but PanelWindow anchors often default to screen or need specific positioning.
    // For simplicity, we'll anchor to all sides and draw the rectangle inside.
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Rectangle {
        id: marker
        visible: root.geomData !== null
        x: root.geomData ? root.geomData.x - 2 : 0
        y: root.geomData ? root.geomData.y - 2 : 0
        width: root.geomData ? root.geomData.width + 4 : 0
        height: root.geomData ? root.geomData.height + 4 : 0
        
        color: "transparent"
        
        DashedBorder {
            anchors.fill: parent
            color: Appearance.m3colors.m3error
            borderWidth: 2
            dashLength: 6
            gapLength: 3
        }
        
        // Pulsing animation
        opacity: 0.8
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { from: 0.8; to: 0.3; duration: 1000; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 0.3; to: 0.8; duration: 1000; easing.type: Easing.InOutQuad }
        }
    }
}
