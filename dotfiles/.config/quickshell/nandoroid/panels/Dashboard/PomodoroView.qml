import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import "../../services"

Item {
    id: root

    property int configMode: 0 // 0: None, 1: Setting Focus, 2: Setting Break
    property string inputDigits: ""

    function formatDuration(totalSeconds) {
        let h = Math.floor(totalSeconds / 3600);
        let m = Math.floor((totalSeconds % 3600) / 60);
        let s = totalSeconds % 60;
        
        let parts = [];
        if (h > 0) parts.push(h + "h");
        if (m > 0) parts.push(m + "m");
        if (s > 0) parts.push(s + "s");
        
        if (parts.length === 0) return "0s";
        return parts.join(" ");
    }

    readonly property string inputDisplay: {
        let padded = inputDigits.padStart(6, '0');
        let h = padded.substring(0, 2);
        let m = padded.substring(2, 4);
        let s = padded.substring(4, 6);
        return h + "h " + m + "m " + s + "s";
    }
    
    function parseInputToSeconds() {
        let padded = inputDigits.padStart(6, '0');
        let h = parseInt(padded.substring(0, 2)) || 0;
        let m = parseInt(padded.substring(2, 4)) || 0;
        let s = parseInt(padded.substring(4, 6)) || 0;
        return (h * 3600) + (m * 60) + s;
    }

    function appendDigit(d) {
        if (inputDigits.length >= 6) return;
        if (inputDigits === "" && (d === "0" || d === "00")) return;
        
        inputDigits += d;
        if (inputDigits.length > 6) {
            inputDigits = inputDigits.substring(0, 6);
        }
    }

    function backspace() {
        if (inputDigits.length > 0) {
            inputDigits = inputDigits.substring(0, inputDigits.length - 1);
        }
    }

    // ── MAIN RUNNING PAGE ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * Appearance.effectiveScale
        visible: root.configMode === 0

        // Arc Ring
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 200 * Appearance.effectiveScale
            implicitHeight: 200 * Appearance.effectiveScale

            GappedCircularProgress {
                anchors.fill: parent
                progress: PomodoroService.progress
                colPrimary: PomodoroService.mode === 0 ? Appearance.m3colors.m3primary : Appearance.m3colors.m3tertiary
                strokeWidth: 10 * Appearance.effectiveScale
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4 * Appearance.effectiveScale

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: 140 * Appearance.effectiveScale
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: 20 * Appearance.effectiveScale
                    text: PomodoroService.timeString
                    font.pixelSize: 48 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    font.family: Appearance.font.family.numbers
                    font.features: { "tnum": 1 }
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18nService.tr(PomodoroService.modeName)
                    font.pixelSize: 14 * Appearance.effectiveScale
                    color: Appearance.colors.colSubtext
                }
            }
            
            // Cycle badge
            Rectangle {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 8 * Appearance.effectiveScale
                anchors.bottomMargin: 8 * Appearance.effectiveScale
                visible: PomodoroService.rotations > 0
                width: 24 * Appearance.effectiveScale
                height: 24 * Appearance.effectiveScale
                radius: width / 2
                color: Appearance.m3colors.m3secondaryContainer

                StyledText {
                    anchors.centerIn: parent
                    text: PomodoroService.rotations
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: 12 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Settings Shortcuts (Focus / Break / Auto-continue)
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 8 * Appearance.effectiveScale
            visible: !PomodoroService.active

            RippleButton {
                implicitWidth: 80 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: { root.inputDigits = ""; root.configMode = 1; }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4 * Appearance.effectiveScale
                    MaterialSymbol { text: "alarm"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: root.formatDuration(PomodoroService.focusTime); font.pixelSize: 12 * Appearance.effectiveScale; font.family: Appearance.font.family.numbers; color: Appearance.colors.colOnLayer1 }
                }
                StyledToolTip { text: I18nService.tr("Set Focus Time") }
            }
            
            RippleButton {
                implicitWidth: 80 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: { root.inputDigits = ""; root.configMode = 2; }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4 * Appearance.effectiveScale
                    MaterialSymbol { text: "coffee"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                    StyledText { text: root.formatDuration(PomodoroService.breakTime); font.pixelSize: 12 * Appearance.effectiveScale; font.family: Appearance.font.family.numbers; color: Appearance.colors.colOnLayer1 }
                }
                StyledToolTip { text: I18nService.tr("Set Break Time") }
            }
            
            RippleButton {
                implicitWidth: 44 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: PomodoroService.autoContinue ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                onClicked: PomodoroService.autoContinue = !PomodoroService.autoContinue
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "autorenew"
                    iconSize: 16 * Appearance.effectiveScale
                    color: PomodoroService.autoContinue ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: I18nService.tr("Auto-continue") }
            }
        }

        Item { Layout.fillHeight: true }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16 * Appearance.effectiveScale

            // Stop / Refresh
            RippleButton {
                implicitWidth: 64 * Appearance.effectiveScale
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: 32 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: {
                    if (PomodoroService.active || PomodoroService.elapsedMs > 0 || PomodoroService.remainingTime !== PomodoroService.duration) {
                        PomodoroService.stop();
                    } else {
                        PomodoroService.rotations = 0;
                        PomodoroService.setMode(0);
                    }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: (PomodoroService.active || PomodoroService.elapsedMs > 0 || PomodoroService.remainingTime !== PomodoroService.duration) ? "stop" : "refresh"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: (PomodoroService.active || PomodoroService.elapsedMs > 0 || PomodoroService.remainingTime !== PomodoroService.duration) ? I18nService.tr("Stop") : I18nService.tr("Reset") }
            }

            // Pause / Resume
            RippleButton {
                implicitWidth: 104 * Appearance.effectiveScale
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: 32 * Appearance.effectiveScale
                colBackground: PomodoroService.active ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3primary
                
                onClicked: {
                    if (PomodoroService.active) {
                        PomodoroService.pause();
                    } else {
                        PomodoroService.start();
                    }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: PomodoroService.active ? "pause" : "play_arrow"
                    iconSize: 24 * Appearance.effectiveScale
                    color: PomodoroService.active ? Appearance.colors.colOnLayer1 : Appearance.m3colors.m3onPrimary
                }
                StyledToolTip { text: PomodoroService.active ? I18nService.tr("Pause") : I18nService.tr("Start") }
            }
        }
    }

    // ── CONFIG NUMPAD PAGE ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * Appearance.effectiveScale
        visible: root.configMode > 0
        
        Item { Layout.fillHeight: true }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.configMode === 1 ? I18nService.tr("Set Focus Time") : I18nService.tr("Set Break Time")
            font.pixelSize: 14 * Appearance.effectiveScale
            color: Appearance.colors.colSubtext
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.inputDisplay
            font.pixelSize: 32 * Appearance.effectiveScale
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }

        Item { Layout.fillHeight: true }

        // Numpad
        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 3
            columnSpacing: 12 * Appearance.effectiveScale
            rowSpacing: 12 * Appearance.effectiveScale

            Repeater {
                model: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "00", "0", "DEL"]
                delegate: RippleButton {
                    implicitWidth: 72 * Appearance.effectiveScale
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 20 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    
                    onClicked: {
                        if (modelData === "DEL") backspace();
                        else appendDigit(modelData);
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: modelData === "DEL"
                            text: "backspace"
                            iconSize: 20 * Appearance.effectiveScale
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            anchors.centerIn: parent
                            visible: modelData !== "DEL"
                            text: modelData
                            font.pixelSize: 18 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12 * Appearance.effectiveScale

            // Cancel
            RippleButton {
                implicitWidth: 72 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: root.configMode = 0
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: I18nService.tr("Cancel") }
            }

            // Reset to default
            RippleButton {
                implicitWidth: 72 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: {
                    if (root.configMode === 1) PomodoroService.focusTime = 1500;
                    else if (root.configMode === 2) PomodoroService.breakTime = 300;
                    PomodoroService.reset();
                    root.configMode = 0;
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "restore"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: I18nService.tr("Reset to Default") }
            }

            // Save
            RippleButton {
                implicitWidth: 72 * Appearance.effectiveScale
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 20 * Appearance.effectiveScale
                enabled: parseInputToSeconds() > 0
                colBackground: enabled ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                
                onClicked: {
                    let secs = parseInputToSeconds();
                    if (secs > 0) {
                        if (root.configMode === 1) PomodoroService.focusTime = secs;
                        else if (root.configMode === 2) PomodoroService.breakTime = secs;
                        
                        PomodoroService.reset();
                        root.configMode = 0;
                    }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "check"
                    iconSize: 20 * Appearance.effectiveScale
                    color: parent.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: I18nService.tr("Save") }
            }
        }
    }
}
