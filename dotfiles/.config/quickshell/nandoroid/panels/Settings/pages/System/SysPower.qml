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
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Power Management"
        aliases: ["Power Profile", "Battery", "Custom Power", "Ryzen", "Power Mode"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "bolt"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Power Profile")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Custom Power Profile Toggle (whole card clickable)
        SegmentedWrapper {
            id: powerEnableCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, powerEnableRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                id: powerEnableClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: powerEnableCard.rTopLeft
                topRightRadius: powerEnableCard.rTopRight
                bottomLeftRadius: powerEnableCard.rBottomLeft
                bottomRightRadius: powerEnableCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.powerProfile) {
                        Config.options.powerProfile.enabled = !Config.options.powerProfile.enabled;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Enable overriding system power modes via a local file.")
                }
            }

            RowLayout {
                id: powerEnableRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "power_settings_new"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Custom Power Profile")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                    onToggled: {
                        if (Config.ready && Config.options.powerProfile) {
                            Config.options.powerProfile.enabled = !Config.options.powerProfile.enabled;
                        }
                    }
                }
            }
        }

        // Custom Profile Path (whole card focuses the input)
        SegmentedWrapper {
            id: powerPathCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, powerPathRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            enabled: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
            opacity: enabled ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RippleButton {
                id: powerPathClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: powerPathCard.rTopLeft
                topRightRadius: powerPathCard.rTopRight
                bottomLeftRadius: powerPathCard.rBottomLeft
                bottomRightRadius: powerPathCard.rBottomRight
                onClicked: powerPathInput.forceActiveFocus()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("The exact path to write custom profile strings.")
                }
            }

            RowLayout {
                id: powerPathRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "folder_open"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Custom Profile Path")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledTextInput {
                    id: powerPathInput
                    Layout.preferredWidth: 250 * Appearance.effectiveScale
                    inputRadius: 24
                    text: (Config.ready && Config.options.powerProfile) ? Functions.FileUtils.shortenHomePath(Config.options.powerProfile.customPath) : "/tmp/ryzen_mode"
                    placeholder: I18nService.tr("Enter path (e.g., /tmp/ryzen_mode)")
                    onEditingFinished: {
                        if (Config.ready && Config.options.powerProfile) {
                            Config.options.powerProfile.customPath = Functions.FileUtils.expandHomePath(text);
                        }
                    }
                }
            }
        }
    }
}
