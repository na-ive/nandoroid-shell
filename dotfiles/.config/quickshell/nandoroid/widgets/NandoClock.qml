import QtQuick
import "../core"
import "../services"

Item {
    id: root

    property bool isLockscreen: false
    property bool interactive: true
    signal requestContextMenu(real x, real y, bool isClock)

    property string style: {
        if (!Config.ready) return "digital"
        if (isLockscreen && !Config.options.appearance.clock.useSameStyle) {
            return Config.options.appearance.clock.styleLocked
        }
        return Config.options.appearance.clock.style
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
    readonly property real clockOffsetY: Config.ready ? Config.options.appearance.clock.offsetY : -50

    // Dynamic anchor point based on alignment to prevent shifting
    property string alignment: {
        if (!loader.item) return "center";
        if (loader.item.alignment !== undefined) return loader.item.alignment;
        if (loader.item.cfg && loader.item.cfg.alignment !== undefined) return loader.item.cfg.alignment;
        return "center";
    }

    // Position the Item's (0,0) at the anchor target (Center + Offset)
    x: isLockscreen ? x : (parentWidth / 2) + clockOffsetX
    y: isLockscreen ? y : (parentHeight / 2 - height / 2) + clockOffsetY
    
    // Shift the item relative to its width based on alignment
    transform: Translate {
        x: {
            if (root.isLockscreen) return 0; // Fixed center on lockscreen
            if (root.alignment === "left") return 0; // Anchor is at X (Left edge)
            if (root.alignment === "right") return -root.width; // Anchor is at X (Right edge)
            return -root.width / 2; // Anchor is at X (Center)
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

    // Drag area - highest z, blocks background swipe
    MouseArea {
        id: dragArea
        width: loader.item ? loader.item.implicitWidth : root.implicitWidth
        height: loader.item ? loader.item.implicitHeight : root.implicitHeight
        anchors.centerIn: parent
        enabled: !root.isLockscreen
        z: 100
        cursorShape: (root.interactive && Config.ready && !Config.options.appearance.clock.locked) ? Qt.SizeAllCursor : Qt.ArrowCursor
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real startWinX: 0
        property real startWinY: 0
        property real startOffsetX: 0
        property real startOffsetY: 0
        property bool dragging: false

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                const winPos = dragArea.mapToItem(null, mouse.x, mouse.y);
                root.requestContextMenu(winPos.x, winPos.y, true);
                mouse.accepted = true;
                return;
            }

            if (!root.interactive) {
                mouse.accepted = false;
                return;
            }

            if (Config.ready && Config.options.appearance.clock.locked) {
                mouse.accepted = false;
                return;
            }

            if (mouse.button === Qt.LeftButton) {
                const winPos = dragArea.mapToItem(null, mouse.x, mouse.y);
                startWinX = winPos.x;
                startWinY = winPos.y;
                startOffsetX = Config.options.appearance.clock.offsetX;
                startOffsetY = Config.options.appearance.clock.offsetY;
                dragging = true;
                mouse.accepted = true;
            }
        }

        onPositionChanged: (mouse) => {
            if (!dragging) return;
            
            const winPos = dragArea.mapToItem(null, mouse.x, mouse.y);
            let dx = winPos.x - startWinX;
            let dy = winPos.y - startWinY;
            
            Config.options.appearance.clock.offsetX = Math.round(startOffsetX + dx);
            Config.options.appearance.clock.offsetY = Math.round(startOffsetY + dy);
        }

        onReleased: (mouse) => {
            dragging = false;
        }

        onCanceled: {
            dragging = false;
        }
    }

    Behavior on opacity { NumberAnimation { duration: 300 } }
}
