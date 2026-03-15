import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

Item {
    id: root

    required property int workspaceId
    required property real workspaceWidth
    required property real workspaceHeight
    required property real workspacePadding
    required property real scale_
    required property int monitorId
    required property var monitorData
    required property string barPosition
    required property int barReserved
    required property var windowList
    required property bool isActive
    required property color activeBorderColor
    property string focusedWindowAddress: ""
    property string searchQuery: ""
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property Item dragOverlay: null
    property Item overviewRoot: null

    // Callbacks for search matching (set by parent)
    property var checkWindowMatched: function (addr) {
        return false;
    }
    property var checkWindowSelected: function (addr) {
        return false;
    }

    implicitWidth: workspaceWidth
    implicitHeight: workspaceHeight

    // The viewport (monitor area) is the center third of the workspace
    readonly property real viewportWidth: workspaceWidth / 3
    readonly property real viewportOffset: viewportWidth  // Offset to center third

    // Filter windows for this workspace and monitor
    readonly property var workspaceWindows: {
        return windowList.filter(win => {
            return win?.workspace?.id === workspaceId && win.monitor === monitorId;
        });
    }

    // Calculate content bounds based on actual window positions
    // Windows are positioned relative to monitor, scaled, then offset by viewportOffset
    readonly property var contentBounds: {
        if (workspaceWindows.length === 0) {
            return {
                minX: 0,
                maxX: 0,
                hasOverflow: false
            };
        }

        let minX = Infinity;
        let maxX = -Infinity;

        for (const win of workspaceWindows) {
            // Calculate window position the same way as in the delegate
            let baseX = (win?.at?.[0] || 0) - (monitorData?.x || 0);
            if (barPosition === "left")
                baseX -= barReserved;
            const scaledX = baseX * scale_;
            const winWidth = (win?.size?.[0] || 100) * scale_;

            minX = Math.min(minX, scaledX);
            maxX = Math.max(maxX, scaledX + winWidth);
        }

        // The full workspace width is 3x viewport (workspaceWidth = viewportWidth * 3)
        // Content in local coords spans from minX to maxX
        // The full scrollable area in local coords is [-viewportWidth, 2*viewportWidth]
        // Overflow exists only if content extends beyond the full workspace width
        const hasOverflow = minX < -viewportWidth || maxX > (viewportWidth * 2);

        return {
            minX,
            maxX,
            hasOverflow
        };
    }

    // Calculate scroll limits based on content
    // We want to allow scrolling so that all content can be brought into view
    readonly property real maxHorizontalScroll: {
        if (!contentBounds.hasOverflow)
            return 0;
        // If content extends to the right (maxX > viewportWidth), we need negative scroll to see it
        // maxX - viewportWidth is how much we need to scroll left (negative offset)
        return Math.max(0, -contentBounds.minX);
    }
    readonly property real minHorizontalScroll: {
        if (!contentBounds.hasOverflow)
            return 0;
        // If content extends to the left (minX < 0), we need positive scroll to see it
        return Math.min(0, viewportWidth - contentBounds.maxX);
    }

    // Horizontal scroll state
    property real horizontalScrollOffset: 0
    property bool isScrollDragging: false  // Track if any right-click drag is active
    property bool isWheelScrolling: false  // Track if wheel is being used

    // Timer to reset wheel scrolling state after a brief pause
    Timer {
        id: wheelScrollTimer
        interval: 150
        onTriggered: root.isWheelScrolling = false
    }

    // Reset scroll when windows change (added, removed, or moved)
    onWorkspaceWindowsChanged: resetScroll()
    onContentBoundsChanged: {
        // If no overflow, ensure we're at center (0)
        if (!contentBounds.hasOverflow && horizontalScrollOffset !== 0) {
            horizontalScrollOffset = 0;
        }
    }

    function resetScroll() {
        horizontalScrollOffset = 0;
    }

    Behavior on horizontalScrollOffset {
        enabled: 250 > 0 && !root.isScrollDragging && !root.isWheelScrolling
        NumberAnimation {
            duration: 250 / 2
            easing.type: Easing.OutQuart
        }
    }

    function clampHorizontalScroll(value) {
        if (!contentBounds.hasOverflow)
            return 0;
        return Math.max(minHorizontalScroll, Math.min(maxHorizontalScroll, value));
    }

    // Main workspace container
    Item {
        id: workspaceContainer
        anchors.fill: parent

        // Background layer (clipped)
        Item {
            id: backgroundLayer
            anchors.fill: parent
            clip: true

            // Wallpaper background
            Image {
                id: workspaceWallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: Config.options?.appearance?.background?.wallpaperPath || ""
            }
            
            // Mask the background to match rounding
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: backgroundLayer.width
                    height: backgroundLayer.height
                    radius: Appearance.rounding.verysmall
                }
            }
        }

        // Semi-transparent overlay
        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.verysmall
            color: Appearance.colors.colLayer0
            opacity: 0.3
        }

        // Border indicator for drag target
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: Appearance.rounding.verysmall
            border.width: root.draggingTargetWorkspace === root.workspaceId && root.draggingFromWorkspace !== root.workspaceId ? 2 : 0
            border.color: Appearance.m3colors.m3outline
            z: 100
        }

        // Windows container
        Item {
            id: windowsContainer
            anchors.fill: parent
            anchors.margins: root.workspacePadding

            // Horizontal scroll handler - right-click drag
            MouseArea {
                id: scrollArea
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                propagateComposedEvents: true

                property real dragStartX: 0
                property real scrollStartOffset: 0

                onPressed: mouse => {
                    if (mouse.button === Qt.RightButton && root.contentBounds.hasOverflow) {
                        dragStartX = mouse.x;
                        scrollStartOffset = root.horizontalScrollOffset;
                        root.isScrollDragging = true;
                        mouse.accepted = true;
                    } else {
                        mouse.accepted = false;
                    }
                }

                onPositionChanged: mouse => {
                    if (root.isScrollDragging && (mouse.buttons & Qt.RightButton)) {
                        const delta = mouse.x - dragStartX;
                        root.horizontalScrollOffset = root.clampHorizontalScroll(scrollStartOffset + delta);
                    }
                }

                onReleased: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.isScrollDragging = false;
                    }
                }

                onCanceled: {
                    root.isScrollDragging = false;
                }

                // Pass through clicks that we don't handle
                onClicked: mouse => mouse.accepted = false
            }

            // Wheel handler for Shift+scroll (horizontal scrolling)
            WheelHandler {
                id: wheelHandler
                acceptedModifiers: Qt.ShiftModifier
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    if (!root.contentBounds.hasOverflow)
                        return;
                    // Mark as wheel scrolling to disable animation
                    root.isWheelScrolling = true;
                    wheelScrollTimer.restart();
                    // Use vertical scroll delta for horizontal movement
                    const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    root.horizontalScrollOffset = root.clampHorizontalScroll(root.horizontalScrollOffset + delta);
                    event.accepted = true;
                }
            }

            // Double-click on empty space to switch workspace
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onDoubleTapped: {
                    Hyprland.dispatch(`workspace ${root.workspaceId}`);
                }
            }

            Repeater {
                model: root.workspaceWindows

                delegate: Item {
                    id: windowDelegate
                    required property var modelData

                    readonly property var windowData: modelData
                    readonly property var toplevel: {
                        const toplevels = ToplevelManager.toplevels.values;
                        return toplevels.find(t => `0x${t.HyprlandToplevel.address}` === windowData.address) || null;
                    }

                    // Override position tracking for immediate visual update
                    property real overrideBaseX: -1
                    property real overrideBaseY: -1
                    property bool useOverridePosition: false

                    // Alignment calculations
                    readonly property real xCenterOffset: {
                        if (!monitorData || !monitorData.reserved) return 0;
                        const left = monitorData.reserved[2];
                        const right = monitorData.reserved[3];
                        return - (left + right) / 2;
                    }

                    readonly property real yCenterOffset: {
                        if (!monitorData || !monitorData.reserved) return 0;
                        const top = monitorData.reserved[0];
                        const bottom = monitorData.reserved[1];
                        return - (top + bottom) / 2;
                    }

                    // Position calculations relative to center viewport
                    readonly property real baseX: {
                        if (useOverridePosition && overrideBaseX >= 0)
                            return overrideBaseX;
                        let base = (windowData?.at?.[0] || 0) - (monitorData?.x || 0);
                        return ((base + xCenterOffset) * scale_) + root.viewportOffset + root.horizontalScrollOffset;
                    }
                    readonly property real baseY: {
                        if (useOverridePosition && overrideBaseY >= 0)
                            return overrideBaseY;
                        let base = (windowData?.at?.[1] || 0) - (monitorData?.y || 0);
                        return Math.round(Math.max((base + yCenterOffset) * scale_, 0));
                    }
                    readonly property real targetWidth: Math.round((windowData?.size[0] || 100) * scale_)
                    readonly property real targetHeight: Math.round((windowData?.size[1] || 100) * scale_)
                    readonly property bool compactMode: targetHeight < 60 || targetWidth < 60
                    readonly property string iconPath: AppSearch && typeof AppSearch.guessIcon === 'function' ? AppSearch.guessIcon(windowData?.class || "") : "application-x-executable"
                    readonly property int calculatedRadius: Appearance.rounding.small
                    readonly property bool isMatched: root.checkWindowMatched(windowData?.address)
                    readonly property bool isSelected: root.checkWindowSelected(windowData?.address)

                    x: baseX
                    y: baseY
                    width: targetWidth
                    height: targetHeight
                    z: dragging ? 1000 : 1

                    property bool hovered: false
                    property bool dragging: false
                    property real initX: baseX
                    property real initY: baseY
                    property Item originalParent: null
                    property point pressPos: Qt.point(0, 0)
                    readonly property real dragThreshold: 5

                    Drag.active: dragging
                    Drag.source: windowDelegate
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2

                    // Timer to reset override position after Hyprland update
                    Timer {
                        id: resetOverrideTimer
                        interval: 200
                        onTriggered: {
                            windowDelegate.useOverridePosition = false;
                        }
                    }

                    // Watch for windowData changes
                    onWindowDataChanged: {
                        if (useOverridePosition) {
                            resetOverrideTimer.restart();
                        }
                    }

                    Behavior on x {
                        enabled: 250 > 0 && !windowDelegate.dragging && !windowDelegate.useOverridePosition
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuart
                        }
                    }
                    Behavior on y {
                        enabled: 250 > 0 && !windowDelegate.dragging && !windowDelegate.useOverridePosition
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuart
                        }
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: windowDelegate.calculatedRadius
                        antialiasing: true
                        color: "transparent"
                        border.color: Appearance.colors.colBackground || "transparent"
                        border.width: 0
                        z: 2 // Place above fallback background to prevent Qt occlusion culling

                        ScreencopyView {
                            id: windowPreview
                            anchors.fill: parent
                            captureSource: GlobalStates.overviewOpen ? windowDelegate.toplevel : null
                            live: GlobalStates.overviewOpen
                            visible: true
                        }
                    }

                    // Background when no preview
                    Rectangle {
                        id: previewBackground
                        anchors.fill: parent
                        radius: windowDelegate.calculatedRadius
                        color: windowDelegate.dragging ? (Appearance.m3colors.m3surfaceBright || "transparent") : windowDelegate.hovered ? (Appearance.m3colors.m3surface || "transparent") : (Appearance.colors.colBackground || "transparent")
                        border.color: windowDelegate.isSelected ? Appearance.m3colors.m3tertiary : windowDelegate.isMatched ? Appearance.colors.colPrimary : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
                        border.width: windowDelegate.isSelected ? 3 : (windowDelegate.isMatched || windowDelegate.hovered ? 2 : 1)
                        visible: !windowPreview.hasContent
                        z: 0 // Keep behind preview

                        Behavior on color {
                            enabled: 250 > 0
                            ColorAnimation {
                                duration: 250 / 2
                            }
                        }
                    }

                    // Icon
                    Image {
                        mipmap: true
                        id: windowIcon
                        readonly property real iconSize: Math.round(Math.min(windowDelegate.targetWidth, windowDelegate.targetHeight) * (windowDelegate.compactMode ? 0.6 : 0.35))
                        anchors.centerIn: parent
                        width: iconSize
                        height: iconSize
                        source: Quickshell.iconPath(windowDelegate.iconPath, "application-x-executable")
                        sourceSize: Qt.size(iconSize, iconSize)
                        asynchronous: true
                        visible: !windowPreview.hasContent
                        z: 0 // Keep behind preview
                    }

                    // Overlay when preview is available (only show on interaction)
                    Rectangle {
                        id: previewOverlay
                        anchors.fill: parent
                        radius: windowDelegate.calculatedRadius
                        color: windowDelegate.dragging ? Qt.rgba(Appearance.m3colors.m3surfaceContainerHighest.r, Appearance.m3colors.m3surfaceContainerHighest.g, Appearance.m3colors.m3surfaceContainerHighest.b, 0.5) : windowDelegate.hovered ? Qt.rgba(Appearance.m3colors.m3surfaceContainer.r, Appearance.m3colors.m3surfaceContainer.g, Appearance.m3colors.m3surfaceContainer.b, 0.2) : "transparent"
                        border.color: windowDelegate.isSelected ? Appearance.m3colors.m3tertiary : windowDelegate.isMatched ? Appearance.colors.colPrimary : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
                        border.width: windowDelegate.isSelected ? 3 : (windowDelegate.isMatched || windowDelegate.hovered ? 2 : 1)
                        visible: windowPreview.hasContent && (windowDelegate.hovered || windowDelegate.dragging || windowDelegate.isMatched || windowDelegate.isSelected)
                        z: 5
                    }

                    // Corner icon when preview available
                    Image {
                        mipmap: true
                        visible: windowPreview.hasContent && !windowDelegate.compactMode
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: 4
                        width: 16
                        height: 16
                        source: Quickshell.iconPath(windowDelegate.iconPath, "application-x-executable")
                        sourceSize: Qt.size(16, 16)
                        asynchronous: true
                        opacity: 0.8
                        z: 10
                    }

                    // XWayland indicator
                    Rectangle {
                        visible: windowDelegate.windowData?.xwayland || false
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 2
                        width: 6
                        height: 6
                        radius: 3
                        color: Appearance.m3colors.m3error
                        z: 10
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        drag.target: windowDelegate.dragging ? windowDelegate : null
                        drag.threshold: 0

                        // Right-click drag state for horizontal scroll
                        property real rightDragStartX: 0
                        property real rightScrollStartOffset: 0

                        onEntered: windowDelegate.hovered = true
                        onExited: windowDelegate.hovered = false

                        onPressed: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                windowDelegate.pressPos = Qt.point(mouse.x, mouse.y);
                                windowDelegate.initX = windowDelegate.x;
                                windowDelegate.initY = windowDelegate.y;
                            } else if (mouse.button === Qt.RightButton && root.contentBounds.hasOverflow) {
                                rightDragStartX = mouse.x;
                                rightScrollStartOffset = root.horizontalScrollOffset;
                                root.isScrollDragging = true;
                            }
                        }

                        onPositionChanged: mouse => {
                            // Handle right-click drag for horizontal scroll
                            if (root.isScrollDragging && (mouse.buttons & Qt.RightButton) && root.contentBounds.hasOverflow) {
                                const delta = mouse.x - rightDragStartX;
                                root.horizontalScrollOffset = root.clampHorizontalScroll(rightScrollStartOffset + delta);
                                return;
                            }

                            if (!(mouse.buttons & Qt.LeftButton))
                                return;

                            // Check if we should start dragging
                            if (!windowDelegate.dragging) {
                                const dx = mouse.x - windowDelegate.pressPos.x;
                                const dy = mouse.y - windowDelegate.pressPos.y;
                                const distance = Math.sqrt(dx * dx + dy * dy);

                                if (distance > windowDelegate.dragThreshold) {
                                    // Start dragging
                                    windowDelegate.dragging = true;
                                    root.draggingFromWorkspace = root.workspaceId;

                                    // Reparent to drag overlay
                                    if (root.dragOverlay) {
                                        windowDelegate.originalParent = windowDelegate.parent;
                                        const globalPos = windowDelegate.mapToItem(root.dragOverlay, 0, 0);
                                        windowDelegate.parent = root.dragOverlay;
                                        windowDelegate.x = globalPos.x;
                                        windowDelegate.y = globalPos.y;
                                    }
                                }
                            } else {
                                // Update target workspace indicator while dragging
                                if (root.overviewRoot && root.overviewRoot.getWorkspaceAtY) {
                                    const globalPos = dragArea.mapToItem(null, mouse.x, mouse.y);
                                    const targetWs = root.overviewRoot.getWorkspaceAtY(globalPos.y);
                                    if (targetWs !== -1 && targetWs !== root.workspaceId) {
                                        root.draggingTargetWorkspace = targetWs;
                                    } else {
                                        root.draggingTargetWorkspace = -1;
                                    }
                                }
                            }
                        }

                        onReleased: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (windowDelegate.dragging) {
                                    windowDelegate.dragging = false;

                                    // Calculate target workspace from cursor position
                                    let targetWs = root.workspaceId; // Default to current workspace
                                    if (root.overviewRoot && root.overviewRoot.getWorkspaceAtY) {
                                        const globalPos = dragArea.mapToItem(null, mouse.x, mouse.y);
                                        const calculatedWs = root.overviewRoot.getWorkspaceAtY(globalPos.y);
                                        if (calculatedWs !== -1) {
                                            targetWs = calculatedWs;
                                        }
                                    }

                                    if (targetWs !== root.workspaceId) {
                                        // Moving to different workspace
                                        if (windowDelegate.windowData?.floating) {
                                            // Calculate position for floating window in target workspace
                                            const draggedX = windowDelegate.x;
                                            const draggedY = windowDelegate.y;
                                            
                                            const workspaceGlobalPos = windowsContainer.mapToItem(root.dragOverlay, 0, 0);
                                            const relativeX = draggedX - workspaceGlobalPos.x;
                                            const relativeY = draggedY - workspaceGlobalPos.y;
                                            
                                            const workspaceX = relativeX - root.horizontalScrollOffset - root.viewportOffset;
                                            const workspaceY = relativeY;
                                            
                                            const monitorWidth = (monitorData?.width || 1920) / (monitorData?.scale || 1.0);
                                            const monitorHeight = (monitorData?.height || 1080) / (monitorData?.scale || 1.0);
                                            
                                            let adjustedMonitorWidth = monitorWidth;
                                            let adjustedMonitorHeight = monitorHeight;
                                            if (barPosition === "left" || barPosition === "right") {
                                                adjustedMonitorWidth -= barReserved;
                                            }
                                            if (barPosition === "top" || barPosition === "bottom") {
                                                adjustedMonitorHeight -= barReserved;
                                            }
                                            
                                            const actualX = workspaceX / scale_;
                                            const actualY = workspaceY / scale_;
                                            
                                            const percentageX = Math.round((actualX / adjustedMonitorWidth) * 100);
                                            const percentageY = Math.round((actualY / adjustedMonitorHeight) * 100);
                                            
                                            // Move to workspace and set position
                                            Hyprland.dispatch(`movetoworkspacesilent ${targetWs}, address:${windowDelegate.windowData?.address}`);
                                            Hyprland.dispatch(`movewindowpixel exact ${percentageX}% ${percentageY}%, address:${windowDelegate.windowData?.address}`);
                                            
                                            // Force immediate window data update
                                            HyprlandData.updateWindowList();
                                        } else {
                                            // Just move workspace without repositioning for tiled windows
                                            Hyprland.dispatch(`movetoworkspacesilent ${targetWs}, address:${windowDelegate.windowData?.address}`);
                                            
                                            // Force immediate window data update
                                            HyprlandData.updateWindowList();
                                        }
                                        
                                        // Restore original parent and reset position
                                        if (windowDelegate.originalParent) {
                                            windowDelegate.parent = windowDelegate.originalParent;
                                            windowDelegate.originalParent = null;
                                        }
                                        windowDelegate.x = windowDelegate.initX;
                                        windowDelegate.y = windowDelegate.initY;
                                        
                                    } else if (windowDelegate.windowData?.floating && (windowDelegate.x !== windowDelegate.initX || windowDelegate.y !== windowDelegate.initY)) {
                                        // Dropped on same workspace and window is floating - reposition it
                                        // The window is currently in the drag overlay with global coordinates
                                        
                                        // Store current drag position
                                        const draggedX = windowDelegate.x;
                                        const draggedY = windowDelegate.y;
                                        
                                        // Get the workspace container position
                                        const workspaceGlobalPos = windowsContainer.mapToItem(root.dragOverlay, 0, 0);
                                        
                                        // Calculate position relative to workspace
                                        const relativeX = draggedX - workspaceGlobalPos.x;
                                        const relativeY = draggedY - workspaceGlobalPos.y;
                                        
                                        // Remove horizontal scroll offset to get actual position in workspace
                                        const workspaceX = relativeX - root.horizontalScrollOffset - root.viewportOffset;
                                        const workspaceY = relativeY;
                                        
                                        // Convert to percentage of workspace dimensions (in scaled space)
                                        const monitorWidth = (monitorData?.width || 1920) / (monitorData?.scale || 1.0);
                                        const monitorHeight = (monitorData?.height || 1080) / (monitorData?.scale || 1.0);
                                        
                                        // Adjust for bar reserved space
                                        let adjustedMonitorWidth = monitorWidth;
                                        let adjustedMonitorHeight = monitorHeight;
                                        if (barPosition === "left" || barPosition === "right") {
                                            adjustedMonitorWidth -= barReserved;
                                        }
                                        if (barPosition === "top" || barPosition === "bottom") {
                                            adjustedMonitorHeight -= barReserved;
                                        }
                                        
                                        // Convert from scaled overview space to actual position
                                        const actualX = workspaceX / scale_;
                                        const actualY = workspaceY / scale_;
                                        
                                        // Calculate percentage
                                        const percentageX = Math.round((actualX / adjustedMonitorWidth) * 100);
                                        const percentageY = Math.round((actualY / adjustedMonitorHeight) * 100);
                                        
                                        // Dispatch movewindowpixel command
                                        Hyprland.dispatch(`movewindowpixel exact ${percentageX}% ${percentageY}%, address:${windowDelegate.windowData?.address}`);
                                        
                                        // Force immediate window data update
                                        HyprlandData.updateWindowList();
                                        
                                        // Restore original parent
                                        if (windowDelegate.originalParent) {
                                            windowDelegate.parent = windowDelegate.originalParent;
                                            windowDelegate.originalParent = null;
                                        }
                                        
                                        // Set override position for immediate visual update
                                        // Calculate what baseX/baseY should be at the dropped position
                                        windowDelegate.overrideBaseX = relativeX;
                                        windowDelegate.overrideBaseY = relativeY;
                                        windowDelegate.useOverridePosition = true;
                                        
                                        // Force position to dropped location
                                        windowDelegate.x = relativeX;
                                        windowDelegate.y = relativeY;
                                        
                                        // Start timer to clear override
                                        resetOverrideTimer.restart();
                                    } else {
                                        // Not a floating window or didn't move - restore original parent and position
                                        if (windowDelegate.originalParent) {
                                            windowDelegate.parent = windowDelegate.originalParent;
                                            windowDelegate.originalParent = null;
                                        }
                                        windowDelegate.x = windowDelegate.initX;
                                        windowDelegate.y = windowDelegate.initY;
                                    }

                                    root.draggingFromWorkspace = -1;
                                    root.draggingTargetWorkspace = -1;
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                root.isScrollDragging = false;
                            }
                        }

                        onClicked: mouse => {
                            if (!windowDelegate.windowData)
                                return;
                            if (mouse.button === Qt.LeftButton && !windowDelegate.dragging) {
                                Hyprland.dispatch(`focuswindow address:${windowDelegate.windowData.address}`);
                            } else if (mouse.button === Qt.MiddleButton) {
                                Hyprland.dispatch(`closewindow address:${windowDelegate.windowData.address}`);
                            }
                        }

                        onDoubleClicked: mouse => {
                            if (!windowDelegate.windowData)
                                return;
                            if (mouse.button === Qt.LeftButton) {
                                GlobalStates.closeAllPanels();
                                Qt.callLater(() => {
                                    Hyprland.dispatch(`focuswindow address:${windowDelegate.windowData.address}`);
                                });
                            }
                        }
                    }

                    // Tooltip
                    ToolTip {
                        id: scrollWindowTooltip
                        visible: dragArea.containsMouse && !windowDelegate.dragging && windowDelegate.windowData
                        delay: 300
                        padding: 8
                        y: -height - 8
                        x: (parent.width - width) / 2
                        text: `${windowDelegate.windowData?.title || ""}\n[${windowDelegate.windowData?.class || ""}]${windowDelegate.windowData?.xwayland ? " [XWayland]" : ""}`

                        contentItem: StyledText {
                            text: scrollWindowTooltip.text
                            color: Appearance.m3colors.m3onSurface
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.NoWrap
                        }

                        background: Rectangle {
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            radius: 8
                            border.color: Appearance.m3colors.m3outlineVariant
                            border.width: 1
                        }
                    }
                }
            }
        }
    }
}
