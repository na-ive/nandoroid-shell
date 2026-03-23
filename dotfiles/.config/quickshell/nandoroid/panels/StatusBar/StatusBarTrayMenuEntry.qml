import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../core"
import "../../widgets"

RippleButton {
    id: root
    required property QsMenuEntry menuEntry
    property bool forceIconColumn: false
    property bool forceInteractionColumn: false
    
    signal dismiss()
    signal openSubmenu(var handle)

    colBackground: menuEntry.isSeparator ? Appearance.colors.colOutlineVariant : "transparent"
    enabled: !menuEntry.isSeparator
    
    implicitWidth: contentLayout.implicitWidth + 24 * Appearance.effectiveScale
    implicitHeight: menuEntry.isSeparator ? 1 * Appearance.effectiveScale : 36 * Appearance.effectiveScale
    Layout.fillWidth: true

    onClicked: {
        if (menuEntry.hasChildren) {
            openSubmenu(menuEntry);
            return;
        }
        menuEntry.triggered();
        dismiss();
    }

    contentItem: RowLayout {
        id: contentLayout
        spacing: 8 * Appearance.effectiveScale
        visible: !root.menuEntry.isSeparator
        anchors {
            fill: parent
            leftMargin: 12 * Appearance.effectiveScale
            rightMargin: 12 * Appearance.effectiveScale
        }

        // Interaction column (checkbox/radio)
        Item {
            visible: root.forceInteractionColumn
            implicitWidth: 16 * Appearance.effectiveScale
            implicitHeight: 16 * Appearance.effectiveScale
            
            // Checkmark for checked items
            MaterialSymbol {
                anchors.fill: parent
                text: "check"
                iconSize: 16 * Appearance.effectiveScale
                visible: root.menuEntry.checkState === Qt.Checked
            }
        }

        // Icon column
        Item {
            visible: root.forceIconColumn
            implicitWidth: 16 * Appearance.effectiveScale
            implicitHeight: 16 * Appearance.effectiveScale
            
            IconImage {
                anchors.fill: parent
                source: root.menuEntry.icon
                asynchronous: true
                visible: source.length > 0
            }
        }

        StyledText {
            id: label
            text: root.menuEntry.text
            font.pixelSize: Appearance.font.pixelSize.smaller
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
        }

        // Submenu indicator
        MaterialSymbol {
            visible: root.menuEntry.hasChildren
            text: "chevron_right"
            iconSize: 16 * Appearance.effectiveScale
        }
    }
}
