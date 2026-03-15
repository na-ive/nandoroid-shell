import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

/**
 * Scrolling Tape Overview
 * Integrated Search Bar (Launcher/Spotlight style)
 */
Rectangle {
    id: scrollingOverviewRoot

    // --- Layout Properties ---
    readonly property real scale: Config.options.overview.scale
    readonly property int totalWorkspaces: Config.options.overview.rows * Config.options.overview.columns
    readonly property int visibleWorkspaces: 3
    readonly property real workspaceSpacing: Config.options.overview.workspaceSpacing
    readonly property real workspacePadding: 4
    readonly property color activeBorderColor: Appearance.colors.colPrimary

    property var currentScreen: null
    readonly property var monitor: currentScreen ? Hyprland.monitorFor(currentScreen) : Hyprland.focusedMonitor
    readonly property int monitorId: monitor?.id ?? -1
    readonly property var monitors: HyprlandData.monitors
    readonly property var monitorData: monitors.find(m => m.id === monitorId) ?? null

    readonly property string barPosition: "top"
    readonly property int barReserved: 40

    // --- Search Logic ---
    property string searchQuery: ""
    property var matchingWindows: []
    property int selectedMatchIndex: 0

    function resetSearch() {
        searchQuery = ""; searchInput.text = ""; matchingWindows = []; selectedMatchIndex = 0;
    }

    onSearchQueryChanged: updateMatchingWindows()
    
    Connections {
        target: HyprlandData
        function onWindowListChanged() { scrollingOverviewRoot.updateMatchingWindows(); }
    }

    function fuzzyMatch(query, target) {
        if (query.length === 0) return true;
        let queryIndex = 0;
        for (let i = 0; i < target.length && queryIndex < query.length; i++) { if (target[i] === query[queryIndex]) queryIndex++; }
        return queryIndex === query.length;
    }

    function fuzzyScore(query, target) {
        if (query.length === 0) return 0;
        if (target.includes(query)) return 1000 + (100 - target.length);
        let queryIndex = 0, consecutiveMatches = 0, maxConsecutive = 0, score = 0;
        for (let i = 0; i < target.length && queryIndex < query.length; i++) {
            if (target[i] === query[queryIndex]) { queryIndex++; consecutiveMatches++; maxConsecutive = Math.max(maxConsecutive, consecutiveMatches); if (i === 0 || target[i-1] === ' ' || target[i-1] === '-' || target[i-1] === '_') score += 10; }
            else { consecutiveMatches = 0; }
        }
        return queryIndex === query.length ? score + maxConsecutive * 5 : -1;
    }

    function updateMatchingWindows() {
        if (searchQuery.length === 0) { matchingWindows = []; selectedMatchIndex = 0; return; }
        const query = searchQuery.toLowerCase();
        matchingWindows = HyprlandData.windowList.filter(win => {
            if (!win) return false;
            return fuzzyMatch(query, (win.title || "").toLowerCase()) || fuzzyMatch(query, (win.class || "").toLowerCase());
        }).map(win => ({
            window: win,
            score: Math.max(fuzzyScore(query, (win.title || "").toLowerCase()), fuzzyScore(query, (win.class || "").toLowerCase()))
        })).sort((a, b) => b.score - a.score).map(item => item.window);
        selectedMatchIndex = matchingWindows.length > 0 ? 0 : -1;
    }

    function navigateToSelectedWindow() {
        if (matchingWindows.length === 0 || selectedMatchIndex < 0) return;
        const win = matchingWindows[selectedMatchIndex]; if (!win) return;
        GlobalStates.closeAllPanels(); Qt.callLater(() => { Hyprland.dispatch(`focuswindow address:${win.address}`); });
    }

    function selectNextMatch() { if (matchingWindows.length > 0) selectedMatchIndex = (selectedMatchIndex + 1) % matchingWindows.length; }
    function selectPrevMatch() { if (matchingWindows.length > 0) selectedMatchIndex = (selectedMatchIndex - 1 + matchingWindows.length) % matchingWindows.length; }
    function isWindowMatched(addr) { return searchQuery.length > 0 && matchingWindows.some(win => win?.address === addr); }
    function isWindowSelected(addr) { return matchingWindows.length > 0 && selectedMatchIndex >= 0 && matchingWindows[selectedMatchIndex]?.address === addr; }

    // --- Dimensions ---
    readonly property real workspaceWidth: {
        if (!monitorData) return 800;
        const width = (monitorData.transform % 2 === 1) ? (monitor?.height || 1920) : (monitor?.width || 1920);
        return Math.max(0, Math.round((width / (monitorData.scale || 1.0)) * scale * 3));
    }

    readonly property real workspaceHeight: {
        if (!monitorData) return 150;
        const height = (monitorData.transform % 2 === 1) ? (monitor?.width || 1080) : (monitor?.height || 1080);
        return Math.max(0, Math.round((height / (monitorData.scale || 1.0)) * scale + workspacePadding * 2));
    }

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    width: implicitWidth
    height: implicitHeight
    implicitWidth: mainLayout.implicitWidth + 48
    implicitHeight: mainLayout.implicitHeight + 48
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.panel
    border.width: 1
    border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

    function getWorkspaceAtY(globalY) {
        if (!workspaceFlickable) return -1;
        const localPos = workspaceFlickable.mapFromItem(null, 0, globalY);
        const contentY = localPos.y + workspaceFlickable.contentY;
        const itemHeight = workspaceHeight + workspaceSpacing;
        const index = Math.floor(contentY / itemHeight);
        if (index >= 0 && index < totalWorkspaces) return index + 1;
        return -1;
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // ── Search Bar Section ──
        Rectangle {
            // Match the width of the workspaces list + scrollbar area
            Layout.preferredWidth: mainContentRow.implicitWidth
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignHCenter
            radius: 12
            color: Appearance.m3colors.m3surfaceContainerHigh
            border.width: 1
            border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12
                MaterialSymbol { Layout.alignment: Qt.AlignVCenter; text: "search"; iconSize: 20; color: Appearance.m3colors.m3onSurfaceVariant }
                TextInput {
                    id: searchInput; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; font.pixelSize: 16; color: Appearance.m3colors.m3onSurface; focus: GlobalStates.overviewOpen
                    Text { text: "Search windows..."; visible: !searchInput.text; color: Appearance.m3colors.m3onSurfaceVariant; opacity: 0.6; font: searchInput.font }
                    onTextChanged: scrollingOverviewRoot.searchQuery = text
                    onAccepted: scrollingOverviewRoot.navigateToSelectedWindow()
                    Text {
                        visible: scrollingOverviewRoot.searchQuery.length > 0; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        text: { const m = scrollingOverviewRoot.matchingWindows.length; return m > 0 ? `${scrollingOverviewRoot.selectedMatchIndex + 1}/${m}` : "0"; }
                        font: searchInput.font; color: scrollingOverviewRoot.matchingWindows.length > 0 ? Appearance.colors.colPrimary : Appearance.m3colors.m3error; opacity: 0.8
                    }
                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                            if (searchInput.text === "") Hyprland.dispatch("workspace r+1"); else scrollingOverviewRoot.selectNextMatch();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                            if (searchInput.text === "") Hyprland.dispatch("workspace r-1"); else scrollingOverviewRoot.selectPrevMatch();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            if (searchInput.text !== "") searchInput.text = ""; else GlobalStates.closeAllPanels();
                            event.accepted = true;
                        }
                    }
                    Connections { target: GlobalStates; function onOverviewOpenChanged() { if (GlobalStates.overviewOpen) { searchInput.text = ""; searchInput.forceActiveFocus(); } } }
                }
            }
        }

        // ── Scrolling Workspaces Section with Side-by-Side Scrollbar ──
        RowLayout {
            id: mainContentRow
            Layout.alignment: Qt.AlignHCenter
            spacing: 12

            Item {
                id: flickableContainer
                width: scrollingOverviewRoot.workspaceWidth
                height: scrollingOverviewRoot.workspaceHeight * 3 + workspaceSpacing * 2

                Flickable {
                    id: workspaceFlickable; anchors.fill: parent; contentWidth: width; contentHeight: workspaceColumn.implicitHeight; clip: true; boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
                    Behavior on contentY { enabled: !scrollingOverviewRoot.isManualScrolling; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    function scrollToActiveWorkspace() {
                        const targetY = (scrollingOverviewRoot.activeWorkspaceId - 1) * (workspaceHeight + workspaceSpacing);
                        const centeredY = targetY - (height - workspaceHeight) / 2;
                        contentY = Math.max(0, Math.min(centeredY, contentHeight - height));
                    }
                    Item {
                        width: parent.width; height: workspaceColumn.implicitHeight
                        Column {
                            id: workspaceColumn; anchors.left: parent.left; anchors.right: parent.right; spacing: workspaceSpacing
                            Repeater {
                                model: totalWorkspaces
                                delegate: ScrollingWorkspace {
                                    required property int index
                                    workspaceId: index + 1; workspaceWidth: scrollingOverviewRoot.workspaceWidth; workspaceHeight: scrollingOverviewRoot.workspaceHeight; workspacePadding: scrollingOverviewRoot.workspacePadding
                                    scale_: scrollingOverviewRoot.scale; monitorId: scrollingOverviewRoot.monitorId; monitorData: scrollingOverviewRoot.monitorData
                                    barPosition: scrollingOverviewRoot.barPosition; barReserved: scrollingOverviewRoot.barReserved; windowList: HyprlandData.windowList
                                    isActive: (scrollingOverviewRoot.monitor?.activeWorkspace?.id || 0) === workspaceId
                                    activeBorderColor: scrollingOverviewRoot.activeBorderColor; focusedWindowAddress: Hyprland.focusedClient?.address ?? ""
                                    searchQuery: scrollingOverviewRoot.searchQuery; checkWindowMatched: scrollingOverviewRoot.isWindowMatched; checkWindowSelected: scrollingOverviewRoot.isWindowSelected
                                    draggingFromWorkspace: scrollingOverviewRoot.draggingFromWorkspace; draggingTargetWorkspace: scrollingOverviewRoot.draggingTargetWorkspace
                                    dragOverlay: dragOverlayItem; overviewRoot: scrollingOverviewRoot; width: scrollingOverviewRoot.workspaceWidth; height: scrollingOverviewRoot.workspaceHeight
                                }
                            }
                        }
                        Rectangle {
                            readonly property int activeId: scrollingOverviewRoot.monitor?.activeWorkspace?.id || 1
                            x: 0; y: (activeId - 1) * (workspaceHeight + workspaceSpacing); width: workspaceWidth; height: workspaceHeight; color: "transparent"; radius: Appearance.rounding.verysmall; border.width: 2; border.color: scrollingOverviewRoot.activeBorderColor; z: 10
                            Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                        }
                    }
                }
            }

            // Thick Vertical Scrollbar beside the workspaces
            ScrollBar {
                id: internalScrollBar
                Layout.preferredWidth: 8
                Layout.fillHeight: true
                policy: ScrollBar.AlwaysOn
                active: true
                position: workspaceFlickable.visibleArea.yPosition
                size: workspaceFlickable.visibleArea.heightRatio
                
                contentItem: Rectangle {
                    implicitWidth: 8
                    radius: 4
                    color: Appearance.colors.colPrimary
                    opacity: 0.6
                }
                
                background: Rectangle {
                    implicitWidth: 8
                    radius: 4
                    color: Appearance.colors.colLayer0
                    opacity: 0.3
                }
            }
        }
    }

    Item { id: dragOverlayItem; anchors.fill: parent; z: 1000 }
    property alias flickable: workspaceFlickable
    readonly property bool needsScrollbar: workspaceFlickable.contentHeight > workspaceFlickable.height
    property bool isManualScrolling: false
    readonly property int activeWorkspaceId: monitor?.activeWorkspace?.id || 1
    onActiveWorkspaceIdChanged: workspaceFlickable.scrollToActiveWorkspace()
    Component.onCompleted: workspaceFlickable.scrollToActiveWorkspace()
}
