import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

/**
 * High-fidelity Weather widget — perfect Google Weather clone.
 * Adheres to the exact layout from the provided reference.
 */
Rectangle {
    id: root
    implicitHeight: mainLayout.implicitHeight + 40
    radius: Appearance.rounding.card
    color: Appearance.m3colors.m3surfaceContainerLow
    
    readonly property string weatherIconsDir: "assets/icons/google-weather"
    readonly property bool showDailyToggle: (Config.ready && Config.options.weather) ? Config.options.weather.showDailyForecast : true

    function getWeatherColor() {
        const icon = Weather.current.icon || "";
        if (icon === "clear_day") return "#FF9800"; // Orange
        if (icon === "clear_night") return "#1A237E"; // Deep Indigo
        if (icon.includes("thunder")) return "#6200EA"; // Deep Purple
        if (icon.includes("snow") || icon.includes("sleet") || icon.includes("ice")) return "#4DD0E1"; // Cyan/Ice
        if (icon.includes("rain") || icon.includes("drizzle")) return "#1976D2"; // Strong Blue
        if (icon.includes("cloud") || icon.includes("haze")) return "#78909C"; // Blue Grey
        return Appearance.colors.colPrimary;
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.alpha(root.getWeatherColor(), Appearance.mode === "dark" ? 0.35 : 0.45) }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 24

        // ── Top Section: Primary Conditions ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 0 // Using spacer for precise alignment

            ColumnLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: 6
                
                RowLayout {
                    spacing: 8
                    CustomIcon {
                        source: Weather.current.icon
                        iconFolder: root.weatherIconsDir
                        width: 32
                        height: 32
                        colorize: false
                        
                        RotationAnimation on rotation {
                            from: 0; to: 360; duration: 1000
                            running: Weather.loading
                            loops: Animation.Infinite
                        }
                    }
                    StyledText {
                        text: Weather.loading ? "Updating..." : Weather.current.condition
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                StyledText {
                    text: `Feels like ${Weather.current.feelsLike}°`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    text: `${Weather.todayHigh}° · ${Weather.todayLow}°`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }
            }

            Item { Layout.fillWidth: true } // Pushes temperature to the right

            StyledText {
                text: Weather.current.temp + "°"
                font.pixelSize: 64
                font.weight: Font.Normal
                color: Appearance.colors.colOnLayer1
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                horizontalAlignment: Text.AlignRight
            }
        }

        // ── Middle Section: Hourly Forecast (Full-Width Row) ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: hourlyCol.implicitHeight + 32
            radius: 20
            color: Qt.rgba(1, 1, 1, 0.1)
            
            ColumnLayout {
                id: hourlyCol
                anchors.fill: parent
                anchors.margins: 16
                
                RowLayout {
                    id: hourlyRow
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Repeater {
                        model: Weather.hourly
                        delegate: ColumnLayout {
                            // Standard way to get 6 equal columns in RowLayout
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            spacing: 8
                            
                            StyledText {
                                text: modelData.temp + "°"
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            CustomIcon {
                                source: modelData.icon
                                iconFolder: root.weatherIconsDir
                                width: 28
                                height: 28
                                colorize: false
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            StyledText {
                                text: index === 0 ? "Now" : modelData.time
                                font.pixelSize: 10
                                color: Appearance.colors.colSubtext
                                Layout.alignment: Qt.AlignHCenter
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // ── Bottom Section: Daily Forecast In Dark Card ──
        Rectangle {
            visible: Weather.daily.length > 0
            Layout.fillWidth: true
            implicitHeight: dailyCol.implicitHeight + 24
            radius: 20
            color: Qt.rgba(1, 1, 1, 0.1)
            
            ColumnLayout {
                id: dailyCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                
                Repeater {
                    model: root.showDailyToggle ? Weather.daily : Weather.daily.slice(0, 1)
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        spacing: 12
                        
                        StyledText {
                            text: modelData.date
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                        
                        StyledText {
                            text: `${modelData.maxTemp}° ${modelData.minTemp}°`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer1
                        }

                        CustomIcon {
                            source: modelData.icon
                            iconFolder: root.weatherIconsDir
                            width: 24
                            height: 24
                            colorize: false
                        }
                    }
                }
            }
        }

        // Updated Timestamp Footer
        StyledText {
            id: timestampText
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 9
            color: Appearance.colors.colSubtext
            opacity: 0.7
            textFormat: Text.StyledText
            
            property string timeString: "Just now"
            text: Weather.loading ? Weather.status : `Updated ${timeString}, <font color="${Appearance.colors.colPrimary}">click to refresh</font>`

            function updateRelativeTime() {
                if (!Weather.lastUpdateTime) {
                    timeString = "unknown";
                    return;
                }
                
                const now = new Date();
                const diffMs = now - Weather.lastUpdateTime;
                const diffMins = Math.floor(diffMs / 60000);
                
                if (diffMins < 1) {
                    timeString = "just now";
                } else {
                    timeString = `${diffMins} ${diffMins === 1 ? 'min' : 'mins'} ago`;
                }
            }

            Timer {
                interval: 60000 // Update every minute
                running: true
                repeat: true
                onTriggered: timestampText.updateRelativeTime()
            }

            Connections {
                target: Weather
                function onLastUpdateTimeChanged() {
                    timestampText.updateRelativeTime();
                }
            }

            Component.onCompleted: updateRelativeTime()

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Weather.fetch();
                }
            }
        }
    }
}
