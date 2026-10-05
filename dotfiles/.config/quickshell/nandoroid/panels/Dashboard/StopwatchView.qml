import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../core"
import "../../core/functions" as Functions
import "../../widgets"
import "../../services"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        // ── Large Time Display ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 4 * Appearance.effectiveScale
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: StopwatchService.timeString
                    font.pixelSize: 52 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    font.family: Appearance.font.family.numbers
                    font.features: { "tnum": 1 }
                    color: Appearance.colors.colOnLayer1
                }
            }
        }

        // ── Horizontal Lap List ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80 * Appearance.effectiveScale
            clip: false
            visible: (StopwatchService.active || StopwatchService.elapsedMs > 0) ? (StopwatchService.laps.length > 0) : (StopwatchService.laps.length > 0)

            // Navigation Arrows
            RowLayout {
                anchors.right: parent.right
                anchors.bottom: lapList.top
                anchors.bottomMargin: 8 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale
                visible: lapList.contentWidth > lapList.width

                PropertyAnimation {
                    id: scrollAnim
                    target: lapList
                    property: "contentX"
                    duration: 250
                    easing.type: Easing.OutCubic
                }

                function scroll(delta) {
                    let targetX = lapList.contentX + delta;
                    let max = Math.max(0, lapList.contentWidth - lapList.width);
                    if (targetX < 0) targetX = 0;
                    if (targetX > max) targetX = max;
                    scrollAnim.stop();
                    scrollAnim.to = targetX;
                    scrollAnim.start();
                }

                RippleButton {
                    implicitWidth: 24 * Appearance.effectiveScale
                    implicitHeight: 24 * Appearance.effectiveScale
                    buttonRadius: 12 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    enabled: lapList.contentX > 1
                    opacity: enabled ? 1 : 0.4
                    onClicked: parent.scroll(-98 * Appearance.effectiveScale) // scroll left
                    MaterialSymbol { anchors.centerIn: parent; text: "chevron_left"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                    StyledToolTip { text: I18nService.tr("Scroll Left") }
                }

                RippleButton {
                    implicitWidth: 24 * Appearance.effectiveScale
                    implicitHeight: 24 * Appearance.effectiveScale
                    buttonRadius: 12 * Appearance.effectiveScale
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    enabled: lapList.contentX < (lapList.contentWidth - lapList.width - 1)
                    opacity: enabled ? 1 : 0.4
                    onClicked: parent.scroll(98 * Appearance.effectiveScale) // scroll right
                    MaterialSymbol { anchors.centerIn: parent; text: "chevron_right"; iconSize: 14 * Appearance.effectiveScale; color: Appearance.colors.colOnLayer1 }
                    StyledToolTip { text: I18nService.tr("Scroll Right") }
                }
            }

            ListView {
                id: lapList
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 80 * Appearance.effectiveScale
                model: (StopwatchService.active || StopwatchService.elapsedMs > 0) ? (StopwatchService.laps.length > 0 ? StopwatchService.laps.length + 1 : 0) : StopwatchService.laps.length
                clip: true
                orientation: ListView.Horizontal
                spacing: 8 * Appearance.effectiveScale
                layoutDirection: Qt.LeftToRight
                
                onCountChanged: {
                    if (count > 0) {
                        positionViewAtEnd();
                    }
                }
                
                delegate: Rectangle {
                    width: 90 * Appearance.effectiveScale
                    height: ListView.view.height
                    color: "transparent"
                    border.width: 1
                    border.color: Appearance.m3colors.m3surfaceContainerHigh
                    radius: 12 * Appearance.effectiveScale
                    
                    property bool isCurrent: index === StopwatchService.laps.length
                    property var lapData: isCurrent ? null : StopwatchService.laps[index]
                    
                    property bool isFastest: !isCurrent && index === StopwatchService.fastestLapIndex
                    property bool isSlowest: !isCurrent && index === StopwatchService.slowestLapIndex
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4 * Appearance.effectiveScale
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: ((index + 1) < 10 ? "0" : "") + (index + 1)
                            color: isCurrent ? Appearance.colors.colOnLayer1 : (isFastest ? Appearance.m3colors.m3primary : (isSlowest ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer1))
                            font.pixelSize: 12 * Appearance.effectiveScale
                            font.features: { "tnum": 1 }
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: isCurrent ? StopwatchService.formatTime(StopwatchService.currentLapMs) : StopwatchService.formatTime(lapData ? lapData.lapMs : 0)
                            color: isCurrent ? Appearance.colors.colOnLayer1 : (isFastest ? Appearance.m3colors.m3primary : (isSlowest ? Appearance.m3colors.m3error : Appearance.colors.colSubtext))
                            font.pixelSize: 12 * Appearance.effectiveScale
                            font.family: Appearance.font.family.numbers
                            font.features: { "tnum": 1 }
                        }
                        
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: isCurrent ? StopwatchService.formatTime(StopwatchService.elapsedMs) : StopwatchService.formatTime(lapData ? lapData.totalMs : 0)
                            color: isCurrent ? Appearance.colors.colSubtext : (isFastest ? Appearance.m3colors.m3primary : (isSlowest ? Appearance.m3colors.m3error : Appearance.colors.colSubtext))
                            font.pixelSize: 12 * Appearance.effectiveScale
                            font.family: Appearance.font.family.numbers
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }
        }

        // ── Controls (Vertical Pills) ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 64 * Appearance.effectiveScale
                buttonRadius: StopwatchService.active ? 16 * Appearance.effectiveScale : height / 2
                colBackground: StopwatchService.active ? Appearance.m3colors.m3error : Appearance.m3colors.m3primary
                
                onClicked: {
                    if (StopwatchService.active) {
                        StopwatchService.pause();
                    } else {
                        StopwatchService.start();
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    text: StopwatchService.active ? I18nService.tr("Stop") : I18nService.tr("Start")
                    font.pixelSize: 16 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: StopwatchService.active ? Appearance.m3colors.m3onError : Appearance.m3colors.m3onPrimary
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Appearance.effectiveScale
                visible: StopwatchService.active || StopwatchService.elapsedMs > 0

                // Reset Button
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64 * Appearance.effectiveScale
                    buttonRadius: height / 2
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    
                    onClicked: {
                        StopwatchService.reset();
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: I18nService.tr("Reset")
                        font.pixelSize: 16 * Appearance.effectiveScale
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // Lap Button
                RippleButton {
                    Layout.fillWidth: true
                    implicitHeight: 64 * Appearance.effectiveScale
                    buttonRadius: height / 2
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    enabled: StopwatchService.active
                    opacity: enabled ? 1 : 0.4
                    
                    onClicked: {
                        if (StopwatchService.active) {
                            StopwatchService.lap();
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: I18nService.tr("Lap")
                        font.pixelSize: 16 * Appearance.effectiveScale
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }
        }
    }
}
