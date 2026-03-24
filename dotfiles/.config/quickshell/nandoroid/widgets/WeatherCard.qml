import "../core"
import "../services"
import "."
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell

import "./weather"

/**
 * Weather widget with Android 16 aesthetics.
 * Features full-card atmospheric animations and a clean M3 surface.
 */
Rectangle {
    id: root
    implicitHeight: mainLayout.implicitHeight
    radius: Appearance.rounding.card
    color: Appearance.m3colors.m3surfaceContainerLow
    
    // Clipping mask to ensure animations respect card corners
    layer.enabled: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.radius
        }
    }
    
    readonly property string weatherIconsDir: "assets/icons/google-weather"
    readonly property bool showDailyForecast: Config.options.weather ? Config.options.weather.showDailyForecast : true
    
    readonly property color contentColor: Appearance.m3colors.m3onSurface
    readonly property real midOpacity: 0.8
    readonly property real lowOpacity: 0.6

    // --- Atmospheric Overlay ---
    WeatherAnimation {
        id: weatherAnim
        anchors.fill: parent
        animationsEnabled: root.visible
        backgroundEnabled: false 
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        // ── Top Section: Primary Conditions ──
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20 * Appearance.effectiveScale
            Layout.bottomMargin: 12 * Appearance.effectiveScale
            spacing: 0 

            ColumnLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: 6 * Appearance.effectiveScale
                
                RowLayout {
                    spacing: 8 * Appearance.effectiveScale
                    CustomIcon {
                        source: Weather.current.icon
                        iconFolder: root.weatherIconsDir
                        width: 32 * Appearance.effectiveScale; height: 32 * Appearance.effectiveScale; colorize: false
                    }
                    StyledText {
                        text: Weather.loading ? "Updating..." : Weather.current.condition
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: root.contentColor
                    }
                }

                StyledText {
                    text: `Feels like ${Weather.current.feelsLike}°`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                    opacity: root.midOpacity
                }

                StyledText {
                    text: `${Weather.todayHigh}° · ${Weather.todayLow}°`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                    opacity: root.lowOpacity
                }
            }

            Item { Layout.fillWidth: true } 

            StyledText {
                text: Weather.current.temp + "°"
                font.pixelSize: 64 * Appearance.effectiveScale
                font.weight: Font.Normal
                color: root.contentColor
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
            }
        }

        // ── Middle Section: Hourly (Transparent) ──
        Item {
            Layout.fillWidth: true
            implicitHeight: hourlyCol.implicitHeight + 32 * Appearance.effectiveScale
            
            ColumnLayout {
                id: hourlyCol
                anchors.fill: parent
                anchors.leftMargin: 20 * Appearance.effectiveScale; anchors.rightMargin: 20 * Appearance.effectiveScale
                anchors.topMargin: 16 * Appearance.effectiveScale; anchors.bottomMargin: 16 * Appearance.effectiveScale
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: Weather.hourly
                        delegate: ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 8 * Appearance.effectiveScale
                            StyledText {
                                text: modelData.temp + "°"; font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium; color: root.contentColor; Layout.alignment: Qt.AlignHCenter
                            }
                            CustomIcon {
                                source: modelData.icon; iconFolder: root.weatherIconsDir
                                width: 28 * Appearance.effectiveScale; height: 28 * Appearance.effectiveScale; colorize: false; Layout.alignment: Qt.AlignHCenter
                            }
                            StyledText {
                                text: index === 0 ? "Now" : modelData.time
                                font.pixelSize: Appearance.font.pixelSize.smallest; color: root.contentColor; opacity: root.lowOpacity
                                Layout.alignment: Qt.AlignHCenter; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // ── Bottom Section: Daily (Transparent) ──
        Item {
            visible: Weather.daily.length > 0
            Layout.fillWidth: true
            implicitHeight: dailyCol.implicitHeight + 24 * Appearance.effectiveScale
            
            ColumnLayout {
                id: dailyCol
                anchors.fill: parent
                anchors.leftMargin: 20 * Appearance.effectiveScale; anchors.rightMargin: 20 * Appearance.effectiveScale
                anchors.topMargin: 12 * Appearance.effectiveScale; anchors.bottomMargin: 12 * Appearance.effectiveScale
                spacing: 8 * Appearance.effectiveScale
                Repeater {
                    model: root.showDailyForecast ? Weather.daily : Weather.daily.slice(0, 1)
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8 * Appearance.effectiveScale; Layout.rightMargin: 8 * Appearance.effectiveScale
                        spacing: 12 * Appearance.effectiveScale
                        StyledText {
                            text: modelData.date; font.pixelSize: Appearance.font.pixelSize.small
                            color: root.contentColor; Layout.fillWidth: true
                        }
                        StyledText {
                            text: `${modelData.maxTemp}° ${modelData.minTemp}°`
                            font.pixelSize: Appearance.font.pixelSize.small; color: root.contentColor; opacity: root.midOpacity
                        }
                        CustomIcon {
                            source: modelData.icon; iconFolder: root.weatherIconsDir
                            width: 24 * Appearance.effectiveScale; height: 24 * Appearance.effectiveScale; colorize: false
                        }
                    }
                }
            }
        }

        // ── Footer Section: Status ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Layout.topMargin: 4 * Appearance.effectiveScale
            Layout.bottomMargin: 16 * Appearance.effectiveScale

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20 * Appearance.effectiveScale
                
                StyledText {
                    id: timestampText
                    anchors.centerIn: parent
                    font.pixelSize: 9 * Appearance.effectiveScale
                    color: root.contentColor; opacity: root.lowOpacity; textFormat: Text.StyledText
                    
                    property string timeString: "just now"
                    text: Weather.loading ? Weather.status : `Updated ${timeString}, click to refresh`
                    
                    function updateRelativeTime() {
                        if (!Weather.lastUpdateTime) { timeString = "unknown"; return; }
                        let diff = Math.floor((new Date() - Weather.lastUpdateTime) / 60000);
                        if (diff < 1) timeString = "just now";
                        else if (diff < 60) timeString = diff + " mins ago";
                        else timeString = Math.floor(diff / 60) + " hours ago";
                    }
                    Timer { interval: 60000; running: true; repeat: true; onTriggered: timestampText.updateRelativeTime(); triggeredOnStart: true }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Weather.fetch()
                }
            }
        }
    }
}
