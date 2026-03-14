import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

/**
 * Dashboard panel — redesigned from the old CalendarContent.
 * Features a vertical Ambxst-style tab strip on the left and
 * 4 content tabs on the right:
 *   0: Calendar + Pomodoro (horizontal)
 *   1: Schedule / Calendar Maker
 *   2: Notepad
 *   3: GitHub Profile Tracker
 */
Item {
    id: root
    signal closed()

    focus: true
    Keys.onEscapePressed: close()
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ControlModifier)) {
            currentTab = (currentTab + 1) % tabCount
            event.accepted = true
        }
    }

    property bool active: GlobalStates.dashboardOpen
    property int currentTab: 0
    onCurrentTabChanged: {
        tabHighlight.idx1 = currentTab
        Qt.callLater(() => { tabHighlight.idx2 = currentTab })
    }
    readonly property int tabCount: 5
    readonly property int tabButtonSize: 44
    readonly property int tabStripWidth: tabButtonSize + 16 // button + side padding

    // The panel itself is centred inside the full-screen-width window
    readonly property int panelWidth: Appearance.sizes.dashboardWidth
    readonly property int panelHeight: Appearance.sizes.dashboardHeight
    // Corner radius used for the shoulder pieces — match statusbar corner radius
    readonly property int shoulderRadius: Config.ready && Config.options.statusBar
        ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20

    // Window is sized exactly for the panel plus shoulder pieces
    implicitWidth: panelWidth + (shoulderRadius * 2)
    implicitHeight: panelHeight

    // ── Animation state (State / Transition pattern) ──
    property real panelOpacity: panelBg.opacity

    states: [
        State {
            name: "visible"
            when: GlobalStates.dashboardOpen
            PropertyChanges {
                target: visualContainer
                y: 0
                opacity: 1
            }
            PropertyChanges {
                target: panelBg
                y: 0
                opacity: 1
            }
            PropertyChanges {
                target: rightShoulder
                opacity: 1
            }
            PropertyChanges {
                target: leftShoulder
                opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "visible"
            ParallelAnimation {
                NumberAnimation {
                    target: visualContainer
                    property: "y"
                    from: -20
                    to: 0
                    duration: 300
                    easing.type: Easing.OutQuart
                }
                NumberAnimation {
                    target: panelBg
                    property: "y"
                    duration: root.showShoulders ? 300 : (Appearance.animation.elementMove.duration || 400)
                    easing.bezierCurve: root.showShoulders ? Appearance.animationCurves.emphasizedDecel : (Appearance.animationCurves.expressiveDefaultSpatial || [0.38, 1.21, 0.22, 1])
                }
                NumberAnimation {
                    targets: [panelBg, rightShoulder, leftShoulder, visualContainer]
                    property: "opacity"
                    duration: 300
                }
            }
        },
        Transition {
            from: "visible"
            to: ""
            ParallelAnimation {
                NumberAnimation {
                    target: visualContainer
                    property: "y"
                    to: -root.panelHeight - 40 // Move the whole container far up
                    duration: Appearance.animation.elementMoveExit.duration || 400
                    easing.bezierCurve: Appearance.animationCurves.emphasized || [0.2, 0.0, 0.0, 1.0]
                }
                NumberAnimation {
                    target: panelBg
                    property: "y"
                    to: -root.panelHeight
                    duration: Appearance.animation.elementMoveExit.duration || 400
                    easing.bezierCurve: Appearance.animationCurves.emphasized || [0.2, 0.0, 0.0, 1.0]
                }
                NumberAnimation {
                    targets: [panelBg, rightShoulder, leftShoulder, visualContainer]
                    property: "opacity"
                    to: 0
                    duration: Appearance.animation.elementMoveExit.duration || 400
                }
            }
        }
    ]

    function close() {
        root.closed()
    }

    Connections {
        target: GlobalStates
        function onDashboardOpenChanged() {
            if (GlobalStates.dashboardOpen) {
                // Reset tab to default (tab 1 = calendar) when opened
                currentTab = 0
                tabHighlight.reset()
                root.forceActiveFocus()
            }
        }
    }
    // ── Statusbar Background Detection ──
    readonly property int bgStyle: Config.ready && Config.options.statusBar
        ? (Config.options.statusBar.backgroundStyle ?? 0) : 0
    property bool hasActiveWindows: false

    Connections {
        enabled: root.bgStyle === 2
        target: HyprlandData
        function onWindowListChanged() {
            root.updateActiveWindows()
        }
        function onActiveWorkspaceChanged() {
            root.updateActiveWindows()
        }
    }
    
    function updateActiveWindows() {
        if (!HyprlandData) return;
        // Check current workspace based on HyprlandData.activeWorkspace
        // Since Dashboard is a global window, assume we care about the currently focused monitor's workspace
        const activeWsId = HyprlandData.activeWorkspace?.id;
        root.hasActiveWindows = activeWsId
            ? HyprlandData.windowList.some(w => w.workspace.id === activeWsId && !w.floating)
            : false;
    }

    readonly property bool showShoulders: {
        if (bgStyle === 1) return true;
        if (bgStyle === 2) return hasActiveWindows;
        return false;
    }

    Component.onCompleted: {
        updateActiveWindows()
        if (GlobalStates.dashboardOpen) root.forceActiveFocus()
    }

    // ── Visual Container for Shadow ──
    Item {
        id: visualContainer
        anchors.fill: parent
        opacity: panelBg.opacity

        layer.enabled: root.showShoulders
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 2
            radius: 24
            samples: 32
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.12)
            transparentBorder: true
        }

        // ── Main Panel Rectangle ──
        Rectangle {
            id: clipRect
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: root.panelWidth
            height: root.panelHeight
            clip: true
            color: "transparent"

            Rectangle {
                id: panelBg
                width: root.panelWidth
                height: root.panelHeight
                // y starts at -height (hidden above), and opacity 0
                y: -root.panelHeight
                opacity: 0
                color: Appearance.m3colors.m3surfaceContainerLow
                topLeftRadius: root.showShoulders ? 0 : Appearance.rounding.large
                topRightRadius: root.showShoulders ? 0 : Appearance.rounding.large
                bottomLeftRadius: Appearance.rounding.large
                bottomRightRadius: Appearance.rounding.large

                // MD3 Outline Style (Active when not fused with status bar)
                border.width: root.showShoulders ? 0 : 1
                border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

                // Prevent clicks inside the panel from falling through to the background closer

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Row {
                    id: mainLayout
                    anchors.fill: parent
                    // Inner padding
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 16
                    bottomPadding: 16
                    spacing: 16

                    // ── Vertical Tab Strip ──
            Item {
                id: tabStrip
                width: root.tabStripWidth
                height: parent.height

                // Scroll to change tab - restricted to tabStrip area
                MouseArea {
                    anchors.fill: parent
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y > 0) {
                            root.currentTab = (root.currentTab - 1 + root.tabCount) % root.tabCount
                        } else if (wheel.angleDelta.y < 0) {
                            root.currentTab = (root.currentTab + 1) % root.tabCount
                        }
                    }
                }

                // Y-offset where the button group starts (vertically centered)
                readonly property real buttonsTop: Math.round(
                    (height - root.tabCount * (root.tabButtonSize + 6) + 6) / 2
                )

                // Card background for the tab buttons
                Rectangle {
                    id: tabButtonsCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: tabStrip.buttonsTop - 8
                    width: root.tabButtonSize + 16
                    height: (root.tabButtonSize + 6) * root.tabCount + 10
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer2
                    opacity: 0.8
                }

                // Animated stretch-highlight pill (Ambxst style)
                Rectangle {
                    id: tabHighlight
                    // Centered within the strip, same as the Column's horizontalCenter
                    x: Math.round((tabStrip.width - root.tabButtonSize) / 2)
                    width: root.tabButtonSize
                    radius: 16

                    // Elastic stretch: idx1 snaps fast, idx2 follows slowly
                    property int idx1: 0
                    property int idx2: 0
                    
                    function reset() {
                        idx1 = 0
                        idx2 = 0
                    }

                    function getYForIndex(i) {
                        return tabStrip.buttonsTop + i * (root.tabButtonSize + 6)
                    }

                    property real targetY1: getYForIndex(idx1)
                    property real targetY2: getYForIndex(idx2)
                    property real animY1: targetY1
                    property real animY2: targetY2

                    y: Math.min(animY1, animY2)
                    height: Math.abs(animY2 - animY1) + root.tabButtonSize

                    color: Appearance.colors.colPrimaryContainer

                    Behavior on animY1 {
                        NumberAnimation { duration: 120; easing.type: Easing.OutSine }
                    }
                    Behavior on animY2 {
                        NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                    }

                    onTargetY1Changed: animY1 = targetY1
                    onTargetY2Changed: animY2 = targetY2

                    onIdx1Changed: { targetY1 = getYForIndex(idx1) }
                    onIdx2Changed: { targetY2 = getYForIndex(idx2) }
                }

                // Tab buttons (vertically centered, matching buttonsTop used by highlight)
                Column {
                    anchors.top: parent.top
                    anchors.topMargin: tabStrip.buttonsTop
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Repeater {
                        model: [
                            { icon: "calendar_today",  tooltip: "Calendar & Pomodoro" },
                            { icon: "event_note",       tooltip: "Schedule" },
                            { icon: "edit_note",        tooltip: "Notepad" },
                            { icon: "translate",        tooltip: "Translator" },
                            { icon: "code",             tooltip: "GitHub" }
                        ]
                        delegate: Item {
                            required property int index
                            required property var modelData
                            width: root.tabButtonSize
                            height: root.tabButtonSize

                            // Hover ripple
                            Rectangle {
                                anchors.fill: parent
                                radius: Appearance.rounding.small
                                color: Appearance.colors.colLayer1
                                opacity: btnMouse.containsMouse && root.currentTab !== index ? 0.7 : 0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: 22
                                color: root.currentTab === index
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colSubtext
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            StyledToolTip { text: modelData.tooltip }

                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.currentTab = index
                                }
                            }
                        }
                    }
                }

            } // End tabStrip

            // ── Content Area ──
            Item {
                id: contentArea
                // panelWidth minus (leftPadding+rightPadding=32) minus tabStripWidth minus spacing(16)
                width: root.panelWidth - 48 - root.tabStripWidth
                height: root.panelHeight - 32

                // Tab 0: Calendar + Pomodoro
                Loader {
                    anchors.fill: parent
                    active: root.currentTab === 0
                    visible: root.currentTab === 0
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 0 ? 0 : (root.currentTab > 0 ? -12 : 12)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    
                    onVisibleChanged: {
                        if (visible && item && typeof item.reloadSchedule === "function") {
                            item.reloadSchedule()
                        }
                    }
                    
                    sourceComponent: DashCalendar { width: contentArea.width; height: contentArea.height }
                }

                // Tab 1: Schedule
                Loader {
                    anchors.fill: parent
                    active: root.currentTab === 1
                    visible: root.currentTab === 1
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 1 ? 0 : (root.currentTab > 1 ? -12 : 12)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashSchedule { width: contentArea.width; height: contentArea.height }
                }

                // Tab 2: Notepad
                Loader {
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 2
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 2 ? 0 : (root.currentTab > 2 ? -12 : 12)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashNotepad { width: contentArea.width; height: contentArea.height }
                }

                // Tab 3: Translator
                Loader {
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 3
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 3 ? 0 : (root.currentTab > 3 ? -12 : 12)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashTranslation { width: contentArea.width; height: contentArea.height }
                }

                // Tab 4: GitHub  (fetches data when selected because Loader recreates it)
                Loader {
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 4
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 4 ? 0 : (root.currentTab > 4 ? -12 : 12)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashGitHub { width: contentArea.width; height: contentArea.height }
                }
            } // End contentArea
                } // End mainLayout
            } // End panelBg
        } // End clipRect

        // ── Concave shoulder corners (flush with statusbar) ──
        RoundCorner {
            id: rightShoulder
            anchors.right: clipRect.left
            y: panelBg.y
            implicitSize: root.shoulderRadius
            corner: RoundCorner.CornerEnum.TopRight
            color: Appearance.colors.colStatusBarSolid
            opacity: 0
            visible: root.showShoulders
        }
        RoundCorner {
            id: leftShoulder
            anchors.left: clipRect.right
            y: panelBg.y
            implicitSize: root.shoulderRadius
            corner: RoundCorner.CornerEnum.TopLeft
            color: Appearance.colors.colStatusBarSolid
            opacity: 0
            visible: root.showShoulders
        }
    }

}
