pragma ComponentBehavior: Bound

import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    Loader {
        active: GlobalStates.datePickerOpen
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData

                readonly property bool isActive: GlobalStates.activeScreen === modelData
                visible: GlobalStates.datePickerOpen && isActive

                anchors { top: true; left: true; right: true; bottom: true }
                color: "transparent"
                WlrLayershell.namespace: "nandoroid:datepicker"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.layer: GlobalStates.datePickerOpen && isActive ? WlrLayer.Overlay : WlrLayer.Background
                exclusionMode: ExclusionMode.Ignore

                Rectangle {
                    anchors.fill: parent
                    color: Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.6)
                    opacity: GlobalStates.datePickerOpen && isActive ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: GlobalStates.datePickerOpen = false
                    }
                }

                DatePicker {
                    id: picker
                    anchors.centerIn: parent
                    currentDateStr: GlobalStates.datePickerCurrentDate

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            GlobalStates.datePickerOpen = false
                            event.accepted = true
                        }
                    }

                    onDateSelected: dateStr => {
                        if (GlobalStates.datePickerOnSelected)
                            GlobalStates.datePickerOnSelected(dateStr)
                        GlobalStates.datePickerOpen = false
                    }

                    onCancelled: {
                        if (GlobalStates.datePickerOnCancelled)
                            GlobalStates.datePickerOnCancelled()
                        GlobalStates.datePickerOpen = false
                    }
                }
            }
        }
    }
}
