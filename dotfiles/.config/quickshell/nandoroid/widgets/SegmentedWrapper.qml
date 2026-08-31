import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../core"

/**
 * SegmentedWrapper: A universal wrapper for segmented UI elements.
 * Automatically handles corner-radius logic based on position and active state.
 * Optimized for stability and smooth transitions using native Rectangle properties.
 */
Item {
    id: root
    
    // Marking this as a segmented wrapper for auto-detection logic
    readonly property bool isSegmentedWrapper: true
    
    // ── Input Properties ──
    property bool active: false
    property int orientation: Qt.Horizontal // Qt.Horizontal or Qt.Vertical
    property bool pillOnActive: true // Keep pill shape when active?
    
    // Manual Overrides (using var to allow checking for undefined/null)
    property var forceFirst: undefined
    property var forceLast: undefined
    property bool forcePill: false
    property bool forceNotStandalone: false
    
    // ── Style Properties ──
    property color color: "transparent"
    property bool hasShadow: false
    property var maxRadius: undefined
    property real fullRadius: maxRadius !== undefined ? maxRadius : (implicitHeight > 0 ? implicitHeight / 2 : 20 * Appearance.effectiveScale)
    property real smallRadius: 8 * Appearance.effectiveScale // M3 Connected Button Group inner radius for Size M
    
    implicitWidth: 40 * Appearance.effectiveScale
    implicitHeight: 40 * Appearance.effectiveScale
    
    // ── Auto-Detection Logic ──
    property bool isFirst: forceFirst !== undefined ? forceFirst : _autoIsFirst
    property bool isLast: forceLast !== undefined ? forceLast : _autoIsLast

    property bool _autoIsFirst: true
    property bool _autoIsLast: true

    function updatePosition() {
        if (!parent) {
            _autoIsFirst = true;
            _autoIsLast = true;
            return;
        }
        let siblings = [];
        let pChildren = parent.children;
        if (!pChildren) return;
        
        for (let i = 0; i < pChildren.length; i++) {
            let child = pChildren[i];
            if (!child || !child.visible) continue;
            
            let isCandidate = (child === root);
            if (!isCandidate) {
                try {
                    if (child.isSegmentedWrapper === true || child["isSegmentedWrapper"] === true) {
                        isCandidate = true;
                    }
                } catch(e) {}
                
                if (!isCandidate) {
                    try {
                        let name = child.toString();
                        if (name.indexOf("Segmented") !== -1 || name.indexOf("Wrapper") !== -1) {
                            isCandidate = true;
                        }
                    } catch(e) {}
                }
            }
            if (isCandidate) siblings.push(child);
        }

        if (siblings.length > 0) {
            _autoIsFirst = (siblings[0] === root);
            _autoIsLast = (siblings[siblings.length - 1] === root);
        } else {
            _autoIsFirst = true;
            _autoIsLast = true;
        }
    }

    function notifySiblings() {
        updatePosition();
        if (!parent) return;
        let pChildren = parent.children;
        if (!pChildren) return;
        for (let i = 0; i < pChildren.length; i++) {
            let child = pChildren[i];
            if (child && typeof child.updatePosition === "function") {
                child.updatePosition();
            }
        }
    }

    Component.onCompleted: Qt.callLater(notifySiblings)
    onParentChanged: Qt.callLater(notifySiblings)
    onVisibleChanged: Qt.callLater(notifySiblings)
    
    // Standalone logic: only true if both first and last, AND not explicitly managed to be otherwise.
    readonly property bool isStandalone: {
        if (forcePill) return true;
        if (forceNotStandalone) return false;

        // If user manually set one boundary but not the other, they imply it's part of a group.
        if (forceFirst === true && forceLast === false) return false;
        if (forceFirst === false && forceLast === true) return false;

        // Both explicitly true → definitively a single standalone item.
        if (forceFirst === true && forceLast === true) return true;

        return isFirst && isLast;
    }
    
    // ── Radius Logic ──
    readonly property real rTopLeft: {
        if ((active && pillOnActive) || isStandalone || forcePill) return fullRadius;
        if (orientation === Qt.Horizontal) return isFirst ? fullRadius : smallRadius;
        return isFirst ? fullRadius : smallRadius;
    }
    readonly property real rTopRight: {
        if ((active && pillOnActive) || isStandalone || forcePill) return fullRadius;
        if (orientation === Qt.Horizontal) return isLast ? fullRadius : smallRadius;
        return isFirst ? fullRadius : smallRadius;
    }
    readonly property real rBottomLeft: {
        if ((active && pillOnActive) || isStandalone || forcePill) return fullRadius;
        if (orientation === Qt.Horizontal) return isFirst ? fullRadius : smallRadius;
        return isLast ? fullRadius : smallRadius;
    }
    readonly property real rBottomRight: {
        if ((active && pillOnActive) || isStandalone || forcePill) return fullRadius;
        if (orientation === Qt.Horizontal) return isLast ? fullRadius : smallRadius;
        return isLast ? fullRadius : smallRadius;
    }

    // Mask Source declared as a sibling to ensure stable rendering and antialiasing
    Rectangle {
        id: maskRect
        visible: false
        width: root.width
        height: root.height
        antialiasing: true
        topLeftRadius: root.rTopLeft
        topRightRadius: root.rTopRight
        bottomLeftRadius: root.rBottomLeft
        bottomRightRadius: root.rBottomRight
        
        Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
        Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
        Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
        Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
    }

    StyledRectangularShadow {
        target: root
        visible: root.hasShadow
        z: -1
    }

    // ── Main Layout Container (With Clipping) ──
    Item {
        id: container
        anchors.fill: parent
        
        layer.enabled: false
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: maskRect
        }

        // ── Background ──
        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: root.color
            visible: root.color !== "transparent"
            antialiasing: true
            
            topLeftRadius: root.rTopLeft
            topRightRadius: root.rTopRight
            bottomLeftRadius: root.rBottomLeft
            bottomRightRadius: root.rBottomRight
            
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(bgRect) }
            Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
            Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
            Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
            Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
        }

        // ── Content container ──
        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    default property alias content: contentItem.data
}
