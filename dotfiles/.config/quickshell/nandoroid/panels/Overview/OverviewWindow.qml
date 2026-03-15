pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
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

    property var windowData
    property var toplevel
    property var monitorData: null
    property real scale
    property real availableWorkspaceWidth
    property real availableWorkspaceHeight
    property real xOffset: 0
    property real yOffset: 0
    property Item overviewRoot: null

    // Alignment calculations
    readonly property real yReservedOffset: {
        if (!monitorData || !monitorData.reserved) return 0;
        return monitorData.reserved[0]; // Top reserved space
    }

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
        // Center by shifting opposite of the average of reserved spaces
        return - (top + bottom) / 2;
    }

    property bool hovered: false
    property bool pressed: false
    property bool atInitPosition: (initX == x && initY == y)

    property string barPosition: "top"
    property int barReserved: 0

    // Search highlighting
    property bool isSearchMatch: false
    property bool isSearchSelected: false

    // Override position tracking for immediate visual update
    property real overrideX: -1
    property real overrideY: -1
    property bool useOverridePosition: false

    // Cache calculated values
    readonly property real initX: {
        if (useOverridePosition && overrideX >= 0)
            return overrideX;

        let base = (windowData?.at?.[0] || 0) - (monitorData?.x || 0);
        return Math.round(Math.max((base + xCenterOffset) * scale, 0) + xOffset);
    }
    readonly property real initY: {
        if (useOverridePosition && overrideY >= 0)
            return overrideY;
        let base = (windowData?.at?.[1] || 0) - (monitorData?.y || 0);
        return Math.round(Math.max((base + yCenterOffset) * scale, 0) + yOffset);
    }
    readonly property real targetWindowWidth: Math.round((windowData?.size[0] || 100) * scale)
    readonly property real targetWindowHeight: Math.round((windowData?.size[1] || 100) * scale)
    readonly property bool compactMode: targetWindowHeight < 60 || targetWindowWidth < 60
    readonly property string iconPath: AppSearch && typeof AppSearch.guessIcon === 'function' ? AppSearch.guessIcon(windowData?.class || "") : "application-x-executable"
    readonly property int calculatedRadius: Appearance.rounding.small

    signal dragStarted
    signal dragFinished(int targetWorkspace)
    signal windowClicked
    signal windowClosed

    x: initX
    y: initY
    width: targetWindowWidth
    height: targetWindowHeight
    z: atInitPosition ? 1 : 99999

    Drag.active: root.pressed
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    clip: true

    // Timer to reset override position after a delay (waiting for Hyprland update)
    Timer {
        id: resetOverrideTimer
        interval: 200
        onTriggered: {
            root.useOverridePosition = false;
        }
    }

    // Watch for windowData changes to reset override when real data updates
    onWindowDataChanged: {
        if (useOverridePosition) {
            resetOverrideTimer.restart();
        }
    }

    Behavior on x {
        enabled: 250 > 0 && !root.useOverridePosition
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }
    Behavior on y {
        enabled: 250 > 0 && !root.useOverridePosition
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }
    Behavior on width {
        enabled: 250 > 0
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }
    Behavior on height {
        enabled: 250 > 0
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutQuart
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.calculatedRadius
        antialiasing: true
        border.color: Appearance.colors.colLayer0
        border.width: 0
        z: 2

        ScreencopyView {
            id: windowPreview
            anchors.fill: parent
            captureSource: (GlobalStates.overviewOpen && root.toplevel && root.toplevel.HyprlandToplevel) ? root.toplevel : null
            live: GlobalStates.overviewOpen
            visible: true
        }
    }

    // Background rectangle with rounded corners
    Rectangle {
        id: previewBackground
        anchors.fill: parent
        radius: root.calculatedRadius
        color: pressed ? Appearance.colors.colLayer1Active : hovered ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
        border.color: root.isSearchSelected ? Appearance.m3colors.m3tertiary : root.isSearchMatch ? Appearance.colors.colPrimary : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
        border.width: root.isSearchSelected ? 3 : (root.isSearchMatch || hovered ? 2 : 1)
        visible: !windowPreview.hasContent
        z: 0

        Behavior on color {
            enabled: 250 > 0
            ColorAnimation {
                duration: 250 / 2
            }
        }

        Behavior on border.width {
            enabled: 250 > 0
            NumberAnimation {
                duration: 250 / 2
            }
        }
    }

    // Overlay content when preview is not available
    Image {
        mipmap: true
        id: windowIcon
        readonly property real iconSize: Math.round(Math.min(root.targetWindowWidth, root.targetWindowHeight) * (root.compactMode ? 0.6 : 0.35))
        anchors.centerIn: parent
        width: iconSize
        height: iconSize
        source: Quickshell.iconPath(root.iconPath, "application-x-executable")
        sourceSize: Qt.size(iconSize, iconSize)
        asynchronous: true
        visible: !windowPreview.hasContent
        z: 0
    }

    // Overlay border and effects when preview is available
    Rectangle {
        id: previewOverlay
        anchors.fill: parent
        radius: root.calculatedRadius
        color: pressed ? Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer1Active, 0.5) : hovered ? Functions.ColorUtils.applyAlpha(Appearance.colors.colLayer1Hover, 0.4) : "transparent"
        border.color: root.isSearchSelected ? Appearance.m3colors.m3tertiary : root.isSearchMatch ? Appearance.colors.colPrimary : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
        border.width: root.isSearchSelected ? 3 : (root.isSearchMatch || hovered ? 2 : 1)
        visible: windowPreview.hasContent
        z: 5

        Behavior on border.width {
            enabled: 250 > 0
            NumberAnimation {
                duration: 250 / 2
            }
        }
    }

    // Search match glow effect
    Rectangle {
        visible: root.isSearchSelected && !root.Drag.active
        anchors.fill: parent
        anchors.margins: -4
        radius: root.calculatedRadius + 4
        color: "transparent"
        border.color: Appearance.m3colors.m3tertiary
        border.width: 2
        opacity: 0.6
        z: -1
    }

    // Overlay icon when preview is available (smaller, in corner)
    Image {
        mipmap: true
        visible: windowPreview.hasContent && !root.compactMode
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 4
        width: 16
        height: 16
        source: Quickshell.iconPath(root.iconPath, "application-x-executable")
        sourceSize: Qt.size(16, 16)
        asynchronous: true
        opacity: 0.8
        z: 10
    }

    // XWayland indicator
    Rectangle {
        visible: root.windowData?.xwayland || false
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
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        drag.target: parent

        onEntered: {
            root.hovered = true;
        }
        onExited: root.hovered = false

        onPressed: mouse => {
            root.pressed = true;
            root.dragStarted();
        }

        onReleased: mouse => {
            let targetWorkspace = overviewRoot ? overviewRoot.draggingTargetWorkspace : -1;

            root.pressed = false;

            if (mouse.button === Qt.LeftButton) {
                // If targetWorkspace is -1, calculate it from current position
                if (targetWorkspace === -1 && overviewRoot) {
                    // Calculate which workspace we're over based on position
                    const workspaceColIndex = Math.floor((root.x - root.xOffset + root.availableWorkspaceWidth / 2) / (root.availableWorkspaceWidth + overviewRoot.workspacePadding + overviewRoot.workspaceSpacing));
                    const workspaceRowIndex = Math.floor((root.y - root.yOffset + root.availableWorkspaceHeight / 2) / (root.availableWorkspaceHeight + overviewRoot.workspacePadding + overviewRoot.workspaceSpacing));
                    
                    if (workspaceColIndex >= 0 && workspaceColIndex < overviewRoot.columns && 
                        workspaceRowIndex >= 0 && workspaceRowIndex < overviewRoot.rows) {
                        targetWorkspace = overviewRoot.workspaceGroup * overviewRoot.workspacesShown + 
                                        workspaceRowIndex * overviewRoot.columns + workspaceColIndex + 1;
                    } else {
                        // Out of bounds, default to current workspace
                        targetWorkspace = windowData?.workspace.id;
                    }
                }

                root.dragFinished(targetWorkspace);
                if (overviewRoot) overviewRoot.draggingTargetWorkspace = -1;

                // Check if moving to different workspace
                if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                    // Moving to different workspace
                    if (windowData?.floating && (root.x !== root.initX || root.y !== root.initY) && overviewRoot) {
                        // Calculate position in the target workspace
                        // Get target workspace offset
                        const targetColIndex = (targetWorkspace - 1) % overviewRoot.columns;
                        const targetRowIndex = Math.floor((targetWorkspace - 1) % overviewRoot.workspacesShown / overviewRoot.columns);
                        const targetXOffset = Math.round((overviewRoot.workspaceImplicitWidth + overviewRoot.workspacePadding + overviewRoot.workspaceSpacing) * targetColIndex + overviewRoot.workspacePadding / 2);
                        const targetYOffset = Math.round((overviewRoot.workspaceImplicitHeight + overviewRoot.workspacePadding + overviewRoot.workspaceSpacing) * targetRowIndex + overviewRoot.workspacePadding / 2);
                        
                        // Calculate relative position in target workspace
                        const relativeX = root.x - targetXOffset;
                        const relativeY = root.y - targetYOffset;
                        
                        // Convert to percentage
                        const percentageX = Math.round((relativeX / root.availableWorkspaceWidth) * 100);
                        const percentageY = Math.round((relativeY / root.availableWorkspaceHeight) * 100);
                        
                        // Set position in target workspace
                        Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${windowData?.address}`);
                        Hyprland.dispatch(`movewindowpixel exact ${percentageX}% ${percentageY}%, address:${windowData?.address}`);
                        
                        // Force immediate window data update
                        HyprlandData.updateWindowList();
                    } else {
                        // Just move workspace without repositioning
                        Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${windowData?.address}`);
                        HyprlandData.updateWindowList();
                    }
                    
                    // Reset position in overview
                    root.x = root.initX;
                    root.y = root.initY;
                } else if (windowData?.floating && (root.x !== root.initX || root.y !== root.initY)) {
                    // Dropped on same workspace and floating - reposition
                    const relativeX = root.x - root.xOffset;
                    const relativeY = root.y - root.yOffset;
                    
                    const percentageX = Math.round((relativeX / root.availableWorkspaceWidth) * 100);
                    const percentageY = Math.round((relativeY / root.availableWorkspaceHeight) * 100);
                    
                    const draggedX = root.x;
                    const draggedY = root.y;
                    
                    Hyprland.dispatch(`movewindowpixel exact ${percentageX}% ${percentageY}%, address:${windowData?.address}`);
                    
                    // Force immediate window data update
                    HyprlandData.updateWindowList();
                    
                    // Set override position for immediate visual update
                    root.overrideX = draggedX;
                    root.overrideY = draggedY;
                    root.useOverridePosition = true;
                    
                    root.x = draggedX;
                    root.y = draggedY;
                    
                    resetOverrideTimer.restart();
                } else {
                    // Reset position for non-floating or non-moved windows
                    root.x = root.initX;
                    root.y = root.initY;
                }
            }
        }

        onClicked: mouse => {
            if (!root.windowData)
                return;

            if (mouse.button === Qt.LeftButton) {
                // Single click just focuses the window without closing overview
                Hyprland.dispatch(`focuswindow address:${windowData.address}`);
            } else if (mouse.button === Qt.MiddleButton) {
                root.windowClosed();
            }
        }

        onDoubleClicked: mouse => {
            if (!root.windowData)
                return;

            if (mouse.button === Qt.LeftButton) {
                // Double click closes overview and focuses window
                root.windowClicked();
            }
        }
    }

    // Tooltip
    ToolTip {
        id: windowTooltip
        visible: dragArea.containsMouse && !root.Drag.active && root.windowData
        delay: 300
        padding: 8
        y: -height - 8
        x: (parent.width - width) / 2
        text: `${root.windowData?.title || ""}\n[${root.windowData?.class || ""}]${root.windowData?.xwayland ? " [XWayland]" : ""}`

        contentItem: StyledText {
            text: windowTooltip.text
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
