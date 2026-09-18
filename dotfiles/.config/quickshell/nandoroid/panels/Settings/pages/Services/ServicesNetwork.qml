import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Network Status"
        aliases: ["Speed Meter", "Bandwidth", "Internet", "Ethernet"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "network_check"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Network Status")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Show Network Speed (whole card clickable)
        SegmentedWrapper {
            id: netSpeedCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, netSpeedRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: netSpeedCard.rTopLeft
                topRightRadius: netSpeedCard.rTopRight
                bottomLeftRadius: netSpeedCard.rBottomLeft
                bottomRightRadius: netSpeedCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.bar) {
                        Config.options.bar.show_network_speed = !Config.options.bar.show_network_speed;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Display real-time upload and download speeds in the status bar.")
                }
            }

            RowLayout {
                id: netSpeedRow
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
                    text: I18nService.tr("Show Network Speed")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
                    onToggled: {
                        if (Config.ready && Config.options.bar) {
                            Config.options.bar.show_network_speed = !Config.options.bar.show_network_speed;
                        }
                    }
                }
            }
        }

        // Starting Unit
        SegmentedWrapper {
            id: netUnitCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, netUnitRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            opacity: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? 1.0 : 0.4
            enabled: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                id: netUnitHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: netUnitHoverArea.containsMouse
                    text: I18nService.tr("Select the default unit for speed measurements.")
                }
            }

            RowLayout {
                id: netUnitRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "swap_horiz"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Starting Unit")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale

                    Repeater {
                        model: ["B", "KB", "MB"]
                        delegate: SegmentedButton {
                            required property var modelData
                            isHighlighted: (Config.ready && Config.options.bar) ? Config.options.bar.network_speed_unit === modelData : false

                            buttonText: modelData
                            leftPadding: 16 * Appearance.effectiveScale
                            rightPadding: 16 * Appearance.effectiveScale

                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow

                            onClicked: {
                                if (Config.ready && Config.options.bar) {
                                    Config.options.bar.network_speed_unit = modelData;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Update Interval
        SegmentedWrapper {
            id: netIntervalCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, netIntervalRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            opacity: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed) ? 1.0 : 0.4
            enabled: (Config.ready && Config.options.bar && Config.options.bar.show_network_speed)
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                id: netIntervalHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: netIntervalHoverArea.containsMouse
                    text: I18nService.tr("How often to poll network speeds.")
                }
            }

            RowLayout {
                id: netIntervalRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "schedule"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Update Interval")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledStepper {
                    value: Config.ready ? Config.options.bar.networkSpeedInterval : 3000
                    from: 1000; to: 10000; stepSize: 500
                    decimals: 0
                    suffix: "ms"
                    onValueChanged: if (Config.ready) Config.options.bar.networkSpeedInterval = Math.round(value)
                }
            }
        }
    }
}
