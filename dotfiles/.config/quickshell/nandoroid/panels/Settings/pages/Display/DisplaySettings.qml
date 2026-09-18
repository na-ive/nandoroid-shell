import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

/**
 * High-fidelity Display Settings page.
 * Manages monitors, resolution, scaling, orientation, and Night Light.
 * Features an interactive monitor selector in the header visualization.
 */
Item {
    id: root
    implicitWidth: parent ? parent.width : 0
    implicitHeight: parent ? parent.height : 0

    // Deep Link Logic
    property string targetSearchQuery: ""
    onTargetSearchQueryChanged: {
        if (targetSearchQuery !== "") {
            deepLinkSearch(targetSearchQuery)
            targetSearchQuery = ""
        }
    }

    function deepLinkSearch(query) {
        if (!query) return;
        query = query.toLowerCase();
        for (let i = 0; i < mainCol.children.length; i++) {
            let child = mainCol.children[i];
            if (isMatch(child, query)) {
                mainFlickable.contentY = Math.min(child.y, mainFlickable.contentHeight - mainFlickable.height);
                highlightAnim.target = child;
                highlightAnim.restart();
                break;
            }
        }
    }

    function isMatch(item, query) {
        if (!item || !item.visible) return false;
        const props = ["title", "text", "mainText", "label", "name"];
        for (let p of props) {
            if (item.hasOwnProperty(p) && typeof item[p] === "string" && item[p].toLowerCase().includes(query)) return true;
        }
        if (item.children) {
            for (let i = 0; i < item.children.length; i++) {
                if (isMatch(item.children[i], query)) return true;
            }
        }
        return false;
    }

    SequentialAnimation {
        id: highlightAnim
        property var target: null
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 1; to: 0.3; duration: 200 }
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 0.3; to: 1; duration: 400 }
    }

    // ── Placeholder Monitors for Testing ──
    readonly property bool showPlaceholders: false // Set to true to test multi-monitor features on single-monitor setups
    readonly property var debugMonitors: [
        { name: "Virtual-1", description: "Placeholder Monitor 1 (4K)", width: 3840, height: 2160, x: 0, y: 0, scale: 2.0, refreshRate: 60, transform: 0, availableModes: ["3840x2160@60Hz", "1920x1080@60Hz"] },
        { name: "Virtual-2", description: "Placeholder Monitor 2 (1080p)", width: 1920, height: 1080, x: 3840, y: 0, scale: 1.0, refreshRate: 75, transform: 0, availableModes: ["1920x1080@75Hz", "1280x720@60Hz"] }
    ]

    readonly property var monitorList: {
        const hMonitors = HyprlandData.monitors;
        if (hMonitors.length > 0) {
            if (showPlaceholders && hMonitors.length === 1) {
                // Add a placeholder next to the real one
                let m = hMonitors[0];
                return [m, { name: "Mock-2", description: "Mock Display (Side)", width: 1920, height: 1080, x: m.width, y: 0, scale: 1.0, refreshRate: 60, transform: 0, availableModes: ["1920x1080@60Hz", "1280x720@60Hz"] }];
            }
            return hMonitors;
        }
        return showPlaceholders ? debugMonitors : [];
    }

    // ── Selection State ──

    property int currentMonitorIndex: 0
    readonly property var currentMonitor: {
        const monitors = root.monitorList;
        if (monitors.length === 0) return null;
        let idx = currentMonitorIndex;
        if (idx >= monitors.length) idx = 0;
        return monitors[idx];
    }

    // ── Staged Changes State ──
    property var stagedChanges: ({})
    property bool hasPendingChanges: false

    function setStagedChange(monitorName, property, value) {
        let changes = JSON.parse(JSON.stringify(stagedChanges));
        if (!changes[monitorName]) changes[monitorName] = {};
        changes[monitorName][property] = value;
        stagedChanges = changes;
        hasPendingChanges = Object.keys(stagedChanges).length > 0;
    }

    // ── Previous State for Revert ──
    property var previousState: ({})
    function captureCurrentState() {
        let state = {};
        root.monitorList.forEach(m => {
            state[m.name] = {
                resolution: m.width + "x" + m.height,
                refreshRate: m.refreshRate,
                scale: m.scale,
                transform: m.transform,
                position: m.x + "x" + m.y,
                mirror: m.mirror
            };
        });
        previousState = state;
    }

    function applyChanges() {
        captureCurrentState();
        DisplayService.batchApply(root.stagedChanges);
        revertPopup.active = true;
        // We don't clear stagedChanges immediately, so the UI keeps showing the preview
    }

    function confirmChanges() {
        root.stagedChanges = {};
        hasPendingChanges = false;
        HyprlandData.updateMonitors();
        HyprlandData.updateMonitorsDelayed(800);
    }

    function revertChanges() {
        DisplayService.batchApply(root.previousState);
        root.stagedChanges = {};
        hasPendingChanges = false;
        HyprlandData.updateMonitors();
        HyprlandData.updateMonitorsDelayed(800);
    }

    // ── Mirroring State Helpers ──
    readonly property bool currentMonitorMirroring: {
        const m = root.currentMonitor;
        if (!m) return false;
        const sj = root.stagedChanges[m.name];
        if (sj && sj.mirror !== undefined) return sj.mirror !== "";
        return m.mirror !== "" && m.mirror !== undefined && m.mirror.length > 0;
    }

    function toggleMirroring() {
        const cur = root.currentMonitor;
        if (!cur) return;
        if (root.currentMonitorMirroring) {
            root.setStagedChange(cur.name, "mirror", "");
            root.setStagedChange(cur.name, "resolution", "preferred");
        } else {
            const main = root.monitorList[0];
            if (main) root.setStagedChange(cur.name, "mirror", main.name);
        }
    }

    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + (48 * Appearance.effectiveScale)
        clip: true
        ScrollBar.vertical: StyledScrollBar {}

        ColumnLayout {
            id: mainCol
            width: parent.width - (24 * Appearance.effectiveScale)
            spacing: 24 * Appearance.effectiveScale

            // ── Header ──
            ColumnLayout {
                spacing: 4 * Appearance.effectiveScale
                StyledText {
                    text: I18nService.tr("Display")
                    font.pixelSize: Appearance.font.pixelSize.huge
                    font.family: Appearance.font.family.title
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: I18nService.tr("Configure your monitors, visual comfort, and layout.")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            // ── Monitor Layout Visualization (Selector & Drag-n-Drop) ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "layers"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: {
                            let base = I18nService.tr("Monitor Layout");
                            if (root.monitorList.length > 1) {
                                base += I18nService.tr(" (") + root.monitorList.length + I18nService.tr(" detected)");
                            }
                            return base;
                        }
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: I18nService.tr("Layout visualization")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        visible: root.monitorList.length > 1
                    }
                }

                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: 360 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    smallRadius: 8 * Appearance.effectiveScale
                    fullRadius: 20 * Appearance.effectiveScale

                    // Grid Background
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        clip: true
                        radius: 20 * Appearance.effectiveScale

                        Canvas {
                            id: vizCanvas
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.strokeStyle = Appearance.m3colors.m3outlineVariant;
                                ctx.lineWidth = 0.5 * Appearance.effectiveScale;
                                ctx.globalAlpha = 0.15;
                                for (var x = 0; x <= width; x += 40 * Appearance.effectiveScale) {
                                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                                }
                                for (var y = 0; y <= height; y += 40 * Appearance.effectiveScale) {
                                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                                }
                            }
                        }
                    }

                    // Monitor Representation
                    Item {
                        id: monitorContainer
                        anchors.fill: parent
                        anchors.margins: 24 * Appearance.effectiveScale

                        readonly property real vizScale: {
                            const m = root.monitorList;
                            if (m.length === 0) return 0.1;
                            let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                            for (let i = 0; i < m.length; i++) {
                                let mx = m[i].x;
                                let my = m[i].y;
                                const sj = root.stagedChanges[m[i].name];
                                if (sj) {
                                    if (sj.x !== undefined) mx = sj.x;
                                    if (sj.y !== undefined) my = sj.y;
                                }
                                minX = Math.min(minX, mx);
                                minY = Math.min(minY, my);
                                maxX = Math.max(maxX, mx + m[i].width);
                                maxY = Math.max(maxY, my + m[i].height);
                            }
                            const bw = maxX - minX;
                            const bh = maxY - minY;
                            if (bw === 0 || bh === 0) return 0.1;
                            return (280 * Appearance.effectiveScale) / Math.max(bw, bh);
                        }

                        readonly property var bounds: {
                            const m = root.monitorList;
                            if (m.length === 0) return { minX: 0, minY: 0, width: 1920, height: 1080 };
                            let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
                            for (let i = 0; i < m.length; i++) {
                                let mx = m[i].x;
                                let my = m[i].y;
                                const sj = root.stagedChanges[m[i].name];
                                if (sj) {
                                    if (sj.x !== undefined) mx = sj.x;
                                    if (sj.y !== undefined) my = sj.y;
                                }
                                minX = Math.min(minX, mx);
                                minY = Math.min(minY, my);
                                maxX = Math.max(maxX, mx + m[i].width);
                                maxY = Math.max(maxY, my + m[i].height);
                            }
                            return { minX, minY, width: maxX - minX, height: maxY - minY };
                        }

                        readonly property point offset: Qt.point(
                            (monitorContainer.width  - bounds.width  * vizScale) / 2 - bounds.minX * vizScale,
                            (monitorContainer.height - bounds.height * vizScale) / 2 - bounds.minY * vizScale
                        )

                        Repeater {
                            model: root.monitorList
                            delegate: Rectangle {
                                id: monRect
                                width: modelData.width * monitorContainer.vizScale
                                height: modelData.height * monitorContainer.vizScale

                                x: {
                                    let targetX = modelData.x;
                                    const sj = root.stagedChanges[modelData.name];
                                    if (sj && sj.x !== undefined) targetX = sj.x;
                                    return targetX * monitorContainer.vizScale + monitorContainer.offset.x;
                                }
                                y: {
                                    let targetY = modelData.y;
                                    const sj = root.stagedChanges[modelData.name];
                                    if (sj && sj.y !== undefined) targetY = sj.y;
                                    return targetY * monitorContainer.vizScale + monitorContainer.offset.y;
                                }

                                radius: 16 * Appearance.effectiveScale
                                color: root.currentMonitorIndex === index ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerLow
                                border.color: root.currentMonitorIndex === index ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                                border.width: 1.5 * Appearance.effectiveScale

                                Behavior on color { ColorAnimation { duration: 250 } }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.color: root.currentMonitorIndex === index ? "white" : "transparent"
                                    border.width: 2 * Appearance.effectiveScale
                                    opacity: 0.3
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4 * Appearance.effectiveScale
                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignCenter
                                        text: index === 0 ? "home" : "monitor"
                                        iconSize: Math.min(24 * Appearance.effectiveScale, monRect.height * 0.4)
                                        color: root.currentMonitorIndex === index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                                    }
                                    StyledText {
                                        text: index === 0 ? "Main" : "" + (index + 1)
                                        Layout.alignment: Qt.AlignCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: root.currentMonitorIndex === index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                                        visible: monRect.height > 25 * Appearance.effectiveScale
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentMonitorIndex = index
                                }
                            }
                        }
                    }
                }
            }

            // ── Layout & Arrangement Controls (Directly under visualization) ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                visible: root.currentMonitorIndex !== 0 && root.monitorList.length > 1

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "grid_view"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: I18nService.tr("Layout & Arrangement")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }

                // Arrangement Presets
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, arrangeRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    MouseArea {
                        id: arrangeHoverArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: arrangeHoverArea.containsMouse
                            text: I18nService.tr("Position relative to Main")
                        }
                    }

                    RowLayout {
                        id: arrangeRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "open_with"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Physical Arrangement")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 2 * Appearance.effectiveScale
                            Repeater {
                                model: [
                                    { label: "Left", icon: "arrow_back" },
                                    { label: "Right", icon: "arrow_forward" },
                                    { label: "Above", icon: "arrow_upward" },
                                    { label: "Below", icon: "arrow_downward" }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    Layout.preferredWidth: 48 * Appearance.effectiveScale
                                    Layout.alignment: Qt.AlignVCenter
                                    colActive: Appearance.colors.colPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    isHighlighted: false
                                    iconName: modelData.icon
                                    iconSize: 18 * Appearance.effectiveScale

                                    onClicked: {
                                        const main = root.monitorList[0];
                                        const cur = root.currentMonitor;
                                        if (!main || !cur) return;

                                        let nx = 0, ny = 0;
                                        if (modelData.label === "Left") nx = -cur.width;
                                        else if (modelData.label === "Right") nx = main.width;
                                        else if (modelData.label === "Above") ny = -cur.height;
                                        else if (modelData.label === "Below") ny = main.height;

                                        // Auto-apply immediately AND update stagedChanges for instant visualization feedback
                                        root.setStagedChange(cur.name, "x", nx);
                                        root.setStagedChange(cur.name, "y", ny);

                                        DisplayService.applyMonitorSettings({
                                            name: cur.name,
                                            resolution: cur.currentResolution,
                                            x: nx,
                                            y: ny,
                                            scale: cur.scale,
                                            transform: cur.transform
                                        });
                                    }
                                }
                            }
                        }
                    }
                }

                // Mirroring
                SegmentedWrapper {
                    id: mirrorCard
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, mirrorRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RippleButton {
                        id: mirrorClickArea
                        anchors.fill: parent
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                        buttonRadius: 0
                        topLeftRadius: mirrorCard.rTopLeft
                        topRightRadius: mirrorCard.rTopRight
                        bottomLeftRadius: mirrorCard.rBottomLeft
                        bottomRightRadius: mirrorCard.rBottomRight
                        onClicked: root.toggleMirroring()

                        StyledToolTip {
                            extraVisibleCondition: parent.hovered || parent.realHovered
                            text: I18nService.tr("Duplicate Main content")
                        }
                    }

                    RowLayout {
                        id: mirrorRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "flip"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Mirror Display")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        AndroidToggle {
                            checked: root.currentMonitorMirroring
                            onToggled: root.toggleMirroring()
                        }
                    }
                }

                // Primary Display (Set as Main)
                SegmentedWrapper {
                    id: primaryCard
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, primaryRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    MouseArea {
                        id: primaryHoverArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: primaryHoverArea.containsMouse
                            text: I18nService.tr("Switch primary monitor")
                        }
                    }

                    RowLayout {
                        id: primaryRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "flag"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Primary Display")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        RippleButton {
                            implicitWidth: 100 * Appearance.effectiveScale
                            implicitHeight: 36 * Appearance.effectiveScale
                            buttonRadius: 18 * Appearance.effectiveScale
                            buttonText: I18nService.tr("Set Main")
                            colBackground: Appearance.colors.colPrimary
                            colText: Appearance.colors.colOnPrimary

                            onClicked: {
                                if (root.currentMonitor) {
                                    root.setStagedChange(root.currentMonitor.name, "x", 0);
                                    root.setStagedChange(root.currentMonitor.name, "y", 0);
                                }
                            }
                        }
                    }
                }
            }

            // ── Selected Monitor Settings ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                visible: root.currentMonitor !== null

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "settings_input_component"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }
                    StyledText {
                        text: {
                            if (!root.currentMonitor) return I18nService.tr("Monitor Configuration");
                            let desc = root.currentMonitor.description || root.currentMonitor.name;
                            return I18nService.tr("Monitor ") + (root.currentMonitorIndex + 1) + ": " + desc;
                        }
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // ── Apply/Cancel Buttons ──
                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        opacity: root.hasPendingChanges ? 1 : 0
                        enabled: root.hasPendingChanges
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        MouseArea {
                            width: cancelText.implicitWidth
                            height: cancelText.implicitHeight
                            cursorShape: Qt.PointingHandCursor
                            StyledText {
                                id: cancelText
                                anchors.centerIn: parent
                                text: I18nService.tr("Cancel")
                                font.pixelSize: Math.round(13 * Appearance.effectiveScale)
                                font.weight: Font.Medium
                                color: Appearance.colors.colSubtext
                            }
                            onClicked: { root.stagedChanges = {}; root.hasPendingChanges = false; }
                        }

                        MouseArea {
                            width: applyText.implicitWidth
                            height: applyText.implicitHeight
                            cursorShape: Qt.PointingHandCursor
                            StyledText {
                                id: applyText
                                anchors.centerIn: parent
                                text: I18nService.tr("Apply")
                                font.pixelSize: Math.round(13 * Appearance.effectiveScale)
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colPrimary
                            }
                            onClicked: root.applyChanges()
                        }
                    }
                }

                // Resolution & Refresh
                SegmentedWrapper {
                    id: resCard
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, resRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RippleButton {
                        id: resClickArea
                        anchors.fill: parent
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                        buttonRadius: 0
                        topLeftRadius: resCard.rTopLeft
                        topRightRadius: resCard.rTopRight
                        bottomLeftRadius: resCard.rBottomLeft
                        bottomRightRadius: resCard.rBottomRight

                        property real popupClosedAt: 0

                        onClicked: {
                            if (Date.now() - popupClosedAt < 250) return;
                            resCombo.isOpened = !resCombo.isOpened;
                        }

                        Connections {
                            target: resCombo
                            function onIsOpenedChanged() {
                                if (!resCombo.isOpened) resClickArea.popupClosedAt = Date.now();
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: parent.hovered || parent.realHovered
                            text: {
                                if (!root.currentMonitor) return "";
                                const sj = root.stagedChanges[root.currentMonitor.name];
                                if (sj && sj.resolution) return root.currentMonitor.name + " @ Stage: " + sj.resolution;
                                return root.currentMonitor.name + " @ " + Math.round(root.currentMonitor.refreshRate) + "Hz";
                            }
                        }
                    }

                    RowLayout {
                        id: resRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "aspect_ratio"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Resolution & Refresh")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            id: resCombo
                            implicitWidth: 260 * Appearance.effectiveScale
                            bgRadius: height / 2

                            Binding on text {
                                when: true
                                value: {
                                    const mName = root.currentMonitor ? root.currentMonitor.name : ""
                                    const mode = (root.stagedChanges[mName] && root.stagedChanges[mName].resolution) || (root.currentMonitor ? (root.currentMonitor.currentResolution || (root.currentMonitor.width + "x" + root.currentMonitor.height)) : "")
                                    const rate = (root.stagedChanges[mName] && root.stagedChanges[mName].refreshRate) || (root.currentMonitor ? root.currentMonitor.refreshRate : 60)
                                    return mode + "@" + rate + "Hz"
                                }
                                restoreMode: Binding.RestoreBindingOrValue
                            }

                            model: root.currentMonitor ? root.currentMonitor.availableModes || [] : []
                            searchable: false
                            onAccepted: (val) => {
                                const match = val.match(/(\d+)x(\d+)@([\d.]+)Hz/);
                                if (match) {
                                    const res = match[1] + "x" + match[2];
                                    const refresh = parseFloat(match[3]);
                                    root.setStagedChange(root.currentMonitor.name, "resolution", res);
                                    root.setStagedChange(root.currentMonitor.name, "refreshRate", refresh);
                                }
                            }
                        }
                    }
                }

                // Scaling
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, scaleRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    MouseArea {
                        id: scaleHoverArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: scaleHoverArea.containsMouse
                            text: I18nService.tr("Adjust text and UI size.")
                        }
                    }

                    RowLayout {
                        id: scaleRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "zoom_out_map"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Display Scaling")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 2 * Appearance.effectiveScale
                            Repeater {
                                model: [1.0, 1.25, 1.5, 2.0]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    buttonText: (modelData * 100) + "%"
                                    isHighlighted: {
                                        if (!root.currentMonitor) return false;
                                        const sj = root.stagedChanges[root.currentMonitor.name];
                                        if (sj && sj.scale !== undefined) return Math.abs(sj.scale - modelData) < 0.01;
                                        return Math.abs(parseFloat(root.currentMonitor.scale || 1.0) - modelData) < 0.01;
                                    }
                                    Layout.alignment: Qt.AlignVCenter
                                    leftPadding: 16 * Appearance.effectiveScale
                                    rightPadding: 16 * Appearance.effectiveScale
                                    colActive: Appearance.m3colors.m3primary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    onClicked: {
                                        root.setStagedChange(root.currentMonitor.name, "scale", modelData);
                                    }
                                }
                            }
                        }
                    }
                }

                // Orientation
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, orientRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    MouseArea {
                        id: orientHoverArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: orientHoverArea.containsMouse
                            text: I18nService.tr("Rotate the screen content.")
                        }
                    }

                    RowLayout {
                        id: orientRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "screen_rotation"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Orientation")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 2 * Appearance.effectiveScale
                            Repeater {
                                model: [
                                    { label: I18nService.tr("Normal"), value: 0 },
                                    { label: "90°", value: 1 },
                                    { label: "180°", value: 2 },
                                    { label: "270°", value: 3 }
                                ]
                                delegate: SegmentedButton {
                                    required property var modelData
                                    buttonText: modelData.label
                                    isHighlighted: {
                                        if (!root.currentMonitor) return false;
                                        const sj = root.stagedChanges[root.currentMonitor.name];
                                        if (sj && sj.transform !== undefined) return sj.transform === modelData.value;
                                        return (root.currentMonitor.transform || 0) === modelData.value;
                                    }
                                    Layout.alignment: Qt.AlignVCenter
                                    leftPadding: 16 * Appearance.effectiveScale
                                    rightPadding: 16 * Appearance.effectiveScale
                                    colActive: Appearance.m3colors.m3primary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    onClicked: {
                                        root.setStagedChange(root.currentMonitor.name, "transform", modelData.value);
                                    }
                                }
                            }
                        }
                    }
                }

                // Brightness
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, brightRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: brightRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        property var mon: root.currentMonitor ? Brightness.getMonitorByName(root.currentMonitor.name) : null

                        MaterialSymbol {
                            text: "brightness_6"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Brightness")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        StyledStepper {
                            from: 0.0
                            to: 1.0
                            stepSize: 0.01
                            displayFactor: 100
                            decimals: 0
                            suffix: "%"
                            value: brightRow.mon ? brightRow.mon.brightness : 0.5
                            onValueChanged: {
                                if (brightRow.mon && Math.abs(brightRow.mon.brightness - value) > 0.0001) brightRow.mon.setBrightness(value);
                            }
                        }
                    }
                }
            }

            // ── UI Scaling Section ──
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "straighten"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: I18nService.tr("UI Scaling")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.fillWidth: true
                    }
                }

                // Toggle Auto Scale (whole card clickable)
                SegmentedWrapper {
                    id: autoScaleCard
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, autoScaleRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RippleButton {
                        id: autoScaleClickArea
                        anchors.fill: parent
                        colBackground: Appearance.m3colors.m3surfaceContainerHigh
                        colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                        buttonRadius: 0
                        topLeftRadius: autoScaleCard.rTopLeft
                        topRightRadius: autoScaleCard.rTopRight
                        bottomLeftRadius: autoScaleCard.rBottomLeft
                        bottomRightRadius: autoScaleCard.rBottomRight
                        onClicked: {
                            if (Config.ready && Config.options.appearance) {
                                Config.options.appearance.autoScale = !Config.options.appearance.autoScale;
                            }
                        }

                        StyledToolTip {
                            extraVisibleCondition: parent.hovered || parent.realHovered
                            text: I18nService.tr("Adjust interface size automatically based on display resolution")
                        }
                    }

                    RowLayout {
                        id: autoScaleRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "fit_screen"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Automatic Scaling")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        AndroidToggle {
                            checked: Config.ready && Config.options.appearance ? Config.options.appearance.autoScale : true
                            onToggled: {
                                if (Config.ready && Config.options.appearance) {
                                    Config.options.appearance.autoScale = !Config.options.appearance.autoScale;
                                }
                            }
                        }
                    }
                }

                // Manual Scale Stepper (Separated)
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, manualScaleRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    enabled: Config.ready && Config.options.appearance ? !Config.options.appearance.autoScale : false
                    opacity: enabled ? 1 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MouseArea {
                        id: manualScaleHoverArea
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        hoverEnabled: true
                        StyledToolTip {
                            extraVisibleCondition: false
                            alternativeVisibleCondition: manualScaleHoverArea.containsMouse
                            text: I18nService.tr("Set interface scale manually")
                        }
                    }

                    RowLayout {
                        id: manualScaleRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 16 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: "tune"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Manual Scale")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }

                        StyledStepper {
                            from: 0.5
                            to: 2.0
                            stepSize: 0.05
                            displayFactor: 100
                            decimals: 0
                            suffix: "%"
                            value: Config.ready && Config.options.appearance ? Config.options.appearance.globalScale : 1.0
                            onValueChanged: if (Config.ready && Config.options.appearance) Config.options.appearance.globalScale = value
                        }
                    }
                }
            }

            // ── Eye Care Section ──
            DisplayEyeCare { Layout.fillWidth: true }

            Item { Layout.fillHeight: true }
        }
    }

    // ── Revert Confirmation Popup ──
    PanelWindow {
        id: revertPopup

        property int countdown: 15
        property bool active: false

        signal confirmed()
        signal reverted()

        visible: active
        color: "transparent"

        screen: Quickshell.screens[0]
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nandoroid:displayrevert"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        exclusionMode: ExclusionMode.Ignore

        // Block interactions with background
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {}
        }

        // Dim background
        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colScrim
            opacity: revertPopup.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Timer {
            id: countdownTimer
            interval: 1000
            repeat: true
            running: revertPopup.active
            onTriggered: {
                revertPopup.countdown--;
                if (revertPopup.countdown <= 0) {
                    revertPopup.reverted();
                    revertPopup.active = false;
                }
            }
        }

        onActiveChanged: {
            if (active) {
                revertPopup.countdown = 15;
                countdownTimer.start();
            } else {
                countdownTimer.stop();
            }
        }

        // Modal Content
        Rectangle {
            id: modal
            anchors.centerIn: parent
            width: 380 * Appearance.effectiveScale
            height: contentCol.implicitHeight + (48 * Appearance.effectiveScale)
            radius: Appearance.rounding.card
            color: Appearance.m3colors.m3surfaceContainerHigh

            // Shadow
            StyledRectangularShadow {
                target: parent
                z: -1
                offset: Qt.vector2d(0, 8 * Appearance.effectiveScale)
                blur: 20 * Appearance.effectiveScale
                color: Qt.rgba(0, 0, 0, 0.3)
            }

            ColumnLayout {
                id: contentCol
                anchors.centerIn: parent
                width: parent.width - (48 * Appearance.effectiveScale)
                spacing: 24 * Appearance.effectiveScale

                // Icon
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "monitor"
                    iconSize: 32 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        Layout.fillWidth: true
                        text: I18nService.tr("Keep these display settings?")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: I18nService.tr("Changes will be reverted in ") + revertPopup.countdown + I18nService.tr(" seconds.")
                        font.pixelSize: Appearance.font.pixelSize.small
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 24 * Appearance.effectiveScale
                    spacing: 12 * Appearance.effectiveScale

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        Layout.preferredWidth: 100 * Appearance.effectiveScale
                        Layout.preferredHeight: 40 * Appearance.effectiveScale
                        buttonRadius: Appearance.rounding.button
                        buttonText: I18nService.tr("Revert")
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        colText: Appearance.m3colors.m3onSurface
                        onClicked: {
                            revertPopup.reverted();
                            revertPopup.active = false;
                        }
                    }

                    RippleButton {
                        Layout.preferredHeight: 40 * Appearance.effectiveScale
                        Layout.minimumWidth: 110 * Appearance.effectiveScale
                        Layout.leftMargin: 8 * Appearance.effectiveScale
                        buttonRadius: Appearance.rounding.button
                        buttonText: I18nService.tr("Keep changes")
                        colBackground: Appearance.colors.colPrimary
                        colText: Appearance.colors.colOnPrimary
                        onClicked: {
                            revertPopup.confirmed();
                            revertPopup.active = false;
                        }
                    }
                }
            }
        }
        onConfirmed: root.confirmChanges()
        onReverted: root.revertChanges()
    }
}
