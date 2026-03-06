import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../widgets"
import "../../services"
import "../../core"

RippleButton {
    id: root
    
    property var app: null
    property bool selected: false
    readonly property string subtitle: (app && app.subtitle) ? app.subtitle : ""
    
    // Icon Source logic
    readonly property bool isPlugin: Boolean(app && app.isPlugin)
    readonly property string iconSource: isPlugin ? "" : Quickshell.iconPath(app ? app.icon : "application-x-executable", "image-missing")

    width: 90
    height: 110
    
    colBackground: root.selected ? Qt.alpha(Appearance.m3colors.m3primary, 0.1) : "transparent"
    buttonRadius: 12
    
    onClicked: {
        if (app) {
            app.execute();
            GlobalStates.launcherOpen = false;
        }
    }
    
    Column {
        anchors.centerIn: parent
        spacing: 4
        width: parent.width - 16
        
        Item {
            width: 56
            height: 56
            anchors.horizontalCenter: parent.horizontalCenter

            MaterialShape {
                id: iconBg
                anchors.fill: parent
                color: (root.hovered || root.selected) ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceVariant
                shapeString: Config.ready ? Config.options.search.iconShape : "Square"
                borderWidth: 1
                borderColor: Qt.rgba(0, 0, 0, 0.1)
                
                IconImage {
                    id: iconImg
                    source: app ? Quickshell.iconPath(app.icon || "application-x-executable", "image-missing") : ""
                    visible: app && !app.isPlugin && !app.emoji
                    width: 32
                    height: 32
                    anchors.centerIn: parent
                }


                MaterialSymbol {
                    text: (app && app.isPlugin) ? app.icon : ""
                    visible: app && app.isPlugin && !app.emoji
                    iconSize: 32
                    anchors.centerIn: parent
                    color: (root.hovered || root.selected) ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
                }

                StyledText {
                    text: (app && app.emoji) ? app.emoji : ""
                    visible: app && app.emoji !== ""
                    font.pixelSize: 32
                    anchors.centerIn: parent
                }
            }
        }
        
        Column {
            width: parent.width
            spacing: 0
            
            StyledText {
                text: app ? app.name : ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: 12
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                font.weight: root.selected ? Font.Bold : Font.Medium
            }

            StyledText {
                text: root.subtitle
                visible: text !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: 10
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                opacity: 0.8
            }
        }
    }
}
