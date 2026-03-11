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
    property real spacing: 8 // Properti baru untuk kontrol jarak seragam

    property Item lastHoveredButton
    property bool buttonHovered: false
    
    Layout.fillHeight: true
    implicitWidth: listView.contentWidth
    
    StyledListView {
        id: listView
        spacing: root.spacing // Gunakan properti spacing dari root
        orientation: ListView.Horizontal
        anchors.fill: parent
        
        interactive: false 

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: TaskbarApps.apps
        
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            dockTopInset: root.buttonPadding
            dockBottomInset: root.buttonPadding
            
            height: parent.height
        }
    }
}
