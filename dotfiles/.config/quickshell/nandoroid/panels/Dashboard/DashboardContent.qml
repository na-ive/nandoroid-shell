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
 *   3: Todo / Kanban
 *   4: Translator
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
        GlobalStates.closeSubPopups()
    }
    readonly property int tabCount: 5
    readonly property int tabStripWidth: 78 * Appearance.effectiveScale // rail box + narrow side padding

    // Per-tab M3 accent pairs (mirrors end4-pC group colors)
    readonly property var dashTabs: {
        const c = Appearance.colors;
        const mix = (a, b) => Functions.ColorUtils.mix(a, b, 0.5);
        return [
            { name: I18nService.tr("Calendar"), icon: "calendar_today", container: mix(c.colPrimaryContainer, c.colTertiaryContainer), onContainer: mix(c.colOnPrimaryContainer, c.colOnTertiaryContainer), accent: mix(c.colPrimary, c.colTertiary), onAccent: mix(c.colOnPrimary, c.colOnTertiary), count: 0 },
            { name: I18nService.tr("Schedule"), icon: "event_note", container: c.colSecondaryContainer, onContainer: c.colOnSecondaryContainer, accent: c.colSecondary, onAccent: c.colOnSecondary, count: 0 },
            { name: I18nService.tr("Notepad"), icon: "edit_note", container: c.colTertiaryContainer, onContainer: c.colOnTertiaryContainer, accent: c.colTertiary, onAccent: c.colOnTertiary, count: 0 },
            { name: I18nService.tr("Kanban"), icon: "view_kanban", container: mix(c.colPrimaryContainer, c.colSecondaryContainer), onContainer: mix(c.colOnPrimaryContainer, c.colOnSecondaryContainer), accent: mix(c.colPrimary, c.colSecondary), onAccent: mix(c.colOnPrimary, c.colOnSecondary), count: 0 },
            { name: I18nService.tr("Translate"), icon: "translate", container: mix(c.colSecondaryContainer, c.colTertiaryContainer), onContainer: mix(c.colOnSecondaryContainer, c.colOnTertiaryContainer), accent: mix(c.colSecondary, c.colTertiary), onAccent: mix(c.colOnSecondary, c.colOnTertiary), count: 0 }
        ];
    }

    // The panel itself is centred inside the full-screen-width window
    readonly property int panelWidth: Appearance.sizes.dashboardWidth
    readonly property int panelHeight: Appearance.sizes.dashboardHeight
    // Corner radius used for the shoulder pieces — match statusbar corner radius
    readonly property int shoulderRadius: (Config.ready && Config.options.statusBar
        ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20) * Appearance.effectiveScale

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
                    from: -20 * Appearance.effectiveScale
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
                    to: -root.panelHeight - 40 * Appearance.effectiveScale // Move the whole container far up
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
        if (!Config.ready || !Config.options.statusBar) return false;
        let style = Config.options.statusBar.moduleStyle ?? "";
        if (style === "m3") return false;
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
            verticalOffset: 2 * Appearance.effectiveScale
            radius: 24 * Appearance.effectiveScale
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
                topLeftRadius: root.showShoulders ? 0 : Appearance.rounding.panel
                topRightRadius: root.showShoulders ? 0 : Appearance.rounding.panel
                bottomLeftRadius: Appearance.rounding.panel
                bottomRightRadius: Appearance.rounding.panel


                // Close internal tooltips/popups when clicking anywhere inside the panel or its padding
                TapHandler {
                    onTapped: GlobalStates.closeSubPopups()
                }

                Row {
                    id: mainLayout
                    anchors.fill: parent
                    // Inner padding (12px grid, same as content card gaps)
                    leftPadding: 12 * Appearance.effectiveScale
                    rightPadding: 12 * Appearance.effectiveScale
                    topPadding: 12 * Appearance.effectiveScale
                    bottomPadding: 12 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    // ── Vertical Navigation Rail (end4-pC group rail style) ──
            Item {
                id: tabStrip
                width: root.tabStripWidth
                // Row padding already offsets y by 12: subtract top+bottom padding
                // so the strip exactly matches the content area (no double inset)
                height: parent.height - 24 * Appearance.effectiveScale

                // Scroll to change tab - restricted to tabStrip area
                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.closeSubPopups()
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y > 0) {
                            root.currentTab = (root.currentTab - 1 + root.tabCount) % root.tabCount
                        } else if (wheel.angleDelta.y < 0) {
                            root.currentTab = (root.currentTab + 1) % root.tabCount
                        }
                    }
                }

                DashGroupRail {
                    anchors.fill: parent
                    groups: root.dashTabs
                    current: root.currentTab
                    onPicked: (index) => {
                        GlobalStates.closeSubPopups()
                        root.currentTab = index
                    }
                }

            } // End tabStrip

            // ── Content Area ──
            Item {
                id: contentArea
                // panelWidth minus (leftPadding+rightPadding=24) minus tabStripWidth minus spacing(12)
                width: root.panelWidth - 36 * Appearance.effectiveScale - root.tabStripWidth
                height: root.panelHeight - 24 * Appearance.effectiveScale

                // Tab 0: Calendar + Pomodoro
                Loader {
                    id: tabCalendarLoader
                    anchors.fill: parent
                    active: root.currentTab === 0
                    visible: root.currentTab === 0
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 0 ? 0 : (root.currentTab > 0 ? -12 * Appearance.effectiveScale : 12 * Appearance.effectiveScale)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    
                    onVisibleChanged: {
                        if (visible && item && typeof item.reloadSchedule === "function") {
                            item.reloadSchedule()
                        }
                    }
                    
                    sourceComponent: DashCalendar { width: contentArea.width; height: contentArea.height }

                    Connections {
                        target: tabCalendarLoader.item
                        function onJumpToSchedule() {
                            root.currentTab = 1
                        }
                    }
                }

                // Tab 1: Schedule
                Loader {
                    id: scheduleLoader
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 1
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 1 ? 0 : (root.currentTab > 1 ? -12 * Appearance.effectiveScale : 12 * Appearance.effectiveScale)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashSchedule {
                        id: scheduleComponent
                        width: contentArea.width
                        height: contentArea.height
                        notepadItems: notepadLoader.item ? notepadLoader.item.items : []
                        todoItems: todoLoader.item ? todoLoader.item.items : []
                    }
                }

                // Connections to keep notepadItems/todoItems reactive across loader boundaries
                Connections {
                    target: notepadLoader.item
                    ignoreUnknownSignals: true
                    function onItemsChanged() {
                        if (scheduleLoader.item)
                            scheduleLoader.item.notepadItems = notepadLoader.item.items
                    }
                }
                Connections {
                    target: todoLoader.item
                    ignoreUnknownSignals: true
                    function onItemsChanged() {
                        if (scheduleLoader.item)
                            scheduleLoader.item.todoItems = todoLoader.item.items
                    }
                }

                // Tab 2: Notepad
                Loader {
                    id: notepadLoader
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 2
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 2 ? 0 : (root.currentTab > 2 ? -12 * Appearance.effectiveScale : 12 * Appearance.effectiveScale)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashNotepad { width: contentArea.width; height: contentArea.height }
                }

                // Tab 3: Todo / Kanban
                Loader {
                    id: todoLoader
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 3
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 3 ? 0 : (root.currentTab > 3 ? -12 * Appearance.effectiveScale : 12 * Appearance.effectiveScale)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashTodo { width: contentArea.width; height: contentArea.height }
                }

                // Tab 4: Translator
                Loader {
                    anchors.fill: parent
                    active: true
                    visible: root.currentTab === 4
                    opacity: visible ? 1 : 0
                    transform: Translate { y: root.currentTab === 4 ? 0 : (root.currentTab > 4 ? -12 * Appearance.effectiveScale : 12 * Appearance.effectiveScale)
                        Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }
                    sourceComponent: DashTranslation { width: contentArea.width; height: contentArea.height }
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
