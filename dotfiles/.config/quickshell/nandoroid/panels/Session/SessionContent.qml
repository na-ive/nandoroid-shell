import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Android 16 Style Session Menu
 * Uses strict dynamic scaling to maintain 1:1 button ratios on all screens.
 */
Item {
    id: root
    focus: true
    property string subtitle: ""

    // Single scaling factor based on screen height for vertical consistency
    readonly property real baseScale: Appearance.sizes.screen.height / 1080
    
    // Core sizing tokens
    readonly property real gridSpacing: 16 * baseScale
    readonly property real islandPadding: 32 * baseScale
    readonly property real footerHeight: 38 * baseScale
    
    // Main Outer Wrapper (The "Island")
    Rectangle {
        id: islandWrapper
        anchors.centerIn: parent
        
        // Dynamically size based on strictly sized children
        implicitWidth: mainLayout.implicitWidth + (islandPadding * 2)
        implicitHeight: mainLayout.implicitHeight + (islandPadding * 2)
        
        radius: Appearance.rounding.panel
        color: Appearance.colors.colLayer0 
        
        // MD3 Outline Style (instead of shadow)
        border.width: 1
        border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
        
        // Very subtle ambient shadow (optional, keep it extremely thin)
        layer.enabled: true
        layer.effect: DropShadow {
            radius: 12
            samples: 24
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.1)
            verticalOffset: 2
            transparentBorder: true
        }

        ColumnLayout {
            id: mainLayout
            anchors.centerIn: parent
            spacing: 24 * baseScale

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.sessionOpen = false;
                }
            }

            // ── Header (Centered) ──
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4 * baseScale

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 22 * baseScale
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3onSurface
                    text: "Session"
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 13 * baseScale
                    color: Appearance.m3colors.m3outline
                    text: "What would you like to do?"
                    opacity: 0.8
                }
            }

            // ── Action Grid (Strict 4x2) ──
            GridLayout {
                id: actionGrid
                columns: 4
                rows: 2
                columnSpacing: gridSpacing
                rowSpacing: gridSpacing
                Layout.alignment: Qt.AlignHCenter

                SessionActionButton {
                    id: sessionLock
                    focus: GlobalStates.sessionOpen
                    iconName: "lock"
                    actionText: "Lock"
                    onClicked: { Session.lock(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.right: sessionSleep; KeyNavigation.down: sessionHibernate
                }
                
                SessionActionButton {
                    id: sessionSleep
                    iconName: "bedtime"
                    actionText: "Sleep"
                    onClicked: { Session.suspend(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.left: sessionLock; KeyNavigation.right: sessionLogout; KeyNavigation.down: sessionShutdown
                }
                
                SessionActionButton {
                    id: sessionLogout
                    iconName: "logout"
                    actionText: "Logout"
                    onClicked: { Session.logout(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.left: sessionSleep; KeyNavigation.right: sessionTaskManager; KeyNavigation.down: sessionReboot
                }
                
                SessionActionButton {
                    id: sessionTaskManager
                    iconName: "browse_activity"
                    actionText: "Monitor"
                    onClicked: { GlobalStates.systemMonitorOpen = true; GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.left: sessionLogout; KeyNavigation.down: sessionFirmwareReboot
                }

                SessionActionButton {
                    id: sessionHibernate
                    iconName: "downloading"
                    actionText: "Hibernate"
                    onClicked: { Session.hibernate(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.up: sessionLock; KeyNavigation.right: sessionShutdown
                }

                SessionActionButton {
                    id: sessionShutdown
                    iconName: "power_settings_new"
                    actionText: "Shutdown"
                    onClicked: { Session.poweroff(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.left: sessionHibernate; KeyNavigation.right: sessionReboot; KeyNavigation.up: sessionSleep
                }

                SessionActionButton {
                    id: sessionReboot
                    iconName: "restart_alt"
                    actionText: "Reboot"
                    onClicked: { Session.reboot(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.left: sessionShutdown; KeyNavigation.right: sessionFirmwareReboot; KeyNavigation.up: sessionLogout
                }

                SessionActionButton {
                    id: sessionFirmwareReboot
                    iconName: "settings_applications"
                    actionText: "UEFI"
                    onClicked: { Session.rebootToFirmware(); GlobalStates.sessionOpen = false; }
                    onFocusChanged: if(focus) root.subtitle = actionText
                    KeyNavigation.left: sessionReboot; KeyNavigation.up: sessionTaskManager
                }
            }
            
            // ── Footer (Island Hints) ──
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: footerHeight
                radius: 12 * baseScale
                color: Appearance.colors.colLayer1 
                Layout.topMargin: 8 * baseScale

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16 * baseScale

                    RowLayout {
                        spacing: 12 * baseScale
                        opacity: 0.8


                        // Navigate
                        RowLayout {
                            spacing: 4 * baseScale
                            StyledText { text: "Navigate"; font.pixelSize: 10 * baseScale; color: Appearance.colors.colOnLayer1 }
                            Rectangle {
                                width: 54 * baseScale; height: 18 * baseScale; radius: 4 * baseScale
                                color: Appearance.m3colors.m3surfaceVariant
                                StyledText { anchors.centerIn: parent; text: "←↑↓→"; font.pixelSize: 10 * baseScale; font.weight: Font.Bold }
                            }
                        }

                        // Select
                        RowLayout {
                            spacing: 4 * baseScale
                            StyledText { text: "Select"; font.pixelSize: 10 * baseScale; color: Appearance.colors.colOnLayer1 }
                            Rectangle {
                                width: 38 * baseScale; height: 18 * baseScale; radius: 4 * baseScale
                                color: Appearance.m3colors.m3surfaceVariant
                                StyledText { anchors.centerIn: parent; text: "Enter"; font.pixelSize: 10 * baseScale; font.weight: Font.Bold }
                            }
                        }

                        // Exit
                        RowLayout {
                            spacing: 4 * baseScale
                            StyledText { text: "Exit"; font.pixelSize: 10 * baseScale; color: Appearance.colors.colOnLayer1 }
                            Rectangle {
                                width: 28 * baseScale; height: 18 * baseScale; radius: 4 * baseScale
                                color: Appearance.m3colors.m3surfaceVariant
                                StyledText { anchors.centerIn: parent; text: "Esc"; font.pixelSize: 10 * baseScale; font.weight: Font.Bold }
                            }
                        }
                    }
                }
            }
        }
    }
}
