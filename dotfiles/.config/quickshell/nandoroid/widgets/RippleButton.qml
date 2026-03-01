import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../core"
import "../core/functions" as Functions
import "."

/**
 * A button with ripple effect similar to in Material Design.
 * Optimized for stability and fluid animation.
 */
Button {
    id: root
    property bool toggled
    property string buttonText
    property bool pointingHandCursor: true
    hoverEnabled: true
    readonly property bool realHovered: mouseArea.containsMouse
    
    // Base radii
    property real buttonRadius: Appearance.rounding.button
    property real buttonRadiusPressed: buttonRadius
    property real buttonEffectiveRadius: root.down ? root.buttonRadiusPressed : root.buttonRadius
    
    // Properties for SegmentedWrapper support
    property real topLeftRadius: buttonEffectiveRadius
    property real topRightRadius: buttonEffectiveRadius
    property real bottomLeftRadius: buttonEffectiveRadius
    property real bottomRightRadius: buttonEffectiveRadius

    property int rippleDuration: 400
    property bool rippleEnabled: true
    property var downAction // When left clicking (down)
    property var releaseAction // When left clicking (release)
    property var altAction // When right clicking
    property var middleClickAction // When middle clicking
    
    // Colors (Exposed for overrides)
    property color colBackground: Appearance.m3colors.m3surfaceContainerHigh
    property color colBackgroundHover: colBackground
    property color colBackgroundToggled: Appearance.m3colors.m3primary
    property color colBackgroundToggledHover: colBackgroundToggled
    
    property color colText: Appearance.m3colors.m3onSurface
    property color colTextToggled: Appearance.m3colors.m3onPrimary
    
    property color colRipple: Functions.ColorUtils.applyAlpha(root.textColor, 0.12)

    opacity: root.enabled ? 1 : 0.4
    
    // Simplified color logic: Use the specific color based on state
    property color baseColor: root.toggled ? 
        (root.hovered ? colBackgroundToggledHover : colBackgroundToggled) :
        (root.hovered ? colBackgroundHover : colBackground)
    
    property color textColor: root.toggled ? colTextToggled : colText

    // ── Animations ──
    Behavior on opacity { animation: Appearance.animation.elementResize.numberAnimation.createObject(root) }
    Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root) }
    Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root) }
    Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root) }
    Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(root) }

    function startRipple(x, y) {
        rippleAnim.x = x;
        rippleAnim.y = y;
        const dist = (ox,oy) => ox*ox + oy*oy
        rippleAnim.radius = Math.sqrt(Math.max(dist(0, 0), dist(0, height), dist(width, 0), dist(width, height)))
        rippleFadeAnim.complete();
        rippleAnim.restart();
    }

    component RippleAnim: NumberAnimation {
        duration: rippleDuration
        easing.type: Easing.OutQuart
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.pointingHandCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: (event) => { 
            if(event.button === Qt.RightButton) {
                if (root.altAction) root.altAction(event);
                return;
            }
            if(event.button === Qt.MiddleButton) {
                if (root.middleClickAction) root.middleClickAction();
                return;
            }
            root.down = true
            if (root.downAction) root.downAction();
            if (!root.rippleEnabled) return;
            startRipple(event.x, event.y)
        }
        onReleased: (event) => {
            root.down = false;
            if (event.button != Qt.LeftButton) return;
            if (root.releaseAction) root.releaseAction();
            root.click(); 
            if (root.rippleEnabled) rippleFadeAnim.restart();
        }
        onCanceled: {
            root.down = false;
            if (root.rippleEnabled) rippleFadeAnim.restart();
        }
    }

    RippleAnim {
        id: rippleFadeAnim
        duration: rippleDuration * 2
        target: ripple; property: "opacity"; to: 0
    }

    SequentialAnimation {
        id: rippleAnim
        property real x; property real y; property real radius
        PropertyAction { target: ripple; property: "x"; value: rippleAnim.x }
        PropertyAction { target: ripple; property: "y"; value: rippleAnim.y }
        PropertyAction { target: ripple; property: "opacity"; value: 1 }
        ParallelAnimation {
            RippleAnim {
                target: ripple
                properties: "implicitWidth,implicitHeight"
                from: 0
                to: rippleAnim.radius * 2
            }
        }
    }

    // ── STABLE BACKGROUND ──
    background: Rectangle {
        id: bgContainer
        color: root.baseColor
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        
        Behavior on color { 
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(bgContainer)
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: bgContainer.width; height: bgContainer.height
                radius: bgContainer.radius
                topLeftRadius: bgContainer.topLeftRadius
                topRightRadius: bgContainer.topRightRadius
                bottomLeftRadius: bgContainer.bottomLeftRadius
                bottomRightRadius: bgContainer.bottomRightRadius
                antialiasing: true // Reduce clipping artifacts (shadows)
            }
        }

        // State Layer (Highlight)
        Rectangle {
            anchors.fill: parent
            color: root.textColor
            opacity: root.down ? 0.12 : (root.hovered ? 0.08 : 0)
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Item {
            id: ripple
            width: ripple.implicitWidth; height: ripple.implicitHeight
            opacity: 0; visible: width > 0 && height > 0
            property real implicitWidth: 0; property real implicitHeight: 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            RadialGradient {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.colRipple }
                    GradientStop { position: 0.5; color: "transparent" }
                }
            }
            transform: Translate { x: -ripple.width / 2; y: -ripple.height / 2 }
        }
    }

    contentItem: StyledText {
        text: root.buttonText
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: root.textColor
        Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(root) }
    }
}
