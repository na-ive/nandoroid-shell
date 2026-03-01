import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    focus: true

    property string subtitle: ""

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 20

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.sessionOpen = false;
            }
        }

        // Title Area
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                    weight: Font.Bold
                }
                color: Appearance.m3colors.m3onSurface
                text: "Session"
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3outline
                text: "Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel"
            }
        }

        GridLayout {
            columns: 4
            columnSpacing: 16
            rowSpacing: 16
            Layout.alignment: Qt.AlignHCenter

            SessionActionButton {
                id: sessionLock
                focus: GlobalStates.sessionOpen
                iconName: "lock"
                actionText: "Lock"
                onClicked: {
                    Session.lock();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText
                
                KeyNavigation.right: sessionSleep
                KeyNavigation.down: sessionHibernate
            }
            
            SessionActionButton {
                id: sessionSleep
                iconName: "bedtime"
                actionText: "Sleep"
                onClicked: {
                    Session.suspend();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText

                KeyNavigation.left: sessionLock
                KeyNavigation.right: sessionLogout
                KeyNavigation.down: sessionShutdown
            }
            
            SessionActionButton {
                id: sessionLogout
                iconName: "logout"
                actionText: "Logout"
                onClicked: {
                    Session.logout();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText

                KeyNavigation.left: sessionSleep
                KeyNavigation.right: sessionTaskManager
                KeyNavigation.down: sessionReboot
            }
            
            SessionActionButton {
                id: sessionTaskManager
                iconName: "browse_activity"
                actionText: "Task Manager"
                onClicked: {
                    GlobalStates.systemMonitorOpen = true;
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText

                KeyNavigation.left: sessionLogout
                KeyNavigation.down: sessionFirmwareReboot
            }

            SessionActionButton {
                id: sessionHibernate
                iconName: "downloading"
                actionText: "Hibernate"
                onClicked: {
                    Session.hibernate();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText

                KeyNavigation.up: sessionLock
                KeyNavigation.right: sessionShutdown
            }

            SessionActionButton {
                id: sessionShutdown
                iconName: "power_settings_new"
                actionText: "Shutdown"
                onClicked: {
                    Session.poweroff();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText
                
                KeyNavigation.left: sessionHibernate
                KeyNavigation.right: sessionReboot
                KeyNavigation.up: sessionSleep
            }

            SessionActionButton {
                id: sessionReboot
                iconName: "restart_alt"
                actionText: "Reboot"
                onClicked: {
                    Session.reboot();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText

                KeyNavigation.left: sessionShutdown
                KeyNavigation.right: sessionFirmwareReboot
                KeyNavigation.up: sessionLogout
            }

            SessionActionButton {
                id: sessionFirmwareReboot
                iconName: "settings_applications"
                actionText: "UEFI Settings"
                onClicked: {
                    Session.rebootToFirmware();
                    GlobalStates.sessionOpen = false;
                }
                onFocusChanged: if(focus) root.subtitle = actionText

                KeyNavigation.left: sessionReboot
                KeyNavigation.up: sessionTaskManager
            }
        }
        
        // Active selection label
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitHeight: subtitleLabel.implicitHeight + 12
            implicitWidth: subtitleLabel.implicitWidth + 28
            color: Appearance.m3colors.m3inverseSurface
            radius: Appearance.rounding.full
            visible: root.subtitle !== ""
            
            StyledText {
                id: subtitleLabel
                anchors.centerIn: parent
                text: root.subtitle
                font.weight: Font.Medium
                color: Appearance.m3colors.m3inverseOnSurface
            }
        }
    }
}
