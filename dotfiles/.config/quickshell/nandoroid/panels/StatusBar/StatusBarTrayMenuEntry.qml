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
    
    implicitWidth: contentLayout.implicitWidth + 24
    implicitHeight: menuEntry.isSeparator ? 1 : 36
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
        spacing: 8
        visible: !root.menuEntry.isSeparator
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }

        // Interaction column (checkbox/radio)
        Item {
            visible: root.forceInteractionColumn
            implicitWidth: 16
            implicitHeight: 16
            
            // Checkmark for checked items
            MaterialSymbol {
                anchors.fill: parent
                text: "check"
                iconSize: 16
                visible: root.menuEntry.checkState === Qt.Checked
            }
        }

        // Icon column
        Item {
            visible: root.forceIconColumn
            implicitWidth: 16
            implicitHeight: 16
            
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
            iconSize: 16
        }
    }
}
