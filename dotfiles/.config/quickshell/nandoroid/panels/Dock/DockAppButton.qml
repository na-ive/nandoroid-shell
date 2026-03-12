import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

/**
 * DockAppButton component for the dock.
 * Represents a single application (pinned or running) in the dock.
 */
DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: Config.ready && Config.options.dock.monochromeIcons ? 24 : 32
    property real countDotWidth: 10
    property real countDotHeight: 4
    
    // Check if any toplevel window of this app is active/activated
    property bool appIsActive: appToplevel.toplevels.some(t => t.activated)

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    
    // Using DesktopEntries.heuristicLookup from Quickshell
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)
    
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : Math.max(48, implicitHeight - (dockTopInset + dockBottomInset))

    // ── Themed Icon Background (matching Launcher) ──
    // We override the default background when monochrome is active
    background: Item {
        anchors.fill: parent
        
        // Original background (for non-monochrome mode)
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: root.dockTopInset
            anchors.bottomMargin: root.dockBottomInset
            radius: root.buttonRadius
            color: root.baseColor
            visible: !(Config.ready && Config.options.dock.monochromeIcons)
            
            Behavior on color { 
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }

        // MaterialShape background (matches Launcher icon shape)
        MaterialShape {
            anchors.fill: parent
            anchors.margins: 4 // Give it some breathing room inside the dock height
            visible: Config.ready && Config.options.dock.monochromeIcons
            
            // Link to launcher's icon shape configuration
            shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"
            color: root.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
            
            Behavior on color { 
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
    
    // Disable default button background styling when we are using MaterialShape
    colBackground: "transparent"
    dockTopInset: Config.ready && Config.options.dock.monochromeIcons ? 4 : 0
    dockBottomInset: Config.ready && Config.options.dock.monochromeIcons ? 4 : 0

    // Separator view
    Loader {
        active: isSeparator
        anchors.fill: parent
        sourceComponent: DockSeparator {
            Layout.topMargin: 10
            Layout.bottomMargin: 10
        }
    }

    // Hover area for preview logic
    MouseArea {
        anchors.fill: parent
        enabled: appToplevel.toplevels.length > 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
        onEntered: {
            if (appListRoot) {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                appListRoot.buttonHoverChanged(root, appToplevel, true)
            }
            lastFocused = appToplevel.toplevels.length - 1
        }
        onExited: {
            if (appListRoot && appListRoot.lastHoveredButton === root) {
                appListRoot.buttonHovered = false
                appListRoot.buttonHoverChanged(root, appToplevel, false)
            }
        }
    }

    onClicked: {
        if (appToplevel.toplevels.length === 0) {
            if (root.desktopEntry) root.desktopEntry.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: () => {
        if (root.desktopEntry) root.desktopEntry.execute();
    }

    contentItem: Item {
        visible: !root.isSeparator
        anchors.fill: parent

        Item {
            id: iconContainer
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize

            IconImage {
                id: iconImage
                anchors.fill: parent
                // Use Quickshell.iconPath for more robust theme lookups
                source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "application-x-executable")
                
                // Hide original when monochrome is active
                visible: !(Config.ready && Config.options.dock.monochromeIcons)
            }

            // Monochrome effect implementation
            Loader {
                id: monochromeEffect
                anchors.fill: parent
                active: Config.ready && Config.options.dock.monochromeIcons
                sourceComponent: Item {
                    anchors.fill: parent
                    
                    Desaturate {
                        id: desaturated
                        anchors.fill: parent
                        source: iconImage
                        desaturation: 1.0 
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: parent
                        source: desaturated
                        color: Appearance.colors.colOnPrimaryContainer
                    }
                }
            }

            // Notification Badge
            Rectangle {
                id: badge
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: -4
                    rightMargin: -4
                }
                width: 16; height: 16
                radius: 8
                color: Appearance.colors.colError
                visible: notifCount > 0
                z: 10
                
                readonly property int notifCount: Notifications.getCountForApp(appToplevel.appId)

                StyledText {
                    anchors.centerIn: parent
                    text: parent.notifCount > 9 ? "!" : parent.notifCount
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: "white"
                }

                // Animation for badge appearing
                scale: visible ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }
        }

        // Indicator dots for running windows
        Row {
            spacing: 2
            anchors {
                bottom: parent.bottom
                bottomMargin: root.dockBottomInset + 6 // Slightly higher to not overlap shape curves
                horizontalCenter: parent.horizontalCenter
            }
            visible: appToplevel.toplevels.length > 0
            
            Repeater {
                model: Math.min(appToplevel.toplevels.length, 3)
                delegate: Rectangle {
                    radius: Appearance.rounding.full
                    width: (appToplevel.toplevels.length === 1) ? 12 : 4
                    height: 4
                    color: root.appIsActive ? Appearance.colors.colPrimary : Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.4)
                    
                    Behavior on color { 
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }
                }
            }
        }
    }
}
