import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

ColumnLayout {
    Layout.fillWidth: true
    spacing: 4 * Appearance.effectiveScale

    RowLayout {
        spacing: 12 * Appearance.effectiveScale
        Layout.bottomMargin: 8 * Appearance.effectiveScale
        MaterialSymbol {
            text: "bedtime"
            iconSize: 24 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
        }
        StyledText {
            text: I18nService.tr("Eye Care")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
    }

    // Night Light (whole card clickable)
    SegmentedWrapper {
        id: nightCard
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, nightRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RippleButton {
            id: nightClickArea
            anchors.fill: parent
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
            buttonRadius: 0
            topLeftRadius: nightCard.rTopLeft
            topRightRadius: nightCard.rTopRight
            bottomLeftRadius: nightCard.rBottomLeft
            bottomRightRadius: nightCard.rBottomRight
            onClicked: Hyprsunset.toggle()

            StyledToolTip {
                extraVisibleCondition: parent.hovered || parent.realHovered
                text: I18nService.tr("Reduce eye strain by displaying warmer colors.")
            }
        }

        RowLayout {
            id: nightRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol {
                text: "nightlight"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: I18nService.tr("Night Light")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            AndroidToggle {
                checked: Hyprsunset.active
                onToggled: Hyprsunset.toggle()
            }
        }
    }

    // Color Temperature
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, colorTempRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        opacity: Hyprsunset.active ? 1.0 : 0.4
        enabled: Hyprsunset.active

        MouseArea {
            id: colorTempHoverArea
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
            StyledToolTip {
                extraVisibleCondition: false
                alternativeVisibleCondition: colorTempHoverArea.containsMouse
                text: I18nService.tr("Warmth of the applied color filter.")
            }
        }

        RowLayout {
            id: colorTempRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol {
                text: "thermostat"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: I18nService.tr("Color Temperature")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            StyledStepper {
                from: 1200
                to: 6500
                stepSize: 100
                decimals: 0
                suffix: "K"
                value: (Config.options && Config.options.nightMode) ? Config.options.nightMode.colorTemperature : 4000
                onValueChanged: {
                    if (Config.ready && Config.options.nightMode) {
                        Config.options.nightMode.colorTemperature = value;
                    }
                }
            }
        }
    }
}
