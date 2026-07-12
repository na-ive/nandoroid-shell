import "../core"
import "../services"
import "../core/functions/NotificationUtils.js" as NotificationUtils
import "../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

/**
 * Individual notification item.
 * 100% Ported from 'ii' source port.
 */
Item { // Notification item area
    id: root
    property var notificationObject
    property bool expanded: false
    property bool onlyNotification: false
    property real fontSize: Appearance.font.pixelSize.small
    property real padding: onlyNotification ? 0 : 8 * Appearance.effectiveScale
    property real summaryElideRatio: 0.85

    property real dragConfirmThreshold: 70 * Appearance.effectiveScale // Drag further to discard notification
    property real dismissOvershoot: 60 * Appearance.effectiveScale // Account for gaps and bouncy animations
    property var qmlParent: root?.parent?.parent // There's something between this and the parent ListView
    property int index: 0
    property var parentDragIndex: qmlParent?.dragIndex ?? -1
    property var parentDragDistance: qmlParent?.dragDistance ?? 0
    property var dragIndexDiff: Math.abs(parentDragIndex - index)
    property real xOffset: dragIndexDiff == 0 ? parentDragDistance : 
        Math.abs(parentDragDistance) > dragConfirmThreshold ? 0 :
        dragIndexDiff == 1 ? (parentDragDistance * 0.3) :
        dragIndexDiff == 2 ? (parentDragDistance * 0.1) : 0

    implicitHeight: background.implicitHeight

    function destroyWithAnimation(left = false) {
        if (qmlParent && qmlParent.resetDrag) qmlParent.resetDrag()
        background.anchors.leftMargin = background.anchors.leftMargin; // Break binding
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    TextMetrics {
        id: summaryTextMetrics
        font.pixelSize: root.fontSize
        text: root.notificationObject.summary || ""
    }

    SequentialAnimation { // Drag finish animation
        id: destroyAnimation
        property bool left: true
        running: false

        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
        onFinished: () => {
            Notifications.discardNotification(notificationObject.notificationId);
        }
    }

    DragManager { // Drag manager
        id: dragManager
        anchors.fill: root
        anchors.leftMargin: root.expanded ? -notificationIcon.implicitWidth : 0
        interactive: expanded || onlyNotification
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) {
                root.destroyWithAnimation();
            }
        }

        onDraggingChanged: () => {
            if (dragging && qmlParent) {
                qmlParent.dragIndex = root.index ?? root.parent.children.indexOf(root);
            }
        }

        onDragDiffXChanged: () => {
            if (qmlParent) qmlParent.dragDistance = dragDiffX;
        }

        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0);
            else 
                dragManager.resetDrag();
        }
    }

    NotificationAppIcon { // App icon
        id: notificationIcon
        opacity: (!onlyNotification && notificationObject.image != "" && expanded) ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        image: notificationObject.image
        anchors.right: background.left
        anchors.top: background.top
        anchors.rightMargin: 10 * Appearance.effectiveScale
    }

    Rectangle { // Background of notification item
        id: background
        width: parent.width
        anchors.left: parent.left
        radius: Appearance.rounding.small
        anchors.leftMargin: root.xOffset

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
            }
        }

        color: (notificationObject.isRestartRequired) ?
            Appearance.colors.colWarningContainer :
            (expanded && !onlyNotification) ? 
                (notificationObject.urgency == NotificationUrgency.Critical) ? 
                    Functions.ColorUtils.mix(Appearance.m3colors.m3secondaryContainer, Appearance.colors.colLayer2, 0.35) :
                    (Appearance.colors.colLayer3) :
            "transparent"

        implicitHeight: expanded ? (contentColumn.implicitHeight + padding * 2) : summaryRow.implicitHeight
        Behavior on implicitHeight {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout { // Content column
            id: contentColumn
            anchors.fill: parent
            anchors.margins: expanded ? root.padding : 0
            spacing: 3 * Appearance.effectiveScale

            Behavior on anchors.margins {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            RowLayout { // Summary row
                id: summaryRow
                visible: !root.onlyNotification || !root.expanded
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale
                implicitHeight: summaryText.implicitHeight
                StyledText {
                    id: summaryText
                    Layout.fillWidth: summaryTextMetrics.width >= summaryRow.implicitWidth * root.summaryElideRatio
                    visible: !root.onlyNotification
                    font.pixelSize: root.fontSize
                    font.weight: notificationObject.isRestartRequired ? Font.Bold : Font.Normal
                    color: notificationObject.isRestartRequired ? Appearance.colors.colOnWarningContainer : Appearance.colors.colOnLayer3
                    elide: Text.ElideRight
                    text: root.notificationObject.summary || ""
                }
                StyledText {
                    id: bodyPreviewText
                    opacity: !root.expanded ? 1 : 0
                    visible: opacity > 0
                    Layout.fillWidth: true
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    font.pixelSize: root.fontSize
                    color: notificationObject.isRestartRequired ? Appearance.colors.colOnWarningContainer : Appearance.colors.colSubtext
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    textFormat: Text.StyledText
                    text: {
                        return (NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.appName || notificationObject.summary) || "").replace(/\n/g, " ")
                    }
                }
            }

            ColumnLayout { // Expanded content
                id: expandedContentColumn
                Layout.fillWidth: true
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0

                StyledText { // Notification body (expanded)
                    id: notificationBodyText
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Layout.fillWidth: true
                    font.pixelSize: root.fontSize
                    color: notificationObject.isRestartRequired ? Appearance.colors.colOnWarningContainer : Appearance.colors.colSubtext
                    wrapMode: Text.WrapAnywhere
                    elide: Text.ElideRight
                    textFormat: Text.RichText
                    text: {
                        return `<style>img{max-width:${expandedContentColumn.width}px;}</style>` + 
                            `${(NotificationUtils.processNotificationBody(notificationObject.body, notificationObject.appName || notificationObject.summary) || "").replace(/\n/g, "<br/>")}`
                    }

                    onLinkActivated: (link) => {
                        Qt.openUrlExternally(link)
                        GlobalStates.notificationCenterOpen = false
                    }
                    
                    PointingHandLinkHover {}
                }

                Item {
                    Layout.fillWidth: true
                    implicitWidth: actionsFlickable.implicitWidth
                    implicitHeight: actionsFlickable.implicitHeight

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: actionsFlickable.width
                            height: actionsFlickable.height
                            radius: Appearance.rounding.small
                        }
                    }


                    ScrollEdgeFade {
                        target: actionsFlickable
                        vertical: false
                        fadeSize: 32 * Appearance.effectiveScale
                        color: notificationObject.isRestartRequired ? 
                            Appearance.colors.colWarningContainer : 
                            (expanded && !onlyNotification ? Appearance.colors.colLayer3 : "transparent")
                    }

                    StyledFlickable { // Notification actions
                        id: actionsFlickable
                        anchors.fill: parent
                        implicitHeight: actionRowLayout.implicitHeight
                        contentWidth: actionRowLayout.implicitWidth

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on height {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on implicitHeight {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        RowLayout {
                            id: actionRowLayout
                            Layout.alignment: Qt.AlignBottom
                            spacing: 8 * Appearance.effectiveScale
                            
                            readonly property bool isWarning: notificationObject.isRestartRequired
                            readonly property bool hasDefaultAction: {
                                for (var i = 0; i < notificationObject.actions.length; i++) {
                                    if (notificationObject.actions[i].identifier === "default") return true;
                                }
                                return false;
                            }
                            readonly property color btnBg: isWarning ? "transparent" : (notificationObject.urgency == NotificationUrgency.Critical ? Appearance.m3colors.m3secondaryContainer : Appearance.m3colors.m3surfaceContainerHighest)
                            readonly property color btnHover: isWarning ? Functions.ColorUtils.applyAlpha("white", 0.05) : (notificationObject.urgency == NotificationUrgency.Critical ? Appearance.m3colors.m3secondaryFixedDim : Appearance.m3colors.m3surfaceBright)

                            NotificationActionButton {
                                id: restartBtn
                                visible: actionRowLayout.isWarning
                                Layout.fillWidth: true
                                buttonText: "Restart"
                                urgency: notificationObject.urgency
                                colBackground: Appearance.colors.colWarning
                                colBackgroundHover: Functions.ColorUtils.mix(Appearance.colors.colWarning, "white", 0.85)
                                colText: Appearance.colors.colOnWarning
                                implicitWidth: (notificationObject.actions.length == 0) ? ((actionsFlickable.width - actionRowLayout.spacing * 3) / 4) : 
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    Session.reboot();
                                }

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
                                            font.pixelSize: 12 * Appearance.effectiveScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                            color: Appearance.colors.colOnWarning
                                        }
                                    }
                                }
                            }

                            NotificationActionButton {
                                id: viewBtn
                                Component.onCompleted: console.log("hasDefaultAction: ", actionRowLayout.hasDefaultAction, " length: ", notificationObject.actions.length)
                                visible: actionRowLayout.hasDefaultAction
                                Layout.fillWidth: true
                                buttonText: "View"
                                urgency: notificationObject.urgency
                                colBackground: actionRowLayout.btnBg
                                colBackgroundHover: actionRowLayout.btnHover
                                colText: actionRowLayout.isWarning ? Appearance.colors.colOnWarningContainer : 
                                    (notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                implicitWidth: (notificationObject.actions.length == 0) ? (actionRowLayout.isWarning ? ((actionsFlickable.width - actionRowLayout.spacing * 3) / 4) : ((actionsFlickable.width - actionRowLayout.spacing * 2) / 3)) : 
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    Notifications.attemptInvokeAction(notificationObject.notificationId, "default");
                                    root.destroyWithAnimation()
                                }

                                contentItem: Item {
                                    implicitWidth: innerRow.implicitWidth
                                    implicitHeight: innerRow.implicitHeight
                                    Row {
                                        id: innerRow
                                        spacing: 4 * Appearance.effectiveScale
                                        anchors.centerIn: parent
                                        MaterialSymbol {
                                            iconSize: 16 * Appearance.effectiveScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: viewBtn.colText
                                            text: "visibility"
                                        }
                                        StyledText {
                                            text: "View"
                                            font.pixelSize: 12 * Appearance.effectiveScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                            color: viewBtn.colText
                                        }
                                    }
                                }
                            }

                            NotificationActionButton {
                                id: closeBtn
                                Layout.fillWidth: true
                                buttonText: "Close"
                                urgency: notificationObject.urgency
                                colBackground: actionRowLayout.btnBg
                                colBackgroundHover: actionRowLayout.btnHover
                                colText: actionRowLayout.isWarning ? Appearance.colors.colOnWarningContainer : 
                                    (notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                implicitWidth: (notificationObject.actions.length == 0) ? (actionRowLayout.isWarning ? ((actionsFlickable.width - actionRowLayout.spacing * 3) / 4) : ((actionsFlickable.width - actionRowLayout.spacing * 2) / 3)) : 
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    root.destroyWithAnimation()
                                }

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
                                            color: closeBtn.colText
                                            text: "close"
                                        }
                                        StyledText {
                                            text: "Close"
                                            font.pixelSize: 12 * Appearance.effectiveScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                            color: closeBtn.colText
                                        }
                                    }
                                }
                            }

                            Repeater {
                                id: actionRepeater
                                model: notificationObject.actions
                                NotificationActionButton {
                                    id: notifAction
                                    visible: modelData.identifier !== "default"
                                    required property var modelData
                                    Layout.fillWidth: true
                                    buttonText: modelData.text
                                    urgency: notificationObject.urgency
                                    colBackground: actionRowLayout.btnBg
                                    colBackgroundHover: actionRowLayout.btnHover
                                    colText: actionRowLayout.isWarning ? Appearance.colors.colOnWarningContainer : 
                                        (urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                    onClicked: {
                                        Notifications.attemptInvokeAction(notificationObject.notificationId, modelData.identifier);
                                        root.destroyWithAnimation()
                                    }
                                }
                            }

                            NotificationActionButton {
                                id: copyBtn
                                Layout.fillWidth: true
                                buttonText: "Copy"
                                urgency: notificationObject.urgency
                                colBackground: actionRowLayout.btnBg
                                colBackgroundHover: actionRowLayout.btnHover
                                colText: actionRowLayout.isWarning ? Appearance.colors.colOnWarningContainer : 
                                    (notificationObject.urgency == NotificationUrgency.Critical) ? Appearance.m3colors.m3onSurfaceVariant : Appearance.m3colors.m3onSurface
                                implicitWidth: (notificationObject.actions.length == 0) ? (actionRowLayout.isWarning ? ((actionsFlickable.width - actionRowLayout.spacing * 3) / 4) : ((actionsFlickable.width - actionRowLayout.spacing * 2) / 3)) : 
                                    (contentItem.implicitWidth + leftPadding + rightPadding)

                                onClicked: {
                                    Quickshell.clipboardText = notificationObject.body
                                    copyIcon.text = "inventory"
                                    copyIconTimer.restart()
                                }

                                Timer {
                                    id: copyIconTimer
                                    interval: 1500
                                    repeat: false
                                    onTriggered: {
                                        copyIcon.text = "content_copy"
                                    }
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
                                            color: copyBtn.colText
                                            text: "content_copy"
                                        }
                                        StyledText {
                                            text: "Copy"
                                            font.pixelSize: 12 * Appearance.effectiveScale
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: parent.parent.parent.width > 60 * Appearance.effectiveScale
                                            color: copyBtn.colText
                                        }
                                    }
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
}
