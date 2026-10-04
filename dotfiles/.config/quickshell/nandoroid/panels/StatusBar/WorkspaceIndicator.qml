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
 *   "unified" — sliding tab indicator + occupied pill stretching
 */
Item {
    id: root
    property HyprlandMonitor monitor
    readonly property int workspacesShown: Config.options.workspaces?.max_shown ?? 5
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1
    readonly property string activeSpecialName: {
        if (!monitor || !monitor.name) return "";
        var v = HyprlandData.monitorSpecialWorkspace[monitor.name];
        return (v !== undefined && v !== null) ? String(v) : "";
    }
    readonly property bool isSpecialActive: activeSpecialName !== ""

    readonly property int startWsId: Math.floor((activeWsId - 1) / workspacesShown) * workspacesShown + 1

    property list<bool> workspaceOccupied: []
    onWorkspacesShownChanged: { _hoveredIndex = -1; updateOccupied() }
    onStartWsIdChanged: { _hoveredIndex = -1; updateOccupied() }

    property string forcedStyle: ""
    readonly property bool isPcIslandActive: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "pcIsland"
    readonly property string indicatorStyle: forcedStyle !== "" ? forcedStyle : (isPcIslandActive ? "unified" : (Config.options.workspaces?.indicatorStyle ?? "pill"))
    readonly property string indicatorLabel: Config.options.workspaces?.indicatorLabel ?? "none"

    // Full-height transparent hitbox when this module lives in a side cluster
    // (pcIsland active): root stretches to status-bar height so wheel events
    // anywhere over the module switch workspace instead of falling through
    // to the brightness/volume scroll areas behind it. Visual stays centered.
    // Set to false when embedding inside a fixed-size pill (e.g. M3 wrapper).
    property bool fullHeightMode: isPcIslandActive
    readonly property real _hitHPad: fullHeightMode ? 8 * Appearance.effectiveScale : 0

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

    // AnimatedTabIndexPair (idx1 fast, idx2 slow)
    property real _tabIdx1: 0
    property real _tabIdx2: 0
    property int _hoveredIndex: -1

    // Public hover API for overlaying owners (e.g. M3 pill):
    // map pointer coords to hoverRow, then call hoveredIndexAt().
    property alias hoverRow: pillRow
    function hoveredIndexAt(rowX) {
        let best = -1
        let bestD = 1e9
        for (let i = 0; i < workspacesShown; i++) {
            const it = wsRepeater.itemAt(i)
            if (!it) continue
            const d = Math.abs(rowX - (it.x + it.width / 2))
            if (d < bestD) { bestD = d; best = i }
        }
        return best
    }

    Behavior on _tabIdx1 {
        enabled: !GlobalStates.screenLocked
        NumberAnimation { duration: 100; easing.type: Easing.OutSine }
    }
    Behavior on _tabIdx2 {
        enabled: !GlobalStates.screenLocked
        NumberAnimation { duration: 300; easing.type: Easing.OutSine }
    }

    readonly property real _tabDotSize: 20 * Appearance.effectiveScale
    readonly property real _tabSpacing: 6 * Appearance.effectiveScale
    readonly property real _tabStep: _tabDotSize + _tabSpacing
    readonly property real _tabMargin: 2 * Appearance.effectiveScale
    readonly property real _tabActiveSize: _tabDotSize - _tabMargin * 2

    // Random material shapes for indicatorLabel === "none" (same pool as PasswordChars)
    readonly property list<int> _noneShapePool: [
        MaterialShape.Shape.Pill,
        MaterialShape.Shape.Diamond,
        MaterialShape.Shape.ClamShell,
        MaterialShape.Shape.Pentagon,
        MaterialShape.Shape.Cookie4Sided,
        MaterialShape.Shape.SoftBurst,
        MaterialShape.Shape.Flower,
        MaterialShape.Shape.Puffy,
        MaterialShape.Shape.Gem,
        MaterialShape.Shape.Cookie9Sided
    ]

    // Deterministic pseudo-random per wsId — stable across paging.
    function _shapeForWs(wsId) {
        if (_noneShapePool.length === 0) return MaterialShape.Shape.Circle
        return _noneShapePool[(wsId * 7 + 3) % _noneShapePool.length]
    }

    // Warna shape aktif mengikuti wrappernya:
    // wrapper primary (darkmode) -> onPrimary, wrapper primaryContainer -> onPrimaryContainer
    readonly property color _onWrapperColor: Appearance.m3colors.darkmode ? Appearance.colors.colOnPrimary : Appearance.colors.colOnPrimaryContainer

    implicitWidth: (root.isSpecialActive ? specialOverlay.implicitWidth : pillRow.implicitWidth) + _hitHPad * 2
    implicitHeight: fullHeightMode ? Appearance.sizes.statusBarHeightCurrent : pillRow.implicitHeight

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

    // Block parent brightness/volume wheel when over indicator.
    // anchors.fill parent covers the full-height transparent wrapper in
    // fullHeightMode, so scrolling anywhere over the module (not just over
    // the dots) switches workspace and never leaks to volume/brightness.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        // Keep hover off: this layer sits below pillRow.
        hoverEnabled: false
        propagateComposedEvents: false
        onWheel: (wheel) => {
            const delta = wheel.angleDelta.y
            if (delta > 0) {
                if (root.activeWsId > 1) Hyprland.dispatch(HyprlandCompat.dspWorkspace("r-1"))
            } else if (delta < 0) {
                Hyprland.dispatch(HyprlandCompat.dspWorkspace("r+1"))
            }
            wheel.accepted = true
        }
    }

    readonly property var japaneseNumbers: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十"]
    readonly property var romanNumbers: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"]

    signal hoveredChanged(bool hovered)

    HoverHandler {
        id: rootHover
        onHoveredChanged: {
            root.hoveredChanged(hovered)
            // Fallback reset if a delegate is destroyed mid-hover (paging).
            if (!hovered && root._hoveredIndex !== -1)
                root._hoveredIndex = -1
        }
    }

    // ====================================================================
    // BASE ROW — click targets + sizing for both styles
    // ====================================================================
    Row {
        id: pillRow
        z: 2
        anchors.centerIn: parent
        spacing: root.indicatorStyle === "unified" ? root._tabSpacing : 4 * Appearance.effectiveScale
        opacity: root.isSpecialActive ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

        Repeater {
            id: wsRepeater
            model: root.workspacesShown

            delegate: Item {
                id: slot
                required property int index
                readonly property int wsId: root.startWsId + index
                readonly property bool isActive: wsId === root.activeWsId
                readonly property bool isOccupied: root.workspaceOccupied[index] ?? false
                readonly property bool isPill: root.indicatorStyle === "pill"
                readonly property bool showLabel: root.indicatorLabel !== "none"
                // Owned by hoverGrabber (single source of truth).
                readonly property bool isHovered: root._hoveredIndex === index

                // Sizing
                implicitWidth: isPill
                    ? (showLabel
                        ? (isActive ? 28 : (isHovered ? 20 : 8))
                        : (isActive ? 26 : 8)) * Appearance.effectiveScale
                    : root._tabDotSize
                implicitHeight: isPill
                    ? (showLabel
                        ? (isActive ? 18 : (isHovered ? 18 : 8))
                        : (isActive ? 18 : 8)) * Appearance.effectiveScale
                    : root._tabDotSize

                anchors.verticalCenter: parent.verticalCenter

                // ----- Pill style visual -----
                Rectangle {
                    visible: isPill
                    anchors.fill: parent
                    radius: height / 2

                    color: {
                        if (isActive) return Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
                        if (isHovered || isOccupied) return Appearance.colors.colNotchText
                        return Appearance.colors.colNotchSubtext
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
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: isActive ? Font.DemiBold : Font.Normal
                        color: isActive ? root._onWrapperColor : Appearance.colors.colNotchSubtext
                        opacity: isPill ? ((isActive || isHovered) ? 1 : 0) : 1
                    }
                }

                // ----- Unified: inactive dot, no label -----
                Rectangle {
                    visible: !isPill && !showLabel && !isActive
                    anchors.centerIn: parent
                    width: Math.round(root._tabDotSize * (isHovered ? 0.4 : 0.25))
                    height: width
                    radius: width / 2
                    color: (isOccupied || isHovered) ? Appearance.colors.colNotchText : Appearance.colors.colNotchSubtext
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutSine } }
                }

                // ----- Unified, no label: active MaterialShape over sliding wrapper -----
                MaterialShape {
                    visible: !isPill && !showLabel && isActive
                    anchors.centerIn: parent
                    implicitSize: Math.round(12 * Appearance.effectiveScale)
                    shape: root._shapeForWs(wsId)
                    color: root._onWrapperColor
                    scale: isActive ? 1 : 0.5
                    opacity: isActive ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // ----- Pill, no label: active MaterialShape over pill -----
                MaterialShape {
                    visible: isPill && !showLabel && isActive
                    anchors.centerIn: parent
                    implicitSize: Math.round(12 * Appearance.effectiveScale)
                    shape: root._shapeForWs(wsId)
                    color: root._onWrapperColor
                    scale: isActive ? 1 : 0.5
                    opacity: isActive ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack; easing.overshoot: 2.0 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
            }
        }
    }

    // Sole hover/click owner where no outer layer covers this indicator.
    // Covers dots and gaps, so gap clicks switch workspace instead of
    // leaking to the dashboard catcher below. Left-only: middle/right
    // fall through to the catcher underneath. Wheel passes through.
    // (In the M3 pill, m3wsWheel sits above, so hover never fires there;
    // clicks still land here, which is equivalent.)
    MouseArea {
        id: hoverGrabber
        anchors.fill: pillRow
        z: 5
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !root.isSpecialActive
        function updateHover(mx) {
            const idx = root.hoveredIndexAt(mx)
            if (idx !== -1 && root._hoveredIndex !== idx)
                root._hoveredIndex = idx
        }
        // entered() carries no coords; mouseX is already in pillRow coords.
        onEntered: updateHover(mouseX)
        onPositionChanged: (mouse) => updateHover(mouse.x)
        onClicked: (mouse) => {
            const idx = root.hoveredIndexAt(mouse.x)
            if (idx !== -1)
                Hyprland.dispatch(HyprlandCompat.dspWorkspace(root.startWsId + idx))
        }
        onExited: {
            if (root._hoveredIndex !== -1)
                root._hoveredIndex = -1
        }
    }

    // ====================================================================
    // UNIFIED STYLE — visual overlay
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

        // Hover overlay (white circle)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: root._hoveredIndex * root._tabStep
            implicitWidth: root._tabDotSize
            implicitHeight: root._tabDotSize
            radius: height / 2
            color: "#ffffff"
            opacity: root._hoveredIndex >= 0 ? 0.28 : 0
            Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.OutSine } }
            Behavior on opacity { NumberAnimation { duration: 100 } }
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
            enabled: root.isSpecialActive
            onClicked: {
                if (root.activeSpecialName !== "")
                    Hyprland.dispatch(HyprlandCompat.dspToggleSpecial(root.activeSpecialName));
                else
                    Hyprland.dispatch(HyprlandCompat.dspToggleSpecial());
            }
        }
    }
}
