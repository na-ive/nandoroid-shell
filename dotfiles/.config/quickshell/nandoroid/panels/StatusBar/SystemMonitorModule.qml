import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property color color: Appearance.colors.colStatusBarText
    property color subtextColor: Appearance.colors.colStatusBarSubtext

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight
    clip: true

    RowLayout {
        id: layout
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * Appearance.effectiveScale

        component StatRing : RowLayout {
            id: rootRing
            property string iconName
            property real value: 0
            property string statText: ""
            property color highlightColor: Appearance.colors.colPrimary
            property bool isVisible: true
            property bool showText: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorText ?? false) : false
            
            Layout.alignment: Qt.AlignVCenter
            visible: isVisible
            spacing: 4 * Appearance.effectiveScale

            Component {
                id: outlineStyle
                ClippedOutlineCircularProgress {
                    lineWidth: 2 * Appearance.effectiveScale
                    value: rootRing.value
                    implicitSize: 20 * Appearance.effectiveScale
                    enableAnimation: false
                    colPrimary: rootRing.highlightColor
                    Item {
                        anchors.centerIn: parent
                        width: 20 * Appearance.effectiveScale
                        height: 20 * Appearance.effectiveScale
                        MaterialSymbol {
                            anchors.centerIn: parent
                            font.weight: Font.DemiBold
                            fill: 1
                            text: rootRing.iconName
                            iconSize: Appearance.font.pixelSize.normal
                            color: rootRing.highlightColor
                        }
                    }
                }
            }

            Component {
                id: filledStyle
                ClippedFilledCircularProgress {
                    lineWidth: 2 * Appearance.effectiveScale
                    value: rootRing.value
                    implicitSize: 20 * Appearance.effectiveScale
                    accountForLightBleeding: true
                    enableAnimation: false
                    colPrimary: rootRing.highlightColor
                    Item {
                        anchors.centerIn: parent
                        width: 20 * Appearance.effectiveScale
                        height: 20 * Appearance.effectiveScale
                        MaterialSymbol {
                            anchors.centerIn: parent
                            font.weight: Font.DemiBold
                            fill: 1
                            text: rootRing.iconName
                            iconSize: Appearance.font.pixelSize.normal
                            color: rootRing.highlightColor
                        }
                    }
                }
            }

            Loader {
                Layout.alignment: Qt.AlignVCenter
                sourceComponent: (Config.ready && Config.options.statusBar && Config.options.statusBar.systemMonitorStyle === "filled") ? filledStyle : outlineStyle
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                visible: rootRing.showText
                implicitWidth: visible ? fullPercentageTextMetrics.width : 0
                implicitHeight: percentageText.implicitHeight

                TextMetrics {
                    id: fullPercentageTextMetrics
                    text: "100"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                }

                StyledText {
                    id: percentageText
                    anchors.centerIn: parent
                    text: rootRing.statText
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: root.color
                }
            }
        }

        StatRing {
            iconName: "monitoring"
            value: SystemData.cpuUsage
            statText: Math.round(SystemData.cpuUsage * 100).toString()
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorCpu ?? true) : true
        }

        StatRing {
            iconName: "memory"
            value: SystemData.memUsage
            statText: Math.round(SystemData.memUsage * 100).toString()
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorRam ?? true) : true
        }
        
        StatRing {
            iconName: "swap_horiz"
            value: SystemData.swapUsage
            statText: Math.round(SystemData.swapUsage * 100).toString()
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorSwap ?? false) : false
        }

        StatRing {
            iconName: "thermostat"
            value: Math.min(SystemData.cpuTemperature / 100, 1.0)
            statText: SystemData.cpuTemperature > 0 ? Math.round(SystemData.cpuTemperature).toString() : "--"
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorTemp ?? true) : true
        }
    }
}
