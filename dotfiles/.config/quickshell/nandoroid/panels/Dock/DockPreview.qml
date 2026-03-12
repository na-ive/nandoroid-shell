import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../widgets"

/**
 * DockPreview.qml
 * A stable, scrollable, and live-updating window preview for the dock.
 * Updated: Supports single-window preview for better information display.
 */
PopupWindow {
    id: root
    visible: false
    
    property string appId: ""
    property Item targetButton: null
    property var parentWindow: null 
    readonly property bool hovered: popupHoverHandler.hovered
    
    property var _lockedRect: Qt.rect(0, 0, 0, 0)

    color: "transparent"
    implicitWidth: 240
    implicitHeight: 400

    anchor {
        window: parentWindow
        rect: root._lockedRect
        edges: Edges.Top
        gravity: Edges.Top
    }

    readonly property var liveToplevels: {
        if (!appId) return [];
        const lowerId = appId.toLowerCase();
        return Array.from(ToplevelManager.toplevels.values).filter(t => 
            (t.appId && t.appId.toLowerCase() === lowerId)
        );
    }

    // Auto-close when no more windows (0 windows)
    onLiveToplevelsChanged: {
        if (visible && liveToplevels.length === 0) {
            root.close();
        }
    }

    function close() {
        if (!visible) return;
        visible = false;
        targetButton = null;
        appId = "";
    }

    Rectangle {
        id: previewContainer
        width: 210
        implicitHeight: Math.min(300, previewListView.contentHeight + 12)
        height: implicitHeight
        
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1
        
        opacity: root.visible ? 0.98 : 0
        scale: root.visible ? 1 : 0.95
        
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        HoverHandler {
            id: popupHoverHandler
            onHoveredChanged: {
                if (hovered) hideTimer.stop();
                else root.requestHide();
            }
        }

        StyledListView {
            id: previewListView
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2
            clip: true
            interactive: contentHeight > height
            model: root.liveToplevels
            
            delegate: Rectangle {
                width: ListView.view.width
                height: 36
                color: itemMouseArea.containsMouse ? Appearance.colors.colLayer1 : "transparent"
                radius: Appearance.rounding.verysmall
                Behavior on color { ColorAnimation { duration: 100 } }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        modelData.activate();
                        root.close();
                    }
                }

                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 6; spacing: 8

                    StyledText {
                        text: modelData.title || "Window"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RippleButton {
                        Layout.preferredWidth: 28; Layout.preferredHeight: 28
                        buttonRadius: Appearance.rounding.verysmall
                        colBackground: hovered ? Appearance.colors.colErrorContainer : "transparent"
                        onClicked: modelData.close()

                        contentItem: MaterialSymbol {
                            text: "close"; iconSize: 16
                            color: parent.hovered ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 250 
        onTriggered: root.close()
    }

    function show(button, appData) {
        // Change: Allow showing if there is at least 1 window
        if (!appData || appData.toplevels.length === 0) {
            close();
            return;
        }
        
        hideTimer.stop();
        targetButton = button;
        appId = appData.appId;
        
        const pos = targetButton.mapToItem(null, targetButton.width / 2, 4);
        root._lockedRect = Qt.rect(pos.x, pos.y, 0, 0);
        
        root.visible = true;
    }

    function requestHide() {
        if (!popupHoverHandler.hovered) {
            hideTimer.restart();
        }
    }
}
