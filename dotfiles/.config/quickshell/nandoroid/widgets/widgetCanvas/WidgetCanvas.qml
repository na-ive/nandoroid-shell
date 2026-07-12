import QtQuick
import "../../core"

MouseArea {
    id: root
    property int gridSize: 24
    property bool showGrid: false
    readonly property bool isWidgetCanvas: true

    function setDragging(active) {
        root.showGrid = active
    }

    Repeater {
        model: root.showGrid ? Math.ceil(root.width / root.gridSize) : 0
        delegate: Rectangle {
            required property int index
            x: index * root.gridSize
            width: 1
            height: root.height
            color: Appearance.m3colors.m3outlineVariant
            opacity: 0.3
        }
    }

    Repeater {
        model: root.showGrid ? Math.ceil(root.height / root.gridSize) : 0
        delegate: Rectangle {
            required property int index
            y: index * root.gridSize
            width: root.width
            height: 1
            color: Appearance.m3colors.m3outlineVariant
            opacity: 0.3
        }
    }

    property bool activeCenterX: false
    property bool activeCenterY: false

    Rectangle {
        x: Math.round(root.width / 2)
        y: 0
        width: 1
        height: root.height
        color: Appearance.m3colors.m3primary
        visible: root.showGrid && root.activeCenterX
    }

    Rectangle {
        x: 0
        y: Math.round(root.height / 2)
        width: root.width
        height: 1
        color: Appearance.m3colors.m3primary
        visible: root.showGrid && root.activeCenterY
    }
}
