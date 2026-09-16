import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../widgets"
import "../../services"
import "../../core"

RippleButton {
    id: root
    
    property var app: null
    property bool selected: false
    readonly property string subtitle: (app && app.subtitle) ? app.subtitle : ""
    // No-shape mode: bg goes transparent (NOT invisible, children must keep rendering).
    readonly property bool noShape: (Config.ready ? Config.options.search?.iconShape : "Square") === "None"
    
    // Whether this app is in the dock favorites (shares the same pinnedApps list).
    readonly property bool isFav: !!(app && !app.isPlugin) && TaskbarApps.pinVersion >= 0 && TaskbarApps.isPinned(app.id)
    
    // Icon Source logic
    readonly property bool isPlugin: Boolean(app && app.isPlugin)
    readonly property string iconSource: isPlugin ? "" : Quickshell.iconPath(app ? app.icon : "application-x-executable", "image-missing")

    width: 90 * Appearance.effectiveScale
    height: 110 * Appearance.effectiveScale
    
    colBackground: root.selected ? Qt.alpha(Appearance.m3colors.m3primary, 0.1) : "transparent"
    buttonRadius: 12 * Appearance.effectiveScale

    // Right-click toggles favorite (pins/unpins in the shared dock list).
    altAction: (event) => {
        if (app && !app.isPlugin) TaskbarApps.togglePin(app.id)
    }
    
    onClicked: {
        if (app) {
            app.execute();
            GlobalStates.launcherOpen = false;
        }
    }
    
    Column {
        anchors.centerIn: parent
        spacing: 4 * Appearance.effectiveScale
        width: parent.width - 16 * Appearance.effectiveScale
        
        Item {
            width: 56 * Appearance.effectiveScale
            height: 56 * Appearance.effectiveScale
            anchors.horizontalCenter: parent.horizontalCenter

            MaterialShape {
                id: iconBg
                anchors.fill: parent
                color: root.noShape ? "transparent" : ((root.hovered || root.selected) ? Appearance.m3colors.m3primaryContainer : Appearance.m3colors.m3surfaceVariant)
                shapeString: Config.ready ? Config.options.search.iconShape : "Square"
                borderWidth: root.noShape ? 0 : 1 * Appearance.effectiveScale
                borderColor: Qt.rgba(0, 0, 0, 0.1)
                
                IconImage {
                    id: iconImg
                    source: app ? Quickshell.iconPath(app.icon || "application-x-executable", "image-missing") : ""
                    visible: app && !app.isPlugin && !app.emoji
                    width: (root.noShape ? 44 : 32) * Appearance.effectiveScale
                    height: (root.noShape ? 44 : 32) * Appearance.effectiveScale
                    anchors.centerIn: parent
                }


                MaterialSymbol {
                    text: (app && app.isPlugin) ? app.icon : ""
                    visible: app && app.isPlugin && !app.emoji
                    iconSize: (root.noShape ? 44 : 32) * Appearance.effectiveScale
                    anchors.centerIn: parent
                    color: (root.hovered || root.selected) ? Appearance.m3colors.m3onPrimaryContainer : Appearance.m3colors.m3onSurfaceVariant
                }

                StyledText {
                    text: (app && app.emoji) ? app.emoji : ""
                    visible: app && app.emoji !== ""
                    font.pixelSize: Math.round((root.noShape ? 44 : 32) * Appearance.effectiveScale)
                    anchors.centerIn: parent
                }
            }

            MaterialSymbol {
                anchors { top: parent.top; right: parent.right; topMargin: -2 * Appearance.effectiveScale; rightMargin: -2 * Appearance.effectiveScale }
                text: "star"
                fill: 1
                iconSize: 16 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
                visible: root.isFav
                z: 10
            }
        }
        
        Column {
            width: parent.width
            spacing: 0
            
            StyledText {
                text: app ? app.name : ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurface
                font.weight: root.selected ? Font.DemiBold : Font.Medium
            }

            StyledText {
                text: root.subtitle
                visible: text !== ""
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: root.selected ? Appearance.m3colors.m3primary : Appearance.m3colors.m3onSurfaceVariant
                opacity: 0.8
            }
        }
    }
}
