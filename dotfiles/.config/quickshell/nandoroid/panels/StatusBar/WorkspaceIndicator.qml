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

    // Layout cycle handlers
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) HyprlandData.cycleLayout()
            if (mouse.button === Qt.RightButton) GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }

    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                if (root.activeWsId > 1) Hyprland.dispatch("workspace r-1")
            } else if (event.angleDelta.y < 0) {
                Hyprland.dispatch("workspace r+1")
            }
        }
    }

    Row {
        id: pillRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: indicatorStyle === "pill" ? 4 : 6

        readonly property string indicatorStyle: Config.options.workspaces?.indicatorStyle ?? "pill"
        readonly property var japaneseNumbers: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
        readonly property var romanNumbers: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

        Repeater {
            model: root.workspacesShown

            delegate: Rectangle {
                id: dot
                required property int index
                property int wsId: index + 1
                property bool isActive: wsId === root.activeWsId
                property bool isOccupied: root.workspaceOccupied[index] ?? false
                property bool isHovered: mouseArea.containsMouse

                // Mode-aware sizing
                readonly property bool isTextMode: pillRow.indicatorStyle !== "pill"

                implicitWidth: {
                    if (isTextMode) {
                        return isActive ? 28 : (isHovered ? 20 : (isOccupied ? 8 : 6))
                    }
                    return isActive ? 16 : (isOccupied ? 8 : 6)
                }
                
                implicitHeight: {
                    if (isTextMode) {
                        return isActive ? 18 : (isHovered ? 18 : (isOccupied ? 8 : 6))
                    }
                    return isActive ? 8 : (isOccupied ? 8 : 6)
                }

                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter

                color: {
                    if (isActive) {
                        return Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
                    }
                    return isOccupied ? Appearance.colors.colNotchText : Appearance.colors.colNotchSubtext
                }

                border.width: (!isActive && !isOccupied && !isHovered) ? 1 : 0
                border.color: Appearance.colors.colNotchSubtext

                // Label container with clip to hide text when dot is small
                Item {
                    anchors.fill: parent
                    clip: true
                    visible: dot.isTextMode

                    StyledText {
                        anchors.centerIn: parent
                        text: {
                            if (pillRow.indicatorStyle === "japanese") {
                                return pillRow.japaneseNumbers[index] || (index + 1).toString()
                            }
                            if (pillRow.indicatorStyle === "roman") {
                                return pillRow.romanNumbers[index] || (index + 1).toString()
                            }
                            return (index + 1).toString()
                        }
                        font.pixelSize: 10
                        font.weight: isActive ? Font.Bold : Font.Normal
                        color: "#1E1E1E" // Always dark text regardless of mode
                        opacity: (isActive || isHovered) ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }
                }
                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
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
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`workspace ${dot.wsId}`)
                }
            }
        }
    }
}
