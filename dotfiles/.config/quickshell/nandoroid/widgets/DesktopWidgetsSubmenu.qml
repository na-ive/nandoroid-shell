import QtQuick
import QtQuick.Layouts
import "../core"
import "../panels/Settings/pages/WallpaperStyle" // For AndroidToggle

Item {
    id: root
    implicitWidth: 348 * Appearance.effectiveScale
    implicitHeight: col.implicitHeight + (12 * Appearance.effectiveScale)

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
    }

    ColumnLayout {
        id: col
        anchors { 
            fill: parent
            leftMargin: 6 * Appearance.effectiveScale
            rightMargin: 6 * Appearance.effectiveScale
            topMargin: 6 * Appearance.effectiveScale
            bottomMargin: 6 * Appearance.effectiveScale
        }
        spacing: 2 * Appearance.effectiveScale

        component SubmenuItem : RippleButton {
            id: itemRoot
            property string menuText: ""
            property string menuIcon: ""
            property alias toggleChecked: toggle.checked
            signal customToggled()
            
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.sizes.contextMenuItemHeight
            
            buttonRadius: Appearance.rounding.small
            colBackground: "transparent"
            
            leftPadding: 12 * Appearance.effectiveScale
            rightPadding: 12 * Appearance.effectiveScale
            
            onClicked: customToggled()
            
            contentItem: RowLayout {
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
                
                AndroidToggle {
                    id: toggle
                    // Stop mouse events from reaching the RippleButton to prevent double toggles when clicking the toggle directly
                    MouseArea {
                        anchors.fill: parent
                        onClicked: itemRoot.customToggled()
                    }
                }
            }
        }

        SubmenuItem {
            menuText: "Clock"
            menuIcon: "schedule"
            toggleChecked: Config.ready && Config.options.appearance.clock.showOnDesktop
            onCustomToggled: if (Config.ready) Config.options.appearance.clock.showOnDesktop = !Config.options.appearance.clock.showOnDesktop
        }

        SubmenuItem {
            menuText: "At a Glance"
            menuIcon: "view_day"
            toggleChecked: Config.ready && Config.options.appearance.atAGlance.show
            onCustomToggled: if (Config.ready) Config.options.appearance.atAGlance.show = !Config.options.appearance.atAGlance.show
        }
    }
}
