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
import "../../widgets"
import "../../services"

/**
 * Standard Grid Overview
 * Integrated Search Bar (Launcher/Spotlight style)
 */
Rectangle {
    id: standardOverviewRoot
    
    // --- Layout Properties ---
    readonly property real scale: Config.options.overview.scale
    readonly property int rows: Config.options.overview.rows
    readonly property int columns: Config.options.overview.columns
    readonly property int workspacesShown: rows * columns
    readonly property real workspaceSpacing: Config.options.overview.workspaceSpacing
    readonly property real workspacePadding: 8
    readonly property color activeBorderColor: Appearance.colors.colPrimary

    property var currentScreen: null
    readonly property var monitor: currentScreen ? Hyprland.monitorFor(currentScreen) : Hyprland.focusedMonitor
    readonly property int workspaceGroup: Math.floor((monitor?.activeWorkspace?.id - 1 || 0) / workspacesShown)

    readonly property var monitors: HyprlandData.monitors
    readonly property int monitorId: monitor?.id ?? -1
    readonly property var monitorData: monitors.find(m => m.id === monitorId) ?? null

    readonly property string barPosition: "top"
    readonly property int barReserved: 40

    // --- Search Logic ---
    property string searchQuery: ""
    property var matchingWindows: []
    property int selectedMatchIndex: 0

    function resetSearch() {
        searchQuery = "";
        searchInput.text = "";
        matchingWindows = [];
        selectedMatchIndex = 0;
    }

    onSearchQueryChanged: updateMatchingWindows()
    
    Connections {
        target: HyprlandData
        function onWindowListChanged() { standardOverviewRoot.updateMatchingWindows(); }
    }

    function fuzzyMatch(query, target) {
        if (query.length === 0) return true;
        let queryIndex = 0;
        for (let i = 0; i < target.length && queryIndex < query.length; i++) {
            if (target[i] === query[queryIndex]) queryIndex++;
        }
        return queryIndex === query.length;
    }

    function fuzzyScore(query, target) {
        if (query.length === 0) return 0;
        if (target.includes(query)) return 1000 + (100 - target.length);
        let queryIndex = 0, consecutiveMatches = 0, maxConsecutive = 0, score = 0;
        for (let i = 0; i < target.length && queryIndex < query.length; i++) {
            if (target[i] === query[queryIndex]) {
                queryIndex++; consecutiveMatches++;
                maxConsecutive = Math.max(maxConsecutive, consecutiveMatches);
                if (i === 0 || target[i - 1] === ' ' || target[i - 1] === '-' || target[i - 1] === '_') score += 10;
            } else { consecutiveMatches = 0; }
        }
        return queryIndex === query.length ? score + maxConsecutive * 5 : -1;
    }

    function updateMatchingWindows() {
        if (searchQuery.length === 0) {
            matchingWindows = []; selectedMatchIndex = 0; return;
        }
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
        const win = matchingWindows[selectedMatchIndex];
        if (!win) return;
        GlobalStates.closeAllPanels();
        Qt.callLater(() => { Hyprland.dispatch(`focuswindow address:${win.address}`); });
    }

    function selectNextMatch() { if (matchingWindows.length > 0) selectedMatchIndex = (selectedMatchIndex + 1) % matchingWindows.length; }
    function selectPrevMatch() { if (matchingWindows.length > 0) selectedMatchIndex = (selectedMatchIndex - 1 + matchingWindows.length) % matchingWindows.length; }
    function isWindowMatched(addr) { return searchQuery.length > 0 && matchingWindows.some(win => win?.address === addr); }
    function isWindowSelected(addr) { return matchingWindows.length > 0 && selectedMatchIndex >= 0 && matchingWindows[selectedMatchIndex]?.address === addr; }

    // --- Workspace Dimensions ---
    readonly property real workspaceImplicitWidth: {
        if (!monitorData) return 200;
        const width = (monitorData.transform % 2 === 1) ? (monitor?.height || 1920) : (monitor?.width || 1920);
        return Math.max(0, Math.round((width / (monitorData.scale || 1.0)) * scale));
    }

    readonly property real workspaceImplicitHeight: {
        if (!monitorData) return 150;
        const height = (monitorData.transform % 2 === 1) ? (monitor?.width || 1080) : (monitor?.height || 1080);
        return Math.max(0, Math.round((height / (monitorData.scale || 1.0)) * scale));
    }

    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    // --- Panel Styling ---
    width: implicitWidth
    height: implicitHeight
    implicitWidth: mainLayout.implicitWidth + 48
    implicitHeight: mainLayout.implicitHeight + 48
    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.panel
    border.width: 1
    border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 24
        spacing: 24

        // ── Search Bar Section ──
        Rectangle {
            id: searchContainer
            Layout.preferredWidth: 480 // Fixed sensible width for standard overview
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignHCenter
            radius: 12
            color: Appearance.m3colors.m3surfaceContainerHigh
            border.width: 1
            border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 16
                spacing: 12

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: "search"; iconSize: 20; color: Appearance.m3colors.m3onSurfaceVariant
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: 16
                    color: Appearance.m3colors.m3onSurface
                    focus: GlobalStates.overviewOpen

                    Text {
                        text: "Search windows..."
                        visible: !searchInput.text
                        color: Appearance.m3colors.m3onSurfaceVariant
                        opacity: 0.6; font: searchInput.font
                    }

                    onTextChanged: standardOverviewRoot.searchQuery = text
                    onAccepted: standardOverviewRoot.navigateToSelectedWindow()

                    // Match counter
                    Text {
                        visible: standardOverviewRoot.searchQuery.length > 0
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            const matches = standardOverviewRoot.matchingWindows.length;
                            return matches > 0 ? `${standardOverviewRoot.selectedMatchIndex + 1}/${matches}` : "0";
                        }
                        font: searchInput.font
                        color: standardOverviewRoot.matchingWindows.length > 0 ? Appearance.colors.colPrimary : Appearance.m3colors.m3error
                        opacity: 0.8
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                            if (searchInput.text === "") Hyprland.dispatch("workspace r+1");
                            else standardOverviewRoot.selectNextMatch();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                            if (searchInput.text === "") Hyprland.dispatch("workspace r-1");
                            else standardOverviewRoot.selectPrevMatch();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape) {
                            if (searchInput.text !== "") searchInput.text = "";
                            else GlobalStates.closeAllPanels();
                            event.accepted = true;
                        }
                    }

                    Connections {
                        target: GlobalStates
                        function onOverviewOpenChanged() {
                            if (GlobalStates.overviewOpen) { searchInput.text = ""; searchInput.forceActiveFocus(); }
                        }
                    }
                }
            }
        }

        // ── Workspaces Section ──
        Item {
            id: overviewContent
            Layout.preferredWidth: workspaceColumnLayout.implicitWidth
            Layout.preferredHeight: workspaceColumnLayout.implicitHeight
            Layout.alignment: Qt.AlignHCenter

            ColumnLayout {
                id: workspaceColumnLayout
                anchors.centerIn: parent
                spacing: workspaceSpacing

                Repeater {
                    model: standardOverviewRoot.rows
                    delegate: RowLayout {
                        id: row
                        property int rowIndex: index
                        spacing: workspaceSpacing
                        Repeater {
                            model: standardOverviewRoot.columns
                            Rectangle {
                                id: workspace
                                property int colIndex: index
                                property int workspaceValue: standardOverviewRoot.workspaceGroup * workspacesShown + rowIndex * standardOverviewRoot.columns + colIndex + 1
                                property bool isActiveWorkspace: Hyprland.focusedWorkspace?.id === workspaceValue
                                
                                implicitWidth: standardOverviewRoot.workspaceImplicitWidth + workspacePadding
                                implicitHeight: standardOverviewRoot.workspaceImplicitHeight + workspacePadding
                                color: isActiveWorkspace ? Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimaryContainer, 0.4) : Appearance.colors.colLayer0
                                radius: Appearance.rounding.verysmall
                                border.width: isActiveWorkspace || hoveredWhileDragging ? 2 : 1
                                border.color: hoveredWhileDragging ? Appearance.m3colors.m3outline : (isActiveWorkspace ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant)
                                property bool hoveredWhileDragging: false

                                Image {
                                    id: workspaceWallpaper; anchors.fill: parent; fillMode: Image.PreserveAspectCrop
                                    source: Config.options?.appearance?.background?.wallpaperPath || ""
                                }

                                MouseArea {
                                    anchors.fill: parent; acceptedButtons: Qt.LeftButton
                                    onClicked: if (standardOverviewRoot.draggingTargetWorkspace === -1) Hyprland.dispatch(`workspace ${workspaceValue}`);
                                    onDoubleClicked: if (standardOverviewRoot.draggingTargetWorkspace === -1) { Hyprland.dispatch(`workspace ${workspaceValue}`); }
                                }

                                DropArea {
                                    anchors.fill: parent
                                    onEntered: { standardOverviewRoot.draggingTargetWorkspace = workspaceValue; if (standardOverviewRoot.draggingFromWorkspace != standardOverviewRoot.draggingTargetWorkspace) hoveredWhileDragging = true; }
                                    onExited: { hoveredWhileDragging = false; if (standardOverviewRoot.draggingTargetWorkspace == workspaceValue) standardOverviewRoot.draggingTargetWorkspace = -1; }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: windowSpace
                anchors.centerIn: parent
                implicitWidth: workspaceColumnLayout.implicitWidth
                implicitHeight: workspaceColumnLayout.implicitHeight

                readonly property var filteredWindowData: {
                    const minWs = standardOverviewRoot.workspaceGroup * standardOverviewRoot.workspacesShown;
                    const maxWs = (standardOverviewRoot.workspaceGroup + 1) * standardOverviewRoot.workspacesShown;
                    const monId = standardOverviewRoot.monitorId;
                    const toplevels = ToplevelManager.toplevels.values;
                    
                    return HyprlandData.windowList.filter(win => {
                        const wsId = win?.workspace?.id;
                        // Use loose equality for monitor ID as it might be string vs int
                        return wsId > minWs && wsId <= maxWs && win.monitor == monId;
                    }).map(win => {
                        const addr = win.address.toLowerCase();
                        // Find matching toplevel by address (case-insensitive and handling 0x)
                        const tl = toplevels.find(t => {
                            const tAddr = "0x" + t.HyprlandToplevel.address.toLowerCase();
                            return tAddr === addr;
                        });
                        return {
                            windowData: win,
                            toplevel: tl || null
                        };
                    });
                }

                Repeater {
                    model: windowSpace.filteredWindowData
                    delegate: OverviewWindow {
                        id: window
                        required property var modelData
                        windowData: modelData.windowData; toplevel: modelData.toplevel
                        overviewRoot: standardOverviewRoot
                        scale: standardOverviewRoot.scale; availableWorkspaceWidth: standardOverviewRoot.workspaceImplicitWidth
                        availableWorkspaceHeight: standardOverviewRoot.workspaceImplicitHeight; monitorData: standardOverviewRoot.monitorData
                        barPosition: standardOverviewRoot.barPosition; barReserved: standardOverviewRoot.barReserved
                        isSearchMatch: standardOverviewRoot.isWindowMatched(windowData?.address)
                        isSearchSelected: standardOverviewRoot.isWindowSelected(windowData?.address)
                        property int workspaceColIndex: (windowData?.workspace.id - 1) % standardOverviewRoot.columns
                        property int workspaceRowIndex: Math.floor((windowData?.workspace.id - 1) % standardOverviewRoot.workspacesShown / standardOverviewRoot.columns)
                        xOffset: Math.round((standardOverviewRoot.workspaceImplicitWidth + workspacePadding + workspaceSpacing) * workspaceColIndex + workspacePadding / 2)
                        yOffset: Math.round((standardOverviewRoot.workspaceImplicitHeight + workspacePadding + workspaceSpacing) * workspaceRowIndex + workspacePadding / 2)
                        onDragStarted: standardOverviewRoot.draggingFromWorkspace = windowData?.workspace.id || -1
                        onDragFinished: targetWorkspace => { standardOverviewRoot.draggingFromWorkspace = -1; if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${windowData?.address}`); }
                        onWindowClicked: { GlobalStates.closeAllPanels(); Qt.callLater(() => { Hyprland.dispatch(`focuswindow address:${windowData.address}`); }); }
                        onWindowClosed: { Hyprland.dispatch(`closewindow address:${windowData.address}`); }
                    }
                }

                Rectangle {
                    id: focusedWorkspaceIndicator
                    property int activeWorkspaceInGroup: (monitor?.activeWorkspace?.id || 1) - (standardOverviewRoot.workspaceGroup * standardOverviewRoot.workspacesShown)
                    property int activeWorkspaceRowIndex: Math.floor((activeWorkspaceInGroup - 1) / standardOverviewRoot.columns)
                    property int activeWorkspaceColIndex: (activeWorkspaceInGroup - 1) % standardOverviewRoot.columns
                    x: Math.round((standardOverviewRoot.workspaceImplicitWidth + workspacePadding + workspaceSpacing) * activeWorkspaceColIndex)
                    y: Math.round((standardOverviewRoot.workspaceImplicitHeight + workspacePadding + workspaceSpacing) * activeWorkspaceRowIndex)
                    width: Math.round(standardOverviewRoot.workspaceImplicitWidth + workspacePadding)
                    height: Math.round(standardOverviewRoot.workspaceImplicitHeight + workspacePadding)
                    color: "transparent"; radius: Appearance.rounding.verysmall; border.width: 2; border.color: standardOverviewRoot.activeBorderColor; z: -1
                    Behavior on x { enabled: 250 > 0; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                    Behavior on y { enabled: 250 > 0; NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                }
            }
        }
    }
}
