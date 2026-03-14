import "../core"
import "../services"
import "../core/functions/NotificationUtils.js" as NotificationUtils
import "../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

/**
 * Super Simplified Notification Item khusus untuk Popup.
 * Hanya Body Text & Title, tanpa header atau shadow.
 */
Item {
    id: root
    required property var modelData
    property var notificationObject: modelData
    property bool expanded: false
    property real padding: 16

    implicitHeight: background.height
    width: parent ? parent.width : 400

    Component.onCompleted: root.updateTimerState()

    onExpandedChanged: {
        root.updateTimerState();
        refreshHoverTimer.restart(); // Kick the system to notice the mouse
    }

    Timer {
        id: refreshHoverTimer
        interval: 150
        onTriggered: root.updateTimerState()
    }

    function updateTimerState() {
        if (!notificationObject || !notificationObject.timer) return;

        // Combine multiple detection sources for maximum reliability
        if (hoverHandler.hovered || dragManager.containsMouse) {
            notificationObject.timer.stop();
        } else {
            notificationObject.timer.restart();
        }
    }

    Rectangle {
        id: background
        anchors.left: parent.left
        width: parent.width
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainer
        clip: true
        
        // MD3 Outline Style
        border.width: 1
        border.color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

        anchors.leftMargin: 0
        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint
            }
        }

        height: contentColumn.height + root.padding * 2
        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: root.updateTimerState()
        }

        DragManager {
            id: dragManager
            anchors.fill: parent
            interactive: true
            automaticallyReset: false
            onClicked: {
                root.expanded = !root.expanded;
            }
            onDragReleased: (diffX, diffY) => {
                if (Math.abs(diffX) > 70) {
                    if (notificationObject) Notifications.discardNotification(notificationObject.notificationId);
                } else {
                    dragManager.resetDrag();
                }
            }
        }

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.padding
            spacing: 6

            // Header Row (App Name, Icon, Time) dihapus sesuai request

            // Title (Summary) dihapus agar jadi bubble message murni
            
            // Body Text (Combined [Header]: [Body] when collapsed)
            StyledText {
                id: bodyText
                anchors.left: parent.left
                anchors.right: parent.right
                text: {
                    if (!notificationObject) return "";
                    if (root.expanded) {
                        return NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.summary);
                    } else {
                        let summary = notificationObject.summary || "";
                        let body = notificationObject.body || "";
                        if (summary !== "" && body !== "") return "<b>" + summary + ":</b> " + body;
                        return summary !== "" ? summary : body;
                    }
                }
                font.pixelSize: 14
                
                wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
                maximumLineCount: root.expanded ? 40 : 1
                elide: Text.ElideRight 
                
                visible: text !== ""
                color: Appearance.m3colors.m3onSurface
                textFormat: Text.StyledText // Better eliding support for simple HTML like <b>

                Behavior on maximumLineCount {
                    NumberAnimation { duration: 200 }
                }
            }
            
            // Actions (Only when expanded) - Responsive Row
            Row {
                id: actionsRow
                width: parent.width
                visible: root.expanded && notificationObject
                spacing: 8
                
                readonly property int totalButtons: (notificationObject ? notificationObject.actions.length : 0) + 2
                readonly property real buttonWidth: (width - (spacing * (totalButtons - 1))) / totalButtons

                NotificationActionButton {
                    width: actionsRow.buttonWidth
                    buttonText: "Close"
                    onClicked: {
                        if (notificationObject) Notifications.discardNotification(notificationObject.notificationId);
                    }
                    contentItem: Item {
                        Row {
                            spacing: 4
                            anchors.centerIn: parent
                            MaterialSymbol {
                                iconSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                                color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                    Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                text: "close"
                            }
                            StyledText {
                                text: "Close"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.parent.parent.width > 60
                                color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                    Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            }
                        }
                    }
                }

                NotificationActionButton {
                    width: actionsRow.buttonWidth
                    onClicked: {
                        Quickshell.clipboardText = notificationObject.body
                        copyIcon.text = "inventory"
                        copyIconTimer.restart()
                    }

                    Timer {
                        id: copyIconTimer
                        interval: 1500
                        onTriggered: copyIcon.text = "content_copy"
                    }

                    contentItem: Item {
                        Row {
                            spacing: 4
                            anchors.centerIn: parent
                            MaterialSymbol {
                                id: copyIcon
                                iconSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                                color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                    Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                text: "content_copy"
                            }
                            StyledText {
                                text: "Copy"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.parent.parent.width > 60
                                color: (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? 
                                    Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            }
                        }
                    }
                }

                Repeater {
                    model: notificationObject ? notificationObject.actions : []
                    NotificationActionButton {
                        width: actionsRow.buttonWidth
                        required property var modelData
                        buttonText: modelData.text
                        onClicked: {
                            Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                        }
                    }
                }
            }
        }
    }
}
