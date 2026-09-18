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
        searchString: "Screenshot"
        aliases: ["Screen Record", "Screen Capture", "Screen Snip", "Capture", "Recording", "Save Path", "Storage", "Screenshot Path", "Recording Path"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "screenshot"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Screenshot & Screen Record")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Auto Save Screenshots (whole card clickable)
        SegmentedWrapper {
            id: autoSaveCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, autoSaveRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: autoSaveCard.rTopLeft
                topRightRadius: autoSaveCard.rTopRight
                bottomLeftRadius: autoSaveCard.rBottomLeft
                bottomRightRadius: autoSaveCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.screenshot) {
                        Config.options.screenshot.autoSave = !Config.options.screenshot.autoSave;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Automatically save screenshots to the storage folder.")
                }
            }

            RowLayout {
                id: autoSaveRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "photo_camera"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Auto Save Screenshots")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.screenshot && Config.options.screenshot.autoSave)
                    onToggled: {
                        if (Config.ready && Config.options.screenshot) {
                            Config.options.screenshot.autoSave = !Config.options.screenshot.autoSave;
                        }
                    }
                }
            }
        }

        // Auto Copy to Clipboard (whole card clickable)
        SegmentedWrapper {
            id: autoCopyCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, autoCopyRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: autoCopyCard.rTopLeft
                topRightRadius: autoCopyCard.rTopRight
                bottomLeftRadius: autoCopyCard.rBottomLeft
                bottomRightRadius: autoCopyCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.screenshot) {
                        Config.options.screenshot.autoCopy = !Config.options.screenshot.autoCopy;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Automatically copy the screenshot to your clipboard.")
                }
            }

            RowLayout {
                id: autoCopyRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "content_copy"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Auto Copy to Clipboard")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.screenshot && Config.options.screenshot.autoCopy)
                    onToggled: {
                        if (Config.ready && Config.options.screenshot) {
                            Config.options.screenshot.autoCopy = !Config.options.screenshot.autoCopy;
                        }
                    }
                }
            }
        }

        // Android-style Preview (whole card clickable)
        SegmentedWrapper {
            id: previewCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, previewRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: previewCard.rTopLeft
                topRightRadius: previewCard.rTopRight
                bottomLeftRadius: previewCard.rBottomLeft
                bottomRightRadius: previewCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.screenshot) {
                        Config.options.screenshot.showPreview = !Config.options.screenshot.showPreview;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Display a floating preview overlay after capturing.")
                }
            }

            RowLayout {
                id: previewRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "visibility"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Show Android-style Preview")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.screenshot && Config.options.screenshot.showPreview)
                    onToggled: {
                        if (Config.ready && Config.options.screenshot) {
                            Config.options.screenshot.showPreview = !Config.options.screenshot.showPreview;
                        }
                    }
                }
            }
        }

        // Satty Annotation (whole card clickable)
        SegmentedWrapper {
            id: sattyCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, sattyRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: sattyCard.rTopLeft
                topRightRadius: sattyCard.rTopRight
                bottomLeftRadius: sattyCard.rBottomLeft
                bottomRightRadius: sattyCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.regionSelector && Config.options.regionSelector.annotation) {
                        Config.options.regionSelector.annotation.useSatty = !Config.options.regionSelector.annotation.useSatty;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Use Satty (modern GTK4) instead of Swappy (classic GTK3) for editing.")
                }
            }

            RowLayout {
                id: sattyRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "edit"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Use Satty for Annotation")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.annotation && Config.options.regionSelector.annotation.useSatty)
                    onToggled: {
                        if (Config.ready && Config.options.regionSelector && Config.options.regionSelector.annotation) {
                            Config.options.regionSelector.annotation.useSatty = !Config.options.regionSelector.annotation.useSatty;
                        }
                    }
                }
            }
        }

        // Screenshot Save Path (whole card focuses the input)
        SegmentedWrapper {
            id: pathCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, pathRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: pathCard.rTopLeft
                topRightRadius: pathCard.rTopRight
                bottomLeftRadius: pathCard.rBottomLeft
                bottomRightRadius: pathCard.rBottomRight
                onClicked: pathInput.forceActiveFocus()
            }

            RowLayout {
                id: pathRow
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
                    text: I18nService.tr("Screenshot Path")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledTextInput {
                    id: pathInput
                    Layout.preferredWidth: 250 * Appearance.effectiveScale
                    inputRadius: 24
                    text: (Config.ready && Config.options.screenshot) ? Functions.FileUtils.shortenHomePath(Config.options.screenshot.savePath) : ""
                    placeholder: I18nService.tr("Enter screenshot directory path")
                    onEditingFinished: {
                        if (Config.ready && Config.options.screenshot) {
                            Config.options.screenshot.savePath = Functions.FileUtils.expandHomePath(Functions.FileUtils.trimFileProtocol(text));
                        }
                    }
                }
            }
        }

        // Recording Save Path (whole card focuses the input)
        SegmentedWrapper {
            id: recordPathCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, recordPathRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: recordPathCard.rTopLeft
                topRightRadius: recordPathCard.rTopRight
                bottomLeftRadius: recordPathCard.rBottomLeft
                bottomRightRadius: recordPathCard.rBottomRight
                onClicked: recordPathInput.forceActiveFocus()
            }

            RowLayout {
                id: recordPathRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "videocam"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Recording Path")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledTextInput {
                    id: recordPathInput
                    Layout.preferredWidth: 250 * Appearance.effectiveScale
                    inputRadius: 24
                    text: (Config.ready && Config.options.screenshot) ? Functions.FileUtils.shortenHomePath(Config.options.screenshot.recordPath) : ""
                    placeholder: I18nService.tr("Enter recording directory path")
                    onEditingFinished: {
                        if (Config.ready && Config.options.screenshot) {
                            Config.options.screenshot.recordPath = Functions.FileUtils.expandHomePath(Functions.FileUtils.trimFileProtocol(text));
                        }
                    }
                }
            }
        }
    }
}
