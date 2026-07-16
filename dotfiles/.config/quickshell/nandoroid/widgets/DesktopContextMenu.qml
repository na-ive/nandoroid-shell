import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt.labs.folderlistmodel
import "../core"
import "../core/functions" as Functions
import "../services"
import Qt5Compat.GraphicalEffects

/**
 * DesktopContextMenu.qml
 * A modern, premium right-click menu for the desktop.
 * Uses PanelWindow pattern for better focus and auto-close behavior.
 */
PanelWindow {
    id: root
    visible: false
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nandoroid:desktop-context-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    
    property var activeConfigObject: null
    property string activeWidgetName: ""
    property string activeWidgetSearchKeyword: ""
    property real targetX: 0
    property real targetY: 0
    property real _mouseX: 0
    property real _mouseY: 0
    
    signal backgroundRightClicked(real x, real y)

    property int currentAnimDuration: Appearance.animation.elementMoveEnter.duration
    property var currentAnimEasing: Appearance.animationCurves.expressiveDefaultSpatial
    
    color: "transparent"

    // Click outside to close or move menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.backgroundRightClicked(mouse.x, mouse.y)
            } else {
                root.close()
            }
        }
    }

    // Wallpaper folder images
    FolderListModel {
        id: wallpaperFolder
        folder: {
            const wallPath = Config.options?.appearance?.background?.wallpaperPath ?? ""
            if (!wallPath || wallPath.length === 0) return ""
            const lastSlash = wallPath.lastIndexOf("/")
            return "file://" + wallPath.substring(0, lastSlash)
        }
        showDirs: false
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp"]
    }

    property int carouselExtraCount: 5
    property var randomWallpapers: {
        const current = Functions.FileUtils.trimFileProtocol(Config.options?.appearance?.background?.wallpaperPath ?? "")
        let all = []
        for (let i = 0; i < wallpaperFolder.count; i++) {
            const fp = Functions.FileUtils.trimFileProtocol(wallpaperFolder.get(i, "filePath").toString())
            if (fp !== current) all.push(fp)
        }
        for (let i = all.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            let temp = all[i];
            all[i] = all[j];
            all[j] = temp;
        }
        return all.slice(0, carouselExtraCount)
    }

    property var carouselModel: {
        const current = Functions.FileUtils.trimFileProtocol(Config.options?.appearance?.background?.wallpaperPath ?? "")
        if (!current || current.length === 0) return randomWallpapers
        return [current, ...randomWallpapers]
    }

    Rectangle {
        id: carouselContainer
        visible: root.activeConfigObject === null && opacity > 0
        
        // Dynamically position above or below based on available space
        property real preferredY: root.targetY - height - 8 * Appearance.effectiveScale
        y: preferredY < 10 * Appearance.effectiveScale 
            ? root.targetY + menuContainer.height + 8 * Appearance.effectiveScale
            : preferredY
        
        // Align horizontally with menuContainer, centering if carousel is wider, but keep on screen
        property real preferredX: root.targetX - (implicitWidth - menuContainer.width) / 2
        x: Math.max(10 * Appearance.effectiveScale, Math.min(preferredX, root.screen.width - implicitWidth - 10 * Appearance.effectiveScale))
            
        implicitWidth: 348 * Appearance.effectiveScale
        implicitHeight: 160 * Appearance.effectiveScale
        radius: Appearance.rounding.extraLarge
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        
        opacity: (root.visible && !root.isClosing) ? 0.98 : 0
        scale: (root.visible && !root.isClosing) ? 1 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: root.currentAnimDuration
                easing.bezierCurve: root.currentAnimEasing
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: root.currentAnimDuration
                easing.bezierCurve: root.currentAnimEasing
            }
        }
        
        // Prevent clicks on the menu from closing it
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        Carousel {
            id: wallpaperCarousel
            anchors.fill: parent
            anchors.margins: 10 * Appearance.effectiveScale
            model: root.carouselModel
            isOpen: root.visible
            onWallpaperSelected: (path) => {
                Wallpapers.select(path, Appearance.m3colors.darkmode)
                root.close()
            }
            onOpenMoreWallpapers: {
                GlobalStates.wallpaperSelectorOpen = true
                root.close()
            }
        }
    }

    Rectangle {
        id: menuContainer
        x: root.targetX
        y: root.targetY
        implicitWidth: root.activeConfigObject === null 
            ? (348 * Appearance.effectiveScale) 
            : Math.max(Appearance.sizes.contextMenuWidth, menuLayout.implicitWidth + (12 * Appearance.effectiveScale))
        implicitHeight: menuLayout.implicitHeight + (12 * Appearance.effectiveScale)
        
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        
        // Glassmorphism effect
        opacity: (root.visible && !root.isClosing) ? 0.98 : 0
        scale: (root.visible && !root.isClosing) ? 1 : 0.95
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: root.currentAnimDuration
                easing.bezierCurve: root.currentAnimEasing
            }
        }
        
        Behavior on scale {
            NumberAnimation {
                duration: root.currentAnimDuration
                easing.bezierCurve: root.currentAnimEasing
            }
        }

        // Prevent clicks on the menu from closing it
        MouseArea {
            anchors.fill: parent
            onPressed: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            id: menuLayout
            anchors.fill: parent
            anchors.margins: 6 * Appearance.effectiveScale
            spacing: 2 * Appearance.effectiveScale

            // --- Widget Specific Items ---
            MenuItem {
                visible: root.activeConfigObject !== null && root.activeConfigObject.locked !== undefined
                menuText: (root.activeConfigObject && root.activeConfigObject.locked) ? "Unlock " + root.activeWidgetName + " Position" : "Lock " + root.activeWidgetName + " Position"
                menuIcon: (root.activeConfigObject && root.activeConfigObject.locked) ? "lock_open" : "lock"
                onClicked: {
                    if (root.activeConfigObject) {
                        root.activeConfigObject.locked = !root.activeConfigObject.locked
                    }
                    root.close()
                }
            }

            MenuItem {
                visible: root.activeConfigObject !== null && root.activeWidgetName !== ""
                menuText: root.activeWidgetName + " Settings"
                menuIcon: "settings" // Generic settings icon for widgets
                onClicked: {
                    GlobalStates.settingsPageIndex = 5 // Widgets panel is index 5
                    SearchRegistry.currentSearch = root.activeWidgetSearchKeyword
                    GlobalStates.activateSettings()
                    root.close()
                }
            }

            // --- General Desktop Items ---

            MenuItem {
                id: widgetsRow
                visible: root.activeConfigObject === null
                menuText: "Widgets"
                menuIcon: "widgets"
                rightIcon: "chevron_right"
                
                Component {
                    id: widgetsSubmenu
                    DesktopWidgetsSubmenu {}
                }
                
                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            submenuCloseTimer.stop()
                            root.openSubmenuComponent = widgetsSubmenu
                            root.submenuAnchorY = menuContainer.y + widgetsRow.mapToItem(menuContainer, 0, 0).y
                        } else {
                            submenuCloseTimer.restart()
                        }
                    }
                }
                
                onClicked: {
                    GlobalStates.settingsPageIndex = 5 // Widgets panel
                    SearchRegistry.currentSearch = ""
                    GlobalStates.activateSettings()
                    root.close()
                }
            }

            
            MenuItem {
                visible: root.activeConfigObject === null
                menuText: "Display settings"
                menuIcon: "monitor"
                
                HoverHandler {
                    onHoveredChanged: if (hovered) root.openSubmenuComponent = null
                }
                
                onClicked: {
                    GlobalStates.settingsPageIndex = 3 // Display
                    SearchRegistry.currentSearch = ""
                    GlobalStates.activateSettings()
                    root.close()
                }
            }

            MenuItem {
                visible: root.activeConfigObject === null
                menuText: "Wallpaper & style"
                menuIcon: "format_paint"
                
                HoverHandler {
                    onHoveredChanged: if (hovered) root.openSubmenuComponent = null
                }
                
                onClicked: {
                    GlobalStates.settingsPageIndex = 4 // Wallpaper & Style
                    SearchRegistry.currentSearch = ""
                    GlobalStates.activateSettings()
                    root.close()
                }
            }
        }
    }

    Process {
        id: terminalProcess
        command: ["kitty"]
    }

    // Helper component for menu items
    component MenuItem : RippleButton {
        id: itemRoot
        property string menuText: ""
        property string menuIcon: ""
        property string rightIcon: ""
        
        Layout.fillWidth: true
        Layout.preferredHeight: Appearance.sizes.contextMenuItemHeight
        
        buttonRadius: Appearance.rounding.small
        colBackground: "transparent"
        
        // Define padding for the content
        leftPadding: 12 * Appearance.effectiveScale
        rightPadding: 12 * Appearance.effectiveScale
        
        // Explicitly calculate implicit width to ensure parent layout sizes correctly
        implicitWidth: leftPadding + rightPadding + contentRow.implicitWidth
        
        contentItem: RowLayout {
            id: contentRow
            spacing: 12 * Appearance.effectiveScale
            
            MaterialSymbol {
                text: itemRoot.menuIcon
                iconSize: Appearance.sizes.iconSize * 0.9
                color: Appearance.colors.colOnLayer0
            }
            
            StyledText {
                text: itemRoot.menuText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
            
            MaterialSymbol {
                visible: itemRoot.rightIcon !== ""
                text: itemRoot.rightIcon
                iconSize: Appearance.sizes.iconSize * 0.9
                color: Appearance.colors.colOnLayer0
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    Loader {
        id: submenuLoader
        active: root.openSubmenuComponent !== null && root.visible
        sourceComponent: root.openSubmenuComponent
        x: {
            let submenuWidth = item ? item.width : (348 * Appearance.effectiveScale);
            let rightPos = menuContainer.x + menuContainer.width + 12 * Appearance.effectiveScale;
            if (rightPos + submenuWidth + 12 * Appearance.effectiveScale <= root.screen.width) {
                return rightPos;
            } else {
                let leftPos = menuContainer.x - submenuWidth - 12 * Appearance.effectiveScale;
                return Math.max(12 * Appearance.effectiveScale, leftPos);
            }
        }
        y: Math.min(root.submenuAnchorY, root.screen.height - height - 12 * Appearance.effectiveScale)
        
        HoverHandler {
            onHoveredChanged: {
                if (hovered) submenuCloseTimer.stop()
                else submenuCloseTimer.restart()
            }
        }
        
        onLoaded: {
            item.opacity = 0
            item.scale = 0.95
            opacityAnim.start()
            scaleAnim.start()
        }
        
        NumberAnimation {
            id: opacityAnim
            target: submenuLoader.item
            property: "opacity"
            to: 1
            duration: Appearance.animation.elementMoveEnter.duration
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
        NumberAnimation {
            id: scaleAnim
            target: submenuLoader.item
            property: "scale"
            to: 1
            duration: Appearance.animation.elementMoveEnter.duration
            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
        }
    }

    Timer {
        id: submenuCloseTimer
        interval: 150
        onTriggered: root.openSubmenuComponent = null
    }

    // Animation state
    property bool isClosing: false
    property var openSubmenuComponent: null
    property real submenuAnchorY: 0

    Timer {
        id: hideTimer
        interval: Appearance.animation.elementMoveExit.duration + 50
        onTriggered: {
            root.visible = false;
            root.isClosing = false;
            root.activeConfigObject = null;
            root.activeWidgetName = "";
            root.activeWidgetSearchKeyword = "";
            root.openSubmenuComponent = null;
            GlobalStates.desktopContextMenuOpen = false;
        }
    }

    function openAt(x, y, configObject = null, widgetName = "", widgetSearchKeyword = "") {
        root._mouseX = x
        root._mouseY = y
        root.activeConfigObject = configObject
        root.activeWidgetName = widgetName
        root.activeWidgetSearchKeyword = widgetSearchKeyword
        hideTimer.stop();
        
        // Ensure enter animation parameters
        root.currentAnimDuration = Appearance.animation.elementMoveEnter.duration;
        root.currentAnimEasing = Appearance.animationCurves.expressiveDefaultSpatial;
        
        // Target calculation
        const screenWidth = root.screen.width;
        const screenHeight = root.screen.height;
        const menuWidth = menuContainer.implicitWidth;
        const menuHeight = menuLayout.implicitHeight + (12 * Appearance.effectiveScale);
        
        // Constrain to screen
        root.targetX = Math.min(root._mouseX, screenWidth - menuWidth - 10 * Appearance.effectiveScale);
        if (root._mouseY + menuHeight > screenHeight - 10 * Appearance.effectiveScale) {
            root.targetY = root._mouseY - menuHeight;
        } else {
            root.targetY = root._mouseY;
        }
        root.targetY = Math.max(10 * Appearance.effectiveScale, root.targetY);
        
        root.isClosing = false;
        root.visible = true;
        GlobalStates.desktopContextMenuOpen = true;
    }

    function close() {
        if (!root.visible || root.isClosing) return
        
        // Ensure exit animation parameters FIRST
        root.currentAnimDuration = Appearance.animation.elementMoveExit.duration;
        root.currentAnimEasing = Appearance.animationCurves.emphasizedAccel;
        
        // Trigger bindings to evaluate to 0
        root.isClosing = true;
        hideTimer.start();
    }

    signal menuClosed()
    onVisibleChanged: {
        if (!visible) {
            menuClosed();
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.visible
        windows: [root]
        onCleared: root.close()
    }
}
