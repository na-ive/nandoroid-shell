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
 * Optimized for stability and GPU performance.
 * Feature: Subtle magnification on hover.
 */
DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int index: -1
    property int lastFocused: -1
    property real iconSize: Config.ready && Config.options.dock.monochromeIcons ? 24 : 32
    
    property bool appIsActive: appToplevel && appToplevel.toplevels ? appToplevel.toplevels.some(t => t.activated) : false
    readonly property bool isSeparator: appToplevel && appToplevel.appId === "SEPARATOR"
    readonly property var desktopEntry: appToplevel ? TaskbarApps.getDesktopEntry(appToplevel.appId) : null
    
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : Math.max(48, implicitHeight - (dockTopInset + dockBottomInset))

    background: Item {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: root.dockTopInset
            anchors.bottomMargin: root.dockBottomInset
            radius: root.buttonRadius
            color: root.baseColor
            visible: !(Config.ready && Config.options.dock.monochromeIcons)
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        }
        MaterialShape {
            anchors.fill: parent; anchors.margins: 4
            visible: Config.ready && Config.options.dock.monochromeIcons
            shapeString: Config.ready && Config.options.search ? Config.options.search.iconShape : "Circle"
            color: root.down ? Appearance.colors.colPrimary : Appearance.colors.colPrimaryContainer
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
        }
    }
    
    colBackground: "transparent"
    dockTopInset: Config.ready && Config.options.dock.monochromeIcons ? 4 : 0
    dockBottomInset: Config.ready && Config.options.dock.monochromeIcons ? 4 : 0

    onClicked: {
        if (!appToplevel || !appToplevel.toplevels) return;
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
        id: visualContent
        visible: !root.isSeparator
        anchors.fill: parent
        
        // Subtle Magnification & Tactile Press Effect
        scale: root.down ? 0.92 : (root.hovered ? 1.05 : 1.0)
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Item {
            id: iconContainer
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize

            IconImage {
                id: iconImage
                anchors.fill: parent
                property string iconName: appToplevel ? AppSearch.guessIcon(appToplevel.appId) : ""
                source: iconName !== "" ? Quickshell.iconPath(iconName, "application-x-executable") : ""
                visible: !(Config.ready && Config.options.dock.monochromeIcons) && source !== ""
            }

            ColorOverlay {
                anchors.fill: parent
                source: iconImage
                color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnPrimaryContainer, 0.5)
                visible: Config.ready && Config.options.dock.monochromeIcons
            }

            Rectangle {
                id: badge
                anchors { top: parent.top; right: parent.right; topMargin: -4; rightMargin: -4 }
                width: 16; height: 16; radius: 8
                color: Appearance.colors.colError
                visible: appToplevel && notifCount > 0
                z: 10
                readonly property int notifCount: appToplevel ? Notifications.getCountForApp(appToplevel.appId) : 0
                StyledText { anchors.centerIn: parent; text: parent.notifCount > 9 ? "!" : parent.notifCount; font.pixelSize: 10; font.weight: Font.Bold; color: "white" }
                scale: visible ? 1 : 0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }
        }

        Row {
            spacing: 2
            anchors { bottom: parent.bottom; bottomMargin: root.dockBottomInset + 6; horizontalCenter: parent.horizontalCenter }
            visible: appToplevel && appToplevel.toplevels && appToplevel.toplevels.length > 0
            Repeater {
                model: (appToplevel && appToplevel.toplevels) ? Math.min(appToplevel.toplevels.length, 3) : 0
                delegate: Rectangle {
                    radius: Appearance.rounding.full
                    width: (appToplevel.toplevels.length === 1) ? 12 : 4
                    height: 4
                    color: root.appIsActive ? Appearance.colors.colPrimary : Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.4)
                    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: appToplevel && appToplevel.toplevels && appToplevel.toplevels.length >= 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
        
        onEntered: {
            if (appListRoot && appToplevel) {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                appListRoot.buttonHoverChanged(root, appToplevel, true)
            }
            if (appToplevel && appToplevel.toplevels)
                lastFocused = appToplevel.toplevels.length - 1
        }
        onExited: {
            if (appListRoot && appListRoot.lastHoveredButton === root) {
                appListRoot.buttonHovered = false
                appListRoot.buttonHoverChanged(root, appToplevel, false)
            }
        }
    }
}
