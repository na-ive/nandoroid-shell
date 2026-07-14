import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../core"
import "../../../core/functions" as Functions
import "../../../services"
import "../../../widgets"

/**
 * Enhanced Battery Stats page for System Monitor (v1.2).
 * Provides deep technical details and Android-inspired visuals.
 */
Flickable {
    id: root
    contentHeight: mainCol.implicitHeight + (100 * Appearance.effectiveScale)
    clip: true
    
    // Smooth value for battery bar
    property real displayPercentage: Battery.percentage
    Behavior on displayPercentage { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

    ColumnLayout {
        id: mainCol
        width: parent.width - (64 * Appearance.effectiveScale)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 32 * Appearance.effectiveScale
        spacing: 32 * Appearance.effectiveScale

        // ── 1. Hero Battery Visual ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 32 * Appearance.effectiveScale

            // Large Android-style Battery Icon (Matching Status Bar style)
            Item {
                id: batteryIconItem
                width: 100 * Appearance.effectiveScale
                height: 160 * Appearance.effectiveScale
                Layout.preferredWidth: width
                Layout.preferredHeight: height
                Layout.alignment: Qt.AlignVCenter

                // Main body
                Rectangle {
                    id: bodyRect
                    anchors.fill: parent
                    anchors.bottomMargin: 8 * Appearance.effectiveScale
                    radius: 16 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    border.width: 2 * Appearance.effectiveScale
                    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.1)

                    // Fill level
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 6 * Appearance.effectiveScale
                        height: (parent.height - (12 * Appearance.effectiveScale)) * root.displayPercentage
                        radius: 10 * Appearance.effectiveScale
                        color: {
                            if (Battery.isCritical && !Battery.isCharging) return Appearance.colors.colError;
                            if (Battery.isLow && !Battery.isCharging) return Appearance.colors.colWarning;
                            return Appearance.colors.colPrimary;
                        }
                        Behavior on height { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }

                    // Charging Bolt Overlay
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "bolt"
                        iconSize: 40 * Appearance.effectiveScale
                        fill: 1
                        color: Appearance.colors.colOnLayer0
                        visible: Battery.isCharging
                        opacity: 0.9
                    }
                }

                // Battery Tip
                Rectangle {
                    anchors.horizontalCenter: bodyRect.horizontalCenter
                    anchors.bottom: bodyRect.top
                    anchors.bottomMargin: -6 * Appearance.effectiveScale
                    width: 32 * Appearance.effectiveScale
                    height: 8 * Appearance.effectiveScale
                    radius: 3 * Appearance.effectiveScale
                    color: Appearance.colors.colLayer2
                    border.width: 2 * Appearance.effectiveScale
                    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.1)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale
                
                StyledText {
                    text: Math.round(root.displayPercentage * 100) + "%"
                    font.pixelSize: Math.round(64 * Appearance.effectiveScale) // Keep this large and scaled
                    font.weight: Font.Black
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: Battery.isCharging ? "Charging" : (Battery.chargeState === 4 ? "Fully Charged" : "Discharging")
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: {
                        if (Battery.isCharging && Battery.timeToFull > 0) return `${Math.round(Battery.timeToFull / 60)} mins until full`;
                        if (!Battery.isCharging && Battery.timeToEmpty > 0) return `${Math.round(Battery.timeToEmpty / 60)} mins remaining`;
                        return Battery.isPluggedIn ? "Power Source: AC Adapter" : "Power Source: Internal Battery";
                    }
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }
        }

        // ── 2. Health & Efficiency Cards ──
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 16 * Appearance.effectiveScale
            rowSpacing: 16 * Appearance.effectiveScale

            StatCard {
                Layout.fillWidth: true
                title: "Health"
                value: Battery.health > 0 ? (Math.round(Battery.health) + "%") : "N/A"
                icon: "favorite"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Life cycle"
            }

            StatCard {
                Layout.fillWidth: true
                title: "Usage"
                value: Battery.energyRate > 0 ? (Battery.energyRate.toFixed(1) + " W") : "0.0 W"
                icon: "bolt"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Power rate"
            }

            StatCard {
                Layout.fillWidth: true
                title: "Voltage"
                value: Battery.voltage > 0 ? (Battery.voltage.toFixed(2) + " V") : "N/A"
                icon: "electric_bolt"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Current"
            }

            StatCard {
                Layout.fillWidth: true
                title: "Cycles"
                value: Battery.cycles > 0 ? Battery.cycles.toString() : "0"
                icon: "autorenew"
                iconColor: Appearance.colors.colPrimary
                subtitle: "Charge count"
            }
        }

        // ── 3. Technical Specifications ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            RowLayout {
                spacing: 8 * Appearance.effectiveScale
                Layout.leftMargin: 4 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "info"
                    iconSize: 18 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Hardware Information"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: techGrid.implicitHeight + (40 * Appearance.effectiveScale)
                radius: 24 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh
                border.width: 1 * Appearance.effectiveScale
                border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

                GridLayout {
                    id: techGrid
                    anchors.fill: parent
                    anchors.margins: 24 * Appearance.effectiveScale
                    columns: 2
                    rowSpacing: 20 * Appearance.effectiveScale
                    columnSpacing: 40 * Appearance.effectiveScale

                    TechInfo { label: "Vendor"; value: Battery.vendor || "Unknown" }
                    TechInfo { label: "Model"; value: Battery.model || "Generic Battery" }
                    TechInfo { label: "Technology"; value: Battery.technology }
                    TechInfo { label: "Serial Number"; value: Battery.serial || "Not Available" }
                    TechInfo { label: "Design Capacity"; value: (Battery.energyFullDesign).toFixed(2) + " Wh" }
                    TechInfo { label: "Full Capacity"; value: (Battery.energyFull).toFixed(2) + " Wh" }
                }
            }
        }

        Item { Layout.preferredHeight: 20 * Appearance.effectiveScale }
    }

    // ── Internal Components ──

    component StatCard: Rectangle {
        id: cardRoot
        property string title
        property string value
        property string subtitle
        property string icon
        property color iconColor: Appearance.colors.colPrimary
        
        implicitHeight: 120 * Appearance.effectiveScale
        radius: 24 * Appearance.effectiveScale
        color: Appearance.colors.colLayer1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 4 * Appearance.effectiveScale

            RowLayout {
                spacing: 8 * Appearance.effectiveScale
                MaterialSymbol { text: cardRoot.icon; iconSize: 18 * Appearance.effectiveScale; color: cardRoot.iconColor }
                StyledText { 
                    text: cardRoot.title
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            StyledText {
                text: cardRoot.value
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            StyledText {
                text: cardRoot.subtitle
                font.pixelSize: Appearance.font.pixelSize.smallest
                color: Appearance.colors.colSubtext
                opacity: 0.7
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    component TechInfo: ColumnLayout {
        id: infoRoot
        property string label
        property string value
        spacing: 2 * Appearance.effectiveScale
        Layout.fillWidth: true

        StyledText {
            text: infoRoot.label
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: infoRoot.value
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
