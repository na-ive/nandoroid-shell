import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../services"
import "../../widgets"

/**
 * DockApps component
 * Displays the list of applications in the dock.
 */
Item {
    id: root
    property real buttonPadding: 5
    property real spacing: 8 

    property Item lastHoveredButton
    property bool buttonHovered: false
    
    signal requestContextMenu(var appData, real x, real y)

    Layout.fillHeight: true
    implicitWidth: listView.contentWidth
    
    StyledListView {
        id: listView
        spacing: root.spacing 
        orientation: ListView.Horizontal
        anchors.fill: parent
        
        interactive: false 

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: TaskbarApps.apps
        
        delegate: DockAppButton {
            id: appButton
            required property var modelData
            appToplevel: modelData
            appListRoot: root
            pointingHandCursor: true

            dockTopInset: root.buttonPadding
            dockBottomInset: root.buttonPadding
            
            height: parent.height

            // Use the altAction property from RippleButton
            altAction: (event) => {
                // Map the mouse position to the window coordinates
                const pos = appButton.mapToItem(null, event.x, event.y);
                root.requestContextMenu(modelData, pos.x, pos.y);
            }
        }
    }
}
