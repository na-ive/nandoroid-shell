import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property var shape
    property bool rotateIcon: false
    property bool scaleIcon: false

    property real valueIndicatorVerticalPadding: 9
    property real valueIndicatorLeftPadding: 15
    property real valueIndicatorRightPadding: 15 // An icon is circle ish, a column isn't, hence the extra padding

    // Use default osdWidth if not defined in Appearance, or hardcode/fallback
    readonly property real osdWidth: (Appearance.sizes && Appearance.sizes.osdWidth) ? Appearance.sizes.osdWidth : 220 
    
    // Fallback for elevationMargin
    readonly property real elevationMargin: (Appearance.sizes && Appearance.sizes.elevationMargin) ? Appearance.sizes.elevationMargin : 10

    implicitWidth: osdWidth + 2 * elevationMargin
    implicitHeight: valueIndicator.implicitHeight + 2 * elevationMargin

    // Removed solid shadow per user request to fix light mode visual bugs
    // StyledRectangularShadow {
    //     target: valueIndicator
    // }
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

        RowLayout { // Icon on the left, stuff on the right
            id: valueRow
            Layout.margins: 10
            anchors.fill: parent
            spacing: 15

            Item {
                implicitWidth: 30
                implicitHeight: 35
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: valueIndicatorLeftPadding
                Layout.topMargin: valueIndicatorVerticalPadding
                Layout.bottomMargin: valueIndicatorVerticalPadding

                MaterialShapeWrappedMaterialSymbol {
                    rotation: root.rotateIcon ? root.value * 360 : 0
                    scale: root.scaleIcon ? (0.85 + root.value * 0.3) : 1.0
                    anchors {
                        fill: parent
                        margins: -5
                    }
                    iconSize: Appearance.font.pixelSize.huge
                    // shape: root.shape // shape property expects int/enum in MaterialShape
                    // Use shapeString if root.shape is a string, otherwise assume it's an enum (but we moved to strings)
                    shapeString: (typeof root.shape === "string") ? root.shape : ""
                    shape: (typeof root.shape !== "string") ? root.shape : undefined
                    text: root.icon
                }
            }
            ColumnLayout { // Stuff
                Layout.alignment: Qt.AlignVCenter
                Layout.rightMargin: valueIndicatorRightPadding
                spacing: 5

                RowLayout { // Name fill left, value on the right end
                    Layout.leftMargin: (valueProgressBar.height / 2) || 0 // Align text with progressbar radius curve's left end
                    Layout.rightMargin: (valueProgressBar.height / 2) || 0 // Align text with progressbar radius curve's left end

                    StyledText {
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: true
                        text: root.name
                    }

                    StyledText {
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.small
                        Layout.fillWidth: false
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(root.value * 100)
                        // animateChange: true // Not supported in basic StyledText?
                    }
                }
                
                StyledProgressBar {
                    id: valueProgressBar
                    Layout.fillWidth: true
                    value: root.value
                    showStopIndicator: false
                    valueBarGap: 0
                }
            }
        }
    }
}
