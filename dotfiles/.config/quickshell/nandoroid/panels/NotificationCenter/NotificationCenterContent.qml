import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * Notification Center: Media/Weather + Notification Island.
 * Refactored to match "island" style with grouped notifications.
 */
Item {
    id: root
    signal closed()
    implicitWidth: Appearance.sizes.notificationCenterWidth
    implicitHeight: contentColumn.implicitHeight + 24 // Padding for bottom

    focus: true
    Keys.onEscapePressed: close()

    property bool _triggeredByClear: false

    function close() {
        root.closed();
    }

    Connections {
        target: GlobalStates
        function onNotificationCenterOpenChanged() {
            if (GlobalStates.notificationCenterOpen) {
                root.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: {
        if (GlobalStates.notificationCenterOpen) {
            root.forceActiveFocus();
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.panel
        
        // MD3 Outline Style
        border.width: 1
        border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
            topMargin: 12
        }
        spacing: 12

        // ── Media Card ──
        MediaCard {
            Layout.fillWidth: true
            visible: (Config.options.media?.showMediaCard ?? true) && MprisController.activePlayer !== null
        }

        // ── Weather Card ──
        WeatherCard {
            Layout.fillWidth: true
            visible: Config.options.weather?.enable ?? true
        }

        // ── Notification Island ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Appearance.sizes.notificationIslandMaxHeight
            
            color: Appearance.colors.colLayer1
            radius: Appearance.rounding.panel
            
            ColumnLayout {
                id: islandColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // ── Main Content (List or Placeholder) ──
                Item {
                    id: listContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    // Placeholder (No Notifications)
                    ColumnLayout {
                        id: placeholder
                        anchors.centerIn: parent
                        visible: opacity > 0
                        opacity: Notifications.list.length === 0 ? 1 : 0
                        spacing: 0
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 250; easing.type: Easing.OutSine }
                        }
                        
                        MaterialShape { 
                            Layout.alignment: Qt.AlignCenter
                            implicitWidth: 100
                            implicitHeight: 100
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            shape: MaterialShape.Shape.Ghostish 
                            
                            MaterialSymbol {
                                id: bellIcon
                                anchors.centerIn: parent
                                text: "notifications"
                                iconSize: 56
                                color: Appearance.m3colors.m3onSurfaceVariant 
                                
                                transform: Rotation { origin.x: bellIcon.width / 2; origin.y: 0; angle: 0; id: bellRotation }

                                SequentialAnimation {
                                    id: bellSwingAnim
                                    
                                    NumberAnimation { target: bellRotation; property: "angle"; from: 0; to: 20; duration: 250; easing.type: Easing.OutBack }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: 20; to: -20; duration: 400; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: -20; to: 15; duration: 300; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: 15; to: -10; duration: 250; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: bellRotation; property: "angle"; from: -10; to: 0; duration: 200; easing.type: Easing.OutSine }
                                }

                                Connections {
                                    target: Notifications
                                    function onListChanged() {
                                        // Only trigger if empty and not from the Clear All button (which handles its own animation timing)
                                        if (Notifications.list.length === 0 && !root._triggeredByClear) {
                                            bellSwingAnim.restart()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Notification List
                    NotificationListView {
                        id: listview
                        anchors.fill: parent
                        visible: Notifications.list.length > 0 || opacity > 0
                        clip: true

                        opacity: root._triggeredByClear ? 0 : 1
                        Behavior on opacity {
                            NumberAnimation { duration: 250; easing.type: Easing.OutSine }
                        }
                    }
                }

                // ── Bottom Action Row ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    visible: true 

                    SegmentedButton {
                        isHighlighted: Notifications.silent
                        forcePill: true
                        implicitWidth: 56
                        implicitHeight: 40
                        iconName: Notifications.silent ? "notifications_off" : "notifications_active"
                        iconSize: 20
                        
                        colActive: Appearance.m3colors.m3primaryContainer
                        colActiveText: Appearance.m3colors.m3onPrimaryContainer
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        colInactiveText: Appearance.m3colors.m3onSurfaceVariant
                        
                        onClicked: Notifications.silent = !Notifications.silent
                    }

                    // Notification Count Wrapper
                    SegmentedWrapper {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        forcePill: true
                        smallRadius: 4
                        color: Appearance.m3colors.m3surfaceContainerHigh
                        
                        StyledText {
                            anchors.centerIn: parent
                            text: Notifications.list.length > 0 ? Notifications.list.length + " notifications" : "No notifications"
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.m3colors.m3onSurfaceVariant
                        }
                    }

                    SegmentedButton {
                        implicitWidth: 56
                        implicitHeight: 40
                        forcePill: true
                        iconName: "delete_sweep"
                        iconSize: 20
                        enabled: Notifications.list.length > 0
                        opacity: enabled ? 1 : 0.5
                        
                        colInactive: Appearance.m3colors.m3surfaceContainerHigh
                        onClicked: {
                            root._triggeredByClear = true
                            // Give time for list to fade out before actually clearing
                            clearDelayTimer.restart()
                        }
                    }

                    Timer {
                        id: clearDelayTimer
                        interval: 250
                        repeat: false
                        onTriggered: {
                            Notifications.discardAllNotifications()
                            if (root._triggeredByClear) {
                                bellSwingAnim.restart()
                                root._triggeredByClear = false
                            }
                        }
                    }
                }
            }
        }
    }
}
