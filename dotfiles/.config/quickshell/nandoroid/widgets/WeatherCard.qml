import "../core"
import "../services"
import "."
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell

import "./weather"

Rectangle {
    id: root
    implicitHeight: mainLayout.implicitHeight
    radius: 30 * Appearance.effectiveScale
    color: Appearance.colors.colOnPrimary

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
    readonly property real lowOpacity: 0.6

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

                    MaterialShape {
                        Layout.alignment: Qt.AlignVCenter
                        implicitWidth: 44 * Appearance.effectiveScale
                        implicitHeight: 44 * Appearance.effectiveScale
                        shape: MaterialShape.Shape.Pentagon
                        color: Appearance.colors.colPrimary

                        CustomIcon {
                            anchors.centerIn: parent
                            source: Weather.current.icon
                            iconFolder: root.weatherIconsDir
                            width: 26 * Appearance.effectiveScale
                            height: 26 * Appearance.effectiveScale
                            colorize: true
                            color: Appearance.colors.colOnPrimary
                        }
                    }

                    StyledText {
                        text: Weather.loading ? "Updating..." : Weather.current.condition
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: root.contentColor
                    }
                }

                StyledText {
                    text: "Feels like " + Weather.current.feelsLike + "\u00b0"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: root.contentColor
                    opacity: root.midOpacity
                }

                StyledText {
                    text: `${Weather.todayHigh}° · ${Weather.todayLow}°`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.contentColor
                    opacity: root.lowOpacity
                }
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: Weather.loading ? "--" : Weather.current.temp + "\u00b0"
                font.pixelSize: Math.round(48 * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                color: Appearance.colors.colPrimary
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.margins: 20 * Appearance.effectiveScale
            Layout.bottomMargin: 10 * Appearance.effectiveScale
            implicitHeight: hourlyRow.implicitHeight + 24 * Appearance.effectiveScale
            radius: 14 * Appearance.effectiveScale
            color: Qt.rgba(1, 1, 1, 0.03)

            RowLayout {
                id: hourlyRow
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 0

                Repeater {
                    model: Weather.hourly
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        spacing: 4 * Appearance.effectiveScale

                        StyledText {
                            text: index === 0 ? "Now" : modelData.time
                            font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                            font.weight: index === 0 ? Font.DemiBold : Font.Medium
                            color: index === 0 ? Appearance.colors.colPrimary : root.contentColor
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2 * Appearance.effectiveScale

                            CustomIcon {
                                source: modelData.icon
                                iconFolder: root.weatherIconsDir
                                width: 20 * Appearance.effectiveScale
                                height: 20 * Appearance.effectiveScale
                                colorize: true
                                color: index === 0 ? Appearance.colors.colPrimary : root.contentColor
                            }

                            StyledText {
                                text: modelData.temp + "\u00b0"
                                font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                font.weight: index === 0 ? Font.DemiBold : Font.Medium
                                color: index === 0 ? Appearance.colors.colPrimary : root.contentColor
                            }
                        }
                    }
                }
            }
        }

        Loader {
            visible: Weather.daily.length > 0
            Layout.fillWidth: true
            Layout.margins: 20 * Appearance.effectiveScale
            Layout.topMargin: 0
            sourceComponent: root.showDailyForecast ? dailyGrid : singleDay
        }

        Component {
            id: singleDay

            Rectangle {
                implicitHeight: Math.round(54 * Appearance.effectiveScale)
                radius: 12 * Appearance.effectiveScale
                color: Qt.rgba(1, 1, 1, 0.03)

                RowLayout {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    anchors.leftMargin: 12 * Appearance.effectiveScale
                    anchors.rightMargin: 12 * Appearance.effectiveScale

                    StyledText {
                        text: Weather.daily[0].date
                        font.pixelSize: Math.round(13 * Appearance.effectiveScale)
                        font.weight: Font.DemiBold
                        color: root.contentColor
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4 * Appearance.effectiveScale

                        CustomIcon {
                            source: Weather.daily[0].icon
                            iconFolder: root.weatherIconsDir
                            width: 26 * Appearance.effectiveScale
                            height: 26 * Appearance.effectiveScale
                            colorize: true
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            text: Weather.daily[0].maxTemp + "\u00b0/" + Weather.daily[0].minTemp + "\u00b0"
                            font.pixelSize: Math.round(13 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: root.contentColor
                        }
                    }
                }
            }
        }

        Component {
            id: dailyGrid

            Item {
                implicitHeight: dailyRow.implicitHeight

                RowLayout {
                    id: dailyRow
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    spacing: 10 * Appearance.effectiveScale

                    Repeater {
                        model: Weather.daily
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Math.round(54 * Appearance.effectiveScale)
                            radius: 12 * Appearance.effectiveScale
                            color: Qt.rgba(1, 1, 1, 0.03)

                            ColumnLayout {
                                id: dayCol
                                anchors.centerIn: parent
                                spacing: 4 * Appearance.effectiveScale

                                StyledText {
                                    text: modelData.date
                                    font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                    font.weight: Font.DemiBold
                                    color: root.contentColor
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 2 * Appearance.effectiveScale

                                    CustomIcon {
                                        source: modelData.icon
                                        iconFolder: root.weatherIconsDir
                                        width: 20 * Appearance.effectiveScale
                                        height: 20 * Appearance.effectiveScale
                                        colorize: true
                                        color: Appearance.colors.colPrimary
                                    }

                                    StyledText {
                                        text: modelData.maxTemp + "\u00b0/" + modelData.minTemp + "\u00b0"
                                        font.pixelSize: Math.round(9 * Appearance.effectiveScale)
                                        font.weight: Font.DemiBold
                                        color: root.contentColor
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
