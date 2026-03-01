import QtQuick
import "../core"
import "../services"

Item {
    id: root

    property bool isLockscreen: false

    property string style: {
        if (!Config.ready) return "digital"
        if (isLockscreen && !Config.options.appearance.clock.useSameStyle) {
            return Config.options.appearance.clock.styleLocked
        }
        return Config.options.appearance.clock.style
    }

    property color color: Appearance.m3colors.m3onSurface

    implicitWidth: loader.item ? loader.item.implicitWidth : 200
    implicitHeight: loader.item ? loader.item.implicitHeight : 80

    width: implicitWidth
    height: implicitHeight

    visible: {
        if (!Config.ready) return true
        if (!isLockscreen && !Config.options.appearance.clock.showOnDesktop) return false
        return true
    }

    // Centering & Offsetting
    readonly property real parentWidth: parent ? parent.width : 1920
    readonly property real parentHeight: parent ? parent.height : 1080

    readonly property real clockOffsetX: Config.ready ? Config.options.appearance.clock.offsetX : 0
    readonly property real clockOffsetY: Config.ready ? Config.options.appearance.clock.offsetY : -50

    x: (parentWidth / 2 - width / 2) + (isLockscreen ? 0 : clockOffsetX)
    y: (parentHeight / 2 - height / 2) + (isLockscreen ? -50 : clockOffsetY)

    Loader {
        id: loader
        anchors.centerIn: parent
        source: {
            switch (root.style) {
                case "analog": return "clock/AnalogClock.qml"
                case "code": return "clock/CodeClock.qml"
                case "stacked": return "clock/StackedClock.qml"
                case "digital":
                default: return "clock/DigitalClock.qml"
            }
        }

        onLoaded: {
            // Don't set color — each clock manages its own from Config.colorStyle
            // Pass isLockscreen so they can use adaptive lockscreen colors
            if (item && item.hasOwnProperty("isLockscreen")) item.isLockscreen = root.isLockscreen
        }

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("[NandoClock] Clock loader error for source:", source)
            }
        }
    }

    // Drag area - highest z, blocks background swipe
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: !root.isLockscreen
        z: 100
        cursorShape: Qt.SizeAllCursor
        hoverEnabled: true
        propagateComposedEvents: false
        preventStealing: true

        property real dragStartX: 0
        property real dragStartY: 0
        property real initialOffsetX: 0
        property real initialOffsetY: 0
        property bool dragging: false

        onPressed: (mouse) => {
            dragStartX = mouse.x + root.x
            dragStartY = mouse.y + root.y
            initialOffsetX = Config.options.appearance.clock.offsetX
            initialOffsetY = Config.options.appearance.clock.offsetY
            dragging = true
            mouse.accepted = true
        }

        onPositionChanged: (mouse) => {
            if (!dragging) return
            let newX = mouse.x + root.x
            let newY = mouse.y + root.y
            let dx = newX - dragStartX
            let dy = newY - dragStartY
            Config.options.appearance.clock.offsetX = Math.round(initialOffsetX + dx)
            Config.options.appearance.clock.offsetY = Math.round(initialOffsetY + dy)
        }

        onReleased: {
            dragging = false
        }
    }

    Behavior on opacity { NumberAnimation { duration: 300 } }
}
