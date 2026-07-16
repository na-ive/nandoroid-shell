import QtQuick
import Quickshell
import "../../core"

/*
 * Generic Widget Wrapper for Drag and Drop with Snap to Grid
 * 
 * HOW TO USE FOR NEW WIDGETS:
 * ---------------------------
 * 1. Define your widget inside an AbstractWidget wrapper in DesktopWidgets.qml
 * 2. Pass its config reference: `configObject: Config.options.appearance.yourWidget`
 * 3. AbstractWidget will automatically read the `locked` property from that config
 *    and disable drag-and-drop if it's locked.
 * 4. Use `onDragFinished` if you need to save the new X/Y coordinates manually 
 *    (e.g., for custom alignment logic like the clock has).
 */
MouseArea {
    id: root
    property bool animateXPos: !root.dragging && root.isLoaded
    property bool animateYPos: !root.dragging && root.isLoaded
    property var configObject: null
    property bool draggable: configObject ? !configObject.locked : true
    property int gridSize: 12
    property bool snapEnabled: true
    property string snapAlign: "left"
    property int centerSnapMargin: 6
    readonly property bool dragging: drag.active

    signal dragFinished(real newX, real newY)
    signal requestContextMenu(real reqX, real reqY)

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    drag.target: draggable ? dragProxy : undefined
    // Use the same cursor logic (SizeAllCursor when hovering over a draggable widget, OpenHand/ClosedHand when dragging)
    cursorShape: (draggable && containsPress) ? Qt.ClosedHandCursor : draggable ? Qt.SizeAllCursor : Qt.ArrowCursor

    onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
            let p = mapToGlobal(mouse.x, mouse.y);
            requestContextMenu(p.x, p.y);
            mouse.accepted = true;
        }
    }

    function center() {
        if (root.parent) {
            root.x = (root.parent.width - root.width) / 2
            root.y = (root.parent.height - root.height) / 2
        }
    }

    function snapX(value) {
        if (!root.parent) return value;
        let centerTarget = (root.parent.width - root.width) / 2;
        if (Math.abs(value - centerTarget) < centerSnapMargin) {
            return centerTarget;
        }

        if (snapAlign === "right") {
            let rightEdge = value + root.width;
            let snappedRight = Math.round(rightEdge / root.gridSize) * root.gridSize;
            return snappedRight - root.width;
        } else if (snapAlign === "center") {
            let centerPoint = value + root.width / 2;
            let snappedCenter = Math.round(centerPoint / root.gridSize) * root.gridSize;
            return snappedCenter - root.width / 2;
        }

        return Math.round(value / root.gridSize) * root.gridSize;
    }

    function snapY(value) {
        if (!root.parent) return value;
        let centerTarget = (root.parent.height - root.height) / 2;
        if (Math.abs(value - centerTarget) < centerSnapMargin) {
            return centerTarget;
        }
        return Math.round(value / root.gridSize) * root.gridSize;
    }

    function findCanvas(item) {
        var p = item
        while (p) {
            if (p.isWidgetCanvas === true) return p
            p = p.parent
        }
        return null
    }

    Item {
        id: dragProxy
        parent: root.parent
        x: root.x
        y: root.y
    }

    Binding {
        target: root
        property: "x"
        value: root.snapEnabled ? root.snapX(dragProxy.x) : dragProxy.x
        when: root.dragging
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root
        property: "y"
        value: root.snapEnabled ? root.snapY(dragProxy.y) : dragProxy.y
        when: root.dragging
        restoreMode: Binding.RestoreNone
    }

    onXChanged: updateCanvasCenterLines()
    onYChanged: updateCanvasCenterLines()

    function updateCanvasCenterLines() {
        if (!dragging) return;
        var canvas = findCanvas(root.parent)
        if (canvas && root.parent) {
            let cx = (root.parent.width - root.width) / 2
            let cy = (root.parent.height - root.height) / 2
            canvas.activeCenterX = Math.abs(x - cx) < 1
            canvas.activeCenterY = Math.abs(y - cy) < 1
        }
    }

    onDraggingChanged: {
        var canvas = findCanvas(root.parent)
        if (canvas) {
            canvas.setDragging(dragging)
            if (!dragging) {
                canvas.activeCenterX = false
                canvas.activeCenterY = false
            }
        }

        dragProxy.x = root.x
        dragProxy.y = root.y

        if (!dragging) {
            root.dragFinished(root.x, root.y)
        }
    }

    property bool isLoaded: false
    Timer {
        interval: 500
        running: true
        onTriggered: root.isLoaded = true
    }

    Behavior on x {
        enabled: animateXPos
        NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
    }
    Behavior on y {
        enabled: animateYPos
        NumberAnimation { duration: 300; easing.type: Easing.OutExpo }
    }
}
