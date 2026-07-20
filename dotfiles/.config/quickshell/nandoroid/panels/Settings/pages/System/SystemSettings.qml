import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * System Settings page.
 * Android-style system configuration: date & time, language, storage, performance, power.
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
        width: parent.width - (24 * Appearance.effectiveScale)
        spacing: 32 * Appearance.effectiveScale

        // ── Header ──
        ColumnLayout {
            spacing: 4 * Appearance.effectiveScale
            StyledText {
                text: "System"
                font.pixelSize: Math.round(24 * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: "Date & time, language, storage paths, performance, and system behavior."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Date & Time ── (first, like Android)
        SysDateTime { Layout.fillWidth: true }

        // ── Language ── (second, like Android)
        SysLanguage { Layout.fillWidth: true }

        // ── Screenshot & Screen Record ──
        SysScreenshot { Layout.fillWidth: true }

        // ── Performance Monitoring ──
        SysPerformance { Layout.fillWidth: true }

        // ── Power Management ──
        SysPower { Layout.fillWidth: true }

        // ── Disk Monitoring ──
        SysDisk { Layout.fillWidth: true }

        // ── System Interface ──
        SysSystemInterface { Layout.fillWidth: true }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 32 * Appearance.effectiveScale }
    }
}
