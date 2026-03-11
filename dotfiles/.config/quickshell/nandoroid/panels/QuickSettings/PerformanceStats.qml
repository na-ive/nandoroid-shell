import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"
import "../../widgets"

/**
 * Refined Performance monitor island for the Quick Settings panel.
 * Displays real-time CPU, Temperature, RAM, Swap, and Multiple Disk usage via SystemData.
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + 24
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    ColumnLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 12

        // Top Row: 4 key metrics with background pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StatItem {
                statIcon: "monitoring"
                label: "CPU"
                value: SystemData.cpuUsage
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 1;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatItem {
                statIcon: "thermostat"
                label: "TEMP"
                value: SystemData.cpuTemperature
                isTemperature: true
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 1;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatItem {
                statIcon: "memory"
                label: "RAM"
                value: SystemData.memUsage
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 3;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatItem {
                statIcon: "swap_horiz"
                label: "SWAP"
                value: SystemData.swapUsage
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 3;
                    GlobalStates.activateSystemMonitor();
                }
            }
        }

        // Bottom Section: Multiple Disk monitors
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: SystemData.diskStats
                delegate: RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 60
                    buttonRadius: 12
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer2
                    
                    onClicked: {
                        GlobalStates.systemMonitorIndex = 0;
                        GlobalStates.performanceSubIndex = 5;
                        GlobalStates.activateSystemMonitor();
                    }

                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            MaterialSymbol {
                                text: "storage"
                                iconSize: 14
                                color: Appearance.m3colors.m3primary
                            }
                            StyledText {
                                text: modelData.hasAlias ? `${modelData.label} DISK USAGE` : `"${modelData.label}" DISK USAGE`
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Appearance.m3colors.m3outline
                            }
                            Item { Layout.fillWidth: true }
                            StyledText {
                                text: `${Math.round(modelData.usage * 100)}%`
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Appearance.m3colors.m3onSurface
                            }
                        }

                        // Large Disk Bar
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 8
                            radius: 4
                            color: Appearance.colors.colLayer2
                            clip: true

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, modelData.usage))
                                height: parent.height
                                radius: 4
                                color: Appearance.m3colors.m3primary
                                visible: modelData.usage > 0

                                Behavior on width {
                                    NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // StatItem: Icon, Label, and Value inside a stylized pill container
    component StatItem: RippleButton {
        id: statItem
        property string statIcon
        property string label
        property real value: 0
        property bool isTemperature: false
        
        implicitHeight: 64
        buttonRadius: 16
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer2
        
        contentItem: ColumnLayout {
            spacing: 6

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4
                MaterialSymbol {
                    text: statItem.statIcon
                    iconSize: 14
                    color: Appearance.m3colors.m3primary
                }
                StyledText {
                    text: statItem.label
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3outline
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 20
                radius: 10
                color: Appearance.colors.colLayer2

                StyledText {
                    anchors.centerIn: parent
                    text: statItem.isTemperature ? (statItem.value > 0 ? `${Math.round(statItem.value)}°C` : "--") : `${Math.round(statItem.value * 100)}%`
                    font.pixelSize: 10
                    font.weight: Font.Black
                    color: Appearance.m3colors.m3onSurface
                }
            }
        }
    }
}
