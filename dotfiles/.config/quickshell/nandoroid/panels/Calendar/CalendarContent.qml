import "../../core"
import "../../widgets"
import "../../services"
import QtQuick
import QtQuick.Layouts

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

    property bool active: GlobalStates.calendarOpen
    property int currentTab: 0
    readonly property int tabCount: 4
    readonly property int tabButtonSize: 44
    readonly property int tabStripWidth: tabButtonSize + 16 // button + side padding

    // The panel itself is centred inside the full-screen-width window
    readonly property int panelWidth: Appearance.sizes.dashboardWidth
    readonly property int panelHeight: Appearance.sizes.dashboardHeight
    // Corner radius used for the shoulder pieces — match statusbar corner radius
    readonly property int shoulderRadius: Config.ready && Config.options.statusBar
        ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20

    // Window is fixed size — no resizing = no jitter
    implicitWidth: panelWidth
    implicitHeight: panelHeight

    // ── Animation state (Caelestia pattern: implicitHeight from 0) ──
    property real animHeight: active ? panelHeight : 0

    Behavior on animHeight {
        NumberAnimation {
            duration: active ? (Appearance.anim.durations.expressiveDefaultSpatial || 400) : (Appearance.anim.durations.emphasized || 250)
            easing.bezierCurve: active ? (Appearance.anim.curves.expressiveDefaultSpatial || [0.2, 0.0, 0.0, 1.0]) : (Appearance.anim.curves.emphasized || [0.2, 0.0, 0.0, 1.0])
        }
    }

    function close() {
        root.closed()
    }

    Connections {
        target: GlobalStates
        function onCalendarOpenChanged() {
            if (GlobalStates.calendarOpen) {
                // Reset tab to default (tab 1 = calendar) when opened
                currentTab = 0
                tabHighlight.reset()
                root.forceActiveFocus()
            }
        }
    }
    Component.onCompleted: {
        if (GlobalStates.calendarOpen) root.forceActiveFocus()
    }

    // ── Main Panel Rectangle ──
    // Fixed full-panel size bounds, but actual visibility is height-clipped.
    Rectangle {
        id: clipRect
        x: Math.round((parent.width - root.panelWidth) / 2)
        y: 0
        width: root.panelWidth
        height: root.animHeight
        clip: true
        color: "transparent"

        Rectangle {
            id: panelBg
            width: root.panelWidth
            height: root.panelHeight
            anchors.bottom: clipRect.bottom
            color: Appearance.m3colors.m3surfaceContainerLow
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Appearance.rounding.large
            bottomRightRadius: Appearance.rounding.large
            border.width: 0

            Row {
                id: mainLayout
                anchors.fill: parent
                // Inner padding
                leftPadding: 8
                rightPadding: 8
                topPadding: 8
                bottomPadding: 8
                spacing: 0

                // ── Vertical Tab Strip ──
        Item {
            id: tabStrip
            width: root.tabStripWidth
            height: parent.height

            // Y-offset where the button group starts (vertically centered)
            readonly property real buttonsTop: Math.round(
                (height - root.tabCount * (root.tabButtonSize + 6) + 6) / 2
            )

            // Animated stretch-highlight pill (Ambxst style)
            Rectangle {
                id: tabHighlight
                // Centered within the strip, same as the Column's horizontalCenter
                x: Math.round((tabStrip.width - root.tabButtonSize) / 2)
                width: root.tabButtonSize
                radius: Appearance.rounding.small

                // Elastic stretch: idx1 snaps fast, idx2 follows slowly
                property int idx1: root.currentTab
                property int idx2: root.currentTab
                
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
                                tabHighlight.idx1 = index
                                Qt.callLater(() => { tabHighlight.idx2 = index })
                                root.currentTab = index
                            }
                        }
                    }
                }
            }

            // Thin separator line (right side)
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 12
                anchors.bottomMargin: 12
                width: 1
                color: Appearance.colors.colOutlineVariant
                opacity: 0.5
            }
        } // End tabStrip

        // ── Content Area ──
        Item {
            id: contentArea
            // panelWidth minus (leftPadding+rightPadding=16) minus tabStripWidth
            width: root.panelWidth - 16 - root.tabStripWidth
            height: root.panelHeight - 16

            // Tab 0: Calendar + Pomodoro
            Loader {
                anchors.fill: parent
                anchors.margins: 12
                active: true
                visible: root.currentTab === 0
                opacity: visible ? 1 : 0
                transform: Translate { y: root.currentTab === 0 ? 0 : (root.currentTab > 0 ? -12 : 12)
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                sourceComponent: DashCalendar { width: contentArea.width - 24; height: contentArea.height - 24 }
            }

            // Tab 1: Schedule
            Loader {
                anchors.fill: parent
                anchors.margins: 12
                active: root.currentTab === 1
                visible: root.currentTab === 1
                opacity: visible ? 1 : 0
                transform: Translate { y: root.currentTab === 1 ? 0 : (root.currentTab > 1 ? -12 : 12)
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                sourceComponent: DashSchedule { width: contentArea.width - 24; height: contentArea.height - 24 }
            }

            // Tab 2: Notepad
            Loader {
                anchors.fill: parent
                anchors.margins: 12
                active: root.currentTab === 2
                visible: root.currentTab === 2
                opacity: visible ? 1 : 0
                transform: Translate { y: root.currentTab === 2 ? 0 : (root.currentTab > 2 ? -12 : 12)
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                sourceComponent: DashNotepad { width: contentArea.width - 24; height: contentArea.height - 24 }
            }

            // Tab 3: GitHub  (fetches data when selected because Loader recreates it)
            Loader {
                anchors.fill: parent
                anchors.margins: 12
                active: true
                visible: root.currentTab === 3
                opacity: visible ? 1 : 0
                transform: Translate { y: root.currentTab === 3 ? 0 : (root.currentTab > 3 ? -12 : 12)
                    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                sourceComponent: DashGitHub { width: contentArea.width - 24; height: contentArea.height - 24 }
            }
        } // End contentArea
            } // End mainLayout
        } // End panelBg
    } // End clipRect

    // ── Concave shoulder corners (flush with statusbar) ──
    RoundCorner {
        x: clipRect.x - implicitSize
        y: 0
        implicitSize: root.shoulderRadius
        corner: RoundCorner.CornerEnum.TopRight
        color: root.animHeight > 0 ? Appearance.colors.colStatusBarSolid : "transparent"
        visible: root.animHeight > 0
        opacity: root.animHeight / root.panelHeight
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    RoundCorner {
        x: clipRect.x + root.panelWidth
        y: 0
        implicitSize: root.shoulderRadius
        corner: RoundCorner.CornerEnum.TopLeft
        color: root.animHeight > 0 ? Appearance.colors.colStatusBarSolid : "transparent"
        visible: root.animHeight > 0
        opacity: root.animHeight / root.panelHeight
        Behavior on color { ColorAnimation { duration: 100 } }
    }

}
