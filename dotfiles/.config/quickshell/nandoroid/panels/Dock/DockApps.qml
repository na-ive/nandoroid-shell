import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../core"
import "../../services"
import "../../widgets"

/**
 * DockApps component
 * Displays the list of applications in the dock.
 * Simplified: Always uses OpacityMask for universal smooth fading.
 */
Item {
    id: root
    property real buttonPadding: 5
    property real spacing: 8 
    property int backgroundStyle: 1

    property Item lastHoveredButton
    property var lastHoveredAppData
    property bool buttonHovered: false
    
    readonly property real screenWidth: (parent && parent.parentWindow) ? parent.parentWindow.screen.width : 1920
    readonly property real maxWidth: screenWidth * 0.8 // Standard dock maximum width
    
    implicitWidth: Math.min(listView.contentWidth, maxWidth)
    
    signal requestContextMenu(var appData, real x, real y)
    signal buttonHoverChanged(Item button, var appData, bool hovered)

    Layout.fillHeight: true

    // Universal Fade Mask: Works perfectly for BG and No-BG modes
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: LinearGradient {
            width: root.width; height: root.height
            start: Qt.point(0, 0); end: Qt.point(width, 0)
            gradient: Gradient {
                GradientStop { position: 0.0; color: (listView.contentX > 5) ? "transparent" : "black" }
                GradientStop { position: 0.1; color: "black" }
                GradientStop { position: 0.9; color: "black" }
                GradientStop { position: 1.0; color: (listView.contentX < listView.contentWidth - listView.width - 5) ? "transparent" : "black" }
            }
        }
    }

    StyledListView {
        id: listView
        spacing: root.spacing 
        orientation: ListView.Horizontal
        anchors.fill: parent
        clip: false 
        interactive: contentWidth > root.maxWidth
        
        Behavior on contentX { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                const delta = event.angleDelta.y || event.angleDelta.x;
                listView.contentX = Math.max(0, Math.min(listView.contentX - delta, listView.contentWidth - listView.width));
            }
        }
        
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic } }
        Behavior on implicitWidth { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

        model: TaskbarApps.apps
        delegate: DockAppButton {
            id: appButton
            required property var modelData
            required property int index
            appToplevel: modelData
            appListRoot: root
            pointingHandCursor: true
            index: index
            dockTopInset: root.buttonPadding
            dockBottomInset: root.buttonPadding
            height: parent.height
            altAction: (event) => {
                const pos = appButton.mapToItem(null, event.x, event.y);
                root.requestContextMenu(modelData, pos.x, pos.y);
            }
        }
    }
}
