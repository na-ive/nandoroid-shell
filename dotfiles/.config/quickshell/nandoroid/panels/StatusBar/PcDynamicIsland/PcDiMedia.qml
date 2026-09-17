import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import "../../../core"
import "../../../services"
import "../../../widgets"

Item {
    id: diMediaRoot
    required property Item di
    anchors.fill: parent

    readonly property bool _cavaNeeded: {
        const style = Config.ready && Config.options.statusBar?.pcIsland ? Config.options.statusBar.pcIsland.visualizerStyle : "dots"
        return style !== "none" && (di.activePlayer?.isPlaying ?? false)
    }
    property bool _cavaActive: false
    function _syncCava() {
        const need = _cavaNeeded
        if (need && !_cavaActive) { CavaService.refCount++; _cavaActive = true }
        else if (!need && _cavaActive) { CavaService.refCount--; _cavaActive = false }
    }
    on_CavaNeededChanged: _syncCava()
    Component.onCompleted: _syncCava()
    Component.onDestruction: if (_cavaActive) { CavaService.refCount--; _cavaActive = false }

    Rectangle {
        id: mediaMask
        anchors.fill: parent
        color: "transparent"
        radius: height / 2

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: mediaMask.width
                height: mediaMask.height
                radius: mediaMask.radius
            }
        }

        // Full-island wave background (fills the whole pill, clipped by mediaMask).
        // Same faint fill look as the source port (alpha ~0.15).
        WaveVisualizer {
            id: visualizerCanvas
            anchors.fill: parent
            points: GlobalStates.visualizerPoints
            style: "wave"
            maxVisualizerValue: 1000
            smoothing: 2
            color: Appearance.colors.colNotchText
            opacityMultiplier: 0.15
            visible: (Config.ready && Config.options.statusBar?.pcIsland ? Config.options.statusBar.pcIsland.visualizerStyle : "dots") === "wave"
        }

        Rectangle {
            id: artMask
            width: di.isMaterial ? di.pillHeight : di.pillHeight - 8
            height: di.isMaterial ? di.pillHeight : di.pillHeight - 8
            anchors {
                left: parent.left
                leftMargin: 4
                verticalCenter: parent.verticalCenter
            }
            radius: di.isMaterial ? Appearance.rounding.full : (Appearance.rounding.small ?? 8)
            color: Appearance.colors.colLayer1
            clip: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: artMask.width
                    height: artMask.height
                    radius: artMask.radius
                }
            }

            StyledImage {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: di.activePlayer?.trackArtUrl ?? ""
                sourceSize.width: artMask.width * 2
                sourceSize.height: artMask.height * 2
                visible: (di.activePlayer?.trackArtUrl ?? "") !== ""
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                iconSize: 14
                color: Appearance.colors.colOnLayer1
                visible: (di.activePlayer?.trackArtUrl ?? "") === ""
            }
        }

        StyledText {
            id: trackTitleMetrics
            visible: false
            text: di.activePlayer?.trackTitle ?? ""
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
        }
        StyledText {
            id: trackArtistMetrics
            visible: false
            text: di.activePlayer?.trackArtist ?? ""
            font.pixelSize: Appearance.font.pixelSize.smallest
        }

        ColumnLayout {
            id: trackInfoColumn
            anchors {
                left: artMask.right
                leftMargin: 8
                verticalCenter: parent.verticalCenter
                right: mediaControlsRow.visible ? mediaControlsRow.left
                    : (islandVisualizer.visible ? islandVisualizer.left : parent.right)
                rightMargin: 8
            }
            spacing: di.isMaterial ? -2 : -4
            opacity: di.mediaTrackInfoVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            StyledText {
                Layout.fillWidth: true
                text: di.activePlayer?.trackTitle ?? ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.DemiBold
                color: Appearance.colors.colNotchText
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }
            StyledText {
                Layout.fillWidth: true
                text: di.activePlayer?.trackArtist ?? ""
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colNotchText
                opacity: 0.7
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
            }

            readonly property real widestLineWidth: Math.max(trackTitleMetrics.implicitWidth, trackArtistMetrics.implicitWidth)

            readonly property real computedContentWidth: artMask.width
                + 8
                + trackInfoColumn.widestLineWidth
                + 12
                + (mediaControlsRow.visible ? mediaControlsRow.implicitWidth
                    : (islandVisualizer.visible ? islandVisualizer.width : 0))
                + 4
                + 10

            onComputedContentWidthChanged: di.reportWidth("mediaTextContentWidth", trackInfoColumn.computedContentWidth)
            Component.onCompleted: di.reportWidth("mediaTextContentWidth", trackInfoColumn.computedContentWidth)
        }

        WaveVisualizer {
            id: islandVisualizer
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 30
            height: di.isMaterial ? di.pillHeight * 1.5 : di.pillHeight * 0.85
            points: GlobalStates.visualizerPoints
            style: "dots"
            dotsBarCount: 5
            dotsDotSize: 3 * Appearance.effectiveScale
            dotsDotSpacing: 3 * Appearance.effectiveScale
            dotsMaxBarHeight: di.isMaterial ? di.pillHeight * 1.5 : di.pillHeight * 0.85
            color: Appearance.colors.colNotchText
            opacityMultiplier: 0.85
            visible: !(Config.ready && Config.options.statusBar?.pcIsland ? Config.options.statusBar.pcIsland.showMediaControls : false)
                && (Config.ready && Config.options.statusBar?.pcIsland ? Config.options.statusBar.pcIsland.visualizerStyle : "dots") === "dots"
        }

        RowLayout {
            id: mediaControlsRow
            anchors {
                right: parent.right
                rightMargin: 8
                verticalCenter: parent.verticalCenter
            }
            spacing: di.isMaterial ? -2 : -4
            visible: (Config.ready && Config.options.statusBar?.pcIsland ? Config.options.statusBar.pcIsland.showMediaControls : false)

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 20
                implicitHeight: 20
                visible: di.activePlayer?.canGoPrevious ?? false

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    fill: 1
                    iconSize: di.isMaterial ? 20 : 16
                    color: Appearance.colors.colNotchText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: di.activePlayer?.previous()
                }
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 22
                implicitHeight: 22

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: di.activePlayer?.isPlaying ? "pause" : "play_arrow"
                    fill: 1
                    iconSize: di.isMaterial ? 20 : 18
                    color: Appearance.colors.colNotchText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: di.activePlayer?.togglePlaying()
                }
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 20
                implicitHeight: 20
                visible: di.activePlayer?.canGoNext ?? false

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "skip_next"
                    fill: 1
                    iconSize: di.isMaterial ? 20 : 16
                    color: Appearance.colors.colNotchText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: di.activePlayer?.next()
                }
            }
        }
    }
}
