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
    property var maxRadius: undefined
    property real fullRadius: {
        let r = (height > 0 ? height : (implicitHeight > 0 ? implicitHeight : 40)) / 2
        if (maxRadius !== undefined) return Math.min(r, maxRadius);
        return r
    }
    property real smallRadius: Appearance.rounding.unsharpenmore || 6
    
    implicitWidth: 40
    implicitHeight: 40
    
    // ── Auto-Detection Logic ──
    readonly property var visibleSiblings: {
        // Trigger re-evaluation when children are added/removed
        let trigger = parent ? parent.children.length : 0; 
        
        if (!parent) return [root];
        let siblings = [];
        let pChildren = parent.children;
        if (!pChildren) return [root];
        
        for (let i = 0; i < pChildren.length; i++) {
            let child = pChildren[i];
            if (!child || !child.visible) continue;
            
            // Robust check for segmented candidates
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
        return siblings;
    }
    
    // Resolved Position
    readonly property bool isFirst: forceFirst !== undefined ? forceFirst : (visibleSiblings.length > 0 && visibleSiblings[0] === root)
    readonly property bool isLast: forceLast !== undefined ? forceLast : (visibleSiblings.length > 0 && visibleSiblings[visibleSiblings.length - 1] === root)
    
    // Standalone logic: only true if both first and last, AND not explicitly managed to be otherwise.
    readonly property bool isStandalone: {
        if (forcePill) return true;
        if (forceNotStandalone) return false;
        
        // If user manually set one boundary but not the other, they imply it's part of a group.
        if (forceFirst === true && forceLast === false) return false;
        if (forceFirst === false && forceLast === true) return false;
        
        return isFirst && isLast;
    }
    
    // ── Radius Logic ──
    readonly property real rTopLeft: (isFirst || isStandalone || (active && pillOnActive) || forcePill) ? fullRadius : smallRadius
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
    readonly property real rBottomRight: (isLast || isStandalone || (active && pillOnActive) || forcePill) ? fullRadius : smallRadius

    // ── Main Layout Container (With Clipping) ──
    Item {
        id: container
        anchors.fill: parent
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: container.width; height: container.height
                topLeftRadius: root.rTopLeft
                topRightRadius: root.rTopRight
                bottomLeftRadius: root.rBottomLeft
                bottomRightRadius: root.rBottomRight
                
                Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
                Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
                Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
                Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
            }
        }

        // ── Background ──
        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: root.color
            visible: root.color !== "transparent"
            
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
