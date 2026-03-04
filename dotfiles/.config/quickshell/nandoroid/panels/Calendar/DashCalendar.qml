import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import "calendar_layout.js" as CalendarLayout

/**
 * Dashboard Tab 1: Calendar + Pomodoro (Horizontal Layout)
 */
RowLayout {
    id: root
    spacing: 12

    // ── Calendar ──
    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.normal

        CalendarWidget {
            anchors.fill: parent
            anchors.margins: 12
        }
    }

    // ── Pomodoro ──
    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.normal

        PomodoroTimer {
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
