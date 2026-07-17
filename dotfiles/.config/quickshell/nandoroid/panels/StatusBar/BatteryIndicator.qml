import "../../core"
import "../../widgets"
import "../../services"
import "../../core/functions"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property color color: Appearance.colors.colStatusBarText
    visible: Battery.available
    
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= (Config.options.battery?.low ?? 20) / 100

    implicitWidth: bodyContainer.width
    implicitHeight: 24 * Appearance.effectiveScale

    readonly property color trackColor: ColorUtils.applyAlpha(root.color, 0.35)
    readonly property color highlightColor: {
        if (isLow && !isCharging) return Appearance.m3colors.m3error
        if (isCharging && Math.round(root.percentage * 100) < 100) return Appearance.m3colors.m3success
        return root.color
    }
    readonly property color textColor: {
        if (isLow && !isCharging) return Appearance.m3colors.m3onError
        if (isCharging && Math.round(root.percentage * 100) < 100) return Appearance.m3colors.m3onSuccess
        return Appearance.m3colors.m3surface
    }

    // Battery Body (Pill Shape)
    Rectangle {
        id: bodyContainer
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 27 * Appearance.effectiveScale
        height: 14 * Appearance.effectiveScale
        radius: height / 2
        color: root.trackColor
        
        // 1. The source item containing the progress fill
        Item {
            id: progressContainer
            anchors.fill: parent
            visible: false

            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.percentage
                color: root.highlightColor
            }
        }

        // 2. The mask shape (pill shape)
        Rectangle {
            id: maskContainer
            anchors.fill: parent
            radius: bodyContainer.radius
            color: "white"
            visible: false
        }

        // 3. Apply the mask
        OpacityMask {
            anchors.fill: parent
            source: progressContainer
            maskSource: maskContainer
        }

        // Centered Content Row (Centers bolt and text together, causing text to shift dynamically when charging)
        Row {
            id: contentRow
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 0.8 * Appearance.effectiveScale
            spacing: 0.5 * Appearance.effectiveScale

            // Charging Bolt Icon (Hidden when 100% to prevent crowding)
            Loader {
                id: boltLoader
                active: root.isCharging && Math.round(root.percentage * 100) < 100
                visible: active
                anchors.verticalCenter: parent.verticalCenter
                
                sourceComponent: MaterialSymbol {
                    fill: 1
                    text: "bolt"
                    iconSize: 8 * Appearance.effectiveScale
                    color: root.textColor
                }
            }

            // Battery Percentage Text
            StyledText {
                id: percentageText
                anchors.verticalCenter: parent.verticalCenter
                renderType: Text.QtRendering
                font.pixelSize: {
                    let pct = Math.round(root.percentage * 100);
                    let base = pct >= 100 ? 8.5 : 11.5;
                    return Math.round(base * Appearance.effectiveScale);
                }
                font.weight: Font.DemiBold
                text: Math.round(root.percentage * 100)
                color: root.textColor
                font.letterSpacing: -0.5
            }
        }
    }

    // Battery Tip (placed outside implicitWidth so it doesn't affect centering of the pill)
    Rectangle {
        anchors.left: bodyContainer.right
        anchors.leftMargin: 0.6 * Appearance.effectiveScale
        anchors.verticalCenter: bodyContainer.verticalCenter
        width: 1.5 * Appearance.effectiveScale
        height: 5 * Appearance.effectiveScale
        radius: width / 2
        color: (root.percentage >= 0.98) ? root.highlightColor : root.trackColor
    }
}



