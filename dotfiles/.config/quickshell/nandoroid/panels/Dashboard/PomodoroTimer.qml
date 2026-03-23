import QtQuick
import QtQuick.Layouts
import "../../widgets"
import "../../core"
import "../../services"

/**
 * Pomodoro Timer UI.
 * Refactored to use Universal SegmentedWrapper for mode selectors.
 */
ColumnLayout {
    id: root
    spacing: 12 * Appearance.effectiveScale
    
    // --- Header & Time ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12 * Appearance.effectiveScale
        
        ColumnLayout {
            spacing: 2 * Appearance.effectiveScale
            StyledText {
                text: PomodoroService.modeName
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
            }
            RowLayout {
                spacing: 6 * Appearance.effectiveScale
                StyledText {
                    text: "Pomodoro"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                
                // Rotation Counter Badge
                Rectangle {
                    visible: PomodoroService.rotations > 0
                    height: 18 * Appearance.effectiveScale
                    width: rotationText.implicitWidth + 12 * Appearance.effectiveScale
                    radius: 9 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3secondaryContainer
                    StyledText {
                        id: rotationText
                        anchors.centerIn: parent
                        text: PomodoroService.rotations
                        font.pixelSize: 10 * Appearance.effectiveScale
                        font.weight: Font.Bold
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: PomodoroService.timeString
            font.pixelSize: 28 * Appearance.effectiveScale
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
    }

    // --- Progress Bar ---
    Rectangle {
        Layout.fillWidth: true
        height: 6 * Appearance.effectiveScale
        radius: 3 * Appearance.effectiveScale
        color: Appearance.m3colors.m3outlineVariant
        
        Rectangle {
            width: parent.width * PomodoroService.progress
            height: parent.height
            radius: parent.radius
            color: Appearance.m3colors.m3primary
        }
    }

    // --- Mode Selector (Universal Segmented Wrapper) ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4 * Appearance.effectiveScale
        
        Repeater {
            model: [
                { icon: "alarm", name: "Focus", mode: 0 },
                { icon: "coffee", name: "Short", mode: 1 },
                { icon: "self_improvement", name: "Long", mode: 2 }
            ]
            delegate: SegmentedButton {
                isHighlighted: PomodoroService.mode === modelData.mode
                implicitWidth: (root.width - 24 * Appearance.effectiveScale) / 3
                implicitHeight: 36 * Appearance.effectiveScale
                iconName: modelData.icon
                buttonText: modelData.name
                
                colInactive: Appearance.m3colors.m3surfaceContainerHigh
                onClicked: PomodoroService.setMode(modelData.mode)
                
                StyledToolTip { text: modelData.name }
            }
        }
    }

    // --- Controls ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 16 * Appearance.effectiveScale
        
        M3IconButton {
            iconName: "stop"
            onClicked: PomodoroService.stop()
            StyledToolTip { text: "Stop & Reset" }
        }

        // Pill Style Start Button
        RippleButton {
            id: startPill
            implicitWidth: 120 * Appearance.effectiveScale
            implicitHeight: 52 * Appearance.effectiveScale
            buttonRadius: 26 * Appearance.effectiveScale
            
            colBackground: Appearance.m3colors.m3primary
            colText: Appearance.m3colors.m3onPrimary
            
            onClicked: {
                if (PomodoroService.active) PomodoroService.pause();
                else PomodoroService.start();
            }

            contentItem: RowLayout {
                spacing: 8 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignHCenter
                MaterialSymbol {
                    text: PomodoroService.active ? "pause" : "play_arrow"
                    iconSize: 24 * Appearance.effectiveScale
                    color: startPill.colText
                    // Optical offset for play triangle
                    anchors.horizontalCenterOffset: (!PomodoroService.active) ? 2 * Appearance.effectiveScale : 0
                }
                StyledText {
                    text: PomodoroService.active ? "Pause" : "Start"
                    font.pixelSize: 14 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: startPill.colText
                }
            }
        }
        
        M3IconButton {
            iconName: "refresh"
            onClicked: {
                PomodoroService.reset();
                PomodoroService.rotations = 0;
            }
            StyledToolTip { text: "Reset Everything" }
        }
    }

    // --- Auto-Continue & Next Break Settings ---
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4 * Appearance.effectiveScale
        spacing: 8 * Appearance.effectiveScale
        
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Auto-continue Sessions"
                font.pixelSize: 12 * Appearance.effectiveScale
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: 40 * Appearance.effectiveScale
                implicitHeight: 24 * Appearance.effectiveScale
                buttonRadius: 12 * Appearance.effectiveScale
                colBackground: PomodoroService.autoContinue ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                
                onClicked: PomodoroService.autoContinue = !PomodoroService.autoContinue
                
                StyledToolTip { text: "Automatically start next session" }

                Rectangle {
                    x: PomodoroService.autoContinue ? parent.width - width - 4 * Appearance.effectiveScale : 4 * Appearance.effectiveScale
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16 * Appearance.effectiveScale
                    height: 16 * Appearance.effectiveScale
                    radius: 8 * Appearance.effectiveScale
                    color: PomodoroService.autoContinue ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                    Behavior on x { NumberAnimation { duration: 200 } }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: PomodoroService.autoContinue
            implicitHeight: 32 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            
            StyledText {
                text: "Next Break"
                font.pixelSize: 12 * Appearance.effectiveScale
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }

            RowLayout {
                spacing: 4 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                
                SegmentedButton {
                    isHighlighted: PomodoroService.nextBreakMode === 1
                    implicitWidth: 60 * Appearance.effectiveScale
                    implicitHeight: 24 * Appearance.effectiveScale
                    iconName: "coffee"
                    buttonText: "Short"
                    iconSize: 11 * Appearance.effectiveScale
                    
                    colInactive: Appearance.m3colors.m3surfaceContainerHigh
                    colActive: Appearance.m3colors.m3secondary
                    colActiveText: Appearance.m3colors.m3onSecondary
                    onClicked: PomodoroService.nextBreakMode = 1
                    StyledToolTip { text: "Short break after focus" }
                }
                
                SegmentedButton {
                    isHighlighted: PomodoroService.nextBreakMode === 2
                    implicitWidth: 64 * Appearance.effectiveScale
                    implicitHeight: 24 * Appearance.effectiveScale
                    iconName: "self_improvement"
                    buttonText: "Long"
                    iconSize: 11 * Appearance.effectiveScale
                    
                    colInactive: Appearance.m3colors.m3surfaceContainerHigh
                    colActive: Appearance.m3colors.m3secondary
                    colActiveText: Appearance.m3colors.m3onSecondary
                    onClicked: PomodoroService.nextBreakMode = 2
                    StyledToolTip { text: "Long break after focus" }
                }
            }
        }
    }
}
