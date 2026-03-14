import "../../core"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Refactored OSD Value Indicator (Volume/Brightness)
 * Simplified structure to eliminate rendering noise.
 */
Item {
    id: root
    
    // Required properties
    property real value: 0
    property string icon: ""
    property string name: ""
    property var shape
    property bool rotateIcon: false
    property bool scaleIcon: false

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
                    
                    rotation: root.rotateIcon ? root.value * 360 : 0
                    scale: root.scaleIcon ? (0.85 + root.value * 0.3) : 1.0
                    
                    shapeString: (typeof root.shape === "string") ? root.shape : "Circle"
                    text: root.icon
                    iconSize: 18
                    
                    color: Appearance.m3colors.m3primaryContainer
                    colSymbol: Appearance.m3colors.m3onPrimaryContainer
                }
            }

            // ── Slot Tengah: Main Content (Sleeker StyledSlider) ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                
                StyledSlider {
                    id: portedSlider
                    anchors.centerIn: parent
                    width: parent.width
                    
                    value: root.value
                    from: 0
                    to: 1
                    enabled: false
                    
                    configuration: StyledSlider.Configuration.M
                    animateValue: true
                    
                    handleMargins: 4
                    highlightColor: Appearance.m3colors.m3primary
                    trackColor: Appearance.m3colors.m3surfaceContainerHighest
                    handleColor: Appearance.m3colors.m3primary
                }
            }

            // ── Slot Kanan: Value Indicator (Compact Centered Square) ──
            Rectangle {
                id: valueSlot
                Layout.preferredWidth: 44
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                
                radius: 12
                color: Appearance.m3colors.m3secondaryContainer

                Text {
                    anchors.centerIn: parent
                    text: Math.round(root.value * 100)
                    font.pixelSize: 13
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3onSecondaryContainer
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
