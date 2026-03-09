pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import "../../services"
import "utils"
import "widgets"

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    readonly property int actionCopy: 0
    readonly property int actionEdit: 1
    readonly property int actionSearch: 2
    readonly property int actionOCR: 3
    readonly property int actionRecord: 4
    readonly property int actionRecordWithSound: 5
    readonly property int actionRecordFullscreenWithSound: 6
    
    readonly property int modeRect: 0
    readonly property int modeCircle: 1

    property int action: actionCopy
    property int selectionMode: modeRect
    signal dismiss()

    property string screenshotDir: Directories.screenshotTemp
    property color overlayColor: Qt.rgba(0, 0, 0, 0.4)
    property color selectionBorderColor: Appearance.colors.colPrimary
    property color selectionFillColor: "#33ffffff"
    
    readonly property var windows: Array.from(HyprlandData.windowList).sort((a, b) => {
        if (a.floating === b.floating) return 0;
        return a.floating ? -1 : 1;
    })
    
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property list<point> points: []
    property var mouseButton: null
    property var imageRegions: []
    
    readonly property list<var> windowRegions: {
        const activeWs = root.activeWorkspaceId;
        const filtered = root.windows.filter(w => {
            const winWsId = (w.workspace && w.workspace.id !== undefined) ? w.workspace.id : -1;
            return winWsId === activeWs;
        });
        
        
        return filtered.map(window => {
            return {
                at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
                size: [window.size[0], window.size[1]],
                class: window.class,
                title: window.title,
            }
        })
    }

    property bool isCircleSelection: (root.selectionMode === root.modeCircle)
    property bool enableWindowRegions: Config.ready ? Config.options.regionSelector.targetRegions.windows && !isCircleSelection : !isCircleSelection
    
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    
    function targetedRegionValid() {
        return (root.targetedRegionX >= 0 && root.targetedRegionY >= 0)
    }
    
    function setRegionToTargeted() {
        const padding = Config.ready ? Config.options.regionSelector.targetRegions.selectionPadding : 5;
        root.regionX = root.targetedRegionX - padding;
        root.regionY = root.targetedRegionY - padding;
        root.regionWidth = root.targetedRegionWidth + padding * 2;
        root.regionHeight = root.targetedRegionHeight + padding * 2;
    }

    function updateTargetedRegion(x, y) {
        if (!enableWindowRegions) return;
        
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = !checkRecordingProc.running;
        }
    }
    
    property bool isRecording: root.action === actionRecord || root.action === actionRecordWithSound || root.action === actionRecordFullscreenWithSound
    property bool recordingShouldStop: false
    
    Process {
        id: checkRecordingProc
        running: isRecording
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = !screenshotProc.running
            root.recordingShouldStop = (exitCode === 0);
        }
    }
    
    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone) return;
        if (root.isRecording && root.recordingShouldStop) {
            Quickshell.execDetached([Quickshell.shellPath("scripts/videos/record.sh")]);
            root.dismiss();
            return;
        }

        // For fullscreen recording, skip the selection UI and start immediately
        if (root.action === actionRecordFullscreenWithSound) {
            root.snip();
            return;
        }

        root.visible = true;
        HyprlandData.updateAll();
    }

    Component.onCompleted: {
    }

    /*
    Process {
        id: snipProc
    }
    */

    function snip() {
        if (root.action !== actionRecordFullscreenWithSound && (root.regionWidth <= 0 || root.regionHeight <= 0)) {
            root.dismiss();
            return;
        }

        root.regionX = Math.max(0, Math.min(root.regionX, root.screen.width - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, root.screen.height - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, root.screen.width - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, root.screen.height - root.regionY));

        if (root.action === actionCopy || root.action === actionEdit) {
            root.action = root.mouseButton === Qt.RightButton ? actionEdit : actionCopy;
        }
        
        const savePath = Config.ready ? Config.options.screenSnip.savePath : "";
        
        // Map SnipAction to ScreenshotAction.Action
        let actionEnum;
        switch(root.action) {
            case actionCopy: actionEnum = ScreenshotAction.Action.Copy; break;
            case actionEdit: actionEnum = ScreenshotAction.Action.Edit; break;
            case actionSearch: actionEnum = ScreenshotAction.Action.Search; break;
            case actionOCR: actionEnum = ScreenshotAction.Action.CharRecognition; break;
            case actionRecord: actionEnum = ScreenshotAction.Action.Record; break;
            case actionRecordWithSound: actionEnum = ScreenshotAction.Action.RecordWithSound; break;
            case actionRecordFullscreenWithSound: actionEnum = ScreenshotAction.Action.RecordFullscreenWithSound; break;
        }

        
        const command = ScreenshotAction.getCommand(
            root.regionX * root.monitorScale,
            root.regionY * root.monitorScale,
            root.regionWidth * root.monitorScale,
            root.regionHeight * root.monitorScale,
            root.screenshotPath,
            actionEnum,
            savePath
        )
        
        Quickshell.execDetached(command);
        root.dismiss();
    }

    ScreencopyView {
        anchors.fill: parent
        live: false
        captureSource: root.screen

        focus: root.visible
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            onPressed: (mouse) => {
                root.dragStartX = mouse.x;
                root.dragStartY = mouse.y;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragging = true;
                root.mouseButton = mouse.button;
            }
            onReleased: (mouse) => {
                if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                    if (root.targetedRegionValid()) {
                        root.setRegionToTargeted();
                    }
                }
                else if (root.selectionMode === modeCircle) {
                    const padding = 10;
                    const dragPoints = (root.points.length > 0) ? root.points : [{ x: mouseArea.mouseX, y: mouseArea.mouseY }];
                    const maxX = Math.max(...dragPoints.map(p => p.x));
                    const minX = Math.min(...dragPoints.map(p => p.x));
                    const maxY = Math.max(...dragPoints.map(p => p.y));
                    const minY = Math.min(...dragPoints.map(p => p.y));
                    root.regionX = minX - padding;
                    root.regionY = minY - padding;
                    root.regionWidth = maxX - minX + padding * 2;
                    root.regionHeight = maxY - minY + padding * 2;
                }
                root.snip();
            }
            onPositionChanged: (mouse) => {
                root.updateTargetedRegion(mouse.x, mouse.y);
                if (!root.dragging) return;
                root.draggingX = mouse.x;
                root.draggingY = mouse.y;
                root.dragDiffX = mouse.x - root.dragStartX;
                root.dragDiffY = mouse.y - root.dragStartY;
                root.points.push({ x: mouse.x, y: mouse.y });
            }
            
            Loader {
                z: 2
                anchors.fill: parent
                active: root.selectionMode === modeRect
                sourceComponent: RectCornersSelectionDetails {
                    regionX: root.regionX
                    regionY: root.regionY
                    regionWidth: root.regionWidth
                    regionHeight: root.regionHeight
                    mouseX: mouseArea.mouseX
                    mouseY: mouseArea.mouseY
                    color: root.selectionBorderColor
                    overlayColor: root.overlayColor
                }
            }

            Loader {
                z: 2
                anchors.fill: parent
                active: root.selectionMode === modeCircle
                sourceComponent: CircleSelectionDetails {
                    color: root.selectionBorderColor
                    overlayColor: root.overlayColor
                    points: root.points
                    dragging: root.dragging
                    mouseX: mouseArea.mouseX
                    mouseY: mouseArea.mouseY
                }
            }

            CursorGuide {
                z: 9999
                x: root.dragging ? root.regionX + root.regionWidth : mouseArea.mouseX
                y: root.dragging ? root.regionY + root.regionHeight : mouseArea.mouseY
                action: root.action
                selectionMode: root.selectionMode
            }

            Repeater {
                model: root.enableWindowRegions ? root.windowRegions : []
                delegate: TargetRegion {
                    id: targetRegion
                    z: 20
                    required property var modelData
                    clientDimensions: modelData
                    showIcon: false
                    targeted: !root.draggedAway &&
                        (Math.abs(root.targetedRegionX - modelData.at[0]) < 1
                        && Math.abs(root.targetedRegionY - modelData.at[1]) < 1
                        && Math.abs(root.targetedRegionWidth - modelData.size[0]) < 1
                        && Math.abs(root.targetedRegionHeight - modelData.size[1]) < 1)

                    opacity: root.draggedAway ? 0 : 0.8
                    borderColor: Appearance.colors.colSecondary
                    fillColor: targeted ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.05)
                    text: `${modelData.class}`
                }
            }
            
            // Close Button
            M3IconButton {
                id: closeButton
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 20
                iconName: "close"
                onClicked: root.dismiss()
                z: 10000
                visible: root.visible
            }
        }
    }
}
