import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions
import "../NotificationCenter" as NotificationCenter

/**
 * Media Notch Popup — The expanded HUD that appears below the Dynamic Island.
 * Refactored for global scaling.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: popupWindow
        required property var modelData
        screen: modelData
        
        readonly property string notchStyle: Config.ready && Config.options.media ? (Config.options.media.notchMediaStyle ?? "mini") : "mini"
        readonly property bool isFull: notchStyle === "full"

        // Positioning: Center top, below status bar
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "nandoroid:media-hud"
        exclusiveZone: 0

        anchors {
            top: true
        }

        WlrLayershell.margins {
            top: 4 * Appearance.effectiveScale
        }

        // Responsive window width
        implicitWidth: isFull ? Math.min(450 * Appearance.effectiveScale, modelData.width * 0.9) : Math.min(320 * Appearance.effectiveScale, modelData.width * 0.9)
        implicitHeight: contentRect.height + (20 * Appearance.effectiveScale)
        color: "transparent"

        visible: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) || contentRect.opacity > 0

        Rectangle {
            id: contentRect
            // Responsive pill width
            width: parent.width - (20 * Appearance.effectiveScale)
            anchors.horizontalCenter: parent.horizontalCenter
            height: isFull ? (fullLoader.item ? fullLoader.item.implicitHeight : 118 * Appearance.effectiveScale) : (miniLayout.implicitHeight + (12 * Appearance.effectiveScale))
            color: isFull ? "transparent" : "black"
            radius: Appearance.rounding.button

            // Animation for entry
            opacity: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) ? 1 : 0
            scale: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

            // Hover tracking area
            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered && Config.options.media.enableMediaHover) GlobalStates.openMediaNotch(modelData);
                    else GlobalStates.closeMediaNotchWithDelay();
                }
            }

            // --- Style 1: Mini HUD ---
            RowLayout {
                id: miniLayout
                visible: !popupWindow.isFull
                anchors.fill: parent
                anchors.margins: 8 * Appearance.effectiveScale
                spacing: 10 * Appearance.effectiveScale

                // ── 1. Art with Play/Pause Overlay ──
                MaterialShape {
                    width: 36 * Appearance.effectiveScale; height: 36 * Appearance.effectiveScale
                    shape: MaterialShape.Shape.Circle
                    image: MprisController.displayedArtFilePath || ""
                    color: Appearance.colors.colLayer2
                    
                    // Semi-transparent overlay for contrast
                    Rectangle {
                        anchors.fill: parent
                        radius: 18 * Appearance.effectiveScale
                        color: "black"
                        opacity: (MprisController.displayedArtFilePath && MprisController.displayedArtFilePath.toString() !== "") ? 0.35 : 0
                        visible: opacity > 0
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: 18 * Appearance.effectiveScale
                        fill: 1
                        visible: !MprisController.isPlaying && (MprisController.displayedArtFilePath?.toString() === "")
                        color: Appearance.colors.colNotchText
                    }

                    // Play/Pause (visible when playing or when art exists)
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.isPlaying ? "pause" : "play_arrow"
                        iconSize: 24 * Appearance.effectiveScale
                        fill: 1
                        color: "white"
                        opacity: 0.9
                        visible: MprisController.isPlaying || (MprisController.displayedArtFilePath?.toString() !== "")
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisController.togglePlaying()
                    }
                }

                // ── 2. Skip Previous ──
                MaterialSymbol {
                    text: "skip_previous"; iconSize: 22 * Appearance.effectiveScale; fill: 1; color: Appearance.colors.colNotchText
                    opacity: MprisController.canGoPrevious ? 1 : 0.4
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                        onClicked: MprisController.previous() 
                    }
                }

                // ── 3. Slider ──
                StyledSlider {
                    id: progressSlider
                    Layout.fillWidth: true; Layout.preferredHeight: 14 * Appearance.effectiveScale
                    configuration: StyledSlider.Configuration.Wavy
                    wavy: MprisController.isPlaying
                    value: MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0
                    highlightColor: MprisController.dynPrimary
                    trackColor: MprisController.dynSecondaryContainer
                    handleColor: MprisController.dynPrimary
                    onMoved: if (MprisController.activePlayer) MprisController.activePlayer.position = value * MprisController.activePlayer.length
                    
                    Connections {
                        target: MprisController
                        function onPositionChanged() {
                            if (!progressSlider.pressed) {
                                progressSlider.value = MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0;
                            }
                        }
                    }
                }

                // ── 4. Skip Next ──
                MaterialSymbol {
                    text: "skip_next"; iconSize: 22 * Appearance.effectiveScale; fill: 1; color: Appearance.colors.colNotchText
                    opacity: MprisController.canGoNext ? 1 : 0.4
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                        onClicked: MprisController.next() 
                    }
                }

                // ── 5. Lyrics Toggle ──
                MaterialSymbol {
                    text: "lyrics"; iconSize: 22 * Appearance.effectiveScale; fill: Config.options.appearance.lyrics.showFloatingLyrics ? 1 : 0
                    color: Config.options.appearance.lyrics.showFloatingLyrics ? MprisController.dynPrimary : Appearance.colors.colNotchText
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                        onClicked: {
                            Config.options.appearance.lyrics.showFloatingLyrics = !Config.options.appearance.lyrics.showFloatingLyrics
                        }
                    }
                }
            }

            // --- Style 2: Full Media Card ---
            Loader {
                id: fullLoader
                anchors.fill: parent
                active: popupWindow.isFull
                visible: popupWindow.isFull
                sourceComponent: MediaCard {
                    // Force a slightly different styling if needed
                    radius: Appearance.rounding.button
                }
            }
        }
    }
}
