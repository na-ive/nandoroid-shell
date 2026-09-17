import "../../../../core"
import "../../../../core/functions" as Functions
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.SystemTray

ColumnLayout {
    id: rootColumn
    Layout.fillWidth: true
    spacing: 0

    // ── Global Module Pool & Layout Manager (on root for guaranteed scope) ────────────
    property bool leftMenuOpened: false
    property bool rightMenuOpened: false
    property string draggedModuleId: ""
    property string draggedSide: ""
    property string dropSide: ""
    property int dropIndex: -1
    property var lastDragScene: Qt.point(0, 0)
    readonly property bool leftDropActive: draggedModuleId !== "" && dropSide === "left" && dropIndex >= 0
    readonly property bool rightDropActive: draggedModuleId !== "" && dropSide === "right" && dropIndex >= 0
    property alias dragOverlay: dragOverlayItem
    readonly property bool isCenteredMode: Config.ready && Config.options.statusBar && (Config.options.statusBar.layoutStyle === "centered") && ((Config.options.statusBar.moduleStyle ?? "base") !== "m3")
    readonly property int maxClusterPoints: isCenteredMode ? 4 : 5
    readonly property int poolMaxModules: 5

    function getModuleWeight(modId) {
        if (!isCenteredMode) return 1;
        if (modId === "systemMonitor" || modId === "activeWindow" || modId === "clock") return 2;
        return 1;
    }

    function getClusterPoints(modulesList) {
        if (!modulesList) return 0;
        return modulesList.reduce(function(sum, m) { return sum + getModuleWeight(m); }, 0);
    }

    function getModuleStatus(clusterModules, index) {
        if (!isCenteredMode) return { isConflict: false, isOverflow: false, labelSuffix: "", tooltipText: "" };
        let modId = clusterModules[index];
        let hasCollision = clusterModules.includes("activeWindow") && clusterModules.includes("systemMonitor");
        let isConflict = (modId === "activeWindow" && hasCollision);

        let currentPoints = 0;
        let isOverflow = false;

        for (let i = 0; i <= index; i++) {
            let m = clusterModules[i];
            if (m === "activeWindow" && hasCollision) continue;
            let w = getModuleWeight(m);
            if (i === index) {
                if (currentPoints + w > maxClusterPoints) {
                    isOverflow = true;
                }
            } else {
                currentPoints += w;
            }
        }

        let label = "";
        let tooltip = "";
        if (isConflict) {
            label = " (Hidden)";
            tooltip = "Active Window is automatically hidden in Centered mode when System Monitor is on the same side.";
        } else if (isOverflow) {
            label = " (Exceeds Limit)";
            tooltip = "This module will not display because it exceeds the capacity limit for Centered mode.";
        }

        return { isConflict: isConflict, isOverflow: isOverflow, labelSuffix: label, tooltipText: tooltip };
    }

    readonly property bool isPcIslandActive: Config.ready && Config.options.statusBar && Config.options.statusBar.centerModule === "pcIsland"

    property var allModules: [
        { id: "distroIcon", name: I18nService.tr("Distro Icon"), icon: "computer" },
        { id: "activeWindow", name: I18nService.tr("Active Window"), icon: "subtitles" },
        { id: "systemMonitor", name: I18nService.tr("System Monitor"), icon: "memory" },
        { id: "clock", name: I18nService.tr("Clock"), icon: "schedule" },
        { id: "networkSpeed", name: I18nService.tr("Network Speed"), icon: "network_check" },
        { id: "sysTray", name: I18nService.tr("System Tray"), icon: "inbox" },
        { id: "statusIconsGroup", name: I18nService.tr("Status Icons (WiFi/Volume)"), icon: "info" },
        { id: "battery", name: I18nService.tr("Battery"), icon: "battery_full" },
        { id: "workspaceIndicator", name: I18nService.tr("Workspace Indicator"), icon: "view_module" }
    ]

    function getLeftModules() {
        return (Config.ready && Config.options.statusBar && Config.options.statusBar.leftModules) ? Array.from(Config.options.statusBar.leftModules) : ["distroIcon", "activeWindow", "systemMonitor"];
    }

    function getRightModules() {
        return (Config.ready && Config.options.statusBar && Config.options.statusBar.rightModules) ? Array.from(Config.options.statusBar.rightModules) : ["networkSpeed", "sysTray", "statusIconsGroup", "battery"];
    }

    function getCenterModule() {
        return (Config.ready && Config.options.statusBar) ? (Config.options.statusBar.centerModule ?? "clock") : "clock";
    }

    function isUsed(modId) {
        let lefts = getLeftModules();
        let rights = getRightModules();
        let center = getCenterModule();
        return lefts.includes(modId) || rights.includes(modId) || (center === modId);
    }

    function getModuleName(modId) {
        let item = allModules.find(m => m.id === modId);
        return item ? item.name : modId;
    }

    function getAvailableForCluster() {
        return allModules.filter(m => !isUsed(m.id) && (m.id !== "workspaceIndicator" || isPcIslandActive));
    }

    function addToLeftCluster(moduleId) {
        var list = getLeftModules();
        if (list.length >= poolMaxModules) return;
        list.push(moduleId);
        if (moduleId === "clock") Config.options.statusBar.centerModule = "none";
        Config.options.statusBar.leftModules = list;
        if (list.length >= poolMaxModules || getAvailableForCluster().length <= 0) leftMenuOpened = false;
    }

    function addToRightCluster(moduleId) {
        var list = getRightModules();
        if (list.length >= poolMaxModules) return;
        list.push(moduleId);
        if (moduleId === "clock") Config.options.statusBar.centerModule = "none";
        Config.options.statusBar.rightModules = list;
        if (list.length >= poolMaxModules || getAvailableForCluster().length <= 0) rightMenuOpened = false;
    }

    function moveLeftModule(moduleId, direction) {
        var list = getLeftModules();
        var idx = list.indexOf(moduleId);
        var target = idx + direction;
        if (target < 0 || target >= list.length) return;
        var temp = list[idx];
        list[idx] = list[target];
        list[target] = temp;
        Config.options.statusBar.leftModules = list;
    }

    function removeLeftModule(moduleId) {
        Config.options.statusBar.leftModules = getLeftModules().filter(function(m) { return m !== moduleId; });
    }

    function moveRightModule(idx, direction) {
        var list = getRightModules();
        var target = idx + direction;
        if (target < 0 || target >= list.length) return;
        var temp = list[idx];
        list[idx] = list[target];
        list[target] = temp;
        Config.options.statusBar.rightModules = list;
    }

    function removeRightModule(moduleId) {
        Config.options.statusBar.rightModules = getRightModules().filter(function(m) { return m !== moduleId; });
    }

    function toggleLeftMenu() { leftMenuOpened = !leftMenuOpened; }
    function toggleRightMenu() { rightMenuOpened = !rightMenuOpened; }

    function getClusterModules(side) {
        return side === "left" ? getLeftModules() : getRightModules();
    }

    function moveModule(moduleId, side, direction) {
        var list = getClusterModules(side);
        var idx = list.indexOf(moduleId);
        var target = idx + direction;
        if (target < 0 || target >= list.length) return;
        var temp = list[idx];
        list[idx] = list[target];
        list[target] = temp;
        if (side === "left") Config.options.statusBar.leftModules = list;
        else Config.options.statusBar.rightModules = list;
    }

    function removeModule(moduleId, side) {
        var list = getClusterModules(side).filter(function(m) { return m !== moduleId; });
        if (side === "left") Config.options.statusBar.leftModules = list;
        else Config.options.statusBar.rightModules = list;
    }

    // end4-style: drop target found by nearest pill center (2D-safe), no layout shift
    function getDropIndex(side, modId, scenePos) {
        var repeater = side === "left" ? leftRepeater : rightRepeater
        var count = repeater.count
        if (count === 0) return 0
        var bestIdx = -1
        var bestDist = Infinity
        for (var i = 0; i < count; i++) {
            var child = repeater.itemAt(i)
            if (!child || child.modId === modId) continue
            var c = child.mapToItem(null, child.width / 2, child.height / 2)
            var d = Math.hypot(scenePos.x - c.x, scenePos.y - c.y)
            if (d < bestDist) { bestDist = d; bestIdx = i }
        }
        if (bestIdx < 0) return count
        var bestChild = repeater.itemAt(bestIdx)
        var bc = bestChild.mapToItem(null, bestChild.width / 2, bestChild.height / 2)
        return scenePos.x < bc.x ? bestIdx : bestIdx + 1
    }

    function containsPoint(item, scenePos) {
        var tl = item.mapToItem(null, 0, 0)
        return scenePos.x >= tl.x && scenePos.x <= tl.x + item.width &&
               scenePos.y >= tl.y && scenePos.y <= tl.y + item.height
    }

    function sideUnderPoint(scenePos) {
        if (containsPoint(leftClusterArea, scenePos)) return "left"
        if (containsPoint(rightClusterArea, scenePos)) return "right"
        return ""
    }

    function updateDropTargetFromScene(modId, scenePos) {
        var side = sideUnderPoint(scenePos)
        if (side === "") {
            if (dropSide !== "") { dropSide = ""; dropIndex = -1 }
            return
        }
        var idx = getDropIndex(side, modId, scenePos)
        dropIndex = idx
        dropSide = side
    }

    function indicatorPos(side, index) {
        var repeater = side === "left" ? leftRepeater : rightRepeater
        var count = repeater.count
        var before = true
        var ref = null
        if (count > 0) {
            if (index < count) {
                ref = repeater.itemAt(index)
            } else {
                ref = repeater.itemAt(count - 1)
                before = false
            }
        }
        if (!ref) return Qt.point(0, 0)
        var x = before ? ref.x - 4 : ref.x + ref.width + 4
        return Qt.point(x, ref.y + ref.height / 2)
    }

    function commitDrop(moduleId, sourceSide, targetSide, dropIndexArg) {
        if (!moduleId || targetSide === "") return;
        var newSource = getClusterModules(sourceSide).filter(function(m) { return m !== moduleId; });
        var targetList = targetSide === sourceSide
            ? newSource
            : getClusterModules(targetSide).filter(function(m) { return m !== moduleId; });
        var idx = dropIndexArg;
        if (targetSide === sourceSide) {
            var origIdx = getClusterModules(sourceSide).indexOf(moduleId);
            if (idx > origIdx) idx -= 1;
        }
        if (idx < 0) idx = 0;
        if (idx > targetList.length) idx = targetList.length;
        targetList.splice(idx, 0, moduleId);

        if (sourceSide === "left") Config.options.statusBar.leftModules = newSource;
        else Config.options.statusBar.rightModules = newSource;
        if (targetSide === "left") Config.options.statusBar.leftModules = targetList;
        else Config.options.statusBar.rightModules = targetList;

        if (moduleId === "clock") Config.options.statusBar.centerModule = "none";
    }

    // ── Drag & Drop Overlay (zero-size, top-most, doesn't affect layout) ──
    Item {
        id: dragOverlayItem
        z: 9999
        width: 0
        height: 0
    }

    // ── Draggable module pill (shared by left & right clusters) ──
    Component {
        id: modulePill

        Item {
            id: pillRoot

            required property var modelData
            required property int index

            readonly property string modId: modelData.id
            readonly property string side: modelData.side
            readonly property var status: rootColumn.getModuleStatus(rootColumn.getClusterModules(side), index)
            readonly property bool hasWarning: status.isConflict || status.isOverflow

            property bool dragging: false
            property var pressPos: Qt.point(0, 0)
            property int dragThreshold: 5
            property Item originalParent: null

            readonly property real pillWidth: modRow.implicitWidth + (24 * Appearance.effectiveScale)

            implicitWidth: pillWidth
            height: 32 * Appearance.effectiveScale
            implicitHeight: height

            Rectangle {
                id: pillRect

                width: pillRoot.pillWidth
                height: pillRoot.height
                implicitWidth: pillRoot.pillWidth
                implicitHeight: 32 * Appearance.effectiveScale
                radius: 8 * Appearance.effectiveScale
                color: pillRoot.hasWarning ? Appearance.m3colors.m3errorContainer : Appearance.m3colors.m3secondaryContainer
                scale: pillRoot.dragging ? 1.02 : 1
                opacity: pillRoot.dragging ? 0.9 : 1

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: pillDragArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: pillRoot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    drag.target: pillRoot.dragging ? pillRect : null
                    drag.threshold: 0
                    onPressed: (mouse) => {
                        pillRoot.pressPos = Qt.point(mouse.x, mouse.y)
                    }
                    onPositionChanged: (mouse) => {
                        if (!pillRoot.dragging && pressed) {
                            const dx = mouse.x - pillRoot.pressPos.x
                            const dy = mouse.y - pillRoot.pressPos.y
                            if (Math.sqrt(dx * dx + dy * dy) > pillRoot.dragThreshold) {
                                pillRoot.originalParent = pillRect.parent
                                const globalPos = pillRect.mapToItem(rootColumn.dragOverlay, 0, 0)
                                pillRect.parent = rootColumn.dragOverlay
                                pillRect.x = globalPos.x
                                pillRect.y = globalPos.y
                                pillRoot.dragging = true
                                rootColumn.draggedModuleId = pillRoot.modId
                                rootColumn.draggedSide = pillRoot.side
                                rootColumn.dropSide = ""
                                rootColumn.dropIndex = -1
                            }
                        }
                        if (pillRoot.dragging) {
                            rootColumn.lastDragScene = pillRect.mapToItem(null, mouse.x, mouse.y)
                            rootColumn.updateDropTargetFromScene(pillRoot.modId, rootColumn.lastDragScene)
                        }
                    }
                    onReleased: {
                        if (pillRoot.dragging) {
                            rootColumn.updateDropTargetFromScene(pillRoot.modId, rootColumn.lastDragScene)
                            const commitId = pillRoot.modId
                            const commitSide = pillRoot.side
                            const targetSide = rootColumn.dropSide
                            const targetIndex = rootColumn.dropIndex
                            pillRoot.dragging = false
                            rootColumn.draggedModuleId = ""
                            rootColumn.draggedSide = ""
                            rootColumn.dropSide = ""
                            rootColumn.dropIndex = -1
                            if (pillRect) {
                                pillRect.parent = pillRoot.originalParent
                                pillRect.x = 0
                                pillRect.y = 0
                            }
                            rootColumn.commitDrop(commitId, commitSide, targetSide, targetIndex)
                        } else {
                            rootColumn.draggedModuleId = ""
                            rootColumn.draggedSide = ""
                            rootColumn.dropSide = ""
                            rootColumn.dropIndex = -1
                        }
                    }
                    onCanceled: {
                        pillRoot.dragging = false
                        rootColumn.draggedModuleId = ""
                        rootColumn.draggedSide = ""
                        rootColumn.dropSide = ""
                        rootColumn.dropIndex = -1
                        if (pillRect) {
                            pillRect.parent = pillRoot.originalParent
                            pillRect.x = 0
                            pillRect.y = 0
                        }
                    }
                }

                StyledToolTip {
                    text: pillRoot.status.tooltipText
                    alternativeVisibleCondition: pillRoot.hasWarning && pillDragArea.containsMouse
                }

                RowLayout {
                    id: modRow

                    anchors.centerIn: parent
                    spacing: 8 * Appearance.effectiveScale

                    MaterialSymbol {
                        visible: pillRoot.hasWarning
                        text: "warning"
                        iconSize: 14 * Appearance.effectiveScale
                        color: pillRoot.hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                    }

                    StyledText {
                        text: rootColumn.getModuleName(pillRoot.modId) + pillRoot.status.labelSuffix
                        color: pillRoot.hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                    }

                    // Remove
                    MaterialSymbol {
                        text: "close"
                        iconSize: 14 * Appearance.effectiveScale
                        color: pillRoot.hasWarning ? Appearance.m3colors.m3onErrorContainer : Appearance.m3colors.m3onSecondaryContainer
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rootColumn.removeModule(pillRoot.modId, pillRoot.side)
                        }
                    }
                }
            }
        }
    }

    SearchHandler { 
        searchString: "Status Bar"
        aliases: ["Bar", "Top Bar", "Panel", "Statusbar", "Distro Icon", "Notification Counter", "Notification Position"]
    }

    // ── Status Bar Section ──

    ColumnLayout {
        id: mainSectionCol
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale
    
                readonly property bool isM3Style: Config.ready && Config.options.statusBar && (Config.options.statusBar.moduleStyle === "m3")

    
                // Computed: background is ALWAYS active (style == 1)
                readonly property bool sbAlwaysSolid: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) === 1
                    : false
                // Computed: any background style is selected (style > 0)
                readonly property bool sbAnyBgStyle: Config.ready && Config.options.statusBar
                    ? (Config.options.statusBar.backgroundStyle ?? 0) > 0
                    : false
                // Gradient is active: only when bg is not ALWAYS solid + useGradient = true
                readonly property bool sbGradientActive: !sbAlwaysSolid
                    && (Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true)
    
                // Section Header
                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "view_compact"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: I18nService.tr("Status Bar")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }
    
                ColumnLayout {
                    id: sbSettingsCol
                    Layout.fillWidth: true
                    spacing: 16 * Appearance.effectiveScale
    
                    Row {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52 * Appearance.effectiveScale
                        spacing: 4 * Appearance.effectiveScale
                        
                        SegmentedButton {
                            width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                            height: parent.height
                            isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle !== "m3"
                            buttonText: I18nService.tr("Base Style")
                            onClicked: if (Config.ready && Config.options.statusBar) Config.options.statusBar.moduleStyle = "base"
                        }
        
                        SegmentedButton {
                            width: (parent.width - (4 * Appearance.effectiveScale)) / 2
                            height: parent.height
                            isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.moduleStyle === "m3"
                            buttonText: I18nService.tr("M3 Style")
                            onClicked: if (Config.ready && Config.options.statusBar) Config.options.statusBar.moduleStyle = "m3"
                        }
                    }

                    // ── Layout & Appearance ─────────────────────────────
                    StyledText {
                        text: I18nService.tr("Layout & Appearance")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Auto Hide ──────────────────────────────────────────────
                    SegmentedWrapper {
                        id: autoHideCard
                        Layout.fillWidth: true
                        implicitHeight: autoHideRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: Appearance.m3colors.m3surfaceContainerHigh
                            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                            buttonRadius: 0
                            topLeftRadius: autoHideCard.rTopLeft
                            topRightRadius: autoHideCard.rTopRight
                            bottomLeftRadius: autoHideCard.rBottomLeft
                            bottomRightRadius: autoHideCard.rBottomRight
                            onClicked: if (Config.ready && Config.options.statusBar)
                                Config.options.statusBar.autoHide = !Config.options.statusBar.autoHide
                        }

                        RowLayout {
                            id: autoHideRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "visibility_off"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Auto hide"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.autoHide ?? false) : false
                                onToggled: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.autoHide = !Config.options.statusBar.autoHide
                            }
                        }
                    }

                    // ── Text color mode (disabled when bg is active) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarTextRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: parent.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        RowLayout {
                            id: statusBarTextRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "palette"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Text color"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "adaptive", label: I18nService.tr("Adaptive") },
                                        { id: "light",    label: I18nService.tr("Light") },
                                        { id: "dark",     label: I18nService.tr("Dark") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        enabled: !sbSettingsCol.parent.sbAlwaysSolid
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.textColorMode === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                            Config.options.statusBar.textColorMode = modelData.id
                                    }
                                }
                            }
                        }
                    }
    
                    // ── Use Gradient (disabled ONLY when background is ALWAYS active) ──────────────
                    SegmentedWrapper {
                        id: sbGradientCard
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarGradientRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        opacity: sbSettingsCol.parent.sbAlwaysSolid ? 0.4 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        RippleButton {
                            anchors.fill: parent
                            colBackground: Appearance.m3colors.m3surfaceContainerHigh
                            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                            buttonRadius: 0
                            topLeftRadius: sbGradientCard.rTopLeft
                            topRightRadius: sbGradientCard.rTopRight
                            bottomLeftRadius: sbGradientCard.rBottomLeft
                            bottomRightRadius: sbGradientCard.rBottomRight
                            enabled: !sbSettingsCol.parent.sbAlwaysSolid
                            onClicked: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                Config.options.statusBar.useGradient = !Config.options.statusBar.useGradient
                        }

                        RowLayout {
                            id: statusBarGradientRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "gradient"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Use gradient"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? Config.options.statusBar.useGradient : true
                                onToggled: if (Config.ready && Config.options.statusBar && !sbSettingsCol.parent.sbAlwaysSolid)
                                    Config.options.statusBar.useGradient = !Config.options.statusBar.useGradient
                            }
                        }
                    }
    
                    // ── Background Style (None / Always / Adaptive) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: statusBarBgRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: statusBarBgRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "rectangle"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Background"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { val: 0, label: I18nService.tr("None") },
                                        { val: 1, label: I18nService.tr("Always") },
                                        { val: 2, label: I18nService.tr("Adaptive") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.backgroundStyle === modelData.val
                                            : modelData.val === 0
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.backgroundStyle = modelData.val
                                    }
                                }
                            }
                        }
                    }

                     // ── Corner radius (visible when ANY background style is active) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbCornerRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: sbSettingsCol.parent.sbAnyBgStyle && !sbSettingsCol.parent.isM3Style && (Config.ready ? Config.options.statusBar?.layoutStyle !== "centered" : true)
                        RowLayout {
                            id: sbCornerRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol { text: "rounded_corner"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText {
                                text: I18nService.tr("Corner radius")
                                Layout.fillWidth: true
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledStepper {
                                Layout.alignment: Qt.AlignVCenter
                                from: 0; to: 20; stepSize: 1
                                decimals: 0
                                suffix: "px"
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.backgroundCornerRadius ?? 20) : 20
                                onValueChanged: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.backgroundCornerRadius = Math.round(value)
                            }
                        }
                    }

                    // ── Layout Style (Standard / Centered) ────────────
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: layoutStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: layoutStyleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "center_focus_strong"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Layout Style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "standard", label: I18nService.tr("Standard") },
                                        { id: "centered", label: I18nService.tr("Centered (HUD)") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.layoutStyle === modelData.id
                                            : modelData.id === "standard"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.layoutStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Centered Width (right below the Standard/Centered switch) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: centeredWidthRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && Config.options.statusBar.layoutStyle === "centered" && !sbSettingsCol.parent.isM3Style
                        RowLayout {
                            id: centeredWidthRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol { text: "width_full"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText {
                                text: I18nService.tr("Centered width")
                                Layout.fillWidth: true
                                color: Appearance.colors.colOnLayer1
                            }

                            StyledStepper {
                                Layout.alignment: Qt.AlignVCenter
                                from: 800; to: 2000; stepSize: 50
                                decimals: 0
                                suffix: "px"
                                value: Config.ready && Config.options.statusBar ? (Config.options.statusBar.centeredWidth ?? 1200) : 1200
                                onValueChanged: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.centeredWidth = Math.round(value)
                            }
                        }
                    }

                    } // End Layout & Appearance ColumnLayout

                    // ── Modules Positioning ──────────────────────────────────
                    StyledText {
                        text: I18nService.tr("Modules Positioning")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Center Module (Clock / None) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: centerModuleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: centerModuleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "view_agenda"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Center Module"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                    RowLayout {
                        spacing: 2 * Appearance.effectiveScale
                        Repeater {
                            model: [
                                { id: "clock", label: I18nService.tr("Clock") },
                                { id: "pcIsland", label: I18nService.tr("pC's Island") },
                                { id: "none",  label: I18nService.tr("None") }
                            ]
                            delegate: SegmentedButton {
                                required property var modelData
                                buttonText: modelData.label
                                isHighlighted: Config.ready && Config.options.statusBar
                                    ? (Config.options.statusBar.centerModule ?? "clock") === modelData.id
                                    : modelData.id === "clock"
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerLow
                                onClicked: if (Config.ready && Config.options.statusBar) {
                                    let currentCenter = Config.options.statusBar.centerModule ?? "clock";
                                    let newCenter = modelData.id;
                                    if (currentCenter === newCenter) return;

                                    let lefts = Array.from(Config.options.statusBar.leftModules || []);
                                    let rights = Array.from(Config.options.statusBar.rightModules || []);

                                    if (newCenter === "clock") {
                                        lefts = lefts.filter(m => m !== "clock");
                                        rights = rights.filter(m => m !== "clock");
                                    } else if (newCenter === "pcIsland") {
                                        // Ensure workspaceIndicator in left cluster by default (unified style)
                                        if (!lefts.includes("workspaceIndicator") && !rights.includes("workspaceIndicator")) {
                                            if (lefts.length < poolMaxModules) lefts.push("workspaceIndicator");
                                            else if (rights.length < poolMaxModules) rights.push("workspaceIndicator");
                                        }
                                        // Remove clock from clusters when pcIsland takes center
                                        lefts = lefts.filter(m => m !== "clock");
                                        rights = rights.filter(m => m !== "clock");
                                    } else if (newCenter === "none" && currentCenter === "clock") {
                                        if (!rights.includes("clock") && !lefts.includes("clock")) {
                                            if (rights.length < poolMaxModules) {
                                                rights.push("clock");
                                            } else if (lefts.length < poolMaxModules) {
                                                lefts.push("clock");
                                            }
                                        }
                                    }

                                    if (newCenter !== "pcIsland") {
                                        lefts = lefts.filter(m => m !== "workspaceIndicator");
                                        rights = rights.filter(m => m !== "workspaceIndicator");
                                    }

                                    Config.options.statusBar.leftModules = lefts;
                                    Config.options.statusBar.rightModules = rights;
                                    Config.options.statusBar.centerModule = newCenter;
                                }
                            }
                        }
                    }
                        }
                    }



                    // ── Left Cluster Modules (Dynamic Drag/Reorder & Add) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: leftModsCol.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        ColumnLayout {
                            id: leftModsCol
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 12 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                MaterialSymbol { text: "align_horizontal_left"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: I18nService.tr("Left Cluster Modules") + " (" + getClusterPoints(getLeftModules()) + "/" + maxClusterPoints + ")"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; font.weight: Font.Medium }
                                
                                // Add Module Dropdown Button (M3 FAB: rounded-square, full-circle when open, tertiary)
                                Item {
                                    id: leftFabHost
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: 40 * Appearance.effectiveScale
                                    implicitHeight: 40 * Appearance.effectiveScale
                                    visible: getAvailableForCluster().length > 0 && getLeftModules().length < poolMaxModules

                                    RippleButton {
                                        id: leftFabButton
                                        anchors.fill: parent
                                        buttonRadius: leftMenuOpened ? height / 2 : 12 * Appearance.effectiveScale
                                        colBackground: Appearance.m3colors.m3tertiaryContainer
                                        colBackgroundHover: Functions.ColorUtils.mix(Appearance.m3colors.m3tertiaryContainer, Appearance.m3colors.m3onTertiaryContainer, 0.9)
                                        colRipple: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onTertiaryContainer, 0.15)
                                        onClicked: leftMenuOpened = !leftMenuOpened

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: leftMenuOpened ? "close" : "add"
                                            iconSize: 22 * Appearance.effectiveScale
                                            color: Appearance.m3colors.m3onTertiaryContainer
                                        }
                                    }
                                }
                            }

                            // Active List Flow (drag & drop reorder)
                            Item {
                                id: leftClusterArea
                                Layout.fillWidth: true
                                implicitHeight: leftClusterFlow.implicitHeight

                                // end4-style drop indicator: slides to the insertion point,
                                // pills stay still (no 2D reflow mess).
                                Rectangle {
                                    id: leftDropIndicator
                                    z: 5
                                    width: 3 * Appearance.effectiveScale
                                    implicitHeight: 32 * Appearance.effectiveScale
                                    radius: 2 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                    visible: rootColumn.leftDropActive
                                    property bool settling: false

                                    Behavior on x {
                                        enabled: !leftDropIndicator.settling
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on y {
                                        enabled: !leftDropIndicator.settling
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }

                                    Connections {
                                        target: rootColumn
                                        function onLeftDropActiveChanged() {
                                            if (rootColumn.leftDropActive) {
                                                leftDropIndicator.settling = true
                                                leftDropIndicator.x = rootColumn.indicatorPos("left", rootColumn.dropIndex).x
                                                leftDropIndicator.y = rootColumn.indicatorPos("left", rootColumn.dropIndex).y - leftDropIndicator.height / 2
                                                leftDropIndicator.settling = false
                                            }
                                        }
                                        function onDropIndexChanged() {
                                            if (rootColumn.leftDropActive && !leftDropIndicator.settling) {
                                                leftDropIndicator.x = rootColumn.indicatorPos("left", rootColumn.dropIndex).x
                                                leftDropIndicator.y = rootColumn.indicatorPos("left", rootColumn.dropIndex).y - leftDropIndicator.height / 2
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: -4 * Appearance.effectiveScale
                                        width: 8 * Appearance.effectiveScale
                                        height: 8 * Appearance.effectiveScale
                                        radius: 4 * Appearance.effectiveScale
                                        color: Appearance.colors.colPrimary
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -4 * Appearance.effectiveScale
                                        width: 8 * Appearance.effectiveScale
                                        height: 8 * Appearance.effectiveScale
                                        radius: 4 * Appearance.effectiveScale
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                Flow {
                                    id: leftClusterFlow
                                    width: parent.width
                                    spacing: 6 * Appearance.effectiveScale

                                    Repeater {
                                        id: leftRepeater
                                        model: getLeftModules().map(function(m) { return { id: m, side: "left" }; })
                                        delegate: modulePill
                                    }
                                }
                            }

                            // Add Dropdown Menu
                            ColumnLayout {
                                id: leftAddMenu
                                visible: leftMenuOpened && getAvailableForCluster().length > 0
                                Layout.fillWidth: true
                                spacing: 4 * Appearance.effectiveScale

                                StyledText {
                                    text: I18nService.tr("Available modules to add:")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 4 * Appearance.effectiveScale
                                    Repeater {
                                        model: getAvailableForCluster()
                                        delegate: Rectangle {
                                            required property var modelData
                                            implicitWidth: addRow.implicitWidth + (24 * Appearance.effectiveScale)
                                            implicitHeight: 32 * Appearance.effectiveScale
                                            radius: 8 * Appearance.effectiveScale
                                            color: Appearance.m3colors.m3surfaceContainerLow

                                            RowLayout {
                                                id: addRow
                                                anchors.centerIn: parent
                                                spacing: 8 * Appearance.effectiveScale
                                                StyledText { text: modelData.name; font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: addToLeftCluster(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Right Cluster Modules (Dynamic Drag/Reorder & Add) ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: rightModsCol.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        ColumnLayout {
                            id: rightModsCol
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 12 * Appearance.effectiveScale

                            RowLayout {
                                spacing: 16 * Appearance.effectiveScale
                                MaterialSymbol { text: "align_horizontal_right"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                StyledText { text: I18nService.tr("Right Cluster Modules") + " (" + getClusterPoints(getRightModules()) + "/" + maxClusterPoints + ")"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1; font.weight: Font.Medium }

                                // Add Module Dropdown Button (M3 FAB: rounded-square, full-circle when open, tertiary)
                                Item {
                                    id: rightFabHost
                                    Layout.alignment: Qt.AlignVCenter
                                    implicitWidth: 40 * Appearance.effectiveScale
                                    implicitHeight: 40 * Appearance.effectiveScale
                                    visible: getAvailableForCluster().length > 0 && getRightModules().length < poolMaxModules

                                    RippleButton {
                                        id: rightFabButton
                                        anchors.fill: parent
                                        buttonRadius: rightMenuOpened ? height / 2 : 12 * Appearance.effectiveScale
                                        colBackground: Appearance.m3colors.m3tertiaryContainer
                                        colBackgroundHover: Functions.ColorUtils.mix(Appearance.m3colors.m3tertiaryContainer, Appearance.m3colors.m3onTertiaryContainer, 0.9)
                                        colRipple: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onTertiaryContainer, 0.15)
                                        onClicked: rightMenuOpened = !rightMenuOpened

                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: rightMenuOpened ? "close" : "add"
                                            iconSize: 22 * Appearance.effectiveScale
                                            color: Appearance.m3colors.m3onTertiaryContainer
                                        }
                                    }
                                }
                            }

                            // Active List Flow (drag & drop reorder)
                            Item {
                                id: rightClusterArea
                                Layout.fillWidth: true
                                implicitHeight: rightClusterFlow.implicitHeight

                                // end4-style drop indicator: slides to the insertion point,
                                // pills stay still (no 2D reflow mess).
                                Rectangle {
                                    id: rightDropIndicator
                                    z: 5
                                    width: 3 * Appearance.effectiveScale
                                    implicitHeight: 32 * Appearance.effectiveScale
                                    radius: 2 * Appearance.effectiveScale
                                    color: Appearance.colors.colPrimary
                                    visible: rootColumn.rightDropActive
                                    property bool settling: false

                                    Behavior on x {
                                        enabled: !rightDropIndicator.settling
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on y {
                                        enabled: !rightDropIndicator.settling
                                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                                    }

                                    Connections {
                                        target: rootColumn
                                        function onRightDropActiveChanged() {
                                            if (rootColumn.rightDropActive) {
                                                rightDropIndicator.settling = true
                                                rightDropIndicator.x = rootColumn.indicatorPos("right", rootColumn.dropIndex).x
                                                rightDropIndicator.y = rootColumn.indicatorPos("right", rootColumn.dropIndex).y - rightDropIndicator.height / 2
                                                rightDropIndicator.settling = false
                                            }
                                        }
                                        function onDropIndexChanged() {
                                            if (rootColumn.rightDropActive && !rightDropIndicator.settling) {
                                                rightDropIndicator.x = rootColumn.indicatorPos("right", rootColumn.dropIndex).x
                                                rightDropIndicator.y = rootColumn.indicatorPos("right", rootColumn.dropIndex).y - rightDropIndicator.height / 2
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: -4 * Appearance.effectiveScale
                                        width: 8 * Appearance.effectiveScale
                                        height: 8 * Appearance.effectiveScale
                                        radius: 4 * Appearance.effectiveScale
                                        color: Appearance.colors.colPrimary
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -4 * Appearance.effectiveScale
                                        width: 8 * Appearance.effectiveScale
                                        height: 8 * Appearance.effectiveScale
                                        radius: 4 * Appearance.effectiveScale
                                        color: Appearance.colors.colPrimary
                                    }
                                }

                                Flow {
                                    id: rightClusterFlow
                                    width: parent.width
                                    spacing: 6 * Appearance.effectiveScale

                                    Repeater {
                                        id: rightRepeater
                                        model: getRightModules().map(function(m) { return { id: m, side: "right" }; })
                                        delegate: modulePill
                                    }
                                }
                            }

                            // Add Dropdown Menu
                            ColumnLayout {
                                id: rightAddMenu
                                visible: rightMenuOpened && getAvailableForCluster().length > 0
                                Layout.fillWidth: true
                                spacing: 4 * Appearance.effectiveScale

                                StyledText {
                                    text: I18nService.tr("Available modules to add:")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 4 * Appearance.effectiveScale
                                    Repeater {
                                        model: getAvailableForCluster()
                                        delegate: Rectangle {
                                            required property var modelData
                                            implicitWidth: addRowRight.implicitWidth + (24 * Appearance.effectiveScale)
                                            implicitHeight: 32 * Appearance.effectiveScale
                                            radius: 8 * Appearance.effectiveScale
                                            color: Appearance.m3colors.m3surfaceContainerLow

                                            RowLayout {
                                                id: addRowRight
                                                anchors.centerIn: parent
                                                spacing: 8 * Appearance.effectiveScale
                                                StyledText { text: modelData.name; font.pixelSize: Appearance.font.pixelSize.smallest; color: Appearance.colors.colOnLayer1 }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: addToRightCluster(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }


                    // ── Notification Unread Attachment (Distro Icon vs Status Icons) ────────────
                    SegmentedWrapper {
                        visible: !rootColumn.isPcIslandActive
                        Layout.fillWidth: true
                        implicitHeight: notifPositionRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: notifPositionRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "notifications"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Notification Unread Badge Host"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "distroIcon", label: I18nService.tr("Distro Icon") },
                                        { id: "statusIconsGroup", label: I18nService.tr("Status Icons") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.notifications
                                            ? (Config.options.notifications.hostModule ?? "distroIcon") === modelData.id
                                            : modelData.id === "distroIcon"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.notifications)
                                            Config.options.notifications.hostModule = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Notification Counter Style ────────────
                    SegmentedWrapper {
                        visible: !rootColumn.isPcIslandActive
                        Layout.fillWidth: true
                        implicitHeight: notifCounterStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: notifCounterStyleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "mark_chat_unread"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Notification Counter"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "counter", label: I18nService.tr("Counter") },
                                        { id: "simple", label: I18nService.tr("Simple") },
                                        { id: "hidden", label: I18nService.tr("Hidden") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.notifications
                                            ? Config.options.notifications.counterStyle === modelData.id
                                            : modelData.id === "counter"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.notifications)
                                            Config.options.notifications.counterStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── System Monitor Options ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sysMonRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && (
                            (Config.options.statusBar.leftModules && Config.options.statusBar.leftModules.includes("systemMonitor")) ||
                            (Config.options.statusBar.rightModules && Config.options.statusBar.rightModules.includes("systemMonitor"))
                        )
                        RowLayout {
                            id: sysMonRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "memory"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("System Monitor Options"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            
                            RowLayout {
                                spacing: 10 * Appearance.effectiveScale
                                
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorCpu ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorCpu = !Config.options.statusBar.showSystemMonitorCpu
                                    }
                                    StyledText { text: I18nService.tr("CPU"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorRam ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorRam = !Config.options.statusBar.showSystemMonitorRam
                                    }
                                    StyledText { text: I18nService.tr("RAM"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorSwap ?? false) : false
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorSwap = !Config.options.statusBar.showSystemMonitorSwap
                                    }
                                    StyledText { text: I18nService.tr("Swap"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorTemp ?? true) : true
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorTemp = !Config.options.statusBar.showSystemMonitorTemp
                                    }
                                    StyledText { text: I18nService.tr("Temp"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                                RowLayout {
                                    spacing: 4 * Appearance.effectiveScale
                                    AndroidToggle {
                                        checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorText ?? false) : false
                                        onToggled: if (Config.ready && Config.options.statusBar) Config.options.statusBar.showSystemMonitorText = !Config.options.statusBar.showSystemMonitorText
                                    }
                                    StyledText { text: I18nService.tr("Text"); color: Appearance.colors.colOnLayer1; font.pixelSize: Appearance.font.pixelSize.smaller }
                                }
                            }
                        }
                    }

                    // ── System Monitor Style ────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sysMonStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        visible: Config.ready && Config.options.statusBar && (
                            (Config.options.statusBar.leftModules && Config.options.statusBar.leftModules.includes("systemMonitor")) ||
                            (Config.options.statusBar.rightModules && Config.options.statusBar.rightModules.includes("systemMonitor"))
                        )
                        RowLayout {
                            id: sysMonStyleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "style"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("System Monitor Style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "outline", label: I18nService.tr("Outline") },
                                        { id: "filled", label: I18nService.tr("Filled") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.systemMonitorStyle ?? "outline") === modelData.id
                                            : modelData.id === "outline"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.systemMonitorStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    } // End Modules Positioning ColumnLayout

                    // ── Modules Styling ──────────────────────────────────────
                    StyledText {
                        text: I18nService.tr("Modules Styling")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.topMargin: 12 * Appearance.effectiveScale
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4 * Appearance.effectiveScale

                    // ── Workspace Style (Shape) ──
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style && !rootColumn.isPcIslandActive
                        Layout.fillWidth: true
                        implicitHeight: wsStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: wsStyleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "layers"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Indicator Shape"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "pill", label: I18nService.tr("Pill") },
                                        { id: "unified", label: I18nService.tr("Unified") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.workspaces
                                            ? Config.options.workspaces.indicatorStyle === modelData.id
                                            : modelData.id === "pill"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.workspaces)
                                            Config.options.workspaces.indicatorStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Workspace Style (Label) ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: wsLabelRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: wsLabelRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "format_list_numbered"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Indicator Label"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "none", label: I18nService.tr("None") },
                                        { id: "numeric", label: I18nService.tr("Numeric") },
                                        { id: "japanese", label: I18nService.tr("Japanese") },
                                        { id: "roman", label: I18nService.tr("Roman") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.workspaces
                                            ? (Config.options.workspaces.indicatorLabel ?? "none") === modelData.id
                                            : modelData.id === "none"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.workspaces)
                                            Config.options.workspaces.indicatorLabel = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Island Style ──
                    SegmentedWrapper {
                        visible: !sbSettingsCol.parent.isM3Style
                        Layout.fillWidth: true
                        implicitHeight: islandStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: islandStyleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "animation"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Island Style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "pill", label: I18nService.tr("Pill") },
                                        { id: "waterdrop", label: I18nService.tr("Waterdrop") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? Config.options.statusBar.islandStyle === modelData.id
                                            : modelData.id === "pill"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.islandStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── pC Island: Visualizer Style ──
                    SegmentedWrapper {
                        visible: rootColumn.isPcIslandActive
                        Layout.fillWidth: true
                        implicitHeight: pcVisRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: pcVisRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "graphic_eq"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("pC Visualizer"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "dots", label: I18nService.tr("Dots") },
                                        { id: "wave", label: I18nService.tr("Wave") },
                                        { id: "none", label: I18nService.tr("None") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar && Config.options.statusBar.pcIsland
                                            ? Config.options.statusBar.pcIsland.visualizerStyle === modelData.id
                                            : modelData.id === "dots"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar && Config.options.statusBar.pcIsland)
                                            Config.options.statusBar.pcIsland.visualizerStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── pC Island: Media Controls ──
                    SegmentedWrapper {
                        visible: rootColumn.isPcIslandActive
                        Layout.fillWidth: true
                        implicitHeight: pcMediaRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: pcMediaRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "play_circle"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Media Buttons"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar && Config.options.statusBar.pcIsland ? Config.options.statusBar.pcIsland.showMediaControls : false
                                onToggled: if (Config.ready && Config.options.statusBar && Config.options.statusBar.pcIsland)
                                    Config.options.statusBar.pcIsland.showMediaControls = !Config.options.statusBar.pcIsland.showMediaControls
                            }
                        }
                    }

                    // ── Tray Style ──
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: trayStyleRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: trayStyleRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "apps"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Tray Style"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            RowLayout {
                                spacing: 2 * Appearance.effectiveScale
                                Repeater {
                                    model: [
                                        { id: "all", label: I18nService.tr("All") },
                                        { id: "adaptive", label: I18nService.tr("Adaptive") },
                                        { id: "hide", label: I18nService.tr("Hide") }
                                    ]
                                    delegate: SegmentedButton {
                                        required property var modelData
                                        buttonText: modelData.label
                                        isHighlighted: Config.ready && Config.options.statusBar
                                            ? (Config.options.statusBar.trayStyle ?? "adaptive") === modelData.id
                                            : modelData.id === "adaptive"
                                        colActive: Appearance.m3colors.m3primary
                                        colActiveText: Appearance.m3colors.m3onPrimary
                                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                                        onClicked: if (Config.ready && Config.options.statusBar)
                                            Config.options.statusBar.trayStyle = modelData.id
                                    }
                                }
                            }
                        }
                    }

                    // ── Volume Indicator ──
                    SegmentedWrapper {
                        id: volumeIndicatorCard
                        Layout.fillWidth: true
                        implicitHeight: volumeIndicatorRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RippleButton {
                            anchors.fill: parent
                            colBackground: Appearance.m3colors.m3surfaceContainerHigh
                            colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                            buttonRadius: 0
                            topLeftRadius: volumeIndicatorCard.rTopLeft
                            topRightRadius: volumeIndicatorCard.rTopRight
                            bottomLeftRadius: volumeIndicatorCard.rBottomLeft
                            bottomRightRadius: volumeIndicatorCard.rBottomRight
                            onClicked: if (Config.ready && Config.options.statusBar)
                                Config.options.statusBar.showVolumeIndicator = !Config.options.statusBar.showVolumeIndicator
                        }

                        RowLayout {
                            id: volumeIndicatorRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "volume_up"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Volume Indicator"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            AndroidToggle {
                                checked: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showVolumeIndicator ?? true) : true
                                onToggled: if (Config.ready && Config.options.statusBar)
                                    Config.options.statusBar.showVolumeIndicator = !Config.options.statusBar.showVolumeIndicator
                            }
                        }
                    }

                    // ── Workspace count ──────────────────────────────────────────
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        implicitHeight: sbWorkspaceRow.implicitHeight + (24 * Appearance.effectiveScale)
                        orientation: Qt.Vertical
                        maxRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        RowLayout {
                            id: sbWorkspaceRow
                            anchors.fill: parent
                            anchors {
                                leftMargin: 16 * Appearance.effectiveScale
                                rightMargin: 16 * Appearance.effectiveScale
                                topMargin: 12 * Appearance.effectiveScale
                                bottomMargin: 12 * Appearance.effectiveScale
                            }
                            spacing: 16 * Appearance.effectiveScale
                            MaterialSymbol { text: "grid_view"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                            StyledText { text: I18nService.tr("Workspace count"); Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
                            StyledStepper {
                                Layout.alignment: Qt.AlignVCenter
                                value: Config.ready && Config.options.workspaces ? (Config.options.workspaces.max_shown ?? 5) : 5
                                from: 1; to: 20; stepSize: 1
                                decimals: 0
                                onValueChanged: if (Config.ready && Config.options.workspaces)
                                    Config.options.workspaces.max_shown = Math.round(value)
                            }
                        }
                    }

                    } // End Modules Styling ColumnLayout
                }
            }
    

}
