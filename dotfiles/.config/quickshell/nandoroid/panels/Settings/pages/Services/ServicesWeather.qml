import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "../../../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell

ColumnLayout {
    Layout.fillWidth: true
    spacing: 0
    
    SearchHandler { 
        searchString: "Weather"
        aliases: ["Forecast", "Temperature", "Climate"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "cloud"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Weather"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: weatherEnableRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: weatherEnableRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Enable Weather Service"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Show the weather widget in the notification center."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                        checked: (Config.ready && Config.options.weather && Config.options.weather.enable)
                        onToggled: {
                            if (Config.ready && Config.options.weather) {
                                Config.options.weather.enable = !Config.options.weather.enable;
                    }
                    }
                }
            }
        }

        // 2. Weather Provider Card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: weatherProviderRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            RowLayout {
                id: weatherProviderRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Weather Provider"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Choose the weather data service to use."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    Layout.preferredHeight: 40 * Appearance.effectiveScale
                    
                    Repeater {
                        model: [
                            { label: "Open-Meteo", value: "openmeteo" },
                            { label: "wttr.in", value: "wttr" }
                        ]
                        delegate: SegmentedButton {
                            isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.provider === modelData.value : false
                            Layout.fillHeight: true
                            
                            buttonText: modelData.label
                            leftPadding: 16 * Appearance.effectiveScale
                            rightPadding: 16 * Appearance.effectiveScale
                            
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.provider = modelData.value;
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Location settings card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: locationRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            RowLayout {
                id: locationRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Location Settings"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Automatically detect location or set coordinates manually."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                RowLayout {
                    spacing: 4 * Appearance.effectiveScale
                    Layout.preferredHeight: 40 * Appearance.effectiveScale
                    
                    Repeater {
                        model: [
                            { label: "Auto", value: true },
                            { label: "Manual", value: false }
                        ]
                        delegate: SegmentedButton {
                            isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.autoLocation === modelData.value : false
                            Layout.fillHeight: true
                            
                            buttonText: modelData.label
                            leftPadding: 16 * Appearance.effectiveScale
                            rightPadding: 16 * Appearance.effectiveScale
                            
                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow
                            
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.autoLocation = modelData.value;
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3b. Manual Location Inputs (Only visible if manual)
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: manualLocationInner.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            visible: Config.ready && Config.options.weather && Config.options.weather.enable && !Config.options.weather.autoLocation
            
            ColumnLayout {
                id: manualLocationInner
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 16 * Appearance.effectiveScale

                StyledText {
                    text: "Manual Coordinates & City Name"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                RowLayout {
                    spacing: 12 * Appearance.effectiveScale
                    Layout.fillWidth: true

                    // Latitude Input
                    ColumnLayout {
                        spacing: 4 * Appearance.effectiveScale
                        Layout.fillWidth: true
                        StyledText {
                            text: "Latitude"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: latInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: latInput
                                anchors.fill: parent
                                anchors.leftMargin: 12 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.weather) ? Config.options.weather.lat : ""
                                onEditingFinished: {
                                    if (Config.ready && Config.options.weather) Config.options.weather.lat = text;
                                }
                            }
                        }
                    }

                    // Longitude Input
                    ColumnLayout {
                        spacing: 4 * Appearance.effectiveScale
                        Layout.fillWidth: true
                        StyledText {
                            text: "Longitude"
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40 * Appearance.effectiveScale
                            radius: 8 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: lonInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: lonInput
                                anchors.fill: parent
                                anchors.leftMargin: 12 * Appearance.effectiveScale
                                anchors.rightMargin: 12 * Appearance.effectiveScale
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.weather) ? Config.options.weather.lon : ""
                                onEditingFinished: {
                                    if (Config.ready && Config.options.weather) Config.options.weather.lon = text;
                                }
                            }
                        }
                    }
                }

                // City Name Input
                ColumnLayout {
                    spacing: 4 * Appearance.effectiveScale
                    Layout.fillWidth: true
                    StyledText {
                        text: "City / Location Name (Displayed in UI)"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40 * Appearance.effectiveScale
                        radius: 8 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerLow
                        border.width: cityInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                        border.color: Appearance.colors.colPrimary

                        TextInput {
                            id: cityInput
                            anchors.fill: parent
                            anchors.leftMargin: 12 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            text: (Config.ready && Config.options.weather) ? Config.options.weather.city : ""
                            onEditingFinished: {
                                if (Config.ready && Config.options.weather) Config.options.weather.city = text;
                            }
                        }
                    }
                }
            }
        }

        // 4. Daily Forecast Card
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: weatherDailyRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            RowLayout {
                id: weatherDailyRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Show Daily Forecast"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Display weather forecast for the upcoming days."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                        checked: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast)
                        onToggled: {
                            if (Config.ready && Config.options.weather) {
                                Config.options.weather.showDailyForecast = !Config.options.weather.showDailyForecast;
                    }
                    }
                }
            }
        }
        // 5. Update Interval Card (Bottom)
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: intervalRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }
            
            RowLayout {
                id: intervalRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Update Interval"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "How often to refresh weather data."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                RowLayout {
                    spacing: 8 * Appearance.effectiveScale
                    
                    StyledComboBox {
                        implicitWidth: 140 * Appearance.effectiveScale
                        searchable: false
                        text: (Config.ready && Config.options.weather) ? (Config.options.weather.updateInterval + " mins") : "30 mins"
                        model: ["15 mins", "30 mins", "1 hour", "2 hours", "4 hours"]
                        onAccepted: (val) => {
                            if (Config.ready && Config.options.weather) {
                                let mins = 30;
                                if (val === "15 mins") mins = 15;
                                else if (val === "30 mins") mins = 30;
                                else if (val === "1 hour") mins = 60;
                                else if (val === "2 hours") mins = 120;
                                else if (val === "4 hours") mins = 240;
                                Config.options.weather.updateInterval = mins;
                            }
                        }
                    }
                }
            }
        }
    }
}
