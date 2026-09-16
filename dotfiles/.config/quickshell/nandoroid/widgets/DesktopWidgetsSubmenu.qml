import QtQuick
import QtQuick.Layouts
import "../core"
import "../services"


Item {
    id: root
    implicitWidth: 348 * Appearance.effectiveScale
    implicitHeight: col.implicitHeight + (12 * Appearance.effectiveScale)

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
    }

    StyledRectangularShadow {
        target: bgRect
        z: -1
    }

    // Block click-through to PanelWindow background (parity with menuContainer)
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: (mouse) => mouse.accepted = true
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
            opacity: enabled ? 1.0 : 0.45
            
            buttonRadius: Appearance.rounding.small
            colBackground: "transparent"
            
            leftPadding: 12 * Appearance.effectiveScale
            rightPadding: 12 * Appearance.effectiveScale
            
            onClicked: if (enabled) customToggled()
            
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
                        enabled: itemRoot.enabled
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
                    enabled: itemRoot.enabled
                    // Stop mouse events from reaching the RippleButton to prevent double toggles when clicking the toggle directly
                    MouseArea {
                        anchors.fill: parent
                        enabled: itemRoot.enabled
                        onClicked: itemRoot.customToggled()
                    }
                }
            }
        }

        SubmenuItem {
            menuText: I18nService.tr("Clock")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.clock
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.clock) ? Config.options.appearance.clock.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.clock) Config.options.appearance.clock.locked = !Config.options.appearance.clock.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.clock && Config.options.appearance.clock.showOnDesktop
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.clock) Config.options.appearance.clock.showOnDesktop = !Config.options.appearance.clock.showOnDesktop
        }

        SubmenuItem {
            menuText: I18nService.tr("At a Glance")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.atAGlance
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.atAGlance) ? Config.options.appearance.atAGlance.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.atAGlance) Config.options.appearance.atAGlance.locked = !Config.options.appearance.atAGlance.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.atAGlance && Config.options.appearance.atAGlance.show
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.atAGlance) Config.options.appearance.atAGlance.show = !Config.options.appearance.atAGlance.show
        }

        SubmenuItem {
            menuText: I18nService.tr("Media Player")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.mediaWidget
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.mediaWidget) ? Config.options.appearance.mediaWidget.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.mediaWidget) Config.options.appearance.mediaWidget.locked = !Config.options.appearance.mediaWidget.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.mediaWidget && Config.options.appearance.mediaWidget.showOnDesktop
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.mediaWidget) Config.options.appearance.mediaWidget.showOnDesktop = !Config.options.appearance.mediaWidget.showOnDesktop
        }

        SubmenuItem {
            menuText: I18nService.tr("System Monitor")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.systemMonitor
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.systemMonitor) ? Config.options.appearance.systemMonitor.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.systemMonitor) Config.options.appearance.systemMonitor.locked = !Config.options.appearance.systemMonitor.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.systemMonitor && Config.options.appearance.systemMonitor.showOnDesktop
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.systemMonitor) Config.options.appearance.systemMonitor.showOnDesktop = !Config.options.appearance.systemMonitor.showOnDesktop
        }

        SubmenuItem {
            menuText: I18nService.tr("Weather")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget
            enabled: Config.ready && (Config.options.weather?.enable ?? true)
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget) ? Config.options.appearance.weatherWidget.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget) Config.options.appearance.weatherWidget.locked = !Config.options.appearance.weatherWidget.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget && (Config.options.weather?.enable ?? true) && Config.options.appearance.weatherWidget.showOnDesktop
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget) Config.options.appearance.weatherWidget.showOnDesktop = !Config.options.appearance.weatherWidget.showOnDesktop
        }

        SubmenuItem {
            menuText: I18nService.tr("Currency")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.currencyWidget
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.currencyWidget) ? Config.options.appearance.currencyWidget.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.currencyWidget) Config.options.appearance.currencyWidget.locked = !Config.options.appearance.currencyWidget.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.currencyWidget && Config.options.appearance.currencyWidget.showOnDesktop
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.currencyWidget) Config.options.appearance.currencyWidget.showOnDesktop = !Config.options.appearance.currencyWidget.showOnDesktop
        }

        SubmenuItem {
            menuText: I18nService.tr("GitHub")
            visible: Config.ready && Config.options.appearance && Config.options.appearance.githubWidget
            enabled: Config.ready && (Config.options.github?.githubUsername ?? "") !== ""
            widgetLocked: (Config.ready && Config.options.appearance && Config.options.appearance.githubWidget) ? Config.options.appearance.githubWidget.locked : false
            onLockToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.githubWidget) Config.options.appearance.githubWidget.locked = !Config.options.appearance.githubWidget.locked
            toggleChecked: Config.ready && Config.options.appearance && Config.options.appearance.githubWidget && Config.options.appearance.githubWidget.showOnDesktop
            onCustomToggled: if (Config.ready && Config.options.appearance && Config.options.appearance.githubWidget) Config.options.appearance.githubWidget.showOnDesktop = !Config.options.appearance.githubWidget.showOnDesktop
        }
    }
}
