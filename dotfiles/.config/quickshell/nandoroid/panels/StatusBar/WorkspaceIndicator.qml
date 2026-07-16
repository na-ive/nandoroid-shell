import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

/**
 * Android-style workspace dot/pill indicator.
 * Refactored for global scaling.
 */
Item {
    id: root
    property HyprlandMonitor monitor
    readonly property int workspacesShown: Config.options.workspaces?.max_shown ?? 5
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    property string activeSpecialName: ""
    property bool isSpecialActive: activeSpecialName !== ""
    
    // Pagination logic
    readonly property int startWsId: Math.floor((activeWsId - 1) / workspacesShown) * workspacesShown + 1
    
    property list<bool> workspaceOccupied: []
    onWorkspacesShownChanged: updateOccupied()
    onStartWsIdChanged: updateOccupied()

    readonly property string indicatorStyle: Config.options.workspaces?.indicatorStyle ?? "pill"
    readonly property string indicatorLabel: Config.options.workspaces?.indicatorLabel ?? "none"

    onActiveWsIdChanged: {
        const localIdx = (activeWsId - 1) % workspacesShown
        if (root.indicatorStyle === "unified") {
            tabHighlight.idx1 = localIdx
            Qt.callLater(() => { tabHighlight.idx2 = localIdx })
        } else {
            tabHighlight.idx1 = localIdx
            tabHighlight.idx2 = localIdx
        }
        root.updateOccupied()
    }

    implicitWidth: root.isSpecialActive ? specialOverlay.implicitWidth : pillRow.implicitWidth
    implicitHeight: pillRow.implicitHeight

    Component.onCompleted: updateOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.updateOccupied() }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.updateOccupied() }
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                let parts = event.data.split(',');
                let name = parts[0];
                let monName = parts[1];
                if (monName === monitor.name) {
                    root.activeSpecialName = name.replace("special:", "");
                }
            } else if (event.name === "activespecialv2") {
                let parts = event.data.split(',');
                let name = parts[1];
                let monName = parts[2];
                if (monName === monitor.name) {
                    root.activeSpecialName = name.replace("special:", "");
                }
            }
        }
    }

    function updateOccupied() {
        workspaceOccupied = Array.from({ length: workspacesShown }, (_, i) => {
            const wsId = root.startWsId + i;
            return Hyprland.workspaces.values.some(ws => ws.id === wsId);
        })
    }

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
                if (root.activeWsId > 1) Hyprland.dispatch(HyprlandCompat.dspWorkspace("r-1"))
            } else if (event.angleDelta.y < 0) {
                Hyprland.dispatch(HyprlandCompat.dspWorkspace("r+1"))
            }
        }
    }

    // Animated stretch-highlight pill
    Rectangle {
        id: tabHighlight
        visible: root.indicatorStyle === "unified"
        opacity: root.isSpecialActive ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        z: 0

        property int idx1: (activeWsId - 1) % workspacesShown
        property int idx2: (activeWsId - 1) % workspacesShown
        
        readonly property real dotWidth: 18 * Appearance.effectiveScale
        readonly property real dotHeight: 18 * Appearance.effectiveScale
        readonly property real spacing: 6 * Appearance.effectiveScale
        readonly property real activeWidth: 18 * Appearance.effectiveScale
        
        function getXForIndex(i) {
            return i * (dotWidth + spacing)
        }
        
        property real targetX1: getXForIndex(idx1)
        property real targetX2: getXForIndex(idx2)
        property real animX1: targetX1
        property real animX2: targetX2
        
        anchors.verticalCenter: pillRow.verticalCenter
        x: pillRow.x + Math.min(animX1, animX2)
        width: Math.abs(animX2 - animX1) + activeWidth
        height: dotHeight
        radius: height / 2
        
        color: Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer

        Behavior on animX1 {
            NumberAnimation { duration: 120; easing.type: Easing.OutSine }
        }
        Behavior on animX2 {
            NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
        }

        onIdx1Changed: { targetX1 = getXForIndex(idx1) }
        onIdx2Changed: { targetX2 = getXForIndex(idx2) }
    }

    Row {
        id: pillRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: (root.indicatorStyle === "pill" ? 4 : 6) * Appearance.effectiveScale
        opacity: root.isSpecialActive ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        readonly property var japaneseNumbers: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
        readonly property var romanNumbers: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

        Repeater {
            model: root.workspacesShown

            delegate: Rectangle {
                id: dot
                required property int index
                property int wsId: root.startWsId + index
                property bool isActive: wsId === root.activeWsId
                property bool isOccupied: root.workspaceOccupied[index] ?? false
                property bool isHovered: mouseArea.containsMouse
                z: 1 

                readonly property bool isUnified: root.indicatorStyle === "unified"
                readonly property bool hasLabel: root.indicatorLabel !== "none"

                implicitWidth: {
                    if (isUnified) return 18 * Appearance.effectiveScale
                    if (hasLabel) {
                        return (isActive ? 28 : (isHovered ? 20 : (isOccupied ? 8 : 6))) * Appearance.effectiveScale
                    }
                    return (isActive ? 16 : (isOccupied ? 8 : 6)) * Appearance.effectiveScale
                }
                
                implicitHeight: {
                    if (isUnified) return 18 * Appearance.effectiveScale
                    if (hasLabel) {
                        return (isActive ? 18 : (isHovered ? 18 : (isOccupied ? 8 : 6))) * Appearance.effectiveScale
                    }
                    return (isActive ? 8 : (isOccupied ? 8 : 6)) * Appearance.effectiveScale
                }

                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter

                color: {
                    if (isUnified && isActive) return "transparent"
                    if (isActive) {
                        return Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
                    }
                    return isOccupied ? Appearance.colors.colNotchText : Appearance.colors.colNotchSubtext
                }

                border.width: (!isUnified && !isActive && !isOccupied && !isHovered) ? 1 : 0
                border.color: Appearance.colors.colNotchSubtext

                Item {
                    anchors.fill: parent
                    clip: true
                    visible: dot.hasLabel

                    StyledText {
                        anchors.centerIn: parent
                        text: {
                            const actualIdx = dot.wsId - 1;
                            if (root.indicatorLabel === "japanese") {
                                return pillRow.japaneseNumbers[actualIdx] || (dot.wsId).toString()
                            }
                            if (root.indicatorLabel === "roman") {
                                return pillRow.romanNumbers[actualIdx] || (dot.wsId).toString()
                            }
                            return (dot.wsId).toString()
                        }
                        font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                        font.weight: isActive ? Font.DemiBold : Font.Normal
                        color: "#1E1E1E" 
                        opacity: (isActive || isHovered || isUnified) ? 1 : 0
                    }
                }

                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -4 * Appearance.effectiveScale
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(HyprlandCompat.dspWorkspace(dot.wsId))
                }
            }
        }

    }

    Rectangle {
        id: specialOverlay
        anchors.centerIn: parent
        width: root.isSpecialActive ? implicitWidth : pillRow.implicitWidth
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
        clip: true
        implicitWidth: specialText.implicitWidth + 24 * Appearance.effectiveScale
        implicitHeight: 24 * Appearance.effectiveScale
        radius: height / 2
        opacity: root.isSpecialActive ? 1 : 0
        scale: root.isSpecialActive ? 1 : 0.8
        color: Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

        StyledText {
            id: specialText
            anchors.centerIn: parent
            text: root.activeSpecialName ? (root.activeSpecialName.charAt(0).toUpperCase() + root.activeSpecialName.slice(1)) : ""
            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
            font.weight: Font.DemiBold
            color: "#1E1E1E"
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("togglespecialworkspace " + root.activeSpecialName)
        }
    }

    Process {
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            id: initialSpecialCollector
            onStreamFinished: {
                try {
                    let monitors = JSON.parse(initialSpecialCollector.text);
                    for (let i = 0; i < monitors.length; i++) {
                        if (monitors[i].name === monitor.name) {
                            if (monitors[i].specialWorkspace && monitors[i].specialWorkspace.name !== "") {
                                root.activeSpecialName = monitors[i].specialWorkspace.name.replace("special:", "");
                            }
                            break;
                        }
                    }
                } catch (e) {}
            }
        }
    }
}
