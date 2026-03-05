import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

RippleButton {
    id: card
    property string label: ""
    property var cardColors: ["transparent", "transparent", "transparent"]
    property bool isSelected: false
    
    implicitWidth: 104
    implicitHeight: 120
    buttonRadius: 28
    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: Appearance.colors.colLayer2 // Handled by border
    colText: "white"
    colTextToggled: "white"
    colRipple: Appearance.colors.colLayer2Active

    contentItem: Item {
        anchors.fill: parent
        
        // Custom background with 3 bars
        Rectangle {
            id: cardContent
            anchors.fill: parent
            radius: card.buttonRadius
            clip: true
            color: Appearance.colors.colLayer2
            
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: cardContent.width
                    height: cardContent.height
                    radius: cardContent.radius
                }
            }

            Row {
                anchors.fill: parent
                Rectangle { width: parent.width/3; height: parent.height; color: card.cardColors[0] }
                Rectangle { width: parent.width/3; height: parent.height; color: card.cardColors[1] }
                Rectangle { width: parent.width/3; height: parent.height; color: card.cardColors[2] }
            }
            
            // Bottom Gradient for text readability
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 48
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.6) }
                }
            }
        }
        
        // Selection Border / Glow
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 3
            border.color: Appearance.m3colors.m3primary
            radius: card.buttonRadius
            visible: card.isSelected
            opacity: 0.8
        }

        // Label
        StyledText {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Medium
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 0.9
            maximumLineCount: 2
            width: parent.width - 12
        }
        
        // Centered Checkmark in Circle
        Rectangle {
            anchors.centerIn: parent
            width: 32
            height: 32
            radius: 16
            color: "#1A1C1E"
            visible: card.isSelected
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: "check"
                iconSize: 20
                color: "white"
            }
        }
    }
}
