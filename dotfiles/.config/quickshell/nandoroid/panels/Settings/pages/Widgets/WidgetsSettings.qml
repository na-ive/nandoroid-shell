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
        width: parent.width - (24 * Appearance.effectiveScale)
        anchors.margins: 4 * Appearance.effectiveScale
        spacing: 32 * Appearance.effectiveScale
        
        SearchHandler {
            visible: false
            searchString: "Widgets"
            aliases: ["Widget", "Desktop"]
        }
        
        SearchHandler {
            visible: false
            searchString: "Desktop Clock"
            aliases: ["Clock", "Time", "Watch", "Clock Style"]
        }

        // ── Header Section ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale
            visible: !root.isOnboarding

            StyledText {
                text: "Widgets"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            StyledText {
                text: "Manage your desktop widgets."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        // ── Desktop Clock Settings ──
        WsClock { 
            Layout.fillWidth: true
            visible: !root.isOnboarding
            isDedicatedContext: true
            dedicatedIsLock: false
        }

        // ── At a Glance Settings ──
        WsAtAGlance { Layout.fillWidth: true; visible: !root.isOnboarding }

        // ── Desktop Media Player Settings ──
        WsDesktopMedia { Layout.fillWidth: true; visible: !root.isOnboarding }
    }
}
