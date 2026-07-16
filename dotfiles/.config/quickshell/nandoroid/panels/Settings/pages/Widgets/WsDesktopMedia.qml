import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: rootMediaWidget
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "Media Player"
        aliases: ["Widget", "Media", "Player", "Music", "Spotify"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "play_circle"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Desktop Media Player"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            StyledText {
                text: "Reset Position"
                font.pixelSize: Appearance.font.pixelSize.small
                color: maResetMedia.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                MouseArea {
                    id: maResetMedia
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!Config.ready) return;
                        Config.options.appearance.mediaWidget.desktopX = -1;
                        Config.options.appearance.mediaWidget.desktopY = -1;
                    }
                }
            }

            AndroidToggle {
                checked: Config.ready && Config.options.appearance.mediaWidget.showOnDesktop
                onToggled: if (Config.ready) Config.options.appearance.mediaWidget.showOnDesktop = !Config.options.appearance.mediaWidget.showOnDesktop
            }
        }
    }
}
