import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property string icon
    required property string name
    property string statusText: ""
    property var shape
    
    // Ensure minimum width of 220, or expand if text is too long
    readonly property real minWidth: (Appearance.sizes && Appearance.sizes.osdWidth) ? Appearance.sizes.osdWidth : 220
    readonly property real elevationMargin: (Appearance.sizes && Appearance.sizes.elevationMargin) ? Appearance.sizes.elevationMargin : 10

    implicitWidth: Math.max(minWidth, valueIndicator.implicitWidth) + 2 * elevationMargin
    implicitHeight: valueIndicator.implicitHeight + 2 * elevationMargin

    Rectangle {
        id: valueIndicator
        anchors {
            fill: parent
            margins: root.elevationMargin
        }
        radius: Appearance.rounding.full
        color: Appearance.m3colors.m3surfaceContainer

        implicitWidth: valueRow.implicitWidth
        implicitHeight: valueRow.implicitHeight

        RowLayout { 
            id: valueRow
            Layout.margins: 10
            anchors.fill: parent
            spacing: 15

            Item {
                implicitWidth: 30
                implicitHeight: 35
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 15
                Layout.topMargin: 9
                Layout.bottomMargin: 9

                MaterialShapeWrappedMaterialSymbol {
                    anchors {
                        fill: parent
                        margins: -5
                    }
                    iconSize: Appearance.font.pixelSize.huge
                    // Use shapeString if root.shape is a string, otherwise assume it's an enum (but we moved to strings)
                    shapeString: (typeof root.shape === "string") ? root.shape : ""
                    shape: (typeof root.shape !== "string") ? root.shape : undefined
                    text: root.icon
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: 15
                spacing: 2

                StyledText {
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    text: root.name
                }
                
                StyledText {
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                    Layout.fillWidth: true
                    text: root.statusText
                    visible: root.statusText !== ""
                }
            }
        }
    }
}
