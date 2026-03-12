import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../widgets"

/**
 * DockPreview.qml
 * A compact, vertically stacked window preview for the dock.
 */
PopupWindow {
    id: root
    visible: false
    
    property var appToplevel: null
    property Item targetButton: null
    property var parentWindow: null 
    readonly property bool hovered: popupHoverHandler.hovered
    
    color: "transparent"
    
    anchor {
        window: parentWindow
        // Map the entire button rect to the window coordinates
        rect: targetButton ? targetButton.mapToItem(null, 0, 0, targetButton.width, targetButton.height) : Qt.rect(0, 0, 0, 0)
        edges: Edges.Top
        gravity: Edges.Top
    }

    implicitWidth: previewContainer.implicitWidth
    implicitHeight: previewContainer.implicitHeight

    function close() {
        if (!visible) return;
        visible = false;
        targetButton = null;
    }

    Rectangle {
        id: previewContainer
        implicitWidth: Math.max(180, previewLayout.implicitWidth + 16)
        implicitHeight: previewLayout.implicitHeight + 12
        radius: Appearance.rounding.normal
        color: Appearance.colors.colLayer0
        border.color: Appearance.colors.colOutlineVariant
        border.width: 1

        opacity: root.visible ? 0.98 : 0
        scale: root.visible ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

        // Use HoverHandler for reliable hover detection
        HoverHandler {
            id: popupHoverHandler
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                } else {
                    root.requestHide();
                }
            }
        }

        ColumnLayout {
            id: previewLayout
            anchors.fill: parent; anchors.margins: 6; spacing: 2


            Repeater {
                model: root.appToplevel ? root.appToplevel.toplevels : []
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
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
                            onClicked: (mouse) => {
                                modelData.close();
                                // If no more windows, close the preview
                                if (root.appToplevel.toplevels.length <= 1) root.close();
                            }

                            contentItem: MaterialSymbol {
                                text: "close"; iconSize: 16
                                color: parent.hovered ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 500 
        onTriggered: root.close()
    }

    function show(button, appData) {
        if (!appData || appData.toplevels.length <= 1) {
            close();
            return;
        }
        
        hideTimer.stop();
        targetButton = button;
        appToplevel = appData;
        root.visible = true;
    }

    function requestHide() {
        // Only start the timer if the mouse is not currently over the popup
        if (!popupHoverHandler.hovered) {
            hideTimer.restart();
        }
    }
}
