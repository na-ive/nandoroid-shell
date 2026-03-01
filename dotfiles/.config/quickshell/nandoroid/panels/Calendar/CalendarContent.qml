import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    signal closed()

    focus: true
    Keys.onEscapePressed: close()

    property bool active: GlobalStates.calendarOpen
    opacity: active ? 1 : 0
    implicitWidth: Appearance.sizes.calendarWidth
    implicitHeight: mainColumn.implicitHeight + 24 + 10 // Account for extra top margin
    
    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }
    
    function close() {
        root.closed();
    }

    Connections {
        target: GlobalStates
        function onCalendarOpenChanged() {
            if (GlobalStates.calendarOpen) {
                root.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: {
        if (GlobalStates.calendarOpen) {
            root.forceActiveFocus();
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.panel
        visible: active
    }

    ColumnLayout {
        id: mainColumn
        width: Appearance.sizes.calendarWidth - 24
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 12
        anchors.topMargin: 12 + 10 // Base 12 + 10 floating margin
        spacing: 12
        
        // --- Calendar Island ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: calendarWidget.implicitHeight + 24
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

            CalendarWidget {
                id: calendarWidget
                anchors.fill: parent
                anchors.margins: 12
            }
        }

        // --- Pomodoro Island ---
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pomodoroTimer.implicitHeight + 20
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.normal

            PomodoroTimer {
                id: pomodoroTimer
                anchors.fill: parent
                anchors.margins: 10
            }
        }
    }
}
