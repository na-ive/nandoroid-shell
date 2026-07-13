import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../widgets/widgetCanvas"
import "../../widgets"

PanelWindow {
    id: root
    visible: Config.options.appearance.lyrics.showFloatingLyrics
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nandoroid:floating-lyrics"
    color: "transparent"

    mask: Region {
        item: Config.options.appearance.lyrics.lyricsPinned ? lockIconContainer : lyricsWrapper
    }

    AbstractWidget {
        id: lyricsWrapper
        property real defaultWidth: Math.min(800 * Appearance.effectiveScale, (Config.options.appearance.lyrics.fontSize * 15 + 100) * Appearance.effectiveScale)
        property real currentWidth: Config.options.appearance.lyrics.customWidth > 0 ? Config.options.appearance.lyrics.customWidth : defaultWidth
        
        width: Math.min(Math.max(300 * Appearance.effectiveScale, currentWidth), root.width * 0.9)
        height: contentCol.implicitHeight + (80 * Appearance.effectiveScale)
        hoverEnabled: true

        Binding on animateXPos { value: !lyricsWrapper.dragging && lyricsWrapper.isLoaded && !resizeArea.pressed }
        Binding on animateYPos { value: !lyricsWrapper.dragging && lyricsWrapper.isLoaded && !resizeArea.pressed }

        
        readonly property real centerX: {
            if (Config.options.appearance.lyrics.desktopCenterX >= 0) return Config.options.appearance.lyrics.desktopCenterX;
            if (Config.options.appearance.lyrics.desktopX >= 0) return Config.options.appearance.lyrics.desktopX + width / 2;
            return root.width / 2;
        }

        readonly property real centerY: {
            if (Config.options.appearance.lyrics.desktopCenterY >= 0) return Config.options.appearance.lyrics.desktopCenterY;
            if (Config.options.appearance.lyrics.desktopY >= 0) return Config.options.appearance.lyrics.desktopY + height / 2;
            return root.height / 2;
        }

        x: centerX - width / 2
        y: centerY - height / 2

        draggable: !Config.options.appearance.lyrics.lyricsPinned
        snapEnabled: false

        onDragFinished: (newX, newY) => {
            Config.options.appearance.lyrics.desktopCenterX = newX + width / 2
            Config.options.appearance.lyrics.desktopCenterY = newY + height / 2
            Config.options.appearance.lyrics.desktopX = -1
            Config.options.appearance.lyrics.desktopY = -1
        }

        onDoubleClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                Config.options.appearance.lyrics.lyricsUseRomaji = !Config.options.appearance.lyrics.lyricsUseRomaji
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                Config.options.appearance.lyrics.lyricsPinned = !Config.options.appearance.lyrics.lyricsPinned
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colLayer2
            opacity: (lyricsWrapper.containsMouse && !Config.options.appearance.lyrics.lyricsPinned) ? 0.3 : 0
            radius: Appearance.rounding.window
            Behavior on opacity { NumberAnimation { duration: 200 } }
            z: -1
        }

        Column {
            id: contentCol
            anchors.centerIn: parent
            spacing: 16

            // Lyrics List
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8
                
                Repeater {
                    model: LyricsService.slots
                    delegate: Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: lyricsWrapper.width - (80 * Appearance.effectiveScale)
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: Config.options.appearance.lyrics.lyricsUseRomaji ? modelData.romajiText : modelData.originalText
                        font.family: (Config.ready && Config.options.appearance.lyrics.fontFamily !== "") ? Config.options.appearance.lyrics.fontFamily : Config.options.appearance.fonts.main
                        font.pixelSize: index === LyricsService.before 
                            ? (Config.ready && Config.options.appearance.lyrics ? Config.options.appearance.lyrics.fontSize : 36) 
                            : Math.max(12, (Config.ready && Config.options.appearance.lyrics ? Config.options.appearance.lyrics.fontSize : 36) * 0.6)
                        font.bold: index === LyricsService.before
                        color: index === LyricsService.before ? Appearance.m3colors.m3primary : "white"
                        opacity: index === LyricsService.before ? 1.0 : 0.6
                        style: Text.Outline
                        styleColor: "black"
                        Behavior on font.pixelSize { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
                    }
                }
            }
        }
        
        Text {
            visible: lyricsWrapper.containsMouse && !Config.options.appearance.lyrics.lyricsPinned
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            text: Config.options.appearance.lyrics.lyricsUseRomaji 
                  ? "Double click to change to original | Right click to lock" 
                  : "Double click to change to romaji | Right click to lock"
            font.family: Config.options.appearance.fonts.main
            font.pixelSize: 12
            color: "white"
            opacity: 0.6
            style: Text.Outline
            styleColor: "black"
        }

        // Resize Handle
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 4 * Appearance.effectiveScale
            width: 36 * Appearance.effectiveScale
            height: 36 * Appearance.effectiveScale
            color: resizeArea.containsMouse ? Qt.rgba(255,255,255, 0.2) : Qt.rgba(255,255,255, 0.1)
            radius: 8 * Appearance.effectiveScale
            visible: lyricsWrapper.containsMouse && !Config.options.appearance.lyrics.lyricsPinned
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: "swap_horiz"
                iconSize: 18
                color: "white"
                opacity: resizeArea.containsMouse ? 1.0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                id: resizeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                
                property real startGlobalX
                property real startWidth
                
                onPressed: (mouse) => {
                    let globalPos = mapToItem(null, mouse.x, mouse.y)
                    startGlobalX = globalPos.x
                    startWidth = lyricsWrapper.width
                    
                    if (Config.options.appearance.lyrics.desktopCenterX < 0) {
                        Config.options.appearance.lyrics.desktopCenterX = lyricsWrapper.centerX
                        Config.options.appearance.lyrics.desktopCenterY = lyricsWrapper.centerY
                    }
                }
                
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        let globalPos = mapToItem(null, mouse.x, mouse.y)
                        let deltaX = globalPos.x - startGlobalX
                        
                        let newWidth = startWidth + deltaX
                        let oldWidth = lyricsWrapper.width
                        
                        newWidth = Math.min(Math.max(300 * Appearance.effectiveScale, newWidth), root.width * 0.9)
                        let actualDelta = newWidth - oldWidth
                        
                        if (actualDelta !== 0) {
                            Config.options.appearance.lyrics.desktopCenterX += actualDelta / 2
                            Config.options.appearance.lyrics.customWidth = newWidth
                        }
                    }
                }
            }
        }

        Rectangle {
            id: lockIconContainer
            visible: Config.options.appearance.lyrics.lyricsPinned
            width: 32
            height: 32
            radius: 16
            color: lockMouseArea.containsMouse ? "black" : "transparent"
            opacity: lockMouseArea.containsMouse ? 0.8 : 0.6
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 4
            Behavior on opacity { NumberAnimation { duration: 150 } }
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: "lock"
                iconSize: 18
                color: "white"
            }
            
            MouseArea {
                id: lockMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.options.appearance.lyrics.lyricsPinned = false
            }
        }
    }
}
