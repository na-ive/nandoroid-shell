import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Performance"
        aliases: ["CPU", "RAM", "Monitoring", "Interval", "Update", "Refresh", "System Monitor"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "monitoring"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Performance Monitoring")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, intervalRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            MouseArea {
                id: intervalHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: intervalHoverArea.containsMouse
                    text: I18nService.tr("How often to refresh system data (statusbar, quick settings, desktop widget).")
                }
            }

            RowLayout {
                id: intervalRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "speed"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Update Interval")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledStepper {
                    id: intervalStepper
                    value: Config.ready ? Config.options.appearance.systemMonitor.updateInterval : 3000
                    from: 1000; to: 10000; stepSize: 500
                    decimals: 0
                    suffix: "ms"
                    onValueChanged: if (Config.ready) Config.options.appearance.systemMonitor.updateInterval = Math.round(value)
                }
            }
        }
    }
}
