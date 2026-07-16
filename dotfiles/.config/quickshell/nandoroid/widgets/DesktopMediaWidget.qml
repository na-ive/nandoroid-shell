import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Controls
import "../core"
import "../core/functions" as Functions
import "../services"
import "."

Item {
    id: root
    implicitWidth: 432 * Appearance.effectiveScale
    implicitHeight: 216 * Appearance.effectiveScale

    property bool showLyrics: Config.options.appearance.mediaWidget.showLyrics

    // Main Card Background
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 30 * Appearance.effectiveScale
        color: Appearance.colors.colOnPrimary // Card bg = play/pause icon color (user request)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 17 * Appearance.effectiveScale
        anchors.bottomMargin: 22 * Appearance.effectiveScale
        spacing: 2 * Appearance.effectiveScale // Tighter spacing for title/artist

        // 1. TITLE (Centered)
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Functions.StringUtils.cleanMusicTitle(MprisController.trackTitle) || "No Music Playing"
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary // Title on colOnPrimary dark card
            elide: Text.ElideRight
        }

        // 2. ARTIST (Centered)
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: MprisController.trackArtist || "Tap to Play"
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.75) // Artist subtitle on dark card
            elide: Text.ElideRight
        }
        
        Item { Layout.fillHeight: true } // Flexible spacer to push down to center

        // 3. BUTTONS (Centered, SANGAT BESAR)
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12 * Appearance.effectiveScale

            // Prev Button
            Item {
                implicitWidth: 62 * Appearance.effectiveScale
                implicitHeight: 62 * Appearance.effectiveScale

                MaterialShape {
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Cookie12Sided
                    color: Appearance.colors.colOnTertiaryContainer // Light lavender bg — swapped (terbalik diperbaiki)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 28 * Appearance.effectiveScale
                        fill: 0
                        color: Appearance.colors.colTertiaryContainer // Dark tertiary icon on light bg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisController.previous()
                    }
                }
            }

            // Play Button (Pill Lebar dan Besar)
            Rectangle {
                implicitWidth: 192 * Appearance.effectiveScale
                implicitHeight: 66 * Appearance.effectiveScale
                radius: 33 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary // Teal pill on dark colOnPrimary card
                Layout.alignment: Qt.AlignVCenter

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: MprisController.isPlaying ? "pause" : "play_arrow"
                    iconSize: 40 * Appearance.effectiveScale
                    fill: 0
                    color: Appearance.colors.colOnPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: MprisController.togglePlaying()
                }
            }

            // Next Button
            Item {
                implicitWidth: 62 * Appearance.effectiveScale
                implicitHeight: 62 * Appearance.effectiveScale

                MaterialShape {
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Cookie12Sided
                    color: Appearance.colors.colOnTertiaryContainer // Light lavender bg — swapped (terbalik diperbaiki)

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: 28 * Appearance.effectiveScale
                        fill: 0
                        color: Appearance.colors.colTertiaryContainer // Dark tertiary icon on light bg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MprisController.next()
                    }
                }
            }
        }
        
        Item { Layout.fillHeight: true } // Flexible spacer to balance vertical distribution

        // 4. DURASI SAAT INI / DURASI TOTAL (Centered)
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: Functions.StringUtils.friendlyTimeForSeconds(MprisController.position) + " / " + Functions.StringUtils.friendlyTimeForSeconds(MprisController.length)
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.family: Appearance.font.family.monospace
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary // Same color as title
        }

        // 5. PROGRESS BAR
        StyledSlider {
            id: progressSlider
            Layout.preferredWidth: 170 * Appearance.effectiveScale
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 12 * Appearance.effectiveScale
            handleMargins: 0
            configuration: StyledSlider.Configuration.Wavy
            stopIndicatorValues: []
            animateValue: false
            value: (MprisController.length > 0 ? (MprisController.position / MprisController.length) : 0) || 0
            wavy: MprisController.isPlaying
            highlightColor: Appearance.colors.colPrimary
            trackColor: Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.25)

            // Lingkaran Titik sebagai handle
            handle: Rectangle {
                x: progressSlider.leftPadding + (progressSlider.visualPosition * (progressSlider.availableWidth - width))
                y: (progressSlider.height - height) / 2
                width: 14 * Appearance.effectiveScale
                height: 14 * Appearance.effectiveScale
                radius: width / 2
                color: Appearance.colors.colPrimary
            }

            onMoved: {
                if (MprisController.activePlayer && MprisController.activePlayer.canSeek) {
                    MprisController.activePlayer.position = value * MprisController.activePlayer.length;
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
    }
}
