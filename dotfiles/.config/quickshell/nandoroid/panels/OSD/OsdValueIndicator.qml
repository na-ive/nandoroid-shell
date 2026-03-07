import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * Refactored OSD Value Indicator (Volume/Brightness)
 * Scaled down to be less "fat" and more aligned with Android 16 proportions.
 */
Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property var shape
    property bool rotateIcon: false
    property bool scaleIcon: false

    // More compact dimensions
    readonly property real osdWidth: 340
    readonly property real osdHeight: 48 // Reduced from 64
    readonly property real elevationMargin: 10

    implicitWidth: osdWidth + 2 * elevationMargin
    implicitHeight: osdHeight + 2 * elevationMargin

    Rectangle {
        id: valueIndicator
        anchors.fill: parent
        anchors.margins: root.elevationMargin
        radius: Appearance.rounding.full
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
                    iconSize: 18 // Smaller icon
                    
                    color: Appearance.m3colors.m3primaryContainer
                    colSymbol: Appearance.m3colors.m3onPrimaryContainer
                }
            }

            // ── Slot Tengah: Main Content (Sleeker StyledSlider) ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32 // Matches icon wrapper height
                Layout.alignment: Qt.AlignVCenter
                
                StyledSlider {
                    id: portedSlider
                    anchors.centerIn: parent
                    width: parent.width
                    
                    value: root.value
                    from: 0
                    to: 1
                    enabled: false
                    
                    // Use M configuration (Medium) for a sleeker look
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
                Layout.preferredHeight: 32 // Matches slider/icon height
                Layout.alignment: Qt.AlignVCenter
                
                radius: 12
                color: Appearance.m3colors.m3secondaryContainer

                Text {
                    anchors.centerIn: parent
                    text: Math.round(root.value * 100)
                    font.pixelSize: 13 // Slightly smaller font
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
