import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import "../../services"

Rectangle {
    id: root
    color: Appearance.m3colors.m3surfaceContainer
    radius: Appearance.rounding.normal
    clip: true

    property int currentTab: 0
    onCurrentTabChanged: GlobalStates.dashClockTab = currentTab
    Connections {
        target: GlobalStates
        function onDashClockTabChanged() { root.currentTab = GlobalStates.dashClockTab }
    }
    readonly property var tabModel: [
        { name: I18nService.tr("Pomodoro"), icon: "av_timer" },
        { name: I18nService.tr("Stopwatch"), icon: "timer" },
        { name: I18nService.tr("Timer"), icon: "hourglass_bottom" },
        { name: I18nService.tr("Alarm"), icon: "access_alarms" }
    ]


    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Top Tab Bar ──
        StyledTabBar {
            showIcon: true
            iconOnTop: true
            currentTab: root.currentTab
            onTabClicked: (index) => root.currentTab = index
            tabModel: root.tabModel
        }

        // ── Content Area ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                anchors.fill: parent
                active: root.currentTab === 0
                visible: active
                sourceComponent: PomodoroView {}
            }

            Loader {
                anchors.fill: parent
                active: root.currentTab === 1
                visible: active
                sourceComponent: StopwatchView {}
            }

            Loader {
                anchors.fill: parent
                active: root.currentTab === 2
                visible: active
                sourceComponent: TimerView {}
            }

            Loader {
                anchors.fill: parent
                active: root.currentTab === 3
                visible: active
                sourceComponent: AlarmView {}
            }
        }
    }
}
