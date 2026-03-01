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
    spacing: 12
    
    // --- Header & Time ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12
        
        ColumnLayout {
            spacing: 2
            StyledText {
                text: PomodoroService.modeName
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
            }
            RowLayout {
                spacing: 6
                StyledText {
                    text: "Pomodoro"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                
                // Rotation Counter Badge
                Rectangle {
                    visible: PomodoroService.rotations > 0
                    height: 18
                    width: rotationText.implicitWidth + 12
                    radius: 9
                    color: Appearance.m3colors.m3secondaryContainer
                    StyledText {
                        id: rotationText
                        anchors.centerIn: parent
                        text: PomodoroService.rotations
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Appearance.m3colors.m3onSecondaryContainer
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        StyledText {
            text: PomodoroService.timeString
            font.pixelSize: 28
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
    }

    // --- Progress Bar ---
    Rectangle {
        Layout.fillWidth: true
        height: 6
        radius: 3
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
        spacing: 4
        
        Repeater {
            model: [
                { icon: "alarm", name: "Focus", mode: 0 },
                { icon: "coffee", name: "Short", mode: 1 },
                { icon: "self_improvement", name: "Long", mode: 2 }
            ]
            delegate: SegmentedButton {
                isHighlighted: PomodoroService.mode === modelData.mode
                implicitWidth: (root.width - 24) / 3
                implicitHeight: 36
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
        spacing: 16
        
        M3IconButton {
            iconName: "stop"
            onClicked: PomodoroService.stop()
            StyledToolTip { text: "Stop & Reset" }
        }

        // Pill Style Start Button
        RippleButton {
            id: startPill
            implicitWidth: 120
            implicitHeight: 52
            buttonRadius: 26
            
            colBackground: Appearance.m3colors.m3primary
            colText: Appearance.m3colors.m3onPrimary
            
            onClicked: {
                if (PomodoroService.active) PomodoroService.pause();
                else PomodoroService.start();
            }

            contentItem: RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignHCenter
                MaterialSymbol {
                    text: PomodoroService.active ? "pause" : "play_arrow"
                    iconSize: 24
                    color: startPill.colText
                    // Optical offset for play triangle
                    anchors.horizontalCenterOffset: (!PomodoroService.active) ? 2 : 0
                }
                StyledText {
                    text: PomodoroService.active ? "Pause" : "Start"
                    font.pixelSize: 14
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
        Layout.topMargin: 4
        spacing: 8
        
        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: "Auto-continue Sessions"
                font.pixelSize: 12
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
                Layout.fillWidth: true
            }

            RippleButton {
                implicitWidth: 40
                implicitHeight: 24
                buttonRadius: 12
                colBackground: PomodoroService.autoContinue ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                
                onClicked: PomodoroService.autoContinue = !PomodoroService.autoContinue
                
                StyledToolTip { text: "Automatically start next session" }

                Rectangle {
                    x: PomodoroService.autoContinue ? parent.width - width - 4 : 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    radius: 8
                    color: PomodoroService.autoContinue ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                    Behavior on x { NumberAnimation { duration: 200 } }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: PomodoroService.autoContinue
            implicitHeight: 32
            spacing: 8
            
            StyledText {
                text: "Next Break"
                font.pixelSize: 12
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                verticalAlignment: Text.AlignVCenter
            }

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter
                
                SegmentedButton {
                    isHighlighted: PomodoroService.nextBreakMode === 1
                    implicitWidth: 60
                    implicitHeight: 24
                    iconName: "coffee"
                    buttonText: "Short"
                    iconSize: 11
                    
                    colInactive: Appearance.m3colors.m3surfaceContainerHigh
                    colActive: Appearance.m3colors.m3secondary
                    colActiveText: Appearance.m3colors.m3onSecondary
                    onClicked: PomodoroService.nextBreakMode = 1
                    StyledToolTip { text: "Short break after focus" }
                }
                
                SegmentedButton {
                    isHighlighted: PomodoroService.nextBreakMode === 2
                    implicitWidth: 64
                    implicitHeight: 24
                    iconName: "self_improvement"
                    buttonText: "Long"
                    iconSize: 11
                    
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
