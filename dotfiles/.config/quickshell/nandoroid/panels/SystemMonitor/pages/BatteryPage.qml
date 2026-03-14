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
    contentHeight: mainCol.implicitHeight + 100
    clip: true
    
    // Smooth value for battery bar
    property real displayPercentage: Battery.percentage
    Behavior on displayPercentage { NumberAnimation { duration: 1000; easing.type: Easing.OutExpo } }

    ColumnLayout {
        id: mainCol
        width: parent.width - 64
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 32
        spacing: 32

        // ── 1. Hero Battery Visual ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 32

            // Large Android-style Battery Icon (Matching Status Bar style)
            Item {
                width: 100
                height: 160
                Layout.alignment: Qt.AlignVCenter

                // Main body
                Rectangle {
                    anchors.fill: parent
                    anchors.bottomMargin: 8
                    radius: 16
                    color: Appearance.colors.colLayer2
                    border.width: 2
                    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.1)

                    // Fill level
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 6
                        height: (parent.height - 12) * root.displayPercentage
                        radius: 10
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
                        iconSize: 40
                        fill: 1
                        color: Appearance.colors.colOnLayer0 // Corrected from colOnPrimary
                        visible: Battery.isCharging
                        opacity: 0.9
                    }
                }

                // Battery Tip
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.top
                    anchors.bottomMargin: -4
                    width: 32
                    height: 8
                    radius: 3
                    color: Appearance.colors.colLayer2
                    border.width: 2
                    border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.1)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                
                StyledText {
                    text: Math.round(root.displayPercentage * 100) + "%"
                    font.pixelSize: 64
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
            columnSpacing: 16
            rowSpacing: 16

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
            spacing: 12

            RowLayout {
                spacing: 8
                Layout.leftMargin: 4
                MaterialSymbol {
                    text: "info"
                    iconSize: 18
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
                implicitHeight: techGrid.implicitHeight + 40
                radius: 24
                color: Appearance.m3colors.m3surfaceContainerHigh
                border.width: 1
                border.color: Functions.ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)

                GridLayout {
                    id: techGrid
                    anchors.fill: parent
                    anchors.margins: 24
                    columns: 2
                    rowSpacing: 20
                    columnSpacing: 40

                    TechInfo { label: "Vendor"; value: Battery.vendor || "Unknown" }
                    TechInfo { label: "Model"; value: Battery.model || "Generic Battery" }
                    TechInfo { label: "Technology"; value: Battery.technology }
                    TechInfo { label: "Serial Number"; value: Battery.serial || "Not Available" }
                    TechInfo { label: "Design Capacity"; value: (Battery.energyFullDesign).toFixed(2) + " Wh" }
                    TechInfo { label: "Full Capacity"; value: (Battery.energyFull).toFixed(2) + " Wh" }
                }
            }
        }

        Item { Layout.preferredHeight: 20 }
    }

    // ── Internal Components ──

    component StatCard: Rectangle {
        id: cardRoot
        property string title
        property string value
        property string subtitle
        property string icon
        property color iconColor: Appearance.colors.colPrimary
        
        implicitHeight: 120
        radius: 24
        color: Appearance.colors.colLayer1
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 2

            RowLayout {
                spacing: 8
                MaterialSymbol { text: cardRoot.icon; iconSize: 18; color: cardRoot.iconColor }
                StyledText { text: cardRoot.title; font.pixelSize: 11; font.weight: Font.Medium; color: Appearance.colors.colSubtext }
            }

            Item { Layout.fillHeight: true }

            StyledText {
                text: cardRoot.value
                font.pixelSize: Appearance.font.pixelSize.huge
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer0
            }

            StyledText {
                text: cardRoot.subtitle
                font.pixelSize: 10
                color: Appearance.colors.colSubtext
                opacity: 0.7
            }
        }
    }

    component TechInfo: ColumnLayout {
        id: infoRoot
        property string label
        property string value
        spacing: 2
        Layout.fillWidth: true

        StyledText {
            text: infoRoot.label
            font.pixelSize: 10
            font.weight: Font.Medium
            color: Appearance.colors.colSubtext
        }
        StyledText {
            text: infoRoot.value
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
