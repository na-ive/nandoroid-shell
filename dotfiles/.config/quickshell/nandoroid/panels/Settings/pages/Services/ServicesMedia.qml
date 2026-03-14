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
    Layout.topMargin: 16
    
    SearchHandler { searchString: "Media Controls" }

    RowLayout {
        spacing: 12
        Layout.bottomMargin: 8
        MaterialSymbol {
            text: "music_note"
            iconSize: 24
            color: Appearance.colors.colPrimary
        }
        StyledText {
            text: "Media Management"
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.Medium
            color: Appearance.colors.colOnLayer1
        }
    }

    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: mediaRow.implicitHeight + 40
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: mediaRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                spacing: 2
                Layout.maximumWidth: 400
                StyledText {
                    text: "Media Player Priority"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Prioritize specific players. Put highest priority first (e.g. 'spotify, firefox'). Case-insensitive."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            
            Rectangle {
                Layout.preferredWidth: 200
                height: 48
                radius: 12
                color: Appearance.m3colors.m3surfaceContainerLow
                border.width: priorityInput.activeFocus ? 2 : 0
                border.color: Appearance.colors.colPrimary

                TextInput {
                    id: priorityInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Appearance.font.family.main
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    text: (Config.ready && Config.options.media) ? Config.options.media.priority : ""
                    onEditingFinished: { if (Config.ready && Config.options.media) Config.options.media.priority = text; }
                }
            }
        }
    }

    // --- Show Media Card Toggle (Notification Center) ---
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: showMediaCardRow.implicitHeight + 40
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: showMediaCardRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                spacing: 2
                Layout.maximumWidth: 400
                StyledText {
                    text: "Show Media Card"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Show the media player card in the Notification Center."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }

            // Custom Switch
            Rectangle {
                implicitWidth: 52
                implicitHeight: 28
                radius: 14
                color: (Config.ready && Config.options.media && Config.options.media.showMediaCard)
                    ? Appearance.colors.colPrimary
                    : Appearance.m3colors.m3surfaceContainerLowest

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: (Config.ready && Config.options.media && Config.options.media.showMediaCard) ? parent.width - width - 4 : 4
                    color: (Config.ready && Config.options.media && Config.options.media.showMediaCard)
                        ? Appearance.colors.colOnPrimary
                        : Appearance.colors.colSubtext
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.ready && Config.options.media) {
                            Config.options.media.showMediaCard = !Config.options.media.showMediaCard;
                        }
                    }
                }
            }
        }
    }

    // --- Dynamic Island Hover Toggle ---
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: dynamicIslandHoverRow.implicitHeight + 40
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: dynamicIslandHoverRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                spacing: 2
                Layout.maximumWidth: 400
                StyledText {
                    text: "Dynamic Island Hover"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Show the media controls popup when hovering over the Dynamic Island."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }

            // Custom Switch
            Rectangle {
                implicitWidth: 52
                implicitHeight: 28
                radius: 14
                color: (Config.ready && Config.options.media && Config.options.media.enableMediaHover)
                    ? Appearance.colors.colPrimary
                    : Appearance.m3colors.m3surfaceContainerLowest

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: (Config.ready && Config.options.media && Config.options.media.enableMediaHover) ? parent.width - width - 4 : 4
                    color: (Config.ready && Config.options.media && Config.options.media.enableMediaHover)
                        ? Appearance.colors.colOnPrimary
                        : Appearance.colors.colSubtext
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.ready && Config.options.media) {
                            Config.options.media.enableMediaHover = !Config.options.media.enableMediaHover;
                        }
                    }
                }
            }
        }
    }

    // --- Notch Media Style (Only visible if Hover is enabled) ---
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: notchMediaStyleRow.implicitHeight + 40
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: Config.ready && Config.options.media && Config.options.media.enableMediaHover

        RowLayout {
            id: notchMediaStyleRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                StyledText {
                    text: "Notch Media Style"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Choose between a compact mini HUD or a full-featured media card."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                spacing: 2
                Repeater {
                    model: [
                        { id: "mini", label: "Mini HUD" },
                        { id: "full", label: "Full Card" }
                    ]
                    delegate: SegmentedButton {
                        required property var modelData
                        buttonText: modelData.label
                        isHighlighted: Config.ready && Config.options.media
                            ? (Config.options.media.notchMediaStyle ?? "mini") === modelData.id
                            : modelData.id === "mini"
                        colActive: Appearance.m3colors.m3primary
                        colActiveText: Appearance.m3colors.m3onPrimary
                        colInactive: Appearance.m3colors.m3surfaceContainerLow
                        onClicked: if (Config.ready && Config.options.media)
                            Config.options.media.notchMediaStyle = modelData.id
                    }
                }
            }
        }
    }

    // --- Dynamic Island Balanced Ears Toggle ---
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: balancedEarsRow.implicitHeight + 40
        orientation: Qt.Vertical
        maxRadius: 20
        color: Appearance.m3colors.m3surfaceContainerHigh

        RowLayout {
            id: balancedEarsRow
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            ColumnLayout {
                spacing: 2
                Layout.maximumWidth: 400
                StyledText {
                    text: "Balanced Media Ears"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: "Synchronize left and right ear widths in Dynamic Island for a symmetric look."
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }

            // Custom Switch
            Rectangle {
                implicitWidth: 52
                implicitHeight: 28
                radius: 14
                color: (Config.ready && Config.options.media && Config.options.media.balancedEars)
                    ? Appearance.colors.colPrimary
                    : Appearance.m3colors.m3surfaceContainerLowest

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: (Config.ready && Config.options.media && Config.options.media.balancedEars) ? parent.width - width - 4 : 4
                    color: (Config.ready && Config.options.media && Config.options.media.balancedEars)
                        ? Appearance.colors.colOnPrimary
                        : Appearance.colors.colSubtext
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.ready && Config.options.media) {
                            Config.options.media.balancedEars = !Config.options.media.balancedEars;
                        }
                    }
                }
            }
        }
    }
}
