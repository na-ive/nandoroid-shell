import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

/**
 * Services Settings page.
 * Manages global services like Weather.
 */
Flickable {
    id: root
    width: parent ? parent.width : 0
    height: parent ? parent.height : 0
    contentHeight: mainCol.implicitHeight + (48 * Appearance.effectiveScale)
    clip: true
    
    ScrollBar.vertical: StyledScrollBar {}

    SequentialAnimation {
        id: highlightAnim
        property var target: null
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 1; to: 0.3; duration: 200 }
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 0.3; to: 1; duration: 400 }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 32 * Appearance.effectiveScale

        // ── Header ──
        ColumnLayout {
            spacing: 4 * Appearance.effectiveScale
            StyledText {
                text: "Services"
                font.pixelSize: Math.round(24 * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: "Configure global system services and data providers."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Weather Section ──
        ServicesWeather { Layout.fillWidth: true }

        // ── Search Section ──
        ServicesSearch { Layout.fillWidth: true }

        // ── Network Section ──
        ServicesNetwork { Layout.fillWidth: true }

        // ── Media Section ──
        ServicesMedia { Layout.fillWidth: true }

        // ── Lyrics Section ──
        ServicesLyrics { Layout.fillWidth: true }

        // ── GitHub Section ──
        ServicesGitHub { Layout.fillWidth: true }
    }
}
