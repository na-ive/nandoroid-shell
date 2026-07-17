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
    implicitWidth: 420 * Appearance.effectiveScale
    implicitHeight: 228 * Appearance.effectiveScale

    property bool showLyrics: Config.options.appearance.mediaWidget.showLyrics
    property bool viewLyrics: false

    onViewLyricsChanged: {
        LyricsService.desktopWidgetLyricsActive = viewLyrics;
        if (viewLyrics) {
            LyricsService.restartLyrics();
        }
    }

    // Main Card Background
    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 30 * Appearance.effectiveScale
        color: Appearance.colors.colOnPrimary // Card bg = play/pause icon color (user request)
    }

    // Toggle button in top right corner (M3 Styled Shape)
    Item {
        id: lyricsToggleBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16 * Appearance.effectiveScale
        anchors.rightMargin: 16 * Appearance.effectiveScale
        implicitWidth: 32 * Appearance.effectiveScale
        implicitHeight: 32 * Appearance.effectiveScale
        z: 20

        MaterialShape {
            anchors.fill: parent
            shape: MaterialShape.Shape.Cookie4Sided
            // Using colTertiaryContainer in dark mode and colSecondaryContainer in light mode for soft pastel visual
            color: viewLyrics 
                ? Appearance.colors.colPrimary 
                : (Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer)

            MaterialSymbol {
                anchors.centerIn: parent
                text: viewLyrics ? "music_note" : "lyrics"
                iconSize: 18 * Appearance.effectiveScale
                fill: 0
                color: viewLyrics 
                    ? Appearance.colors.colOnPrimary 
                    : (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    viewLyrics = !viewLyrics;
                    if (viewLyrics) {
                        if (!Config.options.appearance.lyrics.showFloatingLyrics) {
                            LyricsService.restartLyrics();
                        }
                    }
                }
            }
        }
    }

    // StackLayout to toggle between Media Control (0) and Lyrics View (1)
    StackLayout {
        id: mainStack
        anchors.fill: parent
        anchors.margins: 17 * Appearance.effectiveScale
        anchors.bottomMargin: 22 * Appearance.effectiveScale
        currentIndex: viewLyrics ? 1 : 0

        // PAGE 0: Media Control & Info View
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2 * Appearance.effectiveScale // Tighter spacing for title/artist

            // 1. TITLE (Centered, bounded from lyrics button)
            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 48 * Appearance.effectiveScale
                Layout.rightMargin: 48 * Appearance.effectiveScale
                horizontalAlignment: Text.AlignHCenter
                text: Functions.StringUtils.cleanMusicTitle(MprisController.trackTitle) || "No Music Playing"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colPrimary // Title on colOnPrimary dark card
                elide: Text.ElideRight
            }

            // 2. ARTIST (Centered, bounded from lyrics button)
            StyledText {
                Layout.fillWidth: true
                Layout.leftMargin: 48 * Appearance.effectiveScale
                Layout.rightMargin: 48 * Appearance.effectiveScale
                horizontalAlignment: Text.AlignHCenter
                text: {
                    let rawTitle = (MprisController.trackTitle || "").trim().toLowerCase();
                    let hasTitle = rawTitle !== "" && rawTitle !== "no media" && rawTitle !== "no music playing";
                    let hasArtist = MprisController.trackArtist && MprisController.trackArtist.trim() !== "";
                    if (hasTitle) {
                        return hasArtist ? MprisController.trackArtist : "Unknown Artist";
                    }
                    return "Play some media";
                }
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
                    id: prevBtn
                    implicitWidth: 62 * Appearance.effectiveScale
                    implicitHeight: 62 * Appearance.effectiveScale

                    property bool hovered: false
                    property bool pressed: false

                    MaterialShape {
                        anchors.fill: parent
                        shape: MaterialShape.Shape.Cookie12Sided
                        color: Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer

                        MaterialSymbol {
                            id: prevIcon
                            anchors.centerIn: parent
                            text: "skip_previous"
                            iconSize: 28 * Appearance.effectiveScale
                            fill: 0
                            color: prevBtn.hovered
                                ? (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colPrimary)
                                : (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: prevBtn.hovered = true
                            onExited: prevBtn.hovered = false
                            onPressed: prevBtn.pressed = true
                            onReleased: prevBtn.pressed = false
                            onClicked: MprisController.previous()
                        }
                    }
                }

                // Play Button (Wide Pill)
                Rectangle {
                    id: playBtn
                    implicitWidth: 192 * Appearance.effectiveScale
                    implicitHeight: 66 * Appearance.effectiveScale
                    radius: 33 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                    Layout.alignment: Qt.AlignVCenter

                    property bool hovered: false
                    property bool pressed: false

                    MaterialSymbol {
                        id: playIcon
                        anchors.centerIn: parent
                        text: MprisController.isPlaying ? "pause" : "play_arrow"
                        iconSize: 40 * Appearance.effectiveScale
                        fill: 0
                        color: playBtn.pressed
                            ? Functions.ColorUtils.applyAlpha(Appearance.colors.colOnPrimary, 0.7)
                            : Appearance.colors.colOnPrimary
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Appearance.colors.colOnPrimary
                        opacity: playBtn.pressed ? 0.15 : (playBtn.hovered ? 0.08 : 0)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: playBtn.hovered = true
                        onExited: playBtn.hovered = false
                        onPressed: playBtn.pressed = true
                        onReleased: playBtn.pressed = false
                        onClicked: MprisController.togglePlaying()
                    }
                }

                // Next Button
                Item {
                    id: nextBtn
                    implicitWidth: 62 * Appearance.effectiveScale
                    implicitHeight: 62 * Appearance.effectiveScale

                    property bool hovered: false
                    property bool pressed: false

                    MaterialShape {
                        anchors.fill: parent
                        shape: MaterialShape.Shape.Cookie12Sided
                        color: Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer

                        MaterialSymbol {
                            id: nextIcon
                            anchors.centerIn: parent
                            text: "skip_next"
                            iconSize: 28 * Appearance.effectiveScale
                            fill: 0
                            color: nextBtn.hovered
                                ? (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colPrimary)
                                : (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: nextBtn.hovered = true
                            onExited: nextBtn.hovered = false
                            onPressed: nextBtn.pressed = true
                            onReleased: nextBtn.pressed = false
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

                // Circle dot handle
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

        // PAGE 1: Lyrics View (Clean 5 Lines Display)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Item { Layout.fillHeight: true } // Spacer

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4 * Appearance.effectiveScale

                // 5 Line Lyrics Display (dynamically centered around the active line index 'before')
                Repeater {
                    model: {
                        if (LyricsService.slots.length === 0) return [];
                        let mid = LyricsService.before;
                        // Returns 5 indices centered around 'mid': [mid-2, mid-1, mid, mid+1, mid+2]
                        return [mid - 2, mid - 1, mid, mid + 1, mid + 2];
                    }
                    delegate: StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: {
                            let slotIndex = modelData;
                            if (slotIndex < 0 || slotIndex >= LyricsService.slots.length) return "";
                            let slot = LyricsService.slots[slotIndex];
                            if (!slot) return "";
                            return Config.options.appearance.lyrics.lyricsUseRomaji ? slot.romajiText : slot.originalText;
                        }
                        font.pixelSize: modelData === LyricsService.before // Active line is bigger
                            ? Appearance.font.pixelSize.large
                            : Appearance.font.pixelSize.small
                        font.weight: modelData === LyricsService.before ? Font.Bold : Font.Normal
                        color: {
                            if (modelData === LyricsService.before) return Appearance.colors.colPrimary;
                            // Make outer lines even more faded
                            let isOuter = (modelData === LyricsService.before - 2 || modelData === LyricsService.before + 2);
                            let alpha = isOuter ? 0.25 : 0.45;
                            return Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, alpha);
                        }
                        elide: modelData === LyricsService.before ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: modelData === LyricsService.before ? 2 : 1 // Active line can wrap up to 2 lines for karaoke
                        
                        Behavior on font.pixelSize { NumberAnimation { duration: 200 } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                
                // Fallback if no lyrics/loading
                StyledText {
                    visible: LyricsService.slots.length === 0
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: LyricsService.status === "loading" ? "Loading lyrics..." : "No lyrics available"
                    color: Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.6)
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
            }

            Item { Layout.fillHeight: true } // Spacer
        }
    }

    // Romaji/Original switcher (outside layout, anchored - won't affect centering)
    Item {
        id: romajiToggleBtn
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 16 * Appearance.effectiveScale
        anchors.leftMargin: 16 * Appearance.effectiveScale
        implicitWidth: 32 * Appearance.effectiveScale
        implicitHeight: 32 * Appearance.effectiveScale
        visible: viewLyrics
        z: 20

        property bool hovered: false

        MaterialShape {
            anchors.fill: parent
            shape: MaterialShape.Shape.Pill
            color: Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                text: Config.options.appearance.lyrics.lyricsUseRomaji ? "text_fields" : "translate"
                iconSize: 18 * Appearance.effectiveScale
                fill: 1
                color: romajiToggleBtn.hovered
                    ? (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colPrimary)
                    : (Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer)
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onEntered: romajiToggleBtn.hovered = true
                onExited: romajiToggleBtn.hovered = false
                onClicked: {
                    if (Config.ready) {
                        Config.options.appearance.lyrics.lyricsUseRomaji = !Config.options.appearance.lyrics.lyricsUseRomaji;
                    }
                }
            }
        }
    }
}
