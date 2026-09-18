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

    SearchHandler { searchString: "Search Engine" }

    // Reusable prefix row (whole card focuses its input)
    component PrefixCard: SegmentedWrapper {
        id: prefixCardRoot
        required property string icon
        required property string title
        required property string description
        required property string placeholderText
        property alias input: prefixInput

        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, prefixRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RippleButton {
            anchors.fill: parent
            colBackground: Appearance.m3colors.m3surfaceContainerHigh
            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
            buttonRadius: 0
            topLeftRadius: prefixCardRoot.rTopLeft
            topRightRadius: prefixCardRoot.rTopRight
            bottomLeftRadius: prefixCardRoot.rBottomLeft
            bottomRightRadius: prefixCardRoot.rBottomRight
            onClicked: prefixInput.forceActiveFocus()

            StyledToolTip {
                extraVisibleCondition: parent.hovered || parent.realHovered
                text: prefixCardRoot.description
            }
        }

        RowLayout {
            id: prefixRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol {
                text: prefixCardRoot.icon
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: prefixCardRoot.title
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            StyledTextInput {
                id: prefixInput
                Layout.preferredWidth: 120 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                inputRadius: height / (2 * Appearance.effectiveScale)
                horizontalAlignment: TextInput.AlignHCenter
                text: prefixCardRoot.value
                placeholder: prefixCardRoot.placeholderText
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "search"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Search & Launcher")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        PrefixCard {
            icon: "calculate"
            title: I18nService.tr("Math Prefix")
            description: I18nService.tr("Prefix to trigger mathematical evaluations.")
            placeholderText: "="
            input.text: (Config.ready && Config.options.search) ? Config.options.search.mathPrefix : "="
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.mathPrefix = input.text; }
        }

        PrefixCard {
            icon: "public"
            title: I18nService.tr("Web Search Prefix")
            description: I18nService.tr("Prefix to trigger a Google search.")
            placeholderText: "!"
            input.text: (Config.ready && Config.options.search) ? Config.options.search.webPrefix : "!"
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.webPrefix = input.text; }
        }

        PrefixCard {
            icon: "mood"
            title: I18nService.tr("Emoji Prefix")
            description: I18nService.tr("Prefix to search and copy emojis.")
            placeholderText: ":"
            input.text: (Config.ready && Config.options.search) ? Config.options.search.emojiPrefix : ":"
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.emojiPrefix = input.text; }
        }

        PrefixCard {
            icon: "content_paste"
            title: I18nService.tr("Clipboard Prefix")
            description: I18nService.tr("Prefix to search clipboard history.")
            placeholderText: ";"
            input.text: (Config.ready && Config.options.search) ? Config.options.search.clipboardPrefix : ";"
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.clipboardPrefix = input.text; }
        }

        PrefixCard {
            icon: "folder_open"
            title: I18nService.tr("File Search Prefix")
            description: I18nService.tr("Prefix to trigger local file searching.")
            placeholderText: "?"
            input.text: (Config.ready && Config.options.search) ? Config.options.search.filePrefix : "?"
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.filePrefix = input.text; }
        }

        PrefixCard {
            icon: "terminal"
            title: I18nService.tr("Command Prefix")
            description: I18nService.tr("Prefix to trigger shell commands and quick actions.")
            placeholderText: ">"
            input.text: (Config.ready && Config.options.search) ? Config.options.search.commandPrefix : ">"
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.commandPrefix = input.text; }
        }

        PrefixCard {
            icon: "settings"
            title: I18nService.tr("Settings Search Prefix")
            description: I18nService.tr("Prefix to search and jump to a setting.")
            placeholderText: "<"
            input.text: (Config.ready && Config.options.search) ? Config.options.search.settingsPrefix : "<"
            input.onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.settingsPrefix = input.text; }
        }

        // App Usage Tracking (whole card clickable)
        SegmentedWrapper {
            id: usageCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, usageRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: usageCard.rTopLeft
                topRightRadius: usageCard.rTopRight
                bottomLeftRadius: usageCard.rBottomLeft
                bottomRightRadius: usageCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.search) {
                        Config.options.search.enableUsageTracking = !Config.options.search.enableUsageTracking;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Prioritize frequently used apps in search results.")
                }
            }

            RowLayout {
                id: usageRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "timeline"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("App Usage Tracking")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                AndroidToggle {
                    checked: (Config.ready && Config.options.search) ? Config.options.search.enableUsageTracking : true
                    onToggled: {
                        if (Config.ready && Config.options.search) {
                            Config.options.search.enableUsageTracking = !Config.options.search.enableUsageTracking;
                        }
                    }
                }
            }
        }
    }
}
