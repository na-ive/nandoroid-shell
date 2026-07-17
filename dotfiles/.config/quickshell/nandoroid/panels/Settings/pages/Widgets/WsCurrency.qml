import "../../../../core"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ColumnLayout {
    id: rootCurrencySettings
    Layout.fillWidth: true
    spacing: 0

    SearchHandler { 
        searchString: "Currency Tracker"
        aliases: ["Widget", "Currency", "Money", "Rates", "IDR", "USD", "Finance"]
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
                text: "payments"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Desktop Currency Tracker"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }
            StyledText {
                text: "Reset Position"
                font.pixelSize: Appearance.font.pixelSize.small
                color: maResetCurrency.containsMouse ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary

                MouseArea {
                    id: maResetCurrency
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.ready && Config.options.appearance.currencyWidget) {
                            Config.options.appearance.currencyWidget.desktopX = -1;
                            Config.options.appearance.currencyWidget.desktopY = -1;
                        }
                    }
                }
            }

            AndroidToggle {
                checked: Config.ready && Config.options.appearance.currencyWidget && Config.options.appearance.currencyWidget.showOnDesktop
                onToggled: {
                    if (Config.ready && Config.options.appearance.currencyWidget) {
                        Config.options.appearance.currencyWidget.showOnDesktop = !Config.options.appearance.currencyWidget.showOnDesktop;
                    }
                }
            }
        }
    }
}
