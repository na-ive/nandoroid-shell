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
        width: Math.min(800 * Appearance.effectiveScale, root.width * 0.9)
        height: contentCol.implicitHeight + (80 * Appearance.effectiveScale)
        hoverEnabled: true
        
        x: Config.options.appearance.lyrics.desktopX >= 0 ? Config.options.appearance.lyrics.desktopX : (root.width - width) / 2
        y: Config.options.appearance.lyrics.desktopY >= 0 ? Config.options.appearance.lyrics.desktopY : (root.height - height) / 2

        draggable: !Config.options.appearance.lyrics.lyricsPinned
        snapEnabled: false

        onDragFinished: (newX, newY) => {
            Config.options.appearance.lyrics.desktopX = newX
            Config.options.appearance.lyrics.desktopY = newY
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

        ColumnLayout {
            id: contentCol
            anchors.centerIn: parent
            width: parent.width - (40 * Appearance.effectiveScale)
            spacing: 16



            // Lyrics List
            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                
                Repeater {
                    model: LyricsService.slots
                    delegate: Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        text: Config.options.appearance.lyrics.lyricsUseRomaji ? modelData.romajiText : modelData.originalText
                        font.family: Config.options.appearance.fonts.main
                        font.pixelSize: index === LyricsService.before ? 36 : 22
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
