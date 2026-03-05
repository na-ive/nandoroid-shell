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

                RowLayout {
                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "settings_suggest"
                        iconSize: 24
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "System Interface"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }

                // 1. Distro Icon
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: distroRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: distroRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "StatusBar Distro Icon"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Show the distribution logo on the left side of the status bar."
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
                            color: (Config.ready && Config.options.bar && Config.options.bar.show_distro_icon)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer3

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: (Config.ready && Config.options.bar && Config.options.bar.show_distro_icon) ? parent.width - width - 4 : 4
                                color: (Config.ready && Config.options.bar && Config.options.bar.show_distro_icon)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.ready && Config.options.bar) {
                                        Config.options.bar.show_distro_icon = !Config.options.bar.show_distro_icon;
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. Notification Counter
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: notifyCounterRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: notifyCounterRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Notification Counter"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Unread notification indicator style in the status bar."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        
                        Item { Layout.fillWidth: true }
                        
                        RowLayout {
                            spacing: 4
                            Layout.preferredHeight: 40
                            
                            Repeater {
                                model: [
                                    { label: "Counter", value: "counter" },
                                    { label: "Simple", value: "simple" },
                                    { label: "Hidden", value: "hidden" }
                                ]
                                delegate: SegmentedButton {
                                    isHighlighted: (Config.ready && Config.options.notifications) ? Config.options.notifications.counterStyle === modelData.value : false
                                    Layout.fillHeight: true
                                    
                                    buttonText: modelData.label
                                    leftPadding: 16
                                    rightPadding: 16
                                    
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    colInactive: Appearance.m3colors.m3surfaceContainerLow
                                    
                                    onClicked: {
                                        if (Config.ready && Config.options.notifications) {
                                            Config.options.notifications.counterStyle = modelData.value;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Privacy Indicators
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: privRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: privRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Privacy Indicators"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Show Android-style green pill when microphone or camera is active."
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
                            color: (Config.ready && Config.options.privacy && Config.options.privacy.enable)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer3

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: (Config.ready && Config.options.privacy && Config.options.privacy.enable) ? parent.width - width - 4 : 4
                                color: (Config.ready && Config.options.privacy && Config.options.privacy.enable)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.ready && Config.options.privacy) {
                                        Config.options.privacy.enable = !Config.options.privacy.enable;
                                    }
                                }
                            }
                        }
                    }
                }

                // 4. Region Selector: Windows Snapping
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: snapRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh
                    maxRadius: 20
                    
                    RowLayout {
                        id: snapRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: "Region Selector: Window Snapping"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Enable automatic window detection and snapping when selecting a region."
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
                            color: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows)
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colLayer3

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                anchors.verticalCenter: parent.verticalCenter
                                x: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows) ? parent.width - width - 4 : 4
                                color: (Config.ready && Config.options.regionSelector && Config.options.regionSelector.targetRegions.windows)
                                    ? Appearance.colors.colOnPrimary
                                    : Appearance.colors.colSubtext
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.ready && Config.options.regionSelector) {
                                        Config.options.regionSelector.targetRegions.windows = !Config.options.regionSelector.targetRegions.windows;
                                    }
                                }
                            }
                        }
                    }
            }
        }
