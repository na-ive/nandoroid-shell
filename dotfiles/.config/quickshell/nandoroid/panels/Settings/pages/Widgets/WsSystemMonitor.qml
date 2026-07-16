import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: rootSystemMonitorSettings
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "System Monitor"
        aliases: ["Widget", "System", "Monitor", "CPU", "RAM", "Battery", "Disk"]
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
                text: "monitoring"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Desktop System Monitor"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            StyledText {
                text: "Reset Position"
                font.pixelSize: Appearance.font.pixelSize.small
                color: maResetMonitor.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                MouseArea {
                    id: maResetMonitor
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!Config.ready) return;
                        Config.options.appearance.systemMonitor.desktopX = -1;
                        Config.options.appearance.systemMonitor.desktopY = -1;
                    }
                }
            }

            AndroidToggle {
                checked: Config.ready && Config.options.appearance.systemMonitor.showOnDesktop
                onToggled: if (Config.ready) Config.options.appearance.systemMonitor.showOnDesktop = !Config.options.appearance.systemMonitor.showOnDesktop
            }
        }
    }
}
