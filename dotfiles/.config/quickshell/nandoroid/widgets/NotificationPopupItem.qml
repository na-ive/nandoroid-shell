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
    property real padding: 16 * Appearance.effectiveScale

    property alias dragDiffX: dragManager.dragDiffX
    property alias dragging: dragManager.dragging
    property bool wasDragging: false
    readonly property real currentXOffset: background.anchors.leftMargin

    function destroyWithAnimation(left = false) {
        dragManager.resetDrag();
        background.anchors.leftMargin = background.anchors.leftMargin; // Break binding
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    SequentialAnimation {
        id: destroyAnimation
        property bool left: true
        running: false
        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + 100 * Appearance.effectiveScale) * (destroyAnimation.left ? -1 : 1)
            duration: 300
            easing.type: Easing.InQuint
        }
        onFinished: {
            if (notificationObject) Notifications.discardNotification(notificationObject.notificationId);
        }
    }

    implicitHeight: background.height
    width: parent ? parent.width : 400 * Appearance.effectiveScale

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

        if (hoverHandler.hovered || dragManager.pressed) {
            notificationObject.timer.stop();
        } else {
            if (!notificationObject.timer.running) {
                notificationObject.timer.start();
            }
        }
    }

    DragManager {
        id: dragManager
        anchors.fill: background
        interactive: true
        automaticallyReset: false
        onPressed: root.wasDragging = false
        onDraggingChanged: if (dragging) root.wasDragging = true
        onClicked: {
            if (!root.wasDragging && Math.abs(dragDiffX) < 5 * Appearance.effectiveScale) {
                root.expanded = !root.expanded;
            }
        }
        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > 70 * Appearance.effectiveScale) {
                root.destroyWithAnimation(diffX < 0);
            } else {
                dragManager.resetDrag();
            }
        }
    }

    Rectangle {
        id: background
        anchors.left: parent.left
        width: parent.width
        radius: Appearance.rounding.normal
        color: (notificationObject && notificationObject.isRestartRequired) ? 
            Appearance.colors.colWarningContainer : Appearance.m3colors.m3surfaceContainer
        clip: true
        
        opacity: 1 - (Math.abs(anchors.leftMargin) / (root.width * 1.2))

        // MD3 Outline Style
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: (notificationObject && notificationObject.isRestartRequired) ? 
            Functions.ColorUtils.applyAlpha(Appearance.colors.colWarning, 0.12) : Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3onSurface, 0.12)

        anchors.leftMargin: dragManager.dragDiffX
        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging && !destroyAnimation.running
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

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.padding
            spacing: 6 * Appearance.effectiveScale

            // Warning Header for Restart
            Rectangle {
                visible: notificationObject && notificationObject.isRestartRequired
                anchors.horizontalCenter: parent.horizontalCenter
                height: 28 * Appearance.effectiveScale
                width: warningHeaderRow.implicitWidth + 24 * Appearance.effectiveScale
                radius: height / 2
                color: Appearance.colors.colWarning
                
                Row {
                    id: warningHeaderRow
                    spacing: 6 * Appearance.effectiveScale
                    anchors.centerIn: parent
                    
                    MaterialSymbol {
                        text: "restart_alt"
                        color: Appearance.colors.colOnWarning
                        iconSize: 18 * Appearance.effectiveScale
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Restart Required"
                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnWarning
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

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
                font.pixelSize: Math.round(14 * Appearance.effectiveScale)
                horizontalAlignment: notificationObject && notificationObject.isRestartRequired ? Text.AlignHCenter : Text.AlignLeft
                
                wrapMode: root.expanded ? Text.Wrap : Text.NoWrap
                maximumLineCount: root.expanded ? 12 : 1
                elide: Text.ElideRight 
                
                visible: text !== ""
                color: (notificationObject && notificationObject.isRestartRequired) ? 
                    Appearance.colors.colOnWarningContainer : Appearance.m3colors.m3onSurface
                textFormat: Text.StyledText // Better eliding support for simple HTML like <b>

                topPadding: notificationObject && notificationObject.isRestartRequired ? 4 * Appearance.effectiveScale : 0

                Behavior on maximumLineCount {
                    NumberAnimation { duration: 200 }
                }
            }
            
            // Actions (Only when expanded) - Flickable Row
            Item {
                width: parent.width
                height: actionsFlickable.height
                visible: root.expanded && notificationObject

                ScrollEdgeFade {
                    target: actionsFlickable
                    vertical: false
                    fadeSize: 32 * Appearance.effectiveScale
                    color: notificationObject && notificationObject.isRestartRequired ? 
                        Appearance.colors.colWarningContainer : Appearance.m3colors.m3surfaceContainer
                }

                StyledFlickable {
                    id: actionsFlickable
                    anchors.fill: parent
                    height: actionsRow.implicitHeight
                    contentWidth: actionsRow.implicitWidth
                    clip: true
                    interactive: true

                    Row {
                        id: actionsRow
                        spacing: 8 * Appearance.effectiveScale
                    
                        readonly property bool isWarning: notificationObject && notificationObject.isRestartRequired
                        readonly property bool hasDefaultAction: {
                            if (!notificationObject) return false;
                            for (var i = 0; i < notificationObject.actions.length; i++) {
                                if (notificationObject.actions[i].identifier === "default") return true;
                            }
                            return false;
                        }
                        readonly property color btnBg: isWarning ? "transparent" : (notificationObject && notificationObject.urgency == NotificationUrgency.Critical ? Appearance.m3colors.m3secondaryContainer : Appearance.m3colors.m3surfaceContainerHighest)
                        readonly property color btnHover: isWarning ? Functions.ColorUtils.applyAlpha("white", 0.05) : (notificationObject && notificationObject.urgency == NotificationUrgency.Critical ? Appearance.m3colors.m3secondaryFixedDim : Appearance.m3colors.m3surfaceBright)

                        readonly property int totalButtons: (notificationObject ? notificationObject.actions.length : 0) + (notificationObject && notificationObject.isRestartRequired ? 3 : 2)
                        readonly property real buttonWidth: Math.max(100 * Appearance.effectiveScale, (actionsFlickable.width - (spacing * (totalButtons - 1))) / totalButtons)

                        NotificationActionButton {
                            visible: actionsRow.isWarning
                            width: actionsRow.buttonWidth
                            onClicked: {
                                Session.reboot();
                            }
                            colBackground: Appearance.colors.colWarning
                            colBackgroundHover: Functions.ColorUtils.mix(Appearance.colors.colWarning, "white", 0.95)
                            colText: Appearance.colors.colOnWarning
                            contentItem: Item {
                                implicitWidth: innerRowRestart.implicitWidth
                                implicitHeight: innerRowRestart.implicitHeight
                                Row {
                                    id: innerRowRestart
                                    spacing: 4 * Appearance.effectiveScale
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        iconSize: 16 * Appearance.effectiveScale
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Appearance.colors.colOnWarning
                                        text: "restart_alt"
                                    }
                                    StyledText {
                                        text: "Restart"
                                        font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                        color: Appearance.colors.colOnWarning
                                    }
                                }
                            }
                        }

                        NotificationActionButton {
                            visible: actionsRow.hasDefaultAction
                            width: actionsRow.buttonWidth
                            onClicked: {
                                if (notificationObject) Notifications.attemptInvokeAction(notificationObject.notificationId, "default");
                            }
                            colBackground: actionsRow.btnBg
                            colBackgroundHover: actionsRow.btnHover
                            colText: actionsRow.isWarning ? Appearance.colors.colOnWarningContainer : 
                                (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            contentItem: Item {
                                implicitWidth: innerRowView.implicitWidth
                                implicitHeight: innerRowView.implicitHeight
                                Row {
                                    id: innerRowView
                                    spacing: 4 * Appearance.effectiveScale
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        iconSize: 16 * Appearance.effectiveScale
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: parent.parent.parent.colText
                                        text: "visibility"
                                    }
                                    StyledText {
                                        text: "View"
                                        font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                        color: parent.parent.parent.colText
                                    }
                                }
                            }
                        }

                        NotificationActionButton {
                            width: actionsRow.buttonWidth
                            buttonText: "Close"
                            onClicked: {
                                if (notificationObject) Notifications.discardNotification(notificationObject.notificationId);
                            }
                            colBackground: actionsRow.btnBg
                            colBackgroundHover: actionsRow.btnHover
                            colText: actionsRow.isWarning ? Appearance.colors.colOnWarningContainer : 
                                (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                            contentItem: Item {
                                implicitWidth: innerRowClose.implicitWidth
                                implicitHeight: innerRowClose.implicitHeight
                                Row {
                                    id: innerRowClose
                                    spacing: 4 * Appearance.effectiveScale
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        iconSize: 16 * Appearance.effectiveScale
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: parent.parent.parent.colText
                                        text: "close"
                                    }
                                    StyledText {
                                        text: "Close"
                                        font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                        color: parent.parent.parent.colText
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
                            colBackground: actionsRow.btnBg
                            colBackgroundHover: actionsRow.btnHover
                            colText: actionsRow.isWarning ? Appearance.colors.colOnWarningContainer : 
                                (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface

                            Timer {
                                id: copyIconTimer
                                interval: 1500
                                onTriggered: copyIcon.text = "content_copy"
                            }

                            contentItem: Item {
                                implicitWidth: innerRowCopy.implicitWidth
                                implicitHeight: innerRowCopy.implicitHeight
                                Row {
                                    id: innerRowCopy
                                    spacing: 4 * Appearance.effectiveScale
                                    anchors.centerIn: parent
                                    MaterialSymbol {
                                        id: copyIcon
                                        iconSize: 16 * Appearance.effectiveScale
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: parent.parent.parent.colText
                                        text: "content_copy"
                                    }
                                    StyledText {
                                        text: "Copy"
                                        font.pixelSize: Math.round(12 * Appearance.effectiveScale)
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                        color: parent.parent.parent.colText
                                    }
                                }
                            }
                        }

                        Repeater {
                            model: notificationObject ? notificationObject.actions : []
                            NotificationActionButton {
                                visible: modelData.identifier !== "default"
                                width: actionsRow.buttonWidth
                                required property var modelData
                                buttonText: modelData.text
                                colBackground: actionsRow.btnBg
                                colBackgroundHover: actionsRow.btnHover
                                colText: actionsRow.isWarning ? Appearance.colors.colOnWarningContainer : 
                                    (notificationObject && notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                onClicked: {
                                    Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
