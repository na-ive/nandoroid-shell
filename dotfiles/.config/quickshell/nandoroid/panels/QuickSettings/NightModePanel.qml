import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Night Mode detail panel.
 * Shows toggle + color temperature slider.
 */
Rectangle {
    id: root
    signal dismiss()

    color: Appearance.colors.colLayer0
    radius: Appearance.rounding.panel

    // Block clicks from leaking through to the header
    MouseArea {
        anchors.fill: parent
        onPressed: (mouse) => mouse.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            RippleButton {
                implicitWidth: 36 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.colors.colLayer2
                onClicked: root.dismiss()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3onSurface
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Night Mode"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: Appearance.m3colors.m3onSurface
            }

            RippleButton {
                implicitWidth: 56 * Appearance.effectiveScale
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Hyprsunset.active ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                colBackgroundHover: Hyprsunset.active ? Qt.darker(Appearance.colors.colPrimary, 1.12) : Appearance.colors.colLayer2Hover
                onClicked: Hyprsunset.toggle()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "bedtime"
                    iconSize: 20 * Appearance.effectiveScale
                    fill: Hyprsunset.active ? 1 : 0
                    color: Hyprsunset.active ? Appearance.colors.colOnPrimary : Appearance.m3colors.m3onSurface
                }
            }
        }

        // ── Separator ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }


        // ── Color temperature slider ──
        Column {
            Layout.fillWidth: true
            Layout.topMargin: 8 * Appearance.effectiveScale
            spacing: 6 * Appearance.effectiveScale

            RowLayout {
                width: parent.width
                StyledText {
                    Layout.fillWidth: true
                    text: "Color Temperature"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.m3colors.m3onSurface
                }
                StyledText {
                    text: `${tempSlider.value}K`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colPrimary
                }
            }

            // Temperature label row (cool ← → warm)
            RowLayout {
                width: parent.width
                StyledText {
                    text: "Warm"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3onSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: "Cool"
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.m3colors.m3onSurfaceVariant
                }
            }

            StyledSlider {
                id: tempSlider
                width: parent.width
                from: 1200  // warmest
                to: 6500    // coolest
                stepSize: 100
                value: Config.options.nightMode?.colorTemperature ?? 4000
                configuration: StyledSlider.Configuration.S

                onMoved: {
                    Config.options.nightMode.colorTemperature = value;
                    // Hyprsunset.colorTemperature is bound to this config value,
                    // so onColorTemperatureChanged fires automatically — updating hyprsunset live.
                }
            }
        }



        Item { Layout.fillHeight: true }

        // ── Footer ──
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Appearance.m3colors.m3outlineVariant
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8 * Appearance.effectiveScale

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: doneText.implicitWidth + (24 * Appearance.effectiveScale)
                implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: height / 2
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.1)
                onClicked: root.dismiss()
                StyledText {
                    id: doneText
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnPrimary
                }
            }
        }
    }
}
