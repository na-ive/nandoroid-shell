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
            spacing: 4 * Appearance.effectiveScale
            Layout.topMargin: 16 * Appearance.effectiveScale

            SearchHandler { searchString: "Search Engine" }

            RowLayout {

                    spacing: 12 * Appearance.effectiveScale
                    Layout.bottomMargin: 8 * Appearance.effectiveScale
                    MaterialSymbol {
                        text: "search"
                        iconSize: 24 * Appearance.effectiveScale
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        text: "Search & Launcher"
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                }


                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: mathRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: mathRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "Math Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to trigger mathematical evaluations."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: mathInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: mathInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.mathPrefix : "="
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.mathPrefix = text; }
                            }
                        }
                    }
                }

                // 2. Web Search Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: webRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: webRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "Web Search Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to trigger a Google search."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: webInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: webInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.webPrefix : "!"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.webPrefix = text; }
                            }
                        }
                    }
                }

                // 3. Emoji Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: emojiRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: emojiRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "Emoji Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to search and copy emojis."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: emojiInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: emojiInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.emojiPrefix : ":"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.emojiPrefix = text; }
                            }
                        }
                    }
                }

                // 4. Clipboard Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: clipRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: clipRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "Clipboard Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to search clipboard history."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: clipInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: clipInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.clipboardPrefix : ";"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.clipboardPrefix = text; }
                            }
                        }
                    }
                }

                // 5. File Search Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: fileRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: fileRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "File Search Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to trigger local file searching."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: fileInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: fileInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.filePrefix : "?"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.filePrefix = text; }
                            }
                        }
                    }
                }

                // 6. Command Prefix Card
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: cmdRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: cmdRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "Command Prefix"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prefix to trigger shell commands and quick actions."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        Rectangle {
                            width: 120 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            radius: 12 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: cmdInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: cmdInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.commandPrefix : ">"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.commandPrefix = text; }
                            }
                        }
                    }
                }

                // 7. App Usage Tracking Toggle
                SegmentedWrapper {
                    Layout.fillWidth: true
                    implicitHeight: usageRow.implicitHeight + 40 * Appearance.effectiveScale
                    orientation: Qt.Vertical
                    maxRadius: 20 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: usageRow
                        anchors.fill: parent
                        anchors.margins: 20 * Appearance.effectiveScale
                        spacing: 20 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: "App Usage Tracking"
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: "Prioritize frequently used apps in search results."
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }
                        }
                        Item { Layout.fillWidth: true }
                        
                        AndroidToggle {
                            checked: (Config.ready && Config.options.search) ? Config.options.search.enableUsageTracking : true
                            onToggled: { if (Config.ready && Config.options.search) Config.options.search.enableUsageTracking = checked; }
                        }
                    }
                }
        }

