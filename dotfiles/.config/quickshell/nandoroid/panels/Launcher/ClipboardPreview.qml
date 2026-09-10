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
    readonly property bool isHexColor: {
        if (!selectedItem || selectedItem.isImage) return false;
        const s = (selectedItem.name || fullTextContent || "").trim();
        return /^#?([0-9A-Fa-f]{3,4}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$/.test(s);
    }
    function formatHex(s) {
        let c = s.trim();
        if (/^[0-9A-Fa-f]{3,4}$|^[0-9A-Fa-f]{6}$|^[0-9A-Fa-f]{8}$/.test(c)) return "#" + c;
        return c;
    }
    function hexContrast(hex) {
        let c = hex.trim().replace("#", "");
        if (c.length === 3) c = c[0]+c[0]+c[1]+c[1]+c[2]+c[2];
        if (c.length === 4) c = c[0]+c[0]+c[1]+c[1]+c[2]+c[2];
        if (c.length === 8) c = c.substring(0,6);
        const r = parseInt(c.substring(0,2),16), g = parseInt(c.substring(2,4),16), b = parseInt(c.substring(4,6),16);
        if (isNaN(r)||isNaN(g)||isNaN(b)) return Appearance.m3colors.m3onSurface;
        return ((r*299+g*587+b*114)/1000 >= 128) ? "#000000" : "#ffffff";
    }
    
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

    Rectangle {
        anchors.fill: parent
        anchors.margins: 8 * Appearance.effectiveScale
        anchors.bottomMargin: 56 * Appearance.effectiveScale
        radius: 8 * Appearance.effectiveScale
        color: root.isHexColor ? root.formatHex((selectedItem ? selectedItem.name : "")) : "transparent"
        border.width: 1
        border.color: Qt.rgba(0,0,0,0.08)
        visible: root.isHexColor
        clip: true

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 6 * Appearance.effectiveScale
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.formatHex((selectedItem ? selectedItem.name : "")).toUpperCase()
                font.pixelSize: Math.round(16 * Appearance.effectiveScale)
                font.family: Appearance.font.family.monospace
                font.weight: Font.Bold
                color: root.hexContrast((selectedItem ? selectedItem.name : ""))
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "HEX COLOR"
                font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                color: root.hexContrast((selectedItem ? selectedItem.name : ""))
                opacity: 0.7
                font.letterSpacing: 1.2
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale
        anchors.bottomMargin: 48 * Appearance.effectiveScale // Make room for footer
        visible: !!(root.selectedItem && !root.selectedItem.isImage && !root.isHexColor)
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

