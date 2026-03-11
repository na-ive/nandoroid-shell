import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property color color: Appearance.colors.colStatusBarText
    
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= (Config.options.battery?.low ?? 20) / 100

    implicitWidth: batteryProgress.implicitWidth + 4
    implicitHeight: 24

    RowLayout {
        anchors.centerIn: parent
        spacing: 1

        ClippedProgressBar {
            id: batteryProgress
            valueBarWidth: 26
            valueBarHeight: 14
            Layout.alignment: Qt.AlignVCenter
            
            radius: 4.5 // Soft squircle shape from reference
            
            value: percentage
            // highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colStatusBarText
            highlightColor: {
                 if (isLow && !isCharging) return Appearance.m3colors.m3error
                 return root.color
            }
            trackColor: {
                if (isLow && !isCharging) return Appearance.m3colors.m3errorContainer
                // Force a calculated transparency based on the highlight color to ensure it looks "semi-transparent"
                // 0.2 alpha (80% transparent) gives that subtle look
                return ColorUtils.applyAlpha(highlightColor, 0.2) 
            }
            
            // Custom text mask to include the bolt icon
            textMask: Item {
                width: batteryProgress.valueBarWidth
                height: batteryProgress.valueBarHeight

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    MaterialSymbol {
                        id: boltIcon
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -2
                        Layout.rightMargin: -2
                        fill: 1
                        text: "bolt"
                        iconSize: 8
                        visible: isCharging
                        color: (isLow && !isCharging) ? Appearance.m3colors.m3onError : root.color
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        text: batteryProgress.text
                        color: (isLow && !isCharging) ? Appearance.m3colors.m3onError : root.color
                    }
                }
            }
        }

        // Battery Tip
        Rectangle {
            Layout.preferredWidth: 2
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter
            radius: 1
            color: (percentage >= 0.98) ? batteryProgress.highlightColor : batteryProgress.trackColor
        }
    }
}
