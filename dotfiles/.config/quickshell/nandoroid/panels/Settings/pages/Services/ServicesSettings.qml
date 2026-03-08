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
    contentHeight: mainCol.implicitHeight + 48
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
        spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            StyledText {
                text: "Services"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
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
        ServicesSearch { Layout.fillWidth: true }
        ServicesNetwork { Layout.fillWidth: true }
        ServicesDisk { Layout.fillWidth: true }
        ServicesPerformance { Layout.fillWidth: true }
        ServicesMedia { Layout.fillWidth: true }
        ServicesPower { Layout.fillWidth: true }
        ServicesSystem { Layout.fillWidth: true }
        ServicesGitHub { Layout.fillWidth: true }
    }
}
