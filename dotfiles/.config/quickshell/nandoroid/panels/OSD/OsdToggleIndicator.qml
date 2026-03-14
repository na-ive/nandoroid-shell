import "../../core"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Refactored OSD Toggle Indicator (Power Mode/Layout/Charging)
 * Simplified structure to eliminate rendering noise.
 */
Item {
    id: root
    
    // Required properties
    property string icon: ""
    property string name: ""
    property string statusText: ""
    property var shape
    
    // Root dimensions for the Loader/PanelWindow
    implicitWidth: 340
    implicitHeight: 48

    Rectangle {
        id: valueIndicator
        anchors.fill: parent
        radius: height / 2
        color: Appearance.m3colors.m3surfaceContainer

        RowLayout {
            id: valueRow
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // ── Slot Kiri: Icon Wrapper ──
            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter

                MaterialShapeWrappedMaterialSymbol {
                    id: iconMain
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    
                    shapeString: {
                        if (typeof root.shape === "string" && root.shape !== "") return root.shape;
                        if (root.name.toLowerCase().includes("power")) return "Sunny";
                        if (root.name.toLowerCase().includes("battery") || root.name.toLowerCase().includes("charging")) return "Gem";
                        if (root.name.toLowerCase().includes("layout")) return "PuffyDiamond";
                        return "Ghostish";
                    }
                    
                    text: root.icon
                    iconSize: 18
                    
                    color: Appearance.m3colors.m3primaryContainer
                    colSymbol: Appearance.m3colors.m3onPrimaryContainer
                }
            }

            // ── Slot Tengah: Main Content (Text Pill) ──
            Rectangle {
                id: textWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 16
                color: Appearance.m3colors.m3surfaceContainerHighest
                
                Text {
                    anchors.centerIn: parent
                    text: root.statusText !== "" ? root.statusText : root.name
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Appearance.m3colors.m3onSurface
                    elide: Text.ElideRight
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            // ── Slot Kanan: Category Label (Centered Square) ──
            Rectangle {
                id: contextSlot
                Layout.preferredWidth: 44
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                radius: 12 
                color: Appearance.m3colors.m3secondaryContainer

                Text {
                    anchors.centerIn: parent
                    text: root.name.substring(0, 2).toUpperCase()
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3onSecondaryContainer
                    opacity: 0.8
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
