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
                text: I18nService.tr("Weather")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // Enable Weather Service (whole card clickable)
        SegmentedWrapper {
            id: weatherEnableCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, weatherEnableRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: weatherEnableCard.rTopLeft
                topRightRadius: weatherEnableCard.rTopRight
                bottomLeftRadius: weatherEnableCard.rBottomLeft
                bottomRightRadius: weatherEnableCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.weather) {
                        Config.options.weather.enable = !Config.options.weather.enable;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Fetch weather data for the notification center, desktop widget, and lock screen.")
                }
            }

            RowLayout {
                id: weatherEnableRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "cloud"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Enable Weather Service")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

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

        // Weather Provider
        SegmentedWrapper {
            id: providerCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, weatherProviderRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                id: providerHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: providerHoverArea.containsMouse
                    text: I18nService.tr("Choose the weather data service to use.")
                }
            }

            RowLayout {
                id: weatherProviderRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "dns"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Weather Provider")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale

                    Repeater {
                        model: [
                            { label: "Open-Meteo", value: "open-meteo" },
                            { label: "wttr.in", value: "wttr.in" }
                        ]
                        delegate: SegmentedButton {
                            required property var modelData
                            isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.provider === modelData.value : false

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

        // Location Settings
        SegmentedWrapper {
            id: locationCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, locationRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                id: locationHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: locationHoverArea.containsMouse
                    text: I18nService.tr("Automatically detect location or set a city name manually.")
                }
            }

            RowLayout {
                id: locationRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "location_on"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Location Settings")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale

                    Repeater {
                        model: [
                            { label: I18nService.tr("Auto"), value: true },
                            { label: I18nService.tr("Manual"), value: false }
                        ]
                        delegate: SegmentedButton {
                            required property var modelData
                            isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.autoLocation === modelData.value : false

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

        // Manual City Name (whole card focuses the input)
        SegmentedWrapper {
            id: cityCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, cityRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            visible: Config.ready && Config.options.weather && Config.options.weather.enable && !Config.options.weather.autoLocation

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: cityCard.rTopLeft
                topRightRadius: cityCard.rTopRight
                bottomLeftRadius: cityCard.rBottomLeft
                bottomRightRadius: cityCard.rBottomRight
                onClicked: cityInput.forceActiveFocus()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Used to resolve coordinates via geocoding (e.g. Jakarta).")
                }
            }

            RowLayout {
                id: cityRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "location_city"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("City name")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledTextInput {
                    id: cityInput
                    Layout.preferredWidth: 250 * Appearance.effectiveScale
                    inputRadius: 24
                    text: (Config.ready && Config.options.weather) ? Config.options.weather.location : ""
                    onEditingFinished: {
                        if (Config.ready && Config.options.weather)
                            Config.options.weather.location = text;
                    }
                }
            }
        }

        // Show Daily Forecast (whole card clickable)
        SegmentedWrapper {
            id: dailyForecastCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, weatherDailyRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RippleButton {
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: dailyForecastCard.rTopLeft
                topRightRadius: dailyForecastCard.rTopRight
                bottomLeftRadius: dailyForecastCard.rBottomLeft
                bottomRightRadius: dailyForecastCard.rBottomRight
                onClicked: {
                    if (Config.ready && Config.options.weather) {
                        Config.options.weather.showDailyForecast = !Config.options.weather.showDailyForecast;
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Display weather forecast for the upcoming days.")
                }
            }

            RowLayout {
                id: weatherDailyRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "date_range"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Show Daily Forecast")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

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

        // Temperature Unit
        SegmentedWrapper {
            id: unitCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, weatherUnitRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                id: unitHoverArea
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                hoverEnabled: true
                StyledToolTip {
                    extraVisibleCondition: false
                    alternativeVisibleCondition: unitHoverArea.containsMouse
                    text: I18nService.tr("Choose Celsius or Fahrenheit for weather temperatures.")
                }
            }

            RowLayout {
                id: weatherUnitRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "device_thermostat"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Temperature Unit")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 2 * Appearance.effectiveScale

                    Repeater {
                        model: [
                            { label: "°C", value: "C" },
                            { label: "°F", value: "F" }
                        ]
                        delegate: SegmentedButton {
                            required property var modelData
                            isHighlighted: (Config.ready && Config.options.weather) ? Config.options.weather.unit === modelData.value : false

                            buttonText: modelData.label
                            leftPadding: 16 * Appearance.effectiveScale
                            rightPadding: 16 * Appearance.effectiveScale

                            colActive: Appearance.m3colors.m3primary
                            colActiveText: Appearance.m3colors.m3onPrimary
                            colInactive: Appearance.m3colors.m3surfaceContainerLow

                            onClicked: {
                                if (Config.ready && Config.options.weather) {
                                    Config.options.weather.unit = modelData.value;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Update Interval (whole card opens the combo)
        SegmentedWrapper {
            id: intervalCard
            Layout.fillWidth: true
            implicitHeight: Math.max(64 * Appearance.effectiveScale, intervalRow.implicitHeight)
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh

            enabled: Config.ready && Config.options.weather && Config.options.weather.enable
            opacity: enabled ? 1.0 : 0.5
            Behavior on opacity { NumberAnimation { duration: 200 } }

            RippleButton {
                id: intervalClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: intervalCard.rTopLeft
                topRightRadius: intervalCard.rTopRight
                bottomLeftRadius: intervalCard.rBottomLeft
                bottomRightRadius: intervalCard.rBottomRight

                property real comboClosedAt: 0

                onClicked: {
                    if (Date.now() - comboClosedAt < 250) return;
                    weatherIntervalCombo.isOpened = !weatherIntervalCombo.isOpened;
                }

                Connections {
                    target: weatherIntervalCombo
                    function onIsOpenedChanged() {
                        if (!weatherIntervalCombo.isOpened) intervalClickArea.comboClosedAt = Date.now();
                    }
                }

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("How often to refresh weather data.")
                }
            }

            RowLayout {
                id: intervalRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "schedule"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Update Interval")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                StyledComboBox {
                    id: weatherIntervalCombo
                    implicitWidth: 140 * Appearance.effectiveScale
                    bgRadius: height / 2
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
