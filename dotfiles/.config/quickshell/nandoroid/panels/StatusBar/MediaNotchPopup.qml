import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions

/**
 * Media Notch Popup — The expanded HUD that appears below the Dynamic Island.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: popupWindow
        required property var modelData
        screen: modelData
        
        // Positioning: Center top, below status bar
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "nandoroid:media-hud"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
        }

        WlrLayershell.margins {
            top: 44
        }

        // Responsive window width
        implicitWidth: Math.min(320, modelData.width * 0.9)
        implicitHeight: contentRect.height + 20
        color: "transparent"

        visible: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) || contentRect.opacity > 0

        Rectangle {
            id: contentRect
            // Responsive pill width
            width: parent.width - 20
            anchors.horizontalCenter: parent.horizontalCenter
            height: mainLayout.implicitHeight + 12
            color: "black"
            radius: Appearance.rounding.button // Use token for consistency

            // Animation for entry
            opacity: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) ? 1 : 0
            scale: (GlobalStates.mediaNotchOpen && (GlobalStates.activeMediaNotchScreen === null || GlobalStates.activeMediaNotchScreen === modelData)) ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuint } }
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

            // Hover tracking area
            HoverHandler {
                id: popupHoverHandler
                onHoveredChanged: {
                    if (hovered && Config.options.media.enableMediaHover) GlobalStates.openMediaNotch(modelData);
                    else GlobalStates.closeMediaNotchWithDelay();
                }
            }

            RowLayout {
                id: mainLayout
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                // ── 1. Art with Play/Pause Overlay ──
                MaterialShape {
                    width: 36; height: 36
                    shape: MaterialShape.Shape.Circle
                    image: MprisController.displayedArtFilePath || ""
                    color: Appearance.colors.colLayer2
                    
                    // Semi-transparent overlay for contrast
                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: "black"
                        opacity: (MprisController.displayedArtFilePath && MprisController.displayedArtFilePath.toString() !== "") ? 0.35 : 0
                        visible: opacity > 0
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "music_note"
                        iconSize: 18
                        fill: 1
                        visible: !MprisController.displayedArtFilePath || MprisController.displayedArtFilePath.toString() === ""
                        color: Appearance.colors.colNotchText
                    }

                    // Play/Pause Overlay
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: MprisController.isPlaying ? "pause" : "play_arrow"
                        iconSize: 24
                        fill: 1
                        color: "white"
                        opacity: 0.9
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisController.togglePlaying()
                    }
                }

                // ── 2. Skip Previous ──
                MaterialSymbol {
                    text: "skip_previous"; iconSize: 22; fill: 1; color: Appearance.colors.colNotchText
                    opacity: MprisController.canGoPrevious ? 1 : 0.4
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor; 
                        onClicked: MprisController.previous() 
                    }
                }

                // ── 3. Slider ──
                StyledSlider {
                    id: progressSlider
                    Layout.fillWidth: true; Layout.preferredHeight: 14
                    configuration: StyledSlider.Configuration.Wavy
                    wavy: MprisController.isPlaying
                    value: MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0
                    highlightColor: Appearance.colors.colPrimary
                    trackColor: Appearance.colors.colLayer3
                    handleColor: "white"
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
                    text: "skip_next"; iconSize: 22; fill: 1; color: Appearance.colors.colNotchText
                    opacity: MprisController.canGoNext ? 1 : 0.4
                    MouseArea { 
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor;
                        onClicked: MprisController.next() 
                    }
                }
            }
        }
    }
}
