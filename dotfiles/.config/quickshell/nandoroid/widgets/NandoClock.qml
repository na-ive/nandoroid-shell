import QtQuick
import "../core"
import "../services"

Item {
    id: root

    property bool isLockscreen: false
    property bool interactive: true

    property string style: {
        if (!Config.ready) return "digital"
        if (Config.options.appearance.clock.useSameStyle) return Config.options.appearance.clock.styleLocked
        return isLockscreen ? Config.options.appearance.clock.styleLocked : Config.options.appearance.clock.style
    }

    property color color: Appearance.m3colors.m3onSurface

    implicitWidth: loader.item ? loader.item.implicitWidth : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

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
    readonly property real clockOffsetY: Config.ready ? Config.options.appearance.clock.offsetY : -50 * Appearance.effectiveScale

    // Dynamic anchor point based on alignment to prevent shifting
    property string alignment: {
        if (!loader.item) return "center";
        if (loader.item.alignment !== undefined) return loader.item.alignment;
        if (loader.item.cfg && loader.item.cfg.alignment !== undefined) return loader.item.cfg.alignment;
        return "center";
    }

    // Position the Item's (0,0) at the anchor target (Center + Offset)
    x: isLockscreen ? ((parentWidth / 2) + clockOffsetX) : 0
    y: isLockscreen ? ((parentHeight / 2 - height / 2) + clockOffsetY) : 0
    
    // Shift the item relative to its width based on alignment
    transform: Translate {
        x: {
            if (root.isLockscreen) return 0; // Fixed center on lockscreen
            return 0; // When wrapped in AbstractWidget, alignment is handled by the wrapper or implicit layout
        }
    }

    Loader {
        id: loader
        anchors.centerIn: parent
        source: {
            switch (root.style) {
                case "analog": return "clock/AnalogClock.qml"
                case "code": return "clock/CodeClock.qml"
                case "stacked": return "clock/StackedClock.qml"
                case "text": return "clock/TextClock.qml"
                case "pill": return "clock/PillClock.qml"
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

            }
        }
    }



    Behavior on opacity { NumberAnimation { duration: 300 } }
}
