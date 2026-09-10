import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../widgets"
import "../../core"
import "../../services"

Rectangle {
    id: root
    
    property var selectedItem: null
    
    radius: Appearance.rounding.small
    color: Appearance.m3colors.m3surfaceContainerHigh
    border.width: 1 * Appearance.effectiveScale
    border.color: Qt.rgba(0, 0, 0, 0.1)
    clip: true
    
    property string fullTextContent: ""
    property string _requestedId: ""
    
    Process {
        id: textDecoder
        command: ["cliphist", "decode", root._requestedId]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.selectedItem && !root.selectedItem.isImage && root._requestedId === root.selectedItem.id.replace("clip-", "")) {
                    root.fullTextContent = this.text;
                }
            }
        }
    }
    
    onSelectedItemChanged: {
        if (!selectedItem || selectedItem.isImage) return;
        const newId = selectedItem.id.replace("clip-", "");
        if (newId === root._requestedId && root.fullTextContent !== "") return;
        root._requestedId = newId;
        textDecoder.running = false;
        Qt.callLater(() => {
            if (root.selectedItem && !root.selectedItem.isImage && root._requestedId === root.selectedItem.id.replace("clip-", "")) {
                textDecoder.running = true;
            }
        });
    }
    
    Image {
        id: imgPreview
        anchors.fill: parent
        anchors.margins: 8 * Appearance.effectiveScale
        source: (root.selectedItem && root.selectedItem.isImage) ? "file://" + root.selectedItem.imagePath : ""
        visible: !!(root.selectedItem && root.selectedItem.isImage)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: true
    }
    

    // Text Preview
    ScrollView {
        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale
        anchors.bottomMargin: 48 * Appearance.effectiveScale // Make room for footer
        visible: !!(root.selectedItem && !root.selectedItem.isImage)
        clip: true
        
        TextArea {
            width: parent.width
            textFormat: TextEdit.PlainText
            text: root.fullTextContent
            font.pixelSize: Math.round(10 * Appearance.effectiveScale)
            color: Appearance.m3colors.m3onSurface
            wrapMode: Text.WrapAnywhere
            readOnly: true
            background: Item {}
            
            // Allow selection and copying inside the preview!
            selectByMouse: true
        }
    }
        // Action Footer
    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 1 * Appearance.effectiveScale
        height: 48 * Appearance.effectiveScale
        visible: root.selectedItem !== null
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            
            Item { Layout.fillWidth: true }
            
            RippleButton {
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                implicitWidth: deleteIcon.implicitWidth + deleteText.implicitWidth + 24 * Appearance.effectiveScale
                buttonRadius: 8 * Appearance.effectiveScale
                colBackground: Appearance.m3colors.m3errorContainer
                colRipple: Appearance.m3colors.m3onErrorContainer
                
                onClicked: {
                    if (root.selectedItem) {
                        LauncherSearch.deleteClipboardItem(root.selectedItem);
                    }
                }
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4 * Appearance.effectiveScale
                    MaterialSymbol {
                        id: deleteIcon
                        text: "delete"
                        iconSize: 16 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3onErrorContainer
                    }
                    StyledText {
                        id: deleteText
                        text: I18nService.tr("Delete (Del)")
                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: Appearance.m3colors.m3onErrorContainer
                    }
                }
            }
        }
    }
}

