import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 0

    property var languageCodes: {
        const codes = ["auto"];
        for (const c of I18nService.allAvailableLanguages) {
            if (!c.startsWith("quotes_") && codes.indexOf(c) === -1) codes.push(c);
        }
        return codes;
    }
    property var languageDisplayModel: root.languageCodes.map(c => root.langDisplay(c))
    property string currentLanguageCode: Config.ready ? Config.options.language.ui : "auto"

    function langDisplay(code) {
        if (code === "auto") return I18nService.tr("Auto (System)");
        return I18nService.languageName(code);
    }
    function langCode(display) {
        const i = root.languageDisplayModel.indexOf(display);
        return i >= 0 ? root.languageCodes[i] : display;
    }

    SearchHandler {
        searchString: "Language"
        aliases: ["Translation", "Translate", "trans", "Language Settings"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "translate"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Language & Localization")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Language Selector Card
        SegmentedWrapper {
            id: languageCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, languageRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                id: languageClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: languageCard.rTopLeft
                topRightRadius: languageCard.rTopRight
                bottomLeftRadius: languageCard.rBottomLeft
                bottomRightRadius: languageCard.rBottomRight

                property real comboClosedAt: 0

                onClicked: {
                    if (Date.now() - comboClosedAt < 250) return;
                    langCombo.isOpened = !langCombo.isOpened;
                }

                Connections {
                    target: langCombo
                    function onIsOpenedChanged() {
                        if (!langCombo.isOpened) languageClickArea.comboClosedAt = Date.now();
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Select your preferred UI language. Some strings may not yet be translated.")
                }
            }

            RowLayout {
                id: languageRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "language"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("UI Language")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledComboBox {
                    id: langCombo
                    Layout.preferredWidth: 220 * Appearance.effectiveScale
                    bgRadius: height / 2
                    model: root.languageDisplayModel
                    text: root.langDisplay(root.currentLanguageCode)
                    searchable: false
                    placeholder: ""
                    onAccepted: (value) => {
                        const code = root.langCode(value);
                        if (Config.ready) Config.options.language.ui = code;
                    }
                }
            }
        }
    }
}
