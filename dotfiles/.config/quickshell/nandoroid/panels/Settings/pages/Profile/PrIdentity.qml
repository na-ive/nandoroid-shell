import "../../../../core"
import "../../../../core/functions" as Functions
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0

    SearchHandler {
        searchString: "Identity"
        aliases: ["Display Name", "Description", "Distro", "Uptime"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "badge"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Identity")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Display Name
        SegmentedWrapper {
            id: displayNameCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, displayNameRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                id: displayNameClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: displayNameCard.rTopLeft
                topRightRadius: displayNameCard.rTopRight
                bottomLeftRadius: displayNameCard.rBottomLeft
                bottomRightRadius: displayNameCard.rBottomRight
                onClicked: displayNameInput.forceActiveFocus()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Leave empty to use system real name.")
                }
            }

            RowLayout {
                id: displayNameRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "person"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Display Name")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledTextInput {
                    id: displayNameInput
                    Layout.preferredWidth: 250 * Appearance.effectiveScale
                    inputRadius: 24
                    text: Config.options.profile.displayName
                    placeholder: SystemInfo.realName || SystemInfo.username

                    onEditingFinished: displayNameDebounceTimer.restart()
                }

                Timer {
                    id: displayNameDebounceTimer
                    interval: 800
                    repeat: false
                    onTriggered: {
                        Config.options.profile.displayName = displayNameInput.text
                    }
                }
            }
        }

        // Description Text
        SegmentedWrapper {
            id: descriptionCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, descRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            MouseArea {
                id: descriptionHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: descriptionHoverArea.containsMouse
                    text: I18nService.tr("Shown below your display name.")
                }
            }

            RowLayout {
                id: descRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "subject"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Description Text")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale

                    Repeater {
                        model: [
                            { label: I18nService.tr("Distro"), value: "::distro::" },
                            { label: I18nService.tr("Uptime"), value: "::uptime::" }
                        ]

                        delegate: SegmentedButton {
                            required property var modelData
                            isHighlighted: Config.options.profile.descriptionText === modelData.value
                            buttonText: modelData.label
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            onClicked: Config.options.profile.descriptionText = modelData.value
                        }
                    }
                }
            }
        }
    }
}
