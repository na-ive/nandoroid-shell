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

    property bool forceRunningMode: false
    property string inputDigits: ""
    
    // Convert current inputDigits (e.g. "1234" -> 12m 34s) to string "HHh MMm SSs"
    readonly property string inputDisplay: {
        if (TimerService.active) return "";
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

    // ── INPUT PAGE ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * Appearance.effectiveScale
        visible: !TimerService.active && TimerService.remainingMs === TimerService.setSeconds * 1000 && !TimerService.overflowing && !root.forceRunningMode
        
        Item { Layout.fillHeight: true }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.inputDisplay
            font.family: Appearance.font.family.numbers
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
                            font.family: modelData === "DEL" ? Appearance.font.family.main : Appearance.font.family.numbers
                            font.pixelSize: 18 * Appearance.effectiveScale
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Start Button
        RippleButton {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 72 * Appearance.effectiveScale
            implicitHeight: 40 * Appearance.effectiveScale
            buttonRadius: 20 * Appearance.effectiveScale
            enabled: parseInputToSeconds() > 0
            colBackground: enabled ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
            
            onClicked: {
                let s = root.parseInputToSeconds();
                if (s > 0) {
                    TimerService.setDuration(s);
                    root.forceRunningMode = true;
                    TimerService.start();
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "play_arrow"
                iconSize: 24 * Appearance.effectiveScale
                color: parent.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
            }
            StyledToolTip { text: I18nService.tr("Start Timer") }
        }
    }

    // ── RUNNING / PAUSED PAGE ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * Appearance.effectiveScale
        visible: TimerService.active || TimerService.remainingMs !== TimerService.setSeconds * 1000 || TimerService.overflowing || root.forceRunningMode

        Item { Layout.fillHeight: true }

        // Arc Ring
        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 200 * Appearance.effectiveScale
            implicitHeight: 200 * Appearance.effectiveScale

            GappedCircularProgress {
                anchors.fill: parent
                progress: TimerService.progress
                colPrimary: TimerService.isNegative ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
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
                    text: TimerService.timeString
                    font.pixelSize: 48 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    font.family: Appearance.font.family.numbers
                    font.features: { "tnum": 1 }
                    color: TimerService.isNegative ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1
                }
                
                RippleButton {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 32 * Appearance.effectiveScale
                    implicitHeight: 32 * Appearance.effectiveScale
                    buttonRadius: 16 * Appearance.effectiveScale
                    colBackground: "transparent"
                    visible: TimerService.active || TimerService.remainingMs !== TimerService.setSeconds * 1000
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "replay"
                        iconSize: 20 * Appearance.effectiveScale
                        color: TimerService.isNegative ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                    }
                    
                    onClicked: {
                        root.forceRunningMode = true;
                        TimerService.setDuration(TimerService.setSeconds);
                        TimerService.pause();
                    }
                    StyledToolTip { text: I18nService.tr("Restart") }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16 * Appearance.effectiveScale

            // +1:00 Button (Optional)
            RippleButton {
                implicitWidth: 104 * Appearance.effectiveScale
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: 32 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: TimerService.addMinute()

                StyledText {
                    anchors.centerIn: parent
                    text: "+1:00"
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: 16 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
            }

            // Stop / Delete
            RippleButton {
                implicitWidth: 64 * Appearance.effectiveScale
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: 32 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: {
                    root.forceRunningMode = false;
                    TimerService.stop();
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "stop"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colOnLayer1
                }
                StyledToolTip { text: I18nService.tr("Reset") }
            }

            // Pause / Resume
            RippleButton {
                implicitWidth: 104 * Appearance.effectiveScale
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: 32 * Appearance.effectiveScale
                colBackground: TimerService.active ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3primary
                
                onClicked: {
                    if (TimerService.active) {
                        TimerService.pause();
                    } else {
                        TimerService.start();
                    }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: TimerService.active ? "pause" : "play_arrow"
                    iconSize: 24 * Appearance.effectiveScale
                    color: TimerService.active ? Appearance.colors.colOnLayer1 : Appearance.m3colors.m3onPrimary
                }
                StyledToolTip { text: TimerService.active ? I18nService.tr("Pause") : I18nService.tr("Start") }
            }
        }
    }
}
