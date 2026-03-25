import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Quick Actions view — Floating HUD style for the bottom.
 * Large version (Original scale).
 * Wrapped in FocusScope for reliable keyboard navigation.
 * Features animated tab-style highlight.
 */
FocusScope {
    id: root
    signal closed()
    
    property string position: "bottom"
    
    // Total height of the bar
    implicitHeight: 72 * Appearance.effectiveScale
    implicitWidth: backgroundRect.width

    readonly property color barColor: "black"

    property int currentIndex: 0
    property int totalItems: 11
    
    // Animated stretch-highlight properties
    property int idx1: 0
    property int idx2: 0
    
    onCurrentIndexChanged: {
        idx1 = currentIndex
        Qt.callLater(() => { idx2 = currentIndex })
    }
    
    onIdx1Changed: tabHighlight.updatePositions()
    onIdx2Changed: tabHighlight.updatePositions()

    function reset() {
        currentIndex = 0;
        idx1 = 0;
        idx2 = 0;
        syncTimer.restart();
    }
    
    Timer {
        id: syncTimer
        interval: 50
        onTriggered: {
            tabHighlight.updatePositions(false); // Snap without animation
        }
    }

    focus: true
    
    Keys.onLeftPressed: (event) => {
        currentIndex = (currentIndex - 1 + totalItems) % totalItems;
        event.accepted = true;
    }
    
    Keys.onRightPressed: (event) => {
        currentIndex = (currentIndex + 1) % totalItems;
        event.accepted = true;
    }
    
    Keys.onReturnPressed: (event) => {
        executeItem(currentIndex);
        event.accepted = true;
    }

    Keys.onEscapePressed: (event) => {
        GlobalStates.quickActionsOpen = false;
        root.closed();
        event.accepted = true;
    }
    
    function close() { 
        GlobalStates.quickActionsOpen = false;
        root.closed(); 
    }

    property string pendingFullScreenshotPath: ""
    Process {
        id: fullScreenshotProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && pendingFullScreenshotPath !== "") {
                GlobalStates.screenshotTaken(pendingFullScreenshotPath);
                pendingFullScreenshotPath = "";
            }
        }
    }

    function openFolder(folderPath) {
        Quickshell.execDetached(["bash", "-c", `dir="${folderPath}"; mkdir -p "$dir"; xdg-open "$dir"`]);
        close();
    }

    function executeItem(index) {
        switch(index) {
            case 0: // Full Screenshot
                root.close();
                Functions.General.delayedAction(300, () => {
                    const autoSave = (Config.ready && Config.options.screenshot) ? Config.options.screenshot.autoSave : true;
                    const autoCopy = (Config.ready && Config.options.screenshot) ? Config.options.screenshot.autoCopy : true;
                    const rawSaveDir = (Config.ready && Config.options.screenshot) ? Config.options.screenshot.savePath : "~/Pictures/Screenshots";
                    const finalSaveDir = Functions.FileUtils.trimFileProtocol(rawSaveDir);
                    const tempDir = Functions.FileUtils.trimFileProtocol(Directories.screenshotTemp);
                    const tempPath = `${tempDir}/full-${Date.now()}.png`;
                    
                    const copyCmd = autoCopy ? ` | tee >(wl-copy)` : "";
                    let bashCmd = "";
                    
                    if (autoSave) {
                        bashCmd = `mkdir -p "${tempDir}" && mkdir -p "${finalSaveDir}" && grim - | tee "${tempPath}" ${copyCmd} > "${finalSaveDir}/Screenshot_$(date +%Y-%m-%d-%H-%M-%S).png"`;
                    } else {
                        bashCmd = `mkdir -p "${tempDir}" && grim - | tee "${tempPath}" ${copyCmd} > /dev/null`;
                    }
                    
                    root.pendingFullScreenshotPath = tempPath;
                    fullScreenshotProc.command = ["bash", "-c", bashCmd];
                    fullScreenshotProc.running = true;
                });
                break;
            case 1: // Region Screenshot
                root.close();
                Functions.General.delayedAction(300, () => RegionService.screenshot());
                break;
            case 2: // Open Screenshots
                root.openFolder("$(xdg-user-dir PICTURES)/Screenshots");
                break;
            case 3: // Record Region
                if (ScreenRecord.active) ScreenRecord.stop();
                else {
                    root.close();
                    Functions.General.delayedAction(300, () => RegionService.record());
                }
                break;
            case 4: // Record Region w/ Sound
                if (ScreenRecord.active) ScreenRecord.stop();
                else {
                    root.close();
                    Functions.General.delayedAction(300, () => RegionService.recordWithSound());
                }
                break;
            case 5: // Record Fullscreen w/ Sound
                if (ScreenRecord.active) ScreenRecord.stop();
                else {
                    root.close();
                    Functions.General.delayedAction(300, () => RegionService.recordFullscreenWithSound());
                }
                break;
            case 6: // Open Recordings
                root.openFolder("$(xdg-user-dir VIDEOS)/Recordings");
                break;
            case 7: // OCR
                root.close();
                Functions.General.delayedAction(300, () => RegionService.ocr());
                break;
            case 8: // QR
                root.close();
                Functions.General.delayedAction(300, () => RegionService.qrcode());
                break;
            case 9: // Lens
                root.close();
                Functions.General.delayedAction(300, () => RegionService.search());
                break;
            case 10: // Picker
                root.close();
                Functions.General.delayedAction(300, () => Quickshell.execDetached(["hyprpicker", "-a"]));
                break;
        }
    }

    // --- Background with Waterdrop Corners ---
    Rectangle {
        id: backgroundRect
        color: root.barColor
        
        anchors.bottom: parent.bottom
        height: 64 * Appearance.effectiveScale
        width: layout.implicitWidth + (40 * Appearance.effectiveScale)
        anchors.horizontalCenter: parent.horizontalCenter
        
        radius: height / 2

        // The "Flattener" - Square off the edge side
        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.radius
            color: root.barColor
        }

        // Concave Corners (HUD Style)
        RoundCorner {
            anchors.right: parent.left; anchors.bottom: parent.bottom
            implicitSize: 12 * Appearance.effectiveScale; color: root.barColor
            corner: RoundCorner.CornerEnum.BottomRight
        }

        RoundCorner {
            anchors.left: parent.right; anchors.bottom: parent.bottom
            implicitSize: 12 * Appearance.effectiveScale; color: root.barColor
            corner: RoundCorner.CornerEnum.BottomLeft
        }
        
        // --- Animated Tab Highlight ---
        Rectangle {
            id: tabHighlight
            
            readonly property real buttonWidth: 44 * Appearance.effectiveScale
            readonly property real buttonHeight: 44 * Appearance.effectiveScale
            
            property real animX1: 0
            property real animX2: 0
            
            function updatePositions(animate = true) {
                const t1 = layout.children[idx1 >= 7 ? idx1 + 2 : (idx1 >= 3 ? idx1 + 1 : idx1)];
                const t2 = layout.children[idx2 >= 7 ? idx2 + 2 : (idx2 >= 3 ? idx2 + 1 : idx2)];
                
                if (!animate) {
                    animX1Behavior.enabled = false;
                    animX2Behavior.enabled = false;
                }
                
                if (t1) animX1 = t1.x + layout.x;
                if (t2) animX2 = t2.x + layout.x;
                
                if (!animate) {
                    animX1Behavior.enabled = true;
                    animX2Behavior.enabled = true;
                }
            }
            
            x: Math.min(animX1, animX2)
            width: Math.abs(animX2 - animX1) + buttonWidth
            height: buttonHeight
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2 * Appearance.effectiveScale
            radius: Appearance.rounding.button
            
            color: Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
            visible: root.focus
            
            Behavior on animX1 { id: animX1Behavior; NumberAnimation { duration: 120; easing.type: Easing.OutSine } }
            Behavior on animX2 { id: animX2Behavior; NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        }

        // --- Content Layout ---
        RowLayout {
            id: layout
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -2 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            
            onXChanged: tabHighlight.updatePositions(false)
            
            ToolButton { idx: 0; iconName: "fullscreen"; tooltip: "Full Screenshot"; onClicked: executeItem(0) }
            ToolButton { idx: 1; iconName: "screenshot_region"; tooltip: "Region Screenshot"; onClicked: executeItem(1) }
            ToolButton { idx: 2; iconName: "folder_open"; tooltip: "Open Screenshots"; onClicked: executeItem(2) }
            
            Rectangle {
                id: sep1
                width: 1 * Appearance.effectiveScale
                height: 32 * Appearance.effectiveScale
                color: Qt.rgba(1, 1, 1, 0.2)
                Layout.leftMargin: 6 * Appearance.effectiveScale
                Layout.rightMargin: 6 * Appearance.effectiveScale
            }
            
            ToolButton { idx: 3; iconName: "videocam"; tooltip: "Record Region"; isHighlighted: ScreenRecord.active && ScreenRecord.recordingMode === 0; onClicked: executeItem(3) }
            ToolButton { idx: 4; iconName: "mic"; tooltip: "Record Region w/ Sound"; isHighlighted: ScreenRecord.active && ScreenRecord.recordingMode === 1; onClicked: executeItem(4) }
            ToolButton { idx: 5; iconName: "screen_record"; tooltip: "Record Fullscreen w/ Sound"; isHighlighted: ScreenRecord.active && ScreenRecord.recordingMode === 2; onClicked: executeItem(5) }
            ToolButton { idx: 6; iconName: "folder_managed"; tooltip: "Open Recordings"; onClicked: executeItem(6) }

            Rectangle {
                id: sep2
                width: 1 * Appearance.effectiveScale
                height: 32 * Appearance.effectiveScale
                color: Qt.rgba(1, 1, 1, 0.2)
                Layout.leftMargin: 6 * Appearance.effectiveScale
                Layout.rightMargin: 6 * Appearance.effectiveScale
            }

            ToolButton { idx: 7; iconName: "text_snippet"; tooltip: "OCR (Text Recognition)"; onClicked: executeItem(7) }
            ToolButton { idx: 8; iconName: "qr_code_scanner"; tooltip: "QR Code Scanner"; onClicked: executeItem(8) }
            ToolButton { idx: 9; iconName: "image_search"; tooltip: "Lens Search"; onClicked: executeItem(9) }
            ToolButton { idx: 10; iconName: "colorize"; tooltip: "Color Picker"; onClicked: executeItem(10) }
        }
    }

    component ToolButton: M3IconButton {
        id: btn
        property int idx: -1
        property string tooltip: ""
        property bool isHighlighted: false
        
        implicitWidth: 44 * Appearance.effectiveScale
        implicitHeight: 44 * Appearance.effectiveScale
        buttonRadius: 22 * Appearance.effectiveScale
        iconSize: 24 * Appearance.effectiveScale
        
        readonly property bool isFocused: root.currentIndex === idx && root.focus
        readonly property color activeColor: Appearance.m3colors.darkmode ? Appearance.colors.colNotchPrimary : Appearance.colors.colPrimaryContainer
        
        colBackground: isHighlighted ? activeColor : "transparent"
        color: (isFocused || isHighlighted) ? "#1E1E1E" : Qt.rgba(1, 1, 1, 0.7)
        isM3Highlighted: false
        
        onHoveredChanged: {
            if (hovered) {
                root.currentIndex = idx;
            }
        }
        
        StyledToolTip {
            text: btn.tooltip
            delay: 500
        }
    }
}
