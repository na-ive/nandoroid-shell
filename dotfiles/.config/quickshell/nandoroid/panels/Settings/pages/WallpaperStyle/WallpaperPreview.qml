import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ColumnLayout {
    id: previewComp
    property string title
    property string source
    property bool showCheckmark: false
    property bool clickable: true
    signal clicked()
    spacing: 12
    Item {
        id: previewWrapper
        Layout.fillWidth: true
        Layout.preferredHeight: width * 9/16

        Rectangle {
            id: imgContainer
            anchors.fill: parent
            radius: 24; 
            color: Appearance.colors.colLayer1
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: imgContainer.width
                    height: imgContainer.height
                    radius: imgContainer.radius
                }
            }

            Image { 
                anchors.fill: parent; 
                source: previewComp.source
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }            
            // 1. Selection indicator (Primary tint) - Only when Synced/Selected
            Rectangle {
                anchors.fill: parent
                color: Appearance.colors.colPrimary
                opacity: previewComp.showCheckmark ? 0.3 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // 2. Hover overlay (High contrast for text: 30% Dark Grey)
            Rectangle {
                anchors.fill: parent
                color: "#1A1C1E"
                opacity: (previewComp.clickable && mouseArea.containsMouse) ? 0.3 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // 3. Hover Content (Icon + Text)
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8
                visible: previewComp.clickable && mouseArea.containsMouse
                
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "edit"
                    iconSize: 32
                    color: "white"
                }
                StyledText {
                    text: "Change wallpaper"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.DemiBold
                    color: "white"
                }
            }
            
            // Selection Checkmark
            Rectangle {
                width: 42; height: 42; radius: 21; anchors.centerIn: parent
                color: Appearance.colors.colPrimary
                visible: previewComp.showCheckmark
                MaterialSymbol { 
                    anchors.centerIn: parent; 
                    text: "check"; 
                    color: Appearance.colors.colOnPrimary; 
                    iconSize: 24 
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: previewComp.clickable
            preventStealing: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: previewComp.clicked()
        }
    }
    
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: title
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colSubtext
    }
}
