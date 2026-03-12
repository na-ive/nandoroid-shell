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
 * Updated: Using CSS-style mask-image (OpacityMask with Gradient) to fade apps out 
 * WITHOUT drawing solid colors that bleed over the dock's rounded corners.
 */
Item {
    id: root
    property real buttonPadding: 5
    property real spacing: 8 

    property Item lastHoveredButton
    property var lastHoveredAppData
    property bool buttonHovered: false
    
    readonly property real screenWidth: (parent && parent.parentWindow) ? parent.parentWindow.screen.width : 1920
    readonly property real maxWidth: screenWidth * 0.8 // Restored to 80% for production
    
    implicitWidth: Math.min(listView.contentWidth, maxWidth)
    
    signal requestContextMenu(var appData, real x, real y)
    signal buttonHoverChanged(Item button, var appData, bool hovered)

    Layout.fillHeight: true

    // The Gradient Mask
    // Black means "visible", Transparent means "hidden"
    LinearGradient {
        id: fadeMask
        anchors.fill: parent
        start: Qt.point(0, 0)
        end: Qt.point(width, 0)
        visible: false // Hidden, used only as mask
        
        property bool showLeftFade: listView.contentWidth > root.maxWidth && listView.contentX > 5
        property bool showRightFade: listView.contentWidth > root.maxWidth && listView.contentX < (listView.contentWidth - listView.width - 5)
        
        // Create a 32px fade zone at the edges
        property real leftStop: width > 0 ? Math.min(0.3, 32 / width) : 0.0
        property real rightStop: width > 0 ? Math.max(0.7, 1.0 - (32 / width)) : 1.0

        gradient: Gradient {
            GradientStop { position: 0.0; color: fadeMask.showLeftFade ? "transparent" : "black" }
            GradientStop { position: fadeMask.leftStop; color: "black" }
            
            GradientStop { position: fadeMask.rightStop; color: "black" }
            GradientStop { position: 1.0; color: fadeMask.showRightFade ? "transparent" : "black" }
        }
    }

    // The Content
    Item {
        anchors.fill: parent
        
        // Apply the gradient mask to this layer
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: fadeMask
        }

        StyledListView {
            id: listView
            spacing: root.spacing 
            orientation: ListView.Horizontal
            anchors.fill: parent
            
            clip: false 
            interactive: contentWidth > root.maxWidth
            
            Behavior on contentX {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (event) => {
                    const delta = event.angleDelta.y || event.angleDelta.x;
                    listView.contentX = Math.max(0, Math.min(listView.contentX - delta, listView.contentWidth - listView.width));
                }
            }
            
            displaced: Transition {
                NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
            }

            Behavior on implicitWidth {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

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
}
