import "../../../core"
import "../../../widgets"
import "../../StatusBar"
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 24 * Appearance.effectiveScale
    
    property string simulatedState: "idle"

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8 * Appearance.effectiveScale

        StyledText {
            text: "Step 2: Status Bar & Dynamic Island"
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledText {
            text: "The Status Bar is your central hub. Click the left side for Notifications, the center for the Dashboard, and the right side for Quick Settings.\n\nYou can also intuitively scroll on the left side to adjust Brightness, or scroll on the right side to adjust Volume.\n\nThe notch in the middle acts as a Dynamic Island for media, Pomodoro timers, and screen recording status. Try simulating different states below!"
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // Interactive Area
    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Appearance.colors.colLayer0
        radius: 16 * Appearance.effectiveScale
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Appearance.colors.colOutlineVariant
        clip: true

        // ── The Notch ──
        Item {
            anchors.fill: parent
            
            // Unscaled container to keep rendering sharp
            Item {
                anchors.centerIn: parent
                width: parent.width
                height: 40 * Appearance.effectiveScale

                // Centered Dynamic Island
                DynamicIsland {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    islandStateOverride: root.simulatedState
                    // Provide the gap width so the island leaves space for the dots!
                    // Row width is 82, so 100 leaves 9px padding on each side
                    indicatorWidth: 100 * Appearance.effectiveScale 
                }

                // Mock Workspace Indicator (rendered ON TOP)
                Row {
                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale
                    Repeater {
                        model: 5
                        Rectangle {
                            width: 10 * Appearance.effectiveScale
                            height: 10 * Appearance.effectiveScale
                            radius: 5 * Appearance.effectiveScale
                            color: index === 0 ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        }
                    }
                }
            }
        }

        // ── Controls & Legend ──
        ColumnLayout {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 24 * Appearance.effectiveScale
            spacing: 24 * Appearance.effectiveScale
            
            // Gestures Hint
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16 * Appearance.effectiveScale
                
                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    MaterialSymbol { text: "swipe_up"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Scroll: Workspaces"; font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                }
                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    MaterialSymbol { text: "mouse"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Mid Click: Layout"; font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                }
                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    MaterialSymbol { text: "ads_click"; iconSize: 16 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                    StyledText { text: "Right Click: Overview"; font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                }
            }

            // State Simulators
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 2 * Appearance.effectiveScale
                
                SegmentedButton {
                    buttonText: "Idle"
                    checked: root.simulatedState === "idle"
                    onClicked: root.simulatedState = "idle"
                }

                SegmentedButton {
                    buttonText: "Media"
                    checked: root.simulatedState === "media"
                    onClicked: root.simulatedState = "media"
                }

                SegmentedButton {
                    buttonText: "Notification"
                    checked: root.simulatedState === "notification"
                    onClicked: root.simulatedState = "notification"
                }

                SegmentedButton {
                    buttonText: "Pomodoro"
                    checked: root.simulatedState === "pomodoro"
                    onClicked: root.simulatedState = "pomodoro"
                }
            }
        }
    }
}
