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
            spacing: 4
            
            SearchHandler { 
                searchString: "Weather"
                aliases: ["Forecast", "Temperature", "Climate"]
            }

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 8
                MaterialSymbol {
                    text: "cloud"
                    iconSize: 24
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
                implicitHeight: weatherEnableRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                RowLayout {
                    id: weatherEnableRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
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
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.weather && Config.options.weather.enable)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.weather && Config.options.weather.enable) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.weather && Config.options.weather.enable)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.enable = !Config.options.weather.enable;
                                    if (Config.options.weather.enable) {
                                        Weather.fetch();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 1. Auto Location Card (Top)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: autoLocRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: autoLocRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Auto detect location"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Determine weather based on your IP address."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.weather && Config.options.weather.autoLocation)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.weather && Config.options.weather.autoLocation) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.weather && Config.options.weather.autoLocation)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.autoLocation = !Config.options.weather.autoLocation;
                                    Weather.fetch();
                                }
                            }
                        }
                    }
                }
            }

            // 2. Manual Location Card (Middle)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: locRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable && !Config.options.weather.autoLocation
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    id: locRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    StyledText {
                        text: "Manual Location"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                        Layout.preferredWidth: 200
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 12
                        color: Appearance.m3colors.m3surfaceContainerLow
                        border.width: locInput.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary

                        TextInput {
                            id: locInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            text: (Config.ready && Config.options.weather) ? Config.options.weather.location : ""
                            onEditingFinished: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.location = text;
                                    Weather.fetch();
                                }
                            }
                            
                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Enter city (e.g., London, UK)"
                                color: Appearance.colors.colSubtext
                                visible: locInput.text === "" && !locInput.activeFocus
                            }
                        }
                    }
                }
            }

            // 3. Temperature Unit Card (Middle)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: unitRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: unitRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Temperature Unit"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Choose between Celsius and Fahrenheit."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    RowLayout {
                        spacing: 4
                        Layout.preferredHeight: 52
                        Layout.alignment: Qt.AlignRight
                        
                        Repeater {
                            model: [
                                { label: "°C", value: "C" },
                                { label: "°F", value: "F" }
                            ]
                            delegate: SegmentedButton {
                                isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.unit === modelData.value : false
                                Layout.fillHeight: true
                                
                                buttonText: modelData.label
                                leftPadding: 32
                                rightPadding: 32
                                
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactive: Appearance.m3colors.m3surfaceContainerLow
                                
                                onClicked: {
                                    if (Config.ready && Config.options.weather) {
                                        Config.options.weather.unit = modelData.value;
                                        Weather.fetch();
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // 4. Daily Forecast Card (Middle)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: dailyFlowRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: dailyFlowRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Show 3 Days Forecast"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Display additional weather for the next few days."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    // Custom Switch
                    Rectangle {
                        implicitWidth: 52
                        implicitHeight: 28
                        radius: 14
                        color: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast)
                            ? Appearance.colors.colPrimary
                            : Appearance.m3colors.m3surfaceContainerLowest

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.weather && Config.options.weather.showDailyForecast)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.showDailyForecast = !Config.options.weather.showDailyForecast;
                                }
                            }
                        }
                    }
                }
            }
            // 5. Update Interval Card (Bottom)
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: intervalRow.implicitHeight + 40
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh
                smallRadius: 8
                fullRadius: 20
                
                enabled: Config.ready && Config.options.weather && Config.options.weather.enable
                opacity: enabled ? 1.0 : 0.5
                Behavior on opacity { NumberAnimation { duration: 200 } }
                
                RowLayout {
                    id: intervalRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
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
                        spacing: 8
                        
                        StyledComboBox {
                            implicitWidth: 140
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

