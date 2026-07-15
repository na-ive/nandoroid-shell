import QtQuick
import QtQuick.Layouts
import "../core"
import "../services"

/**
 * Android-style Privacy Indicator.
 * Refactored for global scaling.
 */
Item {
    id: root
    implicitWidth: active ? mainContainer.width : 0
    implicitHeight: 24 * Appearance.effectiveScale

    readonly property bool active: (Config.ready && Config.options.privacy && Config.options.privacy.enable) ? Privacy.anyActive : false
    readonly property bool mic: Privacy.microphoneActive
    readonly property bool cam: Privacy.cameraActive
    readonly property bool screen: Privacy.screensharingActive

    property bool expanded: true
    property bool alwaysExpanded: false

    function triggerExpansion() {
        if (active) {
            root.expanded = true
            if (!alwaysExpanded) {
                shrinkTimer.restart()
            }
        } else {
            root.expanded = false
        }
    }

    onActiveChanged: triggerExpansion()
    onMicChanged: if (mic) triggerExpansion()
    onCamChanged: if (cam) triggerExpansion()
    onScreenChanged: if (screen) triggerExpansion()

    Timer {
        id: shrinkTimer
        interval: 3000
        onTriggered: {
            if (!alwaysExpanded) {
                root.expanded = false
            }
        }
    }

    Rectangle {
        id: mainContainer
        anchors.verticalCenter: parent.verticalCenter
        height: (root.expanded || alwaysExpanded) ? 20 * Appearance.effectiveScale : 8 * Appearance.effectiveScale
        width: (root.expanded || alwaysExpanded) ? contentLayout.implicitWidth + (12 * Appearance.effectiveScale) : 8 * Appearance.effectiveScale
        radius: height / 2
        color: Appearance.m3colors.m3primary
        clip: true

        Behavior on width {
            NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
        }
        Behavior on height {
            NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
        }

        RowLayout {
            id: contentLayout
            anchors.centerIn: parent
            spacing: 4 * Appearance.effectiveScale
            opacity: (root.expanded || alwaysExpanded) ? 1 : 0
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            MaterialSymbol {
                visible: root.mic
                text: "mic"
                iconSize: 14 * Appearance.effectiveScale
                color: Appearance.m3colors.m3onPrimary
                fill: 1
            }

            MaterialSymbol {
                visible: root.cam
                text: "videocam"
                iconSize: 14 * Appearance.effectiveScale
                color: Appearance.m3colors.m3onPrimary
                fill: 1
            }

            MaterialSymbol {
                visible: root.screen
                text: "screen_share"
                iconSize: 14 * Appearance.effectiveScale
                color: Appearance.m3colors.m3onPrimary
                fill: 1
            }
        }
    }

    visible: active
    opacity: active ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }
}
