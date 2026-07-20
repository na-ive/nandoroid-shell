import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../core"
import "../widgets"
import "../services"
import "../core/functions" as Functions

Item {
    id: root

    property var model: []
    property Component delegate: null

    property real largeItemWidthRatio: 0.55
    property real mediumItemWidthRatio: 0.32
    property real smallItemWidthRatio: 0.12
    property real baseItemWidth: 0
    property real activeBonusWidth: 0
    property real itemSpacing: 6 * Appearance.effectiveScale
    property alias currentIndex: listView.currentIndex

    property bool fitMode: false
    property int hoveredIndex: -1
    readonly property int focusedIndex: {
        if (hoveredIndex >= 0) return hoveredIndex
        var idx = listView.currentIndex
        return idx >= 0 ? idx : 0
    }

    property bool hoverSelectsIndex: false
    property bool wheelEnabled: true
    property bool dragEnabled: true

    property real clipRadius: Appearance.rounding.extraLarge - (10 * Appearance.effectiveScale)
    property bool showCurrentIndicator: true
    property bool showFooter: false
    property bool isOpen: true

    signal wallpaperSelected(string path)
    signal openMoreWallpapers()
    signal itemSelected(int index)

    implicitHeight: 160 * Appearance.effectiveScale

    function widthForOffset(offset) {
        if (baseItemWidth > 0) {
            if (offset === 0) return baseItemWidth + activeBonusWidth
            return baseItemWidth
        }
        if (offset === 0) return width * largeItemWidthRatio
        if (Math.abs(offset) === 1) return width * mediumItemWidthRatio
        return width * smallItemWidthRatio
    }

    function footerWidthForOffset(offset) {
        if (offset <= 0) return width
        
        var consumedWidth = 0
        for (var i = 0; i < offset; i++) {
            consumedWidth += widthForOffset(i)
            if (i > 0) consumedWidth += root.itemSpacing
        }
        
        var remaining = width - consumedWidth
        return Math.max(width * smallItemWidthRatio, remaining)
    }

    Row {
        id: fitRow
        visible: root.fitMode
        anchors.fill: parent
        spacing: root.itemSpacing

        Repeater {
            model: root.fitMode ? root.model : []
            delegate: carouselDelegate
        }

        Rectangle {
            id: _fitMask
            anchors.fill: parent
            radius: root.clipRadius
            visible: false
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: _fitMask
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        visible: !root.fitMode
        clip: false
        orientation: ListView.Horizontal
        spacing: root.itemSpacing
        interactive: root.dragEnabled
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0
        preferredHighlightEnd: 0
        highlightMoveDuration: 250
        model: root.fitMode ? null : root.model

        Rectangle {
            id: _listMask
            width: listView.width
            height: listView.height
            radius: root.clipRadius
            visible: false
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: _listMask
        }

        WheelHandler {
            id: wheelHandler
            target: listView
            enabled: root.wheelEnabled
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            property bool coolingDown: false
            onWheel: (event) => {
                if (coolingDown) return
                coolingDown = true
                debounceTimer.restart()

                if (event.angleDelta.y < 0 || event.angleDelta.x > 0)
                    listView.incrementCurrentIndex()
                else
                    listView.decrementCurrentIndex()
            }
        }

        Timer {
            id: debounceTimer
            interval: 80
            onTriggered: wheelHandler.coolingDown = false
        }

        delegate: carouselDelegate

        footer: Item {
            id: footerRoot
            visible: root.showFooter
            
            property int offsetFromCurrent: listView.count - root.focusedIndex
            width: root.footerWidthForOffset(offsetFromCurrent)
            height: listView.height

            Behavior on width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(footerRoot)
            }
            
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: root.itemSpacing
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer3
                
                RippleButton {
                    anchors.fill: parent
                    buttonRadius: Appearance.rounding.large
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    
                    onClicked: root.openMoreWallpapers()
                    
                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            iconSize: 32 * Appearance.effectiveScale
                            color: Appearance.colors.colOnLayer1
                            opacity: footerRoot.width > 20 * Appearance.effectiveScale ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: carouselDelegate

        Item {
            id: itemRoot
            required property var modelData
            required property int index

            property int offsetFromCurrent: index - root.focusedIndex
            width: root.widthForOffset(offsetFromCurrent)
            height: parent.height

            Behavior on width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Rectangle {
                id: cardBg
                anchors.fill: parent
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer3
                clip: true

                opacity: root.isOpen ? 1 : 0
                scale: root.isOpen ? 1 : 0.9

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation { duration: root.isOpen ? Math.min(itemRoot.index, 10) * 50 : 0 }
                        NumberAnimation {
                            duration: root.isOpen ? Appearance.animation.elementMoveEnter.duration : Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: root.isOpen ? Appearance.animationCurves.expressiveDefaultSpatial : Appearance.animationCurves.emphasizedAccel
                        }
                    }
                }

                Behavior on scale {
                    SequentialAnimation {
                        PauseAnimation { duration: root.isOpen ? Math.min(itemRoot.index, 10) * 50 : 0 }
                        NumberAnimation {
                            duration: root.isOpen ? Appearance.animation.elementMoveEnter.duration : Appearance.animation.elementMoveExit.duration
                            easing.bezierCurve: root.isOpen ? Appearance.animationCurves.emphasizedDecel : Appearance.animationCurves.emphasizedAccel
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: root.delegate ?? defaultImageDelegate
                    property var modelData: itemRoot.modelData
                    property int index: itemRoot.index
                    property real fixedWidth: root.width * root.largeItemWidthRatio
                    property real fixedHeight: listView.height
                }

                Rectangle {
                    id: currentIndicator
                    visible: root.showCurrentIndicator && itemRoot.index === 0
                    anchors.centerIn: parent
                    width: 32 * Appearance.effectiveScale
                    height: 32 * Appearance.effectiveScale
                    radius: width / 2
                    color: Appearance.colors.colPrimary

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "check"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnPrimary
                        fill: 1
                    }
                }

                Rectangle {
                    id: _cardMask
                    width: cardBg.width
                    height: cardBg.height
                    radius: cardBg.radius
                    visible: false
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: _cardMask
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.hoveredIndex = itemRoot.index
                        if (root.hoverSelectsIndex) root.currentIndex = itemRoot.index
                    }
                    onExited: if (root.hoveredIndex === itemRoot.index)
                                root.hoveredIndex = -1
                    onClicked: {
                        root.currentIndex = itemRoot.index
                        root.wallpaperSelected(itemRoot.modelData)
                        root.itemSelected(itemRoot.index)
                    }
                }
            }
        }
    }

    Component {
        id: defaultImageDelegate
        StyledImage {
            id: img
            property real fixedWidth: parent?.fixedWidth ?? width
            property real fixedHeight: parent?.fixedHeight ?? height
            
            opacity: (status === Image.Ready) ? 1 : 0
            Behavior on opacity {
                animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(img)
            }
            source: "file://" + Functions.FileUtils.trimFileProtocol(modelData)
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            sourceSize.width: fixedWidth * 1.5
            sourceSize.height: fixedHeight * 1.5
        }
    }
}
