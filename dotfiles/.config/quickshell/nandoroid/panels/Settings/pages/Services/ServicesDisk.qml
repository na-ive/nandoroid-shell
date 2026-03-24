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
            id: diskMainCol
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale
            Layout.topMargin: 16 * Appearance.effectiveScale
            
            SearchHandler { 
                searchString: "Disk Monitoring"
                aliases: ["Storage", "Disk Space", "Drives", "Usage"]
            }

            RowLayout {
                spacing: 12 * Appearance.effectiveScale
                Layout.bottomMargin: 8 * Appearance.effectiveScale
                MaterialSymbol {
                    text: "storage"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: "Disk Monitoring"
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }
            }

            // List of monitored disks
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Appearance.effectiveScale

                Repeater {
                    model: (Config.ready && Config.options.system) ? Config.options.system.monitoredDisks : []
                    delegate: SegmentedWrapper {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 64 * Appearance.effectiveScale
                        orientation: Qt.Vertical
                        smallRadius: 8 * Appearance.effectiveScale
                        fullRadius: 20 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        // Manual rounding for joined list
                        forceFirst: index === 0
                        forceLast: false 
                        forceNotStandalone: true


                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale

                            ColumnLayout {
                                spacing: -2 * Appearance.effectiveScale
                                StyledText {
                                    text: modelData.alias || "No Alias"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                }
                                StyledText {
                                    text: modelData.path
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                }
                            }

                            Item { Layout.fillWidth: true }

                            RippleButton {
                                implicitWidth: 36 * Appearance.effectiveScale
                                implicitHeight: 36 * Appearance.effectiveScale
                                buttonRadius: 18 * Appearance.effectiveScale
                                colBackground: "transparent"
                                onClicked: {
                                    let list = [];
                                    for (let i = 0; i < Config.options.system.monitoredDisks.length; i++) {
                                        if (i !== index) list.push(Config.options.system.monitoredDisks[i]);
                                    }
                                    Config.options.system.monitoredDisks = list;
                                }
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.m3colors.m3error
                                }
                            }
                        }
                    }
                }

                // Add new disk card (Joined to the segmented list)
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: addDiskRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    forceFirst: ((Config.ready && Config.options.system) ? Config.options.system.monitoredDisks.length : 0) === 0
                    forceLast: true
                    forceNotStandalone: true
                    smallRadius: 8 * Appearance.effectiveScale
                    fullRadius: 20 * Appearance.effectiveScale
                    Layout.topMargin: 0 // Joined to above
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: addDiskRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8 * Appearance.effectiveScale

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48 * Appearance.effectiveScale
                                radius: 12 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3surfaceContainerLow
                                border.width: addDiskPathInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                                border.color: Appearance.colors.colPrimary

                                TextInput {
                                    id: addDiskPathInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 16 * Appearance.effectiveScale
                                    anchors.rightMargin: 16 * Appearance.effectiveScale
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    
                                    StyledText {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Mount point (e.g. /home)"
                                        color: Appearance.colors.colSubtext
                                        visible: addDiskPathInput.text === "" && !addDiskPathInput.activeFocus
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48 * Appearance.effectiveScale
                                radius: 12 * Appearance.effectiveScale
                                color: Appearance.m3colors.m3surfaceContainerLow
                                border.width: addDiskAliasInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                                border.color: Appearance.colors.colPrimary

                                TextInput {
                                    id: addDiskAliasInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 16 * Appearance.effectiveScale
                                    anchors.rightMargin: 16 * Appearance.effectiveScale
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Appearance.font.family.main
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    
                                    StyledText {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Alias (e.g. Work)"
                                        color: Appearance.colors.colSubtext
                                        visible: addDiskAliasInput.text === "" && !addDiskAliasInput.activeFocus
                                    }
                                }
                            }
                        }

                        RippleButton {
                            implicitWidth: 48 * Appearance.effectiveScale
                            implicitHeight: 48 * Appearance.effectiveScale
                            buttonRadius: 24 * Appearance.effectiveScale
                            colBackground: Appearance.colors.colPrimary
                            onClicked: {
                                const path = addDiskPathInput.text.trim();
                                const alias = addDiskAliasInput.text.trim();
                                if (path !== "") {
                                    let list = [];
                                    for (let d of Config.options.system.monitoredDisks) {
                                        list.push(d);
                                    }
                                    if (!list.some(d => d.path === path)) {
                                        list.push({ "path": path, "alias": alias });
                                        Config.options.system.monitoredDisks = list;
                                    }
                                    addDiskPathInput.text = "";
                                    addDiskAliasInput.text = "";
                                }
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "add"
                                iconSize: 24 * Appearance.effectiveScale
                                color: Appearance.colors.colOnPrimary
                            }
                        }
                    }
                }
            }
        }
