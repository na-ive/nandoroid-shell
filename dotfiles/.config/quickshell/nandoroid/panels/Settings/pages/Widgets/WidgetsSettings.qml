import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import "../WallpaperStyle"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Flickable {
    id: root
    anchors.fill: parent
    contentHeight: mainCol.implicitHeight + (48 * Appearance.effectiveScale)
    clip: true
    
    property bool isOnboarding: false
    
    ScrollBar.vertical: StyledScrollBar {}

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24 * Appearance.effectiveScale
        spacing: 32 * Appearance.effectiveScale

        // ── Header Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale
            visible: !root.isOnboarding

            StyledText {
                text: "Widgets"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                text: "Manage your desktop widgets"
                font.pixelSize: Appearance.font.pixelSize.medium
                color: Appearance.colors.colOnLayer2
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        // ── Desktop Clock Settings ──
        WsClock { Layout.fillWidth: true; visible: !root.isOnboarding }

        // ── At a Glance Settings ──
        WsAtAGlance { Layout.fillWidth: true; visible: !root.isOnboarding }
    }
}
