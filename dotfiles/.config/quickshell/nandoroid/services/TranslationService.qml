pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "../core/functions" as Functions

/**
 * TranslationService.qml
 * Ported logic from ii: handles text translation using 'translate-shell' (trans).
 */
Singleton {
    id: root

    property string translatedText: ""
    property bool isTranslating: translateProc.running
    property var availableLanguages: ["auto", "id", "en", "ja", "zh", "ko", "fr", "de", "es", "it", "ru", "pt"]

    function translate(text, source, target) {
        const cleanText = (text || "").trim();
        if (cleanText.length === 0) {
            root.translatedText = "";
            return;
        }
        
        if (translateProc.running) translateProc.terminate();

        const s = source || "auto";
        const t = target || "id";

        // Use short flags -s and -t as they are more standard across trans versions
        const cmd = `trans -brief`
            + ` -s '${Functions.StringUtils.shellSingleQuoteEscape(s)}'`
            + ` -t '${Functions.StringUtils.shellSingleQuoteEscape(t)}'`
            + ` '${Functions.StringUtils.shellSingleQuoteEscape(cleanText)}'`;
        

        translateProc.command = ["bash", "-c", cmd];
        translateProc.buffer = "";
        
        translateProc.running = true;
    }

    Process {
        id: translateProc
        command: []
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) {
                    console.error("[TranslationService] stderr:", this.text.trim());
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.translatedText = translateProc.buffer.trim();

            } else {
                console.error("[TranslationService] Process exited with code:", exitCode);
            }
        }
    }

    // Ported from ii: Dynamic fetch to expand the list
    Process {
        id: getLangsProc
        command: ["trans", "-list-codes", "-no-bidi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const output = this.text.trim();

                if (output.length > 0) {
                    // Extract codes: trans -list-codes often outputs in columns
                    // We look for 2-3 letter codes at the start of lines or separated by whitespace
                    let codes = output.split(/\s+/)
                        .filter(s => s.length >= 2 && s.length <= 8 && /^[a-z]+(-[A-Z]+)?$/.test(s))
                        .filter(s => s !== "auto")
                        .sort();
                    
                    if (codes.length > 5) {
                        root.availableLanguages = ["auto", ...codes];

                    }
                }
            }
        }
    }
}
