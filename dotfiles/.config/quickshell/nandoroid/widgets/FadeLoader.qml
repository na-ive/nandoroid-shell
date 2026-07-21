import QtQuick

/**
 * A Loader that automatically fades its content in and out
 * when the 'shown' or 'active' properties change.
 */
Loader {
    id: root
    property bool shown: true
    property alias fade: opacityBehavior.enabled
    
    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: visible

    Behavior on opacity {
        id: opacityBehavior
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
}
