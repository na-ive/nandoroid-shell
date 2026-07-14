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

            Item {
                Layout.alignment: Qt.AlignVCenter
                width: 20 * Appearance.effectiveScale
                height: 20 * Appearance.effectiveScale

                Canvas {
                    id: canvas
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        
                        var centerX = width / 2;
                        var centerY = height / 2;
                        var radius = (Math.min(width, height) / 2) - (2 * Appearance.effectiveScale);
                        
                        // Background ring
                        ctx.beginPath();
                        ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
                        ctx.lineWidth = 3 * Appearance.effectiveScale;
                        ctx.strokeStyle = Appearance.m3colors.m3surfaceContainerHigh;
                        ctx.stroke();
                        
                        // Progress arc
                        if (rootRing.value > 0) {
                            ctx.beginPath();
                            ctx.arc(centerX, centerY, radius, -Math.PI / 2, (-Math.PI / 2) + (Math.PI * 2 * rootRing.value));
                            ctx.lineWidth = 3 * Appearance.effectiveScale;
                            ctx.strokeStyle = rootRing.highlightColor;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                    }
                }
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: rootRing.iconName
                    iconSize: 11 * Appearance.effectiveScale
                    color: root.color
                }
            }

            onValueChanged: canvas.requestPaint()

            StyledText {
                visible: rootRing.showText
                text: rootRing.statText
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: root.color
                Layout.preferredWidth: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
            }
        }

        StatRing {
            iconName: "memory"
            value: SystemData.cpuUsage
            statText: Math.round(SystemData.cpuUsage * 100) + "%"
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorCpu ?? true) : true
        }

        StatRing {
            iconName: "speed"
            value: SystemData.memUsage
            statText: Math.round(SystemData.memUsage * 100) + "%"
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorRam ?? true) : true
        }
        
        StatRing {
            iconName: "swap_horiz"
            value: SystemData.swapUsage
            statText: Math.round(SystemData.swapUsage * 100) + "%"
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorSwap ?? false) : false
        }

        StatRing {
            iconName: "thermostat"
            value: Math.min(SystemData.cpuTemperature / 100, 1.0)
            statText: Math.round(SystemData.cpuTemperature) + "°C"
            highlightColor: root.color
            isVisible: Config.ready && Config.options.statusBar ? (Config.options.statusBar.showSystemMonitorTemp ?? true) : true
        }
    }
}
