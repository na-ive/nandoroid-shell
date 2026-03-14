import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

/**
 * Dashboard Tab 4: Translator - Nandoroid Polished Version
 * Features a horizontal "Google Translate" layout (Left: Source, Right: Result).
 */
RowLayout {
    id: root
    spacing: 16

    property string srcLang: (Config.ready && Config.options.language && Config.options.language.translator) ? Config.options.language.translator.sourceLanguage : "auto"
    property string targetLang: (Config.ready && Config.options.language && Config.options.language.translator) ? Config.options.language.translator.targetLanguage : "id"

    // Unified trigger logic
    function triggerTranslate() {
        const txt = inputText.text.trim();
        if (txt.length > 0) {
            debounceTimer.restart();
        } else if (inputText.text === "") {
            TranslationService.translatedText = "";
            debounceTimer.stop();
        }
    }

    Timer {
        id: debounceTimer
        interval: 300
        repeat: false
        onTriggered: TranslationService.translate(inputText.text, root.srcLang, root.targetLang)
    }

    // --- Left Section: Source ---
    Rectangle {
        Layout.fillHeight: true; Layout.fillWidth: true
        color: Appearance.colors.colLayer1; radius: Appearance.rounding.large
        border.width: 1; border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 16

            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol { text: "translate"; iconSize: 22; color: Appearance.colors.colPrimary }
                StyledText { text: "Source"; font.pixelSize: 15; font.weight: Font.Bold; color: Appearance.colors.colOnLayer1 }
                Item { Layout.fillWidth: true }
                
                StyledComboBox {
                    id: srcCombo
                    Layout.preferredWidth: 130
                    model: (TranslationService.availableLanguages && TranslationService.availableLanguages.length > 0) ? TranslationService.availableLanguages : ["auto", "id", "en", "ja", "zh", "ko", "fr", "de", "es", "it", "ru", "pt"]
                    text: root.srcLang
                    onAccepted: (value) => {
                        root.srcLang = value;
                        if (Config.ready) Config.options.language.translator.sourceLanguage = value;
                        root.triggerTranslate();
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                TextArea {
                    id: inputText
                    placeholderText: "Type or paste text here..."
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer1
                    font.family: Appearance.font.family.main
                    font.pixelSize: 16; wrapMode: Text.Wrap; background: null; selectByMouse: true
                    onTextChanged: {
                        if (activeFocus || text === "") root.triggerTranslate();
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                M3IconButton {
                    id: clearBtn
                    iconName: "close"; visible: inputText.text.length > 0
                    onClicked: { inputText.text = ""; TranslationService.translatedText = ""; }
                    StyledToolTip { text: "Clear input"; extraVisibleCondition: clearBtn.realHovered }
                }
                M3IconButton {
                    id: pasteBtn
                    iconName: "content_paste"
                    onClicked: {
                        inputText.text = Quickshell.clipboardText;
                        inputText.forceActiveFocus();
                        root.triggerTranslate();
                    }
                    StyledToolTip { text: "Paste from clipboard"; extraVisibleCondition: pasteBtn.realHovered }
                }
            }
        }
    }

    MaterialSymbol { text: "arrow_forward"; iconSize: 24; color: Appearance.colors.colSubtext; opacity: 0.4 }

    // --- Right Section: Result ---
    Rectangle {
        Layout.fillHeight: true; Layout.fillWidth: true
        color: Appearance.colors.colLayer2; radius: Appearance.rounding.large
        border.width: 1; border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 16

            RowLayout {
                Layout.fillWidth: true
                StyledText { text: "Translation"; font.pixelSize: 15; font.weight: Font.Bold; color: Appearance.colors.colPrimary }
                Item { Layout.fillWidth: true }
                
                StyledComboBox {
                    id: targetCombo
                    Layout.preferredWidth: 130
                    model: {
                        const base = (TranslationService.availableLanguages && TranslationService.availableLanguages.length > 0) ? TranslationService.availableLanguages : ["id", "en", "ja", "zh", "ko", "fr", "de", "es", "it", "ru", "pt"];
                        return base.filter(l => l !== "auto");
                    }
                    text: root.targetLang
                    onAccepted: (value) => {
                        root.targetLang = value;
                        if (Config.ready) Config.options.language.translator.targetLanguage = value;
                        root.triggerTranslate();
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                TextArea {
                    id: resultText
                    text: TranslationService.translatedText || ""
                    readOnly: true
                    placeholderText: TranslationService.isTranslating ? "Translating..." : "Translation will appear here..."
                    placeholderTextColor: Appearance.colors.colSubtext
                    color: Appearance.colors.colOnLayer2
                    font.family: Appearance.font.family.main
                    font.pixelSize: 18; font.weight: Font.Medium; wrapMode: Text.Wrap; background: null; selectByMouse: true
                    
                    opacity: TranslationService.isTranslating ? 0.6 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                
                RowLayout {
                    spacing: 8
                    visible: !!TranslationService.isTranslating
                    
                    MaterialSymbol {
                        text: "sync"; iconSize: 14; color: Appearance.colors.colPrimary
                        RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                    }
                    StyledText { text: "Translating..."; font.pixelSize: 12; color: Appearance.colors.colPrimary }
                }
                
                Item { Layout.fillWidth: true }

                M3IconButton {
                    id: translateBtn
                    iconName: "translate"
                    highlighted: true
                    visible: inputText.text.length > 0
                    onClicked: TranslationService.translate(inputText.text, root.srcLang, root.targetLang)
                    StyledToolTip { text: "Translate now"; extraVisibleCondition: translateBtn.realHovered }
                }
                
                M3IconButton {
                    id: copyBtn
                    iconName: "content_copy"
                    enabled: (TranslationService.translatedText && TranslationService.translatedText.length > 0)
                    onClicked: Quickshell.clipboardText = TranslationService.translatedText
                    StyledToolTip { text: "Copy translation"; extraVisibleCondition: copyBtn.realHovered }
                }
            }
        }
    }
}
