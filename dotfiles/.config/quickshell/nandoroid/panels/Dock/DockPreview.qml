import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PopupWindow {
    id: root

    property string appId: ""
    property Item targetButton: null
    property var parentWindow: null
    readonly property bool hovered: popupHoverHandler.hovered
    property bool shown: false
    readonly property int threshold: Config.ready ? (Config.options.dock.previewThreshold ?? 3) : 3
    readonly property var liveToplevels: {
        if (!appId)
            return [];

        const canonical = appId.toLowerCase();
        return Array.from(ToplevelManager.toplevels.values).filter((t) => {
            return (t.appId && TaskbarApps.normalizeAppId(t.appId) === canonical);
        });
    }
    readonly property bool useRich: liveToplevels.length > 0 && liveToplevels.length < threshold

    function close() {
        if (!shown && !visible)
            return ;

        shown = false;
    }

    function show(button, appData) {
        if (!appData || appData.toplevels.length === 0) {
            close();
            return ;
        }
        hideTimer.stop();
        targetButton = button;
        appId = appData.appId;
        root.shown = true;
    }

    function requestHide() {
        if (!popupHoverHandler.hovered)
            hideTimer.restart();

    }

    function cancelHide() {
        hideTimer.stop();
    }

    visible: shown || previewContainer.opacity > 0.01
    color: "transparent"
    implicitWidth: previewContainer.width + 24 * Appearance.effectiveScale
    implicitHeight: previewContainer.height + 24 * Appearance.effectiveScale
    onLiveToplevelsChanged: {
        if (shown && liveToplevels.length === 0)
            root.close();

    }

    anchor {
        window: parentWindow
        rect.x: {
            if (!targetButton)
                return 0;

            const _ = targetButton.x + targetButton.y + targetButton.width + targetButton.height;
            return targetButton.mapToItem(null, targetButton.width / 2, 0).x;
        }
        rect.y: {
            if (!targetButton)
                return 0;

            const _ = targetButton.x + targetButton.y + targetButton.width + targetButton.height;
            return targetButton.mapToItem(null, 0, 4 * Appearance.effectiveScale).y;
        }
        edges: Edges.Top
        gravity: Edges.Top
    }

    Rectangle {
        id: previewContainer

        width: useRich ? (richRow.implicitWidth + 12 * Appearance.effectiveScale) : 210 * Appearance.effectiveScale
        height: useRich ? (richRow.implicitHeight + 12 * Appearance.effectiveScale) : Math.min(300 * Appearance.effectiveScale, previewListView.contentHeight + 12 * Appearance.effectiveScale)
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        opacity: root.shown ? 0.98 : 0
        scale: root.shown ? 1 : 0.9
        transformOrigin: Item.Bottom

        HoverHandler {
            id: popupHoverHandler

            onHoveredChanged: {
                if (hovered)
                    hideTimer.stop();
                else
                    root.requestHide();
            }
        }

        StyledRectangularShadow {
            target: parent
            opacity: previewContainer.opacity
            z: -1
        }

        RowLayout {
            id: richRow

            visible: root.useRich
            anchors.fill: parent
            anchors.margins: 6 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale

            Repeater {
                model: root.useRich ? root.liveToplevels : []

                delegate: Rectangle {
                    id: card

                    required property var modelData

                    Layout.preferredWidth: 200 * Appearance.effectiveScale
                    Layout.preferredHeight: 152 * Appearance.effectiveScale
                    Layout.fillWidth: false
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer1
                    border.width: modelData.activated ? 2 * Appearance.effectiveScale : 0
                    border.color: Appearance.colors.colPrimary

                    MouseArea {
                        id: cardHover

                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.MiddleButton) {
                                modelData.close();
                            } else {
                                modelData.activate();
                                root.close();
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Appearance.m3colors.m3primary
                        opacity: cardHover.containsMouse ? 0.1 : 0

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4 * Appearance.effectiveScale
                        spacing: 4 * Appearance.effectiveScale

                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 112 * Appearance.effectiveScale
                            radius: Appearance.rounding.verysmall
                            color: Appearance.colors.colLayer2

                            ScreencopyView {
                                id: thumb

                                anchors.fill: parent
                                captureSource: root.visible ? modelData : null
                                live: root.visible
                                paintCursor: true
                                constraintSize: Qt.size(480, 270)
                                opacity: hasContent ? 1 : 0

                                Behavior on opacity {
                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                }

                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: !thumb.hasContent
                                text: "web_asset"
                                iconSize: 32 * Appearance.effectiveScale
                                color: Appearance.colors.colOnLayer1
                            }

                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28 * Appearance.effectiveScale
                            spacing: 4 * Appearance.effectiveScale

                            StyledText {
                                text: modelData.title || I18nService.tr("Window")
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            RippleButton {
                                id: cardClose

                                Layout.preferredWidth: 28 * Appearance.effectiveScale
                                Layout.preferredHeight: 28 * Appearance.effectiveScale
                                Layout.alignment: Qt.AlignVCenter
                                padding: 0
                                buttonRadius: Appearance.rounding.verysmall
                                colBackground: hovered ? Appearance.colors.colErrorContainer : "transparent"
                                onClicked: modelData.close()

                                contentItem: Item {
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 16 * Appearance.effectiveScale
                                        color: parent.parent.hovered ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
                                    }

                                }

                            }

                        }

                    }

                }

            }

        }

        StyledListView {
            id: previewListView

            visible: !root.useRich
            anchors.fill: parent
            anchors.margins: 6 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            clip: true
            interactive: contentHeight > height
            model: root.useRich ? [] : root.liveToplevels

            delegate: Rectangle {
                required property var modelData

                width: ListView.view.width
                height: 36 * Appearance.effectiveScale
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.small
                border.width: modelData.activated ? 1 * Appearance.effectiveScale : 0
                border.color: Appearance.colors.colPrimary

                MouseArea {
                    id: itemMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        modelData.activate();
                        root.close();
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: Appearance.m3colors.m3primary
                    opacity: (itemMouseArea.containsMouse || closeBtn.hovered) ? 0.12 : 0

                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }

                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10 * Appearance.effectiveScale
                    anchors.rightMargin: 6 * Appearance.effectiveScale
                    spacing: 8 * Appearance.effectiveScale

                    StyledText {
                        text: modelData.title || I18nService.tr("Window")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    RippleButton {
                        id: closeBtn

                        Layout.preferredWidth: 28 * Appearance.effectiveScale
                        Layout.preferredHeight: 28 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignVCenter
                        padding: 0
                        buttonRadius: Appearance.rounding.verysmall
                        colBackground: hovered ? Appearance.colors.colErrorContainer : "transparent"
                        onClicked: modelData.close()

                        contentItem: Item {
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 16 * Appearance.effectiveScale
                                color: parent.parent.hovered ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
                            }

                        }

                    }

                }

            }

        }

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Behavior on scale {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

    }

    Timer {
        id: hideTimer

        interval: 150
        onTriggered: root.close()
    }

}
