import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell

/**
 * M3-styled media player card — Compact horizontal layout matching ii style.
 * Art (left) | Info & Progress (center) | Play/Pause (right).
 * Uses persistent data from MprisController.
 */
Rectangle {
    id: root
    implicitHeight: 118
    radius: Appearance.rounding.card
    color: Functions.ColorUtils.applyAlpha(MprisController.dynLayer0, 1)
    visible: MprisController.activePlayer !== null
    clip: true

    property bool showVisualizer: true
    readonly property var player: MprisController.activePlayer

    // --- Cava Lifecycle Management ---
    readonly property bool shouldVisualize: root.visible && MprisController.isPlaying && root.showVisualizer
    onShouldVisualizeChanged: {
        if (shouldVisualize) CavaService.refCount++;
        else CavaService.refCount--;
    }
    Component.onDestruction: {
        if (shouldVisualize) CavaService.refCount--;
    }

    // Background Art (Blurred)
    Item {
        id: backgroundWrapper
        anchors.fill: parent
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: backgroundWrapper.width
                height: backgroundWrapper.height
                radius: root.radius
            }
        }

        Image {
            id: blurredArt
            anchors.fill: parent
            source: MprisController.displayedArtFilePath
            visible: source.toString() !== ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            
            layer.enabled: true
            layer.effect: GaussianBlur {
                radius: 64 
                samples: 48
            }

            Rectangle {
                anchors.fill: parent
                color: Functions.ColorUtils.transparentize(MprisController.dynLayer0, 0.3)
            }
        }

        // --- Wave Visualizer Overlay ---
        WaveVisualizer {
            anchors.fill: parent
            anchors.topMargin: parent.height * 0.4 // Position it towards the bottom half
            color: MprisController.dynPrimary
            opacityMultiplier: 0.2
            visible: root.shouldVisualize
        }
    }

    // Layout Container
    Item {
        anchors.fill: parent
        anchors.margins: 12

        // Left: Album art
        MaterialShape {
            id: artShape
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 86
            height: 86
            image: MprisController.displayedArtFilePath
            shape: MaterialShape.Shape.Square
            color: MprisController.dynLayer0
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                iconSize: 32
                fill: 1
                color: MprisController.dynSubtext
                visible: !parent.image || parent.image.toString() === ""
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        MprisController.cyclePlayer()
                    } else {
                        MprisController.raisePlayer()
                    }
                }
            }
        }

        // Right: Large Play/Pause
        RippleButton {
            id: playPauseButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 64
            height: 64
            buttonRadius: MprisController.isPlaying ? Appearance.rounding.large : 32
            
            colBackground: MprisController.isPlaying ? MprisController.dynPrimary : MprisController.dynSecondaryContainer
            colBackgroundHover: MprisController.isPlaying ? MprisController.dynPrimaryHover : MprisController.dynSecondaryContainerHover
            colRipple: MprisController.isPlaying ? MprisController.dynPrimaryActive : MprisController.dynSecondaryContainerActive
            
            onClicked: MprisController.togglePlaying()
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: MprisController.isPlaying ? "pause" : "play_arrow"
                iconSize: 32
                fill: 1
                color: MprisController.isPlaying ? MprisController.dynOnPrimary : MprisController.dynOnSecondaryContainer
            }
        }

        // Center: Track info & Progressive bar
        ColumnLayout {
            id: infoLayout
            anchors.left: artShape.right
            anchors.right: playPauseButton.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            height: 94
            spacing: 0

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                MouseArea {
                    Layout.fillWidth: true
                    implicitHeight: trackTitleText.implicitHeight + trackArtistText.implicitHeight
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            MprisController.cyclePlayer()
                        } else {
                            MprisController.raisePlayer()
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0
                        StyledText {
                            id: trackTitleText
                            Layout.fillWidth: true
                            text: Functions.StringUtils.cleanMusicTitle(MprisController.trackTitle) || "No media"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Bold
                            color: MprisController.dynOnLayer0
                            elide: Text.ElideRight
                        }
                        StyledText {
                            id: trackArtistText
                            Layout.fillWidth: true
                            text: MprisController.trackArtist || "Unknown Artist"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: MprisController.dynSubtext
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            StyledText {
                Layout.topMargin: 8
                text: `${Functions.StringUtils.friendlyTimeForSeconds(MprisController.position)} / ${Functions.StringUtils.friendlyTimeForSeconds(MprisController.length)}`
                font.pixelSize: Appearance.font.pixelSize.small
                color: MprisController.dynSubtext
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 4

                RippleButton {
                    implicitWidth: 32; implicitHeight: 32
                    buttonRadius: 16
                    colBackground: "transparent"
                    colBackgroundHover: MprisController.dynSecondaryContainer
                    colRipple: MprisController.dynSecondaryContainerActive
                    enabled: MprisController.canGoPrevious
                    onClicked: MprisController.previous()
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 20
                        fill: 1
                        color: MprisController.dynOnSecondaryContainer
                    }
                }

                StyledSlider {
                    id: progressSlider
                    Layout.preferredWidth: 120
                    configuration: StyledSlider.Configuration.Wavy
                    stopIndicatorValues: []
                    animateValue: false
                    value: MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0
                    wavy: MprisController.isPlaying
                    highlightColor: MprisController.dynPrimary
                    trackColor: MprisController.dynSecondaryContainer
                    handleColor: MprisController.dynPrimary
                    
                    onMoved: {
                        if (player && player.canSeek) {
                            player.position = value * player.length;
                        }
                    }

                    Connections {
                        target: MprisController
                        function onPositionChanged() {
                            if (!progressSlider.pressed) {
                                progressSlider.value = MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0;
                            }
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 32; implicitHeight: 32
                    buttonRadius: 16
                    colBackground: "transparent"
                    colBackgroundHover: MprisController.dynSecondaryContainer
                    colRipple: MprisController.dynSecondaryContainerActive
                    enabled: MprisController.canGoNext
                    onClicked: MprisController.next()
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: 20
                        fill: 1
                        color: MprisController.dynOnSecondaryContainer
                    }
                }
            }
        }
    }
}
