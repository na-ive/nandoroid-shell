import QtQuick
import "."
import "../core"

Revealer { // Scroll hint
    id: root
    property string icon
    property string side: "left"
    property string tooltipText: ""
    property bool hovered: false
    property color color: Appearance.colors.colStatusBarText
    reveal: hovered
    
    MouseArea {
        id: mouseArea
        anchors.right: root.side === "left" ? parent.right : undefined
        anchors.left: root.side === "right" ? parent.left : undefined
        implicitWidth: contentColumn.implicitWidth
        implicitHeight: contentColumn.implicitHeight
        property bool mouseHovered: false

        hoverEnabled: true
        onEntered: mouseHovered = true
        onExited: mouseHovered = false
        acceptedButtons: Qt.NoButton

        property bool showHintTimedOut: false
        onMouseHoveredChanged: showHintTimedOut = false
        Timer {
            running: mouseArea.mouseHovered
            interval: 500
            onTriggered: mouseArea.showHintTimedOut = true
        }

        StyledToolTip {
            extraVisibleCondition: (tooltipText.length > 0 && mouseArea.showHintTimedOut)
            text: tooltipText
        }

        Column {
            id: contentColumn
            anchors {
                fill: parent
            }
            spacing: -6
            MaterialSymbol {
                text: "keyboard_arrow_up"
                iconSize: 12
                color: root.color
            }
            MaterialSymbol {
                text: root.icon
                iconSize: 12
                color: root.color
            }
            MaterialSymbol {
                text: "keyboard_arrow_down"
                iconSize: 12
                color: root.color
            }
        }
    }
}
