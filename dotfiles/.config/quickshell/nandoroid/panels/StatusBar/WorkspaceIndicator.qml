import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

/**
 * Android-style workspace dot/pill indicator.
 * Active = primary-colored pill, Occupied = smaller dot, Empty = outline dot.
 */
Item {
    id: root
    property HyprlandMonitor monitor
    readonly property int workspacesShown: Config.options.workspaces?.max_shown ?? 5
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    property list<bool> workspaceOccupied: []
    onWorkspacesShownChanged: updateOccupied()

    implicitWidth: pillRow.implicitWidth
    implicitHeight: pillRow.implicitHeight


    Component.onCompleted: updateOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.updateOccupied() }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.updateOccupied() }
    }

    function updateOccupied() {
        workspaceOccupied = Array.from({ length: workspacesShown }, (_, i) => {
            const wsId = i + 1;
            return Hyprland.workspaces.values.some(ws => ws.id === wsId);
        })
    }

    Row {
        id: pillRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: root.workspacesShown

            delegate: Rectangle {
                id: dot
                required property int index
                property int wsId: index + 1
                property bool isActive: wsId === root.activeWsId
                property bool isOccupied: root.workspaceOccupied[index] ?? false

                // Active workspace = wider pill, occupied = medium dot, empty = small dot
                implicitWidth: isActive ? 16 : (isOccupied ? 8 : 6)
                implicitHeight: isActive ? 8 : (isOccupied ? 8 : 6)
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter

                color: isActive ? Appearance.colors.colNotchPrimary
                     : isOccupied ? Appearance.colors.colNotchText
                     : Appearance.colors.colNotchSubtext

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.OutCubic
                    }
                }

                // Click to switch workspace
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -2
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`workspace ${dot.wsId}`)
                }
            }
        }
    }
}
