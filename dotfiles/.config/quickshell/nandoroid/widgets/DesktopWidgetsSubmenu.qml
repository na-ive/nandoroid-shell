import QtQuick
import QtQuick.Layouts
import "../core"


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
            property bool widgetLocked: false
            property alias toggleChecked: toggle.checked
            signal customToggled()
            signal lockToggled()
            
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.sizes.contextMenuItemHeight
            
            buttonRadius: Appearance.rounding.small
            colBackground: "transparent"
            
            leftPadding: 12 * Appearance.effectiveScale
            rightPadding: 12 * Appearance.effectiveScale
            
            onClicked: customToggled()
            
            contentItem: RowLayout {
                spacing: 12 * Appearance.effectiveScale
                
                Item {
                    Layout.preferredWidth: 24 * Appearance.effectiveScale
                    Layout.preferredHeight: 24 * Appearance.effectiveScale
                    
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: itemRoot.widgetLocked ? "lock" : "lock_open"
                        iconSize: Appearance.sizes.iconSize * 0.9
                        color: Appearance.colors.colOnLayer0
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8 * Appearance.effectiveScale
                        cursorShape: Qt.PointingHandCursor
                        onClicked: itemRoot.lockToggled()
                    }
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
            widgetLocked: Config.ready ? Config.options.appearance.clock.locked : false
            onLockToggled: if (Config.ready) Config.options.appearance.clock.locked = !Config.options.appearance.clock.locked
            toggleChecked: Config.ready && Config.options.appearance.clock.showOnDesktop
            onCustomToggled: if (Config.ready) Config.options.appearance.clock.showOnDesktop = !Config.options.appearance.clock.showOnDesktop
        }

        SubmenuItem {
            menuText: "At a Glance"
            widgetLocked: Config.ready ? Config.options.appearance.atAGlance.locked : false
            onLockToggled: if (Config.ready) Config.options.appearance.atAGlance.locked = !Config.options.appearance.atAGlance.locked
            toggleChecked: Config.ready && Config.options.appearance.atAGlance.show
            onCustomToggled: if (Config.ready) Config.options.appearance.atAGlance.show = !Config.options.appearance.atAGlance.show
        }

        SubmenuItem {
            menuText: "Media Player"
            widgetLocked: Config.ready ? Config.options.appearance.mediaWidget.locked : false
            onLockToggled: if (Config.ready) Config.options.appearance.mediaWidget.locked = !Config.options.appearance.mediaWidget.locked
            toggleChecked: Config.ready && Config.options.appearance.mediaWidget.showOnDesktop
            onCustomToggled: if (Config.ready) Config.options.appearance.mediaWidget.showOnDesktop = !Config.options.appearance.mediaWidget.showOnDesktop
        }

        SubmenuItem {
            menuText: "System Monitor"
            widgetLocked: Config.ready ? Config.options.appearance.systemMonitor.locked : false
            onLockToggled: if (Config.ready) Config.options.appearance.systemMonitor.locked = !Config.options.appearance.systemMonitor.locked
            toggleChecked: Config.ready && Config.options.appearance.systemMonitor.showOnDesktop
            onCustomToggled: if (Config.ready) Config.options.appearance.systemMonitor.showOnDesktop = !Config.options.appearance.systemMonitor.showOnDesktop
        }

        SubmenuItem {
            menuText: "Weather"
            widgetLocked: Config.ready ? Config.options.appearance.weatherWidget.locked : false
            onLockToggled: if (Config.ready) Config.options.appearance.weatherWidget.locked = !Config.options.appearance.weatherWidget.locked
            toggleChecked: Config.ready && Config.options.appearance.weatherWidget.showOnDesktop
            onCustomToggled: if (Config.ready) Config.options.appearance.weatherWidget.showOnDesktop = !Config.options.appearance.weatherWidget.showOnDesktop
        }

        SubmenuItem {
            menuText: "Currency"
            widgetLocked: Config.ready ? Config.options.appearance.currencyWidget.locked : false
            onLockToggled: if (Config.ready) Config.options.appearance.currencyWidget.locked = !Config.options.appearance.currencyWidget.locked
            toggleChecked: Config.ready && Config.options.appearance.currencyWidget.showOnDesktop
            onCustomToggled: if (Config.ready) Config.options.appearance.currencyWidget.showOnDesktop = !Config.options.appearance.currencyWidget.showOnDesktop
        }
    }
}
