import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4 * Appearance.effectiveScale

    SearchHandler {
        searchString: "Date & Time"
        aliases: ["Time Format", "Date Format", "First Day of Week", "Clock", "12H", "24H"]
    }

    RowLayout {
        spacing: 12 * Appearance.effectiveScale
        Layout.bottomMargin: 8 * Appearance.effectiveScale
        MaterialSymbol {
            text: "schedule"
            iconSize: 24 * Appearance.effectiveScale
            color: Appearance.colors.colPrimary
        }
        StyledText {
            text: I18nService.tr("Date & Time")
            font.pixelSize: Appearance.font.pixelSize.large
            font.family: Appearance.font.family.title
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
    }

    // Time Format Card
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, timeRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: timeRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol { text: "pace"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            StyledText {
                text: I18nService.tr("Time Format")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 2 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { label: "12H pm", value: "12H_pm" },
                        { label: "12H PM", value: "12H_PM" },
                        { label: "24H",    value: "24H" }
                    ]
                    delegate: SegmentedButton {
                        required property var modelData
                        isHighlighted: Config.ready && Config.options.time ? Config.options.time.timeStyle === modelData.value : false
                        Layout.alignment: Qt.AlignVCenter

                        buttonText: modelData.label
                        leftPadding: 16 * Appearance.effectiveScale
                        rightPadding: 16 * Appearance.effectiveScale

                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary

                        onClicked: if(Config.ready) Config.options.time.timeStyle = modelData.value
                    }
                }
            }
        }
    }

    // Date Format Card
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, dateRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: dateRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol { text: "calendar_month"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            StyledText {
                text: I18nService.tr("Date Format")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 2 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { label: "DD/MM/YYYY", value: "DMY" },
                        { label: "MM/DD/YYYY", value: "MDY" },
                        { label: "YYYY/MM/DD", value: "YMD" }
                    ]
                    delegate: SegmentedButton {
                        required property var modelData
                        isHighlighted: Config.ready && Config.options.time ? Config.options.time.dateStyle === modelData.value : false
                        Layout.alignment: Qt.AlignVCenter

                        buttonText: modelData.label
                        leftPadding: 16 * Appearance.effectiveScale
                        rightPadding: 16 * Appearance.effectiveScale

                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary

                        onClicked: if(Config.ready) Config.options.time.dateStyle = modelData.value
                    }
                }
            }
        }
    }

    // First Day of Week Card
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, weekRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: weekRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol { text: "calendar_view_day"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            StyledText {
                text: I18nService.tr("First Day of Week")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 2 * Appearance.effectiveScale

                Repeater {
                    model: [
                        { label: I18nService.tr("Saturday"), value: 6 },
                        { label: I18nService.tr("Sunday"), value: 0 },
                        { label: I18nService.tr("Monday"), value: 1 }
                    ]
                    delegate: SegmentedButton {
                        required property var modelData
                        isHighlighted: Config.ready && Config.options.time ? Config.options.time.firstDayOfWeek === modelData.value : false
                        Layout.alignment: Qt.AlignVCenter

                        buttonText: modelData.label
                        leftPadding: 16 * Appearance.effectiveScale
                        rightPadding: 16 * Appearance.effectiveScale

                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary

                        onClicked: if(Config.ready) Config.options.time.firstDayOfWeek = modelData.value
                    }
                }
            }
        }
    }
}
