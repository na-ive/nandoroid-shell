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
        anchors.margins: 12
        spacing: 8

        // ── Header ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            RippleButton {
                implicitWidth: 36
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Appearance.colors.colLayer2
                onClicked: root.dismiss()
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "arrow_back"
                    iconSize: 20
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
                implicitWidth: 56
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Hyprsunset.active ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                colBackgroundHover: Hyprsunset.active ? Qt.darker(Appearance.colors.colPrimary, 1.12) : Appearance.colors.colLayer2Hover
                onClicked: Hyprsunset.toggle()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "bedtime"
                    iconSize: 20
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
            Layout.topMargin: 8
            spacing: 6

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

        // ── Anti-flashbang ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Appearance.m3colors.m3outlineVariant
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: "Anti-Flashbang"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.m3colors.m3onSurface
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: "Dim screen automatically when bright white content is shown."
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.m3colors.m3onSurfaceVariant
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                // Custom Switch
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 24
                    radius: 12
                    color: (Config.ready && Config.options.light && Config.options.light.antiFlashbang && Config.options.light.antiFlashbang.enable)
                        ? Appearance.colors.colPrimary
                        : Appearance.colors.colLayer3

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: (Config.ready && Config.options.light && Config.options.light.antiFlashbang && Config.options.light.antiFlashbang.enable) ? parent.width - width - 4 : 4
                        color: (Config.ready && Config.options.light && Config.options.light.antiFlashbang && Config.options.light.antiFlashbang.enable)
                            ? Appearance.colors.colOnPrimary
                            : Appearance.m3colors.m3onSurfaceVariant
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Config.ready && Config.options.light && Config.options.light.antiFlashbang) {
                                Config.options.light.antiFlashbang.enable = !Config.options.light.antiFlashbang.enable;
                            }
                        }
                    }
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
            spacing: 8

            Item { Layout.fillWidth: true }

            RippleButton {
                implicitWidth: doneText.implicitWidth + 24
                implicitHeight: 36
                buttonRadius: 18
                colBackground: Appearance.colors.colPrimary
                colBackgroundHover: Qt.darker(Appearance.colors.colPrimary, 1.12)
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
