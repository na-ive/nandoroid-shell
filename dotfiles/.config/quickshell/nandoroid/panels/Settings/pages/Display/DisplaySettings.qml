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
    property bool isDraggingBrightness: false
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
    readonly property bool hasPendingChanges: Object.keys(stagedChanges).length > 0

    function setStagedChange(monitorName, property, value) {
        let changes = JSON.parse(JSON.stringify(stagedChanges));
        if (!changes[monitorName]) changes[monitorName] = {};
        changes[monitorName][property] = value;
        stagedChanges = changes;
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
    }

    function revertChanges() {
        DisplayService.batchApply(root.previousState);
        root.stagedChanges = {};
    }

    Flickable {
        id: mainFlickable
        anchors.fill: parent
        contentHeight: mainCol.implicitHeight + 48
        clip: true
        ScrollBar.vertical: StyledScrollBar {}

        ColumnLayout {
            id: mainCol
            width: parent.width
            spacing: 32

        // ── Header ──
        ColumnLayout {
            spacing: 4
            StyledText {
                text: "Display"
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: "Configure your monitors, visual comfort, and layout."
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Monitor Layout Visualization (Selector & Drag-n-Drop) ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "layers"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: {
                        let base = "Monitor Layout";
                        if (root.monitorList.length > 1) {
                            base += " (" + root.monitorList.length + " detected)";
                        }
                        return base;
                    }
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }
                
                StyledText {
                    text: "Layout visualization"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    visible: root.monitorList.length > 1
                }
            }
            // ── Monitor Layout Visualization (Selector) ──
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: 320
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                // Grid Background
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    clip: true
                    radius: 20
                    
                    Canvas {
                        id: vizCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.strokeStyle = Appearance.m3colors.m3outlineVariant;
                            ctx.lineWidth = 0.5;
                            ctx.globalAlpha = 0.15;
                            for (var x = 0; x <= width; x += 40) {
                                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke();
                            }
                            for (var y = 0; y <= height; y += 40) {
                                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                            }
                        }
                    }
                }

                // Monitor Representation
                Item {
                    id: monitorContainer
                    anchors.fill: parent
                    anchors.margins: 40
                    
                    readonly property real vizScale: {
                        const m = root.monitorList;
                        if (m.length === 0) return 10;
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
                        return Math.max(10, Math.max(maxX - minX, maxY - minY) / 240);
                    }
                    
                    readonly property var bounds: {
                        const m = root.monitorList;
                        if (m.length === 0) return { centerX: 1920, centerY: 1080 };
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
                        return { centerX: minX + (maxX - minX)/2, centerY: minY + (maxY - minY)/2 };
                    }

                    Repeater {
                        model: root.monitorList
                        delegate: Rectangle {
                            id: monRect
                            width: modelData.width / monitorContainer.vizScale
                            height: modelData.height / monitorContainer.vizScale
                            
                            // Target position (dynamic binding with staged changes support)
                            x: {
                                let targetX = modelData.x;
                                const sj = root.stagedChanges[modelData.name];
                                if (sj && sj.x !== undefined) targetX = sj.x;
                                return (monitorContainer.width / 2) + ((targetX - monitorContainer.bounds.centerX) / monitorContainer.vizScale);
                            }
                            y: {
                                let targetY = modelData.y;
                                const sj = root.stagedChanges[modelData.name];
                                if (sj && sj.y !== undefined) targetY = sj.y;
                                return (monitorContainer.height / 2) + ((targetY - monitorContainer.bounds.centerY) / monitorContainer.vizScale);
                            }
                            
                            radius: 16
                            color: root.currentMonitorIndex === index ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerLow
                            border.color: root.currentMonitorIndex === index ? Appearance.colors.colPrimary : Appearance.m3colors.m3outline
                            border.width: 1.5
                            
                            Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                            Behavior on color { ColorAnimation { duration: 250 } }
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.color: root.currentMonitorIndex === index ? "white" : "transparent"
                                border.width: 2
                                opacity: 0.3
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignCenter
                                    text: index === 0 ? "home" : "monitor"
                                    iconSize: Math.min(24, monRect.height * 0.4)
                                    color: root.currentMonitorIndex === index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                                }
                                StyledText {
                                    text: index === 0 ? "Main" : "" + (index + 1)
                                    Layout.alignment: Qt.AlignCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: 10
                                    font.weight: Font.Black
                                    color: root.currentMonitorIndex === index ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurface
                                    visible: monRect.height > 25
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
            spacing: 4 // Match Eye Care / ServicesSettings
            visible: root.currentMonitorIndex !== 0 && root.monitorList.length > 1
                
                // Arrangement Presets
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: arrangeRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    smallRadius: 8
                    fullRadius: 20
                    
                    RowLayout {
                        id: arrangeRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        ColumnLayout {
                            spacing: 0
                            StyledText {
                                text: "Physical Arrangement"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Position relative to Main"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 4
                            Repeater {
                                model: [
                                    { label: "Left", icon: "arrow_back" },
                                    { label: "Right", icon: "arrow_forward" },
                                    { label: "Above", icon: "arrow_upward" },
                                    { label: "Below", icon: "arrow_downward" }
                                ]
                                delegate: SegmentedButton {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 32
                                    colActive: Appearance.colors.colPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    isHighlighted: false
                                    iconName: modelData.icon
                                    iconSize: 18
                                    
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
                                        
                                        DisplayService.applyMonitorSettings(
                                            cur.name, 
                                            cur.currentResolution, 
                                            nx + "x" + ny, 
                                            cur.scale, 
                                            cur.transform
                                        );
                                        
                                        // Clear just the position from staged changes after a small delay
                                        // or let the user confirm. Actually, since it's auto-apply,
                                        // we should probably clear it when the system confirms.
                                        // For now, let's keep it in stagedChanges so it stays moved.
                                    }
                                }
                            }
                        }
                    }
                }

                // Mirroring
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: mirrorRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    smallRadius: 8
                    fullRadius: 20
                    
                    RowLayout {
                        id: mirrorRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        ColumnLayout {
                            spacing: 0
                            StyledText {
                                text: "Mirror Display"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Duplicate Main content"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 48
                            implicitHeight: 26
                            radius: 13
                            readonly property bool isMirroring: {
                                if (!root.currentMonitor) return false;
                                const sj = root.stagedChanges[root.currentMonitor.name];
                                if (sj && sj.mirror !== undefined) return sj.mirror !== "";
                                return root.currentMonitor.mirror !== "" && root.currentMonitor.mirror !== undefined && root.currentMonitor.mirror.length > 0;
                            }
                            color: isMirroring ? Appearance.colors.colPrimary : Appearance.m3colors.m3surfaceContainerLowest

                            Rectangle {
                                width: 18
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.isMirroring ? parent.width - width - 4 : 4
                                color: parent.isMirroring ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (parent.isMirroring) {
                                        root.setStagedChange(root.currentMonitor.name, "mirror", "");
                                        root.setStagedChange(root.currentMonitor.name, "resolution", "preferred");
                                    } else {
                                        const main = root.monitorList[0];
                                        if (main) root.setStagedChange(root.currentMonitor.name, "mirror", main.name);
                                    }
                                }
                            }
                        }
                    }
                }

                // Primary Display (Set as Main)
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: primaryRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    smallRadius: 8
                    fullRadius: 20
                    visible: root.currentMonitorIndex !== 0
                    
                    RowLayout {
                        id: primaryRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20
                        
                        ColumnLayout {
                            spacing: 0
                            StyledText {
                                text: "Primary Display"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Switch primary monitor"
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }

                        RippleButton {
                            implicitWidth: 100
                            implicitHeight: 32
                            buttonRadius: 16
                            buttonText: "Set Main"
                            Layout.alignment: Qt.AlignVCenter
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

        // Eye Care (Night Light) moved to bottom

        // ── Selected Monitor Settings ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 // Match Eye Care / ServicesSettings
            visible: root.currentMonitor !== null
            
            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8 // Space from header to first card
                MaterialSymbol {
                    text: "settings_input_component"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                    Layout.alignment: Qt.AlignVCenter
                }
                StyledText {
                    text: {
                        if (!root.currentMonitor) return "Monitor Configuration";
                        let desc = root.currentMonitor.description || root.currentMonitor.name;
                        return "Monitor " + (root.currentMonitorIndex + 1) + ": " + desc;
                    }
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                }
                
                // ── Apply/Cancel Buttons moved here ──
                RowLayout {
                    spacing: 16
                    opacity: root.hasPendingChanges ? 1 : 0
                    enabled: root.hasPendingChanges
                    Layout.alignment: Qt.AlignVCenter
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    
                    MouseArea {
                        width: cancelText.implicitWidth
                        height: 32
                        cursorShape: Qt.PointingHandCursor
                        StyledText {
                            id: cancelText
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            color: Appearance.colors.colSubtext
                        }
                        onClicked: root.stagedChanges = {}
                    }
                    
                    MouseArea {
                        width: applyText.implicitWidth
                        height: 32
                        cursorShape: Qt.PointingHandCursor
                        StyledText {
                            id: applyText
                            anchors.centerIn: parent
                            text: "Apply"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            color: Appearance.colors.colPrimary
                        }
                        onClicked: root.applyChanges()
                    }
                }
            }

            // Arrangement & Mirroring logic moved to Layout section

            // Resolution
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: resRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: resRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Resolution & Refresh"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: {
                                if (!root.currentMonitor) return "";
                                const sj = root.stagedChanges[root.currentMonitor.name];
                                if (sj && sj.resolution) return root.currentMonitor.name + " @ Stage: " + sj.resolution;
                                return root.currentMonitor.name + " @ " + Math.round(root.currentMonitor.refreshRate) + "Hz";
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }

                    StyledComboBox {
                        id: resCombo
                        implicitWidth: 260
                        
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
                implicitHeight: scaleRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: scaleRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Display Scaling"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Adjust text and UI size."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4
                        Repeater {
                            model: [1.0, 1.25, 1.5, 2.0]
                            delegate: SegmentedButton {
                                buttonText: (modelData * 100) + "%"
                                isHighlighted: {
                                    if (!root.currentMonitor) return false;
                                    const sj = root.stagedChanges[root.currentMonitor.name];
                                    if (sj && sj.scale !== undefined) return Math.abs(sj.scale - modelData) < 0.01;
                                    return Math.abs(parseFloat(root.currentMonitor.scale || 1.0) - modelData) < 0.01;
                                }
                                Layout.preferredHeight: 36
                                leftPadding: 16
                                rightPadding: 16
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
                implicitHeight: orientRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: orientRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20
                    
                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Orientation"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Rotate the screen content."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4
                        Repeater {
                            model: [
                                { label: "Normal", value: 0 },
                                { label: "90°", value: 1 },
                                { label: "180°", value: 2 },
                                { label: "270°", value: 3 }
                            ]
                            delegate: SegmentedButton {
                                buttonText: modelData.label
                                isHighlighted: {
                                    if (!root.currentMonitor) return false;
                                    const sj = root.stagedChanges[root.currentMonitor.name];
                                    if (sj && sj.transform !== undefined) return sj.transform === modelData.value;
                                    return (root.currentMonitor.transform || 0) === modelData.value;
                                }
                                Layout.preferredHeight: 36
                                leftPadding: 16
                                rightPadding: 16
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
                implicitHeight: brightCol.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                ColumnLayout {
                    id: brightCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12
                    
                    property var mon: root.currentMonitor ? Brightness.getMonitorByName(root.currentMonitor.name) : null

                    RowLayout {
                        width: parent.width
                        StyledText {
                            text: "Brightness"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: brightCol.mon ? Math.round(brightCol.mon.multipliedBrightness * 100) + "%" : "N/A"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colPrimary
                        }
                    }

                    StyledSlider {
                        Layout.fillWidth: true
                        from: 0.0
                        to: 1.0
                        stepSize: 0.01
                        value: brightCol.mon ? brightCol.mon.brightness : 0.5
                        configuration: StyledSlider.Configuration.M
                        onPressedChanged: {
                            if (!pressed) {
                                // Small delay to allow the last update to settle
                                timerRelease.restart();
                            } else {
                                root.isDraggingBrightness = true;
                            }
                        }
                        
                        Timer {
                            id: timerRelease
                            interval: 100
                            onTriggered: root.isDraggingBrightness = false
                        }

                        onMoved: {
                            if (brightCol.mon) brightCol.mon.setBrightness(value);
                        }
                        
                        // Prevent the value from updating via binding while dragging
                        Binding on value {
                            when: !root.isDraggingBrightness && brightCol.mon !== null
                            value: brightCol.mon ? brightCol.mon.brightness : 0.5
                            restoreMode: Binding.RestoreBindingOrValue
                        }
                    }
                }
            }
        }

        // ── Eye Care Section (Moved here) ──
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
            width: 380
            height: contentCol.implicitHeight + 48
            radius: Appearance.rounding.card
            color: Appearance.m3colors.m3surfaceContainerHigh
            
            // Shadow
            StyledRectangularShadow {
                target: parent
                z: -1
                offset: Qt.vector2d(0, 8)
                blur: 20
                color: Qt.rgba(0, 0, 0, 0.3)
            }

            ColumnLayout {
                id: contentCol
                anchors.centerIn: parent
                width: parent.width - 48
                spacing: 24

                // Icon
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "monitor"
                    iconSize: 32
                    color: Appearance.colors.colPrimary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: "Keep these display settings?"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.m3colors.m3onSurface
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: "Changes will be reverted in " + revertPopup.countdown + " seconds."
                        font.pixelSize: Appearance.font.pixelSize.small
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.m3colors.m3onSurfaceVariant
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    spacing: 12

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 40
                        buttonRadius: Appearance.rounding.button
                        buttonText: "Revert"
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        colText: Appearance.m3colors.m3onSurface
                        onClicked: {
                            revertPopup.reverted();
                            revertPopup.active = false;
                        }
                    }

                    RippleButton {
                        Layout.preferredHeight: 40
                        Layout.minimumWidth: 110
                        Layout.leftMargin: 8
                        buttonRadius: Appearance.rounding.button
                        buttonText: "Keep changes"
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
