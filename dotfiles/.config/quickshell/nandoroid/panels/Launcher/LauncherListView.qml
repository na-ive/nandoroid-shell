import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import "../../widgets"
import "../../core"

RippleButton {
    id: root
    
    property var result: modelData
    property bool selected: false
    
    width: parent ? parent.width : 0
    height: 64
    
    colBackground: root.selected ? Qt.alpha(Appearance.m3colors.m3primary, 0.1) : "transparent"
    buttonRadius: 12
    
    onClicked: {
        if (result) {
            result.execute();
            GlobalStates.launcherOpen = false;
            GlobalStates.spotlightOpen = false;
        }
    }
    
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16
        
        // Icon Container
        Item {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter

            MaterialShape {
                id: iconBg
                anchors.fill: parent
                shapeString: Config.ready ? Config.options.search.iconShape : "Square"
                color: (root.hovered || root.selected) ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceVariant
                borderWidth: 1
                borderColor: Qt.rgba(0, 0, 0, 0.1)
                
                IconImage {
                    id: iconImg
                    source: (result && !result.isPlugin) ? Quickshell.iconPath(result.icon || "application-x-executable", "image-missing") : ""
                    visible: result && !result.isPlugin && result.emoji === ""
                    width: 20
                    height: 20
                    anchors.centerIn: parent
                }

                StyledText {
                    text: result.emoji || ""
                    visible: result && result.emoji !== ""
                    anchors.centerIn: parent
                    font.pixelSize: 20
                }
                
                MaterialSymbol {
                    text: (result && result.isPlugin) ? (result.icon || "extension") : ""
                    visible: result && result.isPlugin && result.emoji === "" && !result.isImage
                    iconSize: 20
                    anchors.centerIn: parent
                    color: (root.hovered || root.selected) ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
                }

                ThumbnailImage {
                    anchors.fill: parent
                    sourcePath: (result && result.isImage) ? result.imagePath : ""
                    visible: !!(result && result.isImage)
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }
        Column {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            spacing: 0
            
            StyledText {
                text: (result && result.name) ? result.name : ""
                font.pixelSize: 15
                font.weight: root.selected ? Font.Bold : Font.Medium
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                elide: Text.ElideRight
            }
            
            StyledText {
                text: (result && result.subtitle) ? result.subtitle : ""
                visible: text !== ""
                font.pixelSize: 11
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                opacity: 0.7
                elide: Text.ElideRight
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignVCenter
            text: (result && result.category) ? result.category : (result && result.isPlugin ? "Command" : "Application")
            font.pixelSize: 12
            color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
            opacity: 0.5
        }
    }
}
