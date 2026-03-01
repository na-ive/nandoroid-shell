import QtQuick
import QtQuick.Controls
import "../core"

Flickable {
    id: root
    maximumFlickVelocity: 3500
    boundsBehavior: Flickable.DragOverBounds

    property real touchpadScrollFactor: (Config.ready && Config.options.interactions && Config.options.interactions.scrolling) ? Config.options.interactions.scrolling.touchpadScrollFactor : 100
    property real mouseScrollFactor: (Config.ready && Config.options.interactions && Config.options.interactions.scrolling) ? Config.options.interactions.scrolling.mouseScrollFactor : 50
    property real mouseScrollDeltaThreshold: (Config.ready && Config.options.interactions && Config.options.interactions.scrolling) ? Config.options.interactions.scrolling.mouseScrollDeltaThreshold : 120
    // Accumulated scroll destination so wheel deltas stack while animating
    property real scrollTargetY: 0

    ScrollBar.vertical: StyledScrollBar {}

    MouseArea {
        visible: (Config.ready && Config.options.interactions && Config.options.interactions.scrolling) ? Config.options.interactions.scrolling.fasterTouchpadScroll : false
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheelEvent) {
            const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;
            // The angleDelta.y of a touchpad is usually small and continuous,
            // while that of a mouse wheel is typically in multiples of ±120.
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold ? root.mouseScrollFactor : root.touchpadScrollFactor;

            const maxY = Math.max(0, root.contentHeight - root.height);
            const base = scrollAnim.running ? root.scrollTargetY : root.contentY;
            var targetY = Math.max(0, Math.min(base - delta * scrollFactor, maxY));

            root.scrollTargetY = targetY;
            root.contentY = targetY;
            wheelEvent.accepted = true;
        }
    }

    Behavior on contentY {
        NumberAnimation {
            id: scrollAnim
            duration: (Appearance.animation && Appearance.animation.scroll) ? Appearance.animation.scroll.duration : 400
            easing.type: (Appearance.animation && Appearance.animation.scroll) ? Appearance.animation.scroll.type : Easing.BezierSpline
            easing.bezierCurve: (Appearance.animation && Appearance.animation.scroll) ? Appearance.animation.scroll.bezierCurve : [0.05, 0.7, 0.1, 1, 1, 1]
        }
    }

    // Keep target synced when not animating (e.g., drag/flick or programmatic changes)
    onContentYChanged: {
        if (!scrollAnim.running) {
            root.scrollTargetY = root.contentY;
        }
    }

}
