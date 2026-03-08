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
            
            SearchHandler { searchString: "Power Management" }

            RowLayout {
                spacing: 12
                Layout.bottomMargin: 4
                MaterialSymbol {
                    text: "bolt"
                    iconSize: 24
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Power Profile"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // 1. Enable Toggle Card
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: powerEnableRow.implicitHeight + 40
                orientation: Qt.Vertical
                forceLast: false
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh

                RowLayout {
                    id: powerEnableRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: "Custom Power Profile"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "Enable overriding system power modes via a local file."
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
                        color: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                            ? Appearance.colors.colPrimary
                            : Appearance.colors.colLayer3

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled) ? parent.width - width - 4 : 4
                            color: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                                ? Appearance.colors.colOnPrimary
                                : Appearance.colors.colSubtext
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.ready && Config.options.powerProfile) {
                                    Config.options.powerProfile.enabled = !Config.options.powerProfile.enabled;
                                }
                            }
                        }
                    }
                }
            }

            // 2. Custom Path Card
            SegmentedWrapper {
                Layout.fillWidth: true
                implicitHeight: powerPathRow.implicitHeight + 40
                orientation: Qt.Vertical
                forceFirst: false
                forceLast: true
                maxRadius: 20
                color: Appearance.m3colors.m3surfaceContainerHigh
                opacity: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled) ? 1.0 : 0.4
                enabled: (Config.ready && Config.options.powerProfile && Config.options.powerProfile.enabled)
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    id: powerPathRow
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 20

                    ColumnLayout {
                        spacing: 2
                        Layout.maximumWidth: 400
                        StyledText {
                            text: "Custom Profile Path"
                            font.pixelSize: Appearance.font.pixelSize.normal
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                        StyledText {
                            text: "The exact path to write custom profile strings."
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 48
                        radius: 12
                        color: Appearance.m3colors.m3surfaceContainerLow
                        border.width: powerPathInput.activeFocus ? 2 : 0
                        border.color: Appearance.colors.colPrimary

                        TextInput {
                            id: powerPathInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Appearance.font.family.main
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer1
                            clip: true
                            text: (Config.ready && Config.options.powerProfile) ? Config.options.powerProfile.customPath : "/tmp/ryzen_mode"
                            onEditingFinished: { 
                                if (Config.ready && Config.options.powerProfile) {
                                    Config.options.powerProfile.customPath = text;
                                }
                            }
                            
                            StyledText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Enter path (e.g., /tmp/ryzen_mode)"
                                color: Appearance.colors.colSubtext
                                visible: powerPathInput.text === "" && !powerPathInput.activeFocus
                            }
                        }
                    }
                }
            }
        }

