import "../core"
import "../services"
import "."
import "../core/functions" as Functions
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
    implicitHeight: 118 * Appearance.effectiveScale
    radius: Appearance.rounding.card
    color: Functions.ColorUtils.applyAlpha(MprisController.dynLayer0, 1)
    visible: MprisController.activePlayer !== null
    clip: true

    property bool showVisualizer: true
    readonly property var player: MprisController.activePlayer

    // --- Cava Lifecycle Management ---
    property bool _cavaActive: false
    readonly property bool shouldVisualize: root.visible && MprisController.isPlaying && root.showVisualizer
    onShouldVisualizeChanged: {
        if (shouldVisualize && !_cavaActive) {
            CavaService.refCount++;
            _cavaActive = true;
        } else if (!shouldVisualize && _cavaActive) {
            CavaService.refCount--;
            _cavaActive = false;
        }
    }
    Component.onDestruction: {
        if (_cavaActive) CavaService.refCount--;
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
                radius: 64 * Appearance.effectiveScale
                samples: Math.round(48 * Appearance.effectiveScale)
                cached: true
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
        anchors.margins: 12 * Appearance.effectiveScale

        // Left: Album art
        MaterialShape {
            id: artShape
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 86 * Appearance.effectiveScale
            height: 86 * Appearance.effectiveScale
            image: MprisController.displayedArtFilePath
            shape: MaterialShape.Shape.Square
            color: MprisController.dynLayer0
            
            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                iconSize: 32 * Appearance.effectiveScale
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

        // Main Content Area (Right of Art)
        ColumnLayout {
            anchors.left: artShape.right
            anchors.right: parent.right
            anchors.top: artShape.top
            anchors.bottom: artShape.bottom
            anchors.leftMargin: 16 * Appearance.effectiveScale
            spacing: 0

            // Top Row: Track Info + Play/Pause
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
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
                                font.weight: Font.DemiBold
                                color: MprisController.dynOnLayer0
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop
                            }
                            StyledText {
                                id: trackArtistText
                                Layout.fillWidth: true
                                text: MprisController.trackArtist || "Unknown Artist"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: MprisController.dynSubtext
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignTop
                            }
                        }
                    }
                }

                // Play/Pause Button
                RippleButton {
                    id: playPauseButton
                    padding: 0
                    implicitWidth: 52 * Appearance.effectiveScale
                    implicitHeight: 52 * Appearance.effectiveScale
                    Layout.preferredWidth: 52 * Appearance.effectiveScale
                    Layout.preferredHeight: 52 * Appearance.effectiveScale
                    Layout.alignment: Qt.AlignTop
                    buttonRadius: MprisController.isPlaying ? Appearance.rounding.large : Appearance.rounding.normal
                    
                    colBackground: MprisController.isPlaying ? MprisController.dynPrimary : MprisController.dynSecondaryContainer
                    colBackgroundHover: MprisController.isPlaying ? MprisController.dynPrimaryHover : MprisController.dynSecondaryContainerHover
                    colRipple: MprisController.isPlaying ? MprisController.dynPrimaryActive : MprisController.dynSecondaryContainerActive
                    
                    onClicked: MprisController.togglePlaying()
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.isPlaying ? "pause" : "play_arrow"
                        iconSize: 28 * Appearance.effectiveScale
                        fill: 1
                        color: MprisController.isPlaying ? MprisController.dynOnPrimary : MprisController.dynOnSecondaryContainer
                    }
                }
            }

            // Fill space between top and bottom
            Item { Layout.fillHeight: true }

            // Bottom Row: Full Width Playback Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24 * Appearance.effectiveScale
                spacing: 0 // Experimental: Remove base spacing

                // Skip Previous
                RippleButton {
                    id: prevBtn
                    padding: 0
                    implicitWidth: 24 * Appearance.effectiveScale; implicitHeight: 24 * Appearance.effectiveScale; buttonRadius: 12 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                    colText: "transparent"
                    rippleEnabled: false
                    enabled: MprisController.canGoPrevious
                    onClicked: MprisController.previous()
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"; iconSize: 18 * Appearance.effectiveScale; fill: 1
                        color: prevBtn.hovered ? MprisController.dynPrimary : MprisController.dynOnSecondaryContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Current Time
                StyledText {
                    id: currentTimeText
                    text: Functions.StringUtils.friendlyTimeForSeconds(MprisController.position)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                    font.features: { "tnum": 1 }
                    font.weight: Font.Medium
                    color: MprisController.dynSubtext
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.leftMargin: 0
                    Layout.rightMargin: 6 * Appearance.effectiveScale
                    renderType: Text.QtRendering
                }

                // Slider
                StyledSlider {
                    id: progressSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14 * Appearance.effectiveScale
                    handleMargins: 0 
                    configuration: StyledSlider.Configuration.Wavy
                    stopIndicatorValues: []
                    animateValue: false
                    value: (MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0) || 0
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
                                progressSlider.value = (MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0) || 0;
                            }
                        }
                    }
                }

                // Total Time
                StyledText {
                    id: totalTimeText
                    text: Functions.StringUtils.friendlyTimeForSeconds(MprisController.length)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.family: Appearance.font.family.numbers
                    font.features: { "tnum": 1 }
                    font.weight: Font.Medium
                    color: MprisController.dynSubtext
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                    Layout.leftMargin: 6 * Appearance.effectiveScale
                    Layout.rightMargin: 0
                    renderType: Text.QtRendering
                }

                // Skip Next
                RippleButton {
                    id: nextBtn
                    padding: 0
                    implicitWidth: 24 * Appearance.effectiveScale; implicitHeight: 24 * Appearance.effectiveScale; buttonRadius: 12 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                    colText: "transparent"
                    rippleEnabled: false
                    enabled: MprisController.canGoNext
                    onClicked: MprisController.next()

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"; iconSize: 18 * Appearance.effectiveScale; fill: 1
                        color: nextBtn.hovered ? MprisController.dynPrimary : MprisController.dynOnSecondaryContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Lyrics Toggle
                RippleButton {
                    id: lyricsBtn
                    padding: 0
                    implicitWidth: 24 * Appearance.effectiveScale; implicitHeight: 24 * Appearance.effectiveScale; buttonRadius: 12 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: "transparent"
                    colText: "transparent"
                    rippleEnabled: false
                    onClicked: {
                        Config.options.appearance.lyrics.showFloatingLyrics = !Config.options.appearance.lyrics.showFloatingLyrics
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "lyrics"; iconSize: 18 * Appearance.effectiveScale; fill: Config.options.appearance.lyrics.showFloatingLyrics ? 1 : 0
                        color: (lyricsBtn.hovered || Config.options.appearance.lyrics.showFloatingLyrics) ? MprisController.dynPrimary : MprisController.dynOnSecondaryContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }
        }
    }
}
