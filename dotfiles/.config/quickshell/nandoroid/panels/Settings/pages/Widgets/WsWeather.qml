import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: rootWeatherSettings
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "Weather"
        aliases: ["Widget", "Weather", "Cuaca", "Temp", "Temperature"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale
        
        // Section Header
        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 4 * Appearance.effectiveScale
            MaterialSymbol {
                text: "partly_cloudy_day"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Desktop Weather"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            StyledText {
                text: "Reset Position"
                font.pixelSize: Appearance.font.pixelSize.small
                color: maResetWeather.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                MouseArea {
                    id: maResetWeather
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!Config.ready) return;
                        Config.options.appearance.weatherWidget.desktopX = -1;
                        Config.options.appearance.weatherWidget.desktopY = -1;
                    }
                }
            }

            AndroidToggle {
                checked: Config.ready && Config.options.appearance.weatherWidget.showOnDesktop
                onToggled: if (Config.ready) Config.options.appearance.weatherWidget.showOnDesktop = !Config.options.appearance.weatherWidget.showOnDesktop
            }
        }
    }
}
