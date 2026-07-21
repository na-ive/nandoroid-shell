import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

/**
 * Workspace indicator with two modes:
 *   "pill"    — simple Android-style expanding dots
 *   "unified" — sliding tab indicator + occupied pill stretching (port of end4-pC)
 */
Item {
    id: root
    property HyprlandMonitor monitor
    readonly property int workspacesShown: Config.options.workspaces?.max_shown ?? 5
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    property string activeSpecialName: ""
    property bool isSpecialActive: activeSpecialName !== ""

    readonly property int startWsId: Math.floor((activeWsId - 1) / workspacesShown) * workspacesShown + 1

    property list<bool> workspaceOccupied: []
    onWorkspacesShownChanged: updateOccupied()
    onStartWsIdChanged: updateOccupied()

    readonly property string indicatorStyle: Config.options.workspaces?.indicatorStyle ?? "pill"
    readonly property string indicatorLabel: Config.options.workspaces?.indicatorLabel ?? "none"

    // Contiguous occupied groups — one rect per group, no overlap
    readonly property var _occGroups: {
        const occ = root.workspaceOccupied;
        const groups = [];
        let start = -1;
        for (let i = 0; i < occ.length; i++) {
            if (occ[i]) {
                if (start === -1) start = i;
            } else if (start !== -1) {
                groups.push([start, i - 1]);
                start = -1;
            }
        }
        if (start !== -1) groups.push([start, occ.length - 1]);
        return groups;
    }

    onActiveWsIdChanged: {
        const localIdx = (activeWsId - 1) % workspacesShown
        _tabIdx1 = localIdx
        _tabIdx2 = localIdx
        root.updateOccupied()
    }

    // AnimatedTabIndexPair (end4-pC pattern: idx1 fast, idx2 slow)
    property real _tabIdx1: 0
    property real _tabIdx2: 0

    Behavior on _tabIdx1 {
        NumberAnimation { duration: 100; easing.type: Easing.OutSine }
    }
    Behavior on _tabIdx2 {
        NumberAnimation { duration: 300; easing.type: Easing.OutSine }
    }

    readonly property real _tabDotSize: 20 * Appearance.effectiveScale
    readonly property real _tabSpacing: 6 * Appearance.effectiveScale
    readonly property real _tabStep: _tabDotSize + _tabSpacing
    readonly property real _tabMargin: 2 * Appearance.effectiveScale
    readonly property real _tabActiveSize: _tabDotSize - _tabMargin * 2

    implicitWidth: root.isSpecialActive ? specialOverlay.implicitWidth : pillRow.implicitWidth
    implicitHeight: pillRow.implicitHeight

    Component.onCompleted: {
        const localIdx = (root.activeWsId - 1) % root.workspacesShown
        _tabIdx1 = localIdx
        _tabIdx2 = localIdx
        root.updateOccupied()
    }

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

    readonly property var japaneseNumbers: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
    readonly property var romanNumbers: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

    signal hoveredChanged(bool hovered)

    HoverHandler {
        onHoveredChanged: root.hoveredChanged(hovered)
    }

    // ====================================================================
    // BASE ROW — click targets + sizing for both styles
    // ====================================================================
    Row {
        id: pillRow
        z: 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.indicatorStyle === "unified" ? root._tabSpacing : 4 * Appearance.effectiveScale
        opacity: root.isSpecialActive ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        Repeater {
            model: root.workspacesShown

            delegate: Item {
                id: slot
                required property int index
                readonly property int wsId: root.startWsId + index
                readonly property bool isActive: wsId === root.activeWsId
                readonly property bool isOccupied: root.workspaceOccupied[index] ?? false
                readonly property bool isPill: root.indicatorStyle === "pill"
                readonly property bool showLabel: root.indicatorLabel !== "none"
                readonly property bool isHovered: mouseArea.containsMouse

                // Sizing
                implicitWidth: isPill
                    ? (showLabel
                        ? (isActive ? 28 : (isHovered ? 20 : (isOccupied ? 8 : 6)))
                        : (isActive ? 16 : (isOccupied ? 8 : 6))) * Appearance.effectiveScale
                    : root._tabDotSize
                implicitHeight: isPill
                    ? (showLabel
                        ? (isActive ? 18 : (isHovered ? 18 : (isOccupied ? 8 : 6)))
                        : (isActive ? 8 : (isOccupied ? 8 : 6))) * Appearance.effectiveScale
                    : root._tabDotSize

                anchors.verticalCenter: parent.verticalCenter

                // ----- Pill style visual -----
                Rectangle {
                    visible: isPill
                    anchors.fill: parent
                    radius: height / 2

                    color: {
                        if (isActive) return Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
                        return isOccupied ? Appearance.colors.colNotchText : Appearance.colors.colNotchSubtext
                    }
                    border.width: (!isActive && !isOccupied && !isHovered) ? 1 : 0
                    border.color: Appearance.colors.colNotchSubtext
                }

                // ----- Number label -----
                Item {
                    anchors.fill: parent
                    clip: true
                    visible: showLabel

                    StyledText {
                        anchors.centerIn: parent
                        text: {
                            const actualIdx = wsId - 1;
                            if (root.indicatorLabel === "japanese") return root.japaneseNumbers[actualIdx] || wsId.toString()
                            if (root.indicatorLabel === "roman") return root.romanNumbers[actualIdx] || wsId.toString()
                            return wsId.toString()
                        }
                        font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                        font.weight: isActive ? Font.DemiBold : Font.Normal
                        color: isActive ? Appearance.colors.colNotchActive : (isHovered ? Appearance.colors.colNotchActive : Appearance.colors.colNotchSubtext)
                        opacity: isPill ? ((isActive || isHovered) ? 1 : 0) : 1
                    }
                }

                // ----- Unified: small dot fallback when no label -----
                Rectangle {
                    visible: !isPill && !showLabel
                    anchors.centerIn: parent
                    width: Math.round(root._tabDotSize * (isActive ? 0.45 : 0.25))
                    height: width
                    radius: width / 2
                    color: isActive ? Appearance.colors.colNotchActive : (isOccupied ? Appearance.colors.colNotchText : Appearance.colors.colNotchSubtext)
                }

                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.margins: -4 * Appearance.effectiveScale
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(HyprlandCompat.dspWorkspace(wsId))
                }
            }
        }
    }

    // ====================================================================
    // UNIFIED STYLE — visual overlay (port of end4-pC Workspaces.qml)
    // ====================================================================
    Item {
        id: unifiedSection
        visible: root.indicatorStyle === "unified"
        anchors.fill: pillRow
        opacity: root.isSpecialActive ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        // Occupied indicator groups (one pill per contiguous occupied block, no overlap)
        Repeater {
            model: root._occGroups.length

            delegate: Rectangle {
                required property int index
                readonly property var range: root._occGroups[index]
                readonly property int gStart: range[0]
                readonly property int gEnd: range[1]

                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2

                x: gStart * root._tabStep
                implicitWidth: (gEnd - gStart) * root._tabStep + root._tabDotSize
                implicitHeight: root._tabDotSize

                color: Appearance.colors.colNotchText
                opacity: 0.25

                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
                Behavior on implicitWidth { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }
            }
        }

        // Trailing indicator (sliding active pill, two-speed animation)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter

            readonly property real _minIdx: Math.min(root._tabIdx1, root._tabIdx2)
            readonly property real _maxIdx: Math.max(root._tabIdx1, root._tabIdx2)

            x: _minIdx * root._tabStep
            implicitWidth: (_maxIdx - _minIdx) * root._tabStep + root._tabDotSize
            implicitHeight: root._tabDotSize
            radius: height / 2

            color: Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
        }

    }

    // ====================================================================
    // SPECIAL WORKSPACE OVERLAY
    // ====================================================================
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
            color: Appearance.colors.colNotchActive
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
