import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: rootWeatherSettings
    visible: Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget
    Layout.fillWidth: true
    implicitHeight: 96 * Appearance.effectiveScale
    radius: 24 * Appearance.effectiveScale
    color: Appearance.m3colors.m3surfaceContainerHigh

    SearchHandler { 
        searchString: "Weather"
        visible: rootWeatherSettings.visible
        aliases: ["Widget", "Weather", "Cuaca", "Temp", "Temperature"]
    }

    // Top row container (Icon & Toggle)
    RowLayout {
        id: topRow
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 16 * Appearance.effectiveScale
            leftMargin: 16 * Appearance.effectiveScale
            rightMargin: 16 * Appearance.effectiveScale
        }

        MaterialSymbol {
            text: "partly_cloudy_day"
            iconSize: 24 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
        }
        
        Item { Layout.fillWidth: true } // Spacer

        AndroidToggle {
            checked: Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget && Config.options.appearance.weatherWidget.showOnDesktop
            onToggled: {
                if (Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget) {
                    Config.options.appearance.weatherWidget.showOnDesktop = !Config.options.appearance.weatherWidget.showOnDesktop
                }
            }
        }
    }

    // Bottom row container (Title/Status & Reset Link)
    RowLayout {
        id: bottomRow
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            bottomMargin: 16 * Appearance.effectiveScale
            leftMargin: 16 * Appearance.effectiveScale
            rightMargin: 16 * Appearance.effectiveScale
        }

        ColumnLayout {
            spacing: 0
            
            StyledText {
                text: "Weather"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                id: statusText
                text: (Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget && Config.options.appearance.weatherWidget.showOnDesktop) ? "Enabled" : "Disabled"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }

        Item { Layout.fillWidth: true } // Spacer

        StyledText {
            text: "Reset Position"
            font.pixelSize: Appearance.font.pixelSize.small
            color: maResetWeather.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 1 * Appearance.effectiveScale

            MouseArea {
                id: maResetWeather
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (Config.ready && Config.options.appearance && Config.options.appearance.weatherWidget) {
                        Config.options.appearance.weatherWidget.desktopX = -1;
                        Config.options.appearance.weatherWidget.desktopY = -1;
                    }
                }
            }
        }
    }
}
