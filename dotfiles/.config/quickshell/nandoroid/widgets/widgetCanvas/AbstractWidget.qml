import QtQuick
import Quickshell
import "../../core"

/*
 * Smart Widget Wrapper for Drag and Drop with Enhanced Grid System
 *
 * FEATURES:
 * ---------
 * - Pixel-perfect snap grid (12px)
 * - Smart center snap that respects grid
 * - Widget-to-widget edge snap (Photoshop-style guides)
 * - Live helper gap detection during drag
 * - Gap distance visualization
 *
 * SNAP PRIORITY:
 *   2 — Widget edge/center snap (threshold: 4px)
 *   1 — Screen center snap + gap snap (gap threshold: gridSize)
 *   0 — Grid snap (fallback, only when no other snap matches)
 *
 * ─────────────────────────────────────────────────────────────
 * nandoroid SMART GRID SYSTEM SPECIFICATION
 * ─────────────────────────────────────────────────────────────
 * - Snap Grid: 12px
 * - Widget Snap Threshold: 4px
 * ─────────────────────────────────────────────────────────────
 */
MouseArea {
    id: root
    property bool isAbstractWidget: true
    property bool animateXPos: !root.dragging && root.isLoaded
    property bool animateYPos: !root.dragging && root.isLoaded
    property var configObject: null
    property bool draggable: configObject ? !configObject.locked : true
    property int gridSize: 12
    property bool snapEnabled: true
    property string snapAlign: "left"
    property int snapThreshold: 4
    readonly property bool dragging: drag.active

    signal dragFinished(real newX, real newY)
    signal requestContextMenu(real reqX, real reqY)

    // Smart helper system
    readonly property bool useSmartHelpers: Config.ready && Config.options.appearance.background ? Config.options.appearance.background.showSnapLines : false
    property var widgetEdges: []

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    drag.target: draggable ? dragProxy : undefined
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

    function findCanvas(item) {
        var p = item
        while (p) {
            if (p.isWidgetCanvas === true) return p
            p = p.parent
        }
        return null
    }

    // Collect all visible sibling widget edges
    function refreshWidgetEdges() {
        if (!root.parent) return;
        let canvas = findCanvas(root.parent);
        if (!canvas) return;

        widgetEdges = [];

        canvas.children.forEach(child => {
            if (child.isAbstractWidget && child !== root && child.visible && child.width > 0 && child.height > 0) {
                widgetEdges.push({
                    left: child.x,
                    right: child.x + child.width,
                    top: child.y,
                    bottom: child.y + child.height,
                    cx: child.x + child.width / 2,
                    cy: child.y + child.height / 2
                });
            }
        });
    }

    // Unified smart snap: builds candidate list, picks highest priority match
    function smartSnap(axis, value) {
        if (!root.parent) return value;

        let size = axis === "x" ? root.width : root.height;
        let parentSize = axis === "x" ? root.parent.width : root.parent.height;
        let isX = axis === "x";
        let snapped = value;
        let bestPrio = -1;
        let candidates = [];

        if (useSmartHelpers) {
            for (let i = 0; i < widgetEdges.length; i++) {
                let w = widgetEdges[i];
                let near = isX ? w.left : w.top;
                let far  = isX ? w.right : w.bottom;
                let cntr = isX ? w.cx : w.cy;

                candidates.push({ pos: near,            prio: 2, thr: snapThreshold });
                candidates.push({ pos: far - size,      prio: 2, thr: snapThreshold });
                candidates.push({ pos: far,             prio: 2, thr: snapThreshold });
                candidates.push({ pos: near - size,     prio: 2, thr: snapThreshold });
                candidates.push({ pos: cntr - size / 2, prio: 2, thr: snapThreshold });
                candidates.push({ pos: near - size - root.gridSize, prio: 1, thr: root.gridSize });
                candidates.push({ pos: far + root.gridSize,         prio: 1, thr: root.gridSize });
            }
        }
        candidates.push({ pos: (parentSize - size) / 2, prio: 1, thr: snapThreshold });

        for (let i = 0; i < candidates.length; i++) {
            let c = candidates[i];
            if (c.prio > bestPrio && Math.abs(value - c.pos) < c.thr) {
                snapped = c.pos;
                bestPrio = c.prio;
            }
        }

        if (bestPrio < 1) {
            if (isX && snapAlign !== "left") {
                let offset = snapAlign === "right" ? size : size / 2;
                snapped = Math.round((value + offset) / root.gridSize) * root.gridSize - offset;
            } else {
                snapped = Math.round(value / root.gridSize) * root.gridSize;
            }
        }

        return snapped;
    }

    // During drag, show snap guides and gap hints like Photoshop
    function updateDragHelpers() {
        if (!root.dragging) return;
        refreshWidgetEdges();
        let canvas = findCanvas(root.parent);
        if (!canvas || !useSmartHelpers) return;

        let myLeft = root.x;
        let myRight = root.x + root.width;
        let myTop = root.y;
        let myBottom = root.y + root.height;
        let myCx = myLeft + root.width / 2;
        let myCy = myTop + root.height / 2;
        let maxDist = 80;

        let vguides = [];
        let hguides = [];
        let gapHints = [];

        // Center lines (always on)
        vguides.push(root.parent.width / 2);
        hguides.push(root.parent.height / 2);

        for (let i = 0; i < widgetEdges.length; i++) {
            let w = widgetEdges[i];

            // ── Horizontal gap hints (dragged widget ↔ other widget) ──
            // Check if my right edge is near their left edge (gap between us horizontally)
            let gapR = Math.round(w.left - myRight);
            if (gapR > 0 && gapR < maxDist) {
                let midX = myRight + gapR / 2;
                let overlapTop = Math.max(myTop, w.top);
                let overlapBottom = Math.min(myBottom, w.bottom);
                let overlapY = overlapBottom - overlapTop;
                if (overlapY > 0) {
                    vguides.push(myRight);
                    vguides.push(w.left);
                    if (gapR % root.gridSize === 0)
                        gapHints.push({ pos: midX, gap: gapR, isVertical: true, perpPos: (overlapTop + overlapBottom) / 2 });
                }
            }
            // Check if my left edge is near their right edge
            let gapL = Math.round(myLeft - w.right);
            if (gapL > 0 && gapL < maxDist) {
                let midX = w.right + gapL / 2;
                let overlapTop = Math.max(myTop, w.top);
                let overlapBottom = Math.min(myBottom, w.bottom);
                let overlapY = overlapBottom - overlapTop;
                if (overlapY > 0) {
                    vguides.push(w.right);
                    vguides.push(myLeft);
                    if (gapL % root.gridSize === 0)
                        gapHints.push({ pos: midX, gap: gapL, isVertical: true, perpPos: (overlapTop + overlapBottom) / 2 });
                }
            }

            // ── Vertical gap hints (dragged widget ↔ other widget) ──
            let gapB = Math.round(w.top - myBottom);
            if (gapB > 0 && gapB < maxDist) {
                let midY = myBottom + gapB / 2;
                let overlapLeft = Math.max(myLeft, w.left);
                let overlapRight = Math.min(myRight, w.right);
                let overlapX = overlapRight - overlapLeft;
                if (overlapX > 0) {
                    hguides.push(myBottom);
                    hguides.push(w.top);
                    if (gapB % root.gridSize === 0)
                        gapHints.push({ pos: midY, gap: gapB, isVertical: false, perpPos: (overlapLeft + overlapRight) / 2 });
                }
            }
            let gapT = Math.round(myTop - w.bottom);
            if (gapT > 0 && gapT < maxDist) {
                let midY = w.bottom + gapT / 2;
                let overlapLeft = Math.max(myLeft, w.left);
                let overlapRight = Math.min(myRight, w.right);
                let overlapX = overlapRight - overlapLeft;
                if (overlapX > 0) {
                    hguides.push(w.bottom);
                    hguides.push(myTop);
                    if (gapT % root.gridSize === 0)
                        gapHints.push({ pos: midY, gap: gapT, isVertical: false, perpPos: (overlapLeft + overlapRight) / 2 });
                }
            }

            // ── Gap hints between TWO existing widgets ──
            for (let j = i + 1; j < widgetEdges.length; j++) {
                let w2 = widgetEdges[j];

                // Vertical gap between two existing widgets
                let topW = w.top < w2.top ? w : w2;
                let botW = w.top < w2.top ? w2 : w;
                let existGapV = Math.round(botW.top - topW.bottom);
                if (existGapV > 0 && existGapV < maxDist && existGapV % root.gridSize === 0) {
                    let midY = topW.bottom + existGapV / 2;
                    let overlapLeft = Math.max(topW.left, botW.left);
                    let overlapRight = Math.min(topW.right, botW.right);
                    let overlapX = overlapRight - overlapLeft;
                    // Check if dragged widget's X overlaps or is near this pair's X range
                    let xNear = myRight > overlapLeft - 60 && myLeft < overlapRight + 60;
                    if (overlapX > 0 && xNear) {
                        gapHints.push({ pos: midY, gap: existGapV, isVertical: false, perpPos: (overlapLeft + overlapRight) / 2 });
                    }
                }

                // Horizontal gap between two existing widgets
                let leftW = w.left < w2.left ? w : w2;
                let rightW = w.left < w2.left ? w2 : w;
                let existGapH = Math.round(rightW.left - leftW.right);
                if (existGapH > 0 && existGapH < maxDist && existGapH % root.gridSize === 0) {
                    let midX = leftW.right + existGapH / 2;
                    let overlapTop = Math.max(leftW.top, rightW.top);
                    let overlapBottom = Math.min(leftW.bottom, rightW.bottom);
                    let overlapY = overlapBottom - overlapTop;
                    // Check if dragged widget's Y overlaps or is near this pair's Y range
                    let yNear = myBottom > overlapTop - 60 && myTop < overlapBottom + 60;
                    if (overlapY > 0 && yNear) {
                        gapHints.push({ pos: midX, gap: existGapH, isVertical: true, perpPos: (overlapTop + overlapBottom) / 2 });
                    }
                }
            }
        }

        // De-duplicate
        vguides = [...new Set(vguides.map(Math.round))];
        hguides = [...new Set(hguides.map(Math.round))];

        canvas.updateGuides(vguides, hguides);
        canvas.updateGapHints(gapHints);
    }

    Item {
        id: dragProxy
        parent: root.parent
        x: root.x
        y: root.y
        onXChanged: if (root.dragging) dragDetectionTimer.restart();
        onYChanged: if (root.dragging) dragDetectionTimer.restart();
    }

    Binding {
        target: root
        property: "x"
        value: root.snapEnabled ? root.smartSnap("x", dragProxy.x) : dragProxy.x
        when: root.dragging
        restoreMode: Binding.RestoreNone
    }
    Binding {
        target: root
        property: "y"
        value: root.snapEnabled ? root.smartSnap("y", dragProxy.y) : dragProxy.y
        when: root.dragging
        restoreMode: Binding.RestoreNone
    }

    onXChanged: updateCanvasCenterLines();
    onYChanged: updateCanvasCenterLines();

    function updateCanvasCenterLines() {
        if (!dragging) return;
        var canvas = findCanvas(root.parent)
        if (canvas && root.parent) {
            let cx = (root.parent.width - root.width) / 2;
            let cy = (root.parent.height - root.height) / 2;
            canvas.activeCenterX = Math.abs(x - cx) < 1;
            canvas.activeCenterY = Math.abs(y - cy) < 1;
        }
    }

    onDraggingChanged: {
        if (dragging) {
            refreshWidgetEdges();
            updateDragHelpers();
        }
        var canvas = findCanvas(root.parent)
        if (canvas) {
            canvas.setDragging(dragging)
            if (!dragging) {
                canvas.activeCenterX = false
                canvas.activeCenterY = false
                canvas.clearWidgetAlignment()
                canvas.clearGuides()
                canvas.clearGapHints()
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

    // Periodic helper update during drag
    Timer {
        id: dragDetectionTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (root.dragging) {
                refreshWidgetEdges();
                updateDragHelpers();
            }
        }
    }

}
