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
 * Features a vertical layout with modern "Google Translate" side-by-side cards.
 */
ColumnLayout {
    id: root
    spacing: 12 * Appearance.effectiveScale

    // ── Translate accent family (matches the Translate rail button inactive state) ──
    readonly property color translateContainer: Functions.ColorUtils.mix(Appearance.colors.colSecondaryContainer, Appearance.colors.colTertiaryContainer, 0.5)
    readonly property color translateOnContainer: Functions.ColorUtils.mix(Appearance.colors.colOnSecondaryContainer, Appearance.colors.colOnTertiaryContainer, 0.5)

    property string srcLang: (Config.ready && Config.options.language && Config.options.language.translator) ? Config.options.language.translator.sourceLanguage : "auto"
    property string targetLang: (Config.ready && Config.options.language && Config.options.language.translator) ? Config.options.language.translator.targetLanguage : "en"

    function getLanguageName(code) {
        if (code === "auto") return "Auto Detect";
        if (TranslationService.languageNamesMap && TranslationService.languageNamesMap[code]) {
            return TranslationService.languageNamesMap[code];
        }
        return code;
    }

    function getLanguageCode(name) {
        if (name.startsWith("Auto Detect")) return "auto";
        if (TranslationService.languageNamesMap) {
            for (let code in TranslationService.languageNamesMap) {
                if (TranslationService.languageNamesMap[code] === name) {
                    return code;
                }
            }
        }
        return name;
    }

    // Unified trigger logic
    function triggerTranslate() {
        const txt = inputText.text.trim();
        if (txt.length > 0) {
            debounceTimer.restart();
        } else if (inputText.text === "") {
            TranslationService.translate("", root.srcLang, root.targetLang);
            TranslationService.detectedLanguage = "";
            debounceTimer.stop();
        }
    }

    Timer {
        id: debounceTimer
        interval: 300
        repeat: false
        onTriggered: TranslationService.translate(inputText.text, root.srcLang, root.targetLang)
    }

    // --- Top Bar: Language Selectors ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12 * Appearance.effectiveScale

        StyledComboBox {
            id: srcCombo
            Layout.fillWidth: true
            Layout.preferredHeight: 48 * Appearance.effectiveScale
            colBackground: root.translateContainer
            colText: root.translateOnContainer
            bgRadius: 24 * Appearance.effectiveScale
            borderWidth: isOpened ? Math.max(2, 2 * Appearance.effectiveScale) : 0
            model: {
                let langs = (TranslationService.availableLanguages && TranslationService.availableLanguages.length > 0) ? TranslationService.availableLanguages : ["auto", "en", "id", "ja", "zh", "ko", "fr", "de", "es", "it", "ru", "pt"];
                return langs.map(c => root.getLanguageName(c));
            }
            
            // Custom text to show Auto (detectedLanguage) if applicable
            text: {
                if (root.srcLang === "auto") {
                    if (TranslationService.detectedLanguage !== "" && inputText.text.trim().length > 0) {
                        return "Auto Detect (" + root.getLanguageName(TranslationService.detectedLanguage) + ")";
                    }
                    return "Auto Detect";
                }
                return root.getLanguageName(root.srcLang);
            }

            onAccepted: (value) => {
                let realValue = root.getLanguageCode(value);
                
                root.srcLang = realValue;
                if (Config.ready) Config.options.language.translator.sourceLanguage = realValue;
                root.triggerTranslate();
            }
        }

        MaterialShapeWrappedMaterialSymbol {
            id: swapBtn
            text: "sync_alt"
            iconSize: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3primaryContainer
            colSymbol: Appearance.m3colors.m3onPrimaryContainer
            shape: MaterialShape.Shape.Squircle
            width: 40 * Appearance.effectiveScale
            height: 40 * Appearance.effectiveScale

            // Disable swap if source is auto and we haven't detected anything yet
            property bool isSwapEnabled: (root.srcLang !== "auto") || (TranslationService.detectedLanguage !== "" && inputText.text.trim().length > 0)
            opacity: isSwapEnabled ? 1.0 : 0.4
            
            // Add a fun bounce effect when pressed
            scale: swapMouseArea.pressed ? 0.8 : (swapMouseArea.containsMouse ? 1.05 : 1.0)
            
            Behavior on scale {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutBack
                }
            }

            MouseArea {
                id: swapMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.isSwapEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                
                onClicked: {
                    if (!parent.isSwapEnabled) return;

                    let newSrc = root.targetLang;
                    let newTarget = root.srcLang;

                    if (root.srcLang === "auto") {
                        newTarget = TranslationService.detectedLanguage;
                    }

                    if (newTarget === "auto") {
                        newTarget = "en";
                    }

                    root.srcLang = newSrc;
                    root.targetLang = newTarget;

                    if (Config.ready) {
                        Config.options.language.translator.sourceLanguage = newSrc;
                        Config.options.language.translator.targetLanguage = newTarget;
                    }

                    let oldResult = TranslationService.translatedText || "";
                    if (oldResult.length > 0) {
                        inputText.text = oldResult;
                        TranslationService.translatedText = "";
                        TranslationService.transliteratedText = "";
                    }

                    root.triggerTranslate();
                }
            }

            StyledToolTip {
                text: I18nService.tr("Swap Languages")
                extraVisibleCondition: swapMouseArea.containsMouse
            }
        }

        StyledComboBox {
            id: targetCombo
            Layout.fillWidth: true
            Layout.preferredHeight: 48 * Appearance.effectiveScale
            colBackground: root.translateContainer
            colText: root.translateOnContainer
            bgRadius: 24 * Appearance.effectiveScale
            borderWidth: isOpened ? Math.max(2, 2 * Appearance.effectiveScale) : 0
            model: {
                const base = (TranslationService.availableLanguages && TranslationService.availableLanguages.length > 0) ? TranslationService.availableLanguages : ["en", "id", "ja", "zh", "ko", "fr", "de", "es", "it", "ru", "pt"];
                return base.filter(l => l !== "auto").map(c => root.getLanguageName(c));
            }
            text: root.getLanguageName(root.targetLang)
            onAccepted: (value) => {
                let code = root.getLanguageCode(value);
                root.targetLang = code;
                if (Config.ready) Config.options.language.translator.targetLanguage = code;
                root.triggerTranslate();
            }
        }
    }

    // --- Bottom Section: Cards ---
    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 12 * Appearance.effectiveScale

        // --- Left Card (Input) ---
        Rectangle {
            Layout.fillHeight: true; Layout.fillWidth: true
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.large * 1.5
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    TextArea {
                        id: inputText
                        placeholderText: I18nService.tr("Type or paste text here...")
                        placeholderTextColor: Appearance.colors.colSubtext
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.large
                        wrapMode: Text.Wrap; background: null; selectByMouse: true
                        onTextChanged: {
                            if (activeFocus || text === "") root.triggerTranslate();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    
                    StyledText {
                        text: inputText.text.length + " " + I18nService.tr("characters")
                        font.pixelSize: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colSubtext
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    RippleButton {
                        id: pasteBtn
                        implicitWidth: 36 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        
                        MaterialSymbol { anchors.centerIn: parent; text: "content_paste"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                        
                        onClicked: {
                            inputText.text = Quickshell.clipboardText;
                            inputText.forceActiveFocus();
                            root.triggerTranslate();
                        }
                        StyledToolTip { text: I18nService.tr("Paste from clipboard"); extraVisibleCondition: pasteBtn.realHovered }
                    }

                    RippleButton {
                        id: clearBtn
                        implicitWidth: 36 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        visible: inputText.text.length > 0
                        
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                        
                        onClicked: { inputText.text = ""; TranslationService.translatedText = ""; TranslationService.transliteratedText = ""; TranslationService.detectedLanguage = ""; }
                        StyledToolTip { text: I18nService.tr("Clear input"); extraVisibleCondition: clearBtn.realHovered }
                    }
                }
            }
        }

        // --- Right Card (Output) ---
        Rectangle {
            Layout.fillHeight: true; Layout.fillWidth: true
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.large * 1.5
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale

                ScrollView {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    TextArea {
                        id: resultText
                        text: TranslationService.status === "failed" ? "" : (TranslationService.translatedText || "")
                        readOnly: true
                        placeholderText: {
                            if (TranslationService.isTranslating) return I18nService.tr("Translating...");
                            if (TranslationService.status === "failed") return I18nService.tr("Rate limited or unavailable on all engines. Please try again later.");
                            return I18nService.tr("Translation will appear here...");
                        }
                        placeholderTextColor: TranslationService.status === "failed" ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.large
                        wrapMode: Text.Wrap; background: null; selectByMouse: true
                        
                        opacity: TranslationService.isTranslating ? 0.6 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }

                // Transliteration / Romaji
                Rectangle {
                    id: transliterationBubble
                    Layout.fillWidth: true
                    visible: TranslationService.transliteratedText.length > 0 && TranslationService.status !== "failed"
                    opacity: visible ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    radius: 12 * Appearance.effectiveScale
                    color: Qt.darker(Appearance.m3colors.m3surfaceContainerHigh, 1.15)
                    implicitHeight: transliterationText.implicitHeight + 20 * Appearance.effectiveScale + (transliterationCopyBtn.visible ? 0 : 0)
                    property bool hovered: false

                    HoverHandler {
                        onHoveredChanged: transliterationBubble.hovered = hovered
                    }

                    StyledText {
                        id: transliterationText
                        text: TranslationService.transliteratedText
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colOnLayer1
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.italic: true
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: 10 * Appearance.effectiveScale
                            bottomMargin: 10 * Appearance.effectiveScale
                        }
                    }

                    RippleButton {
                        id: transliterationCopyBtn
                        implicitWidth: 28 * Appearance.effectiveScale
                        implicitHeight: 28 * Appearance.effectiveScale
                        buttonRadius: 14 * Appearance.effectiveScale
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: 6 * Appearance.effectiveScale
                        }
                        opacity: transliterationBubble.hovered ? 1.0 : 0.0
                        visible: opacity > 0.01
                        colBackground: Appearance.m3colors.m3surfaceContainerHighest
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "content_copy"
                            iconSize: 14 * Appearance.effectiveScale
                            color: Appearance.colors.colOnLayer1
                        }

                        onClicked: {
                            Quickshell.clipboardText = TranslationService.transliteratedText;
                            SnackbarService.show(I18nService.tr("Transliteration copied to clipboard"));
                        }
                        StyledToolTip { text: I18nService.tr("Copy transliteration"); extraVisibleCondition: transliterationBubble.hovered }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    RowLayout {
                        id: engineBadge
                        visible: TranslationService.status === "ok" && TranslationService.lastEngine !== "" && TranslationService.lastEngine !== "google"
                        spacing: 4 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "public"
                            iconSize: 14 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: I18nService.tr("Translated with") + " " + ((TranslationService.engineDisplayNames && TranslationService.engineDisplayNames[TranslationService.lastEngine]) || TranslationService.lastEngine)
                            font.pixelSize: 12 * Appearance.effectiveScale
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Item { Layout.fillWidth: true } // Spacer
                    
                    RippleButton {
                        id: copyBtn
                        implicitWidth: 36 * Appearance.effectiveScale
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        visible: resultText.text.length > 0
                        
                        MaterialSymbol { anchors.centerIn: parent; text: "content_copy"; iconSize: 20 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                        
                        onClicked: {
                            Quickshell.clipboardText = resultText.text;
                            SnackbarService.show(I18nService.tr("Translation copied to clipboard"));
                        }
                        StyledToolTip { text: I18nService.tr("Copy to clipboard"); extraVisibleCondition: copyBtn.realHovered }
                    }
                }
            }
        }
    }
}
