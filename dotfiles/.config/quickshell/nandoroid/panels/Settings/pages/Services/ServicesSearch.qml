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

            SearchHandler { searchString: "Search Engine" }

            RowLayout {

                    spacing: 12
                    Layout.bottomMargin: 8
                    MaterialSymbol {
                        text: "search"
                        iconSize: 24
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
                    implicitHeight: mathRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: mathRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
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
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: mathInput.activeFocus ? 2 : 0
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
                    implicitHeight: webRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: webRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
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
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: webInput.activeFocus ? 2 : 0
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
                    implicitHeight: emojiRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: emojiRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
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
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: emojiInput.activeFocus ? 2 : 0
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
                    implicitHeight: clipRow.implicitHeight + 40
                    orientation: Qt.Vertical
                    maxRadius: 20
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    RowLayout {
                        id: clipRow
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 20

                        ColumnLayout {
                            spacing: 2
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
                            width: 120
                            height: 48
                            radius: 12
                            color: Appearance.m3colors.m3surfaceContainerLow
                            border.width: clipInput.activeFocus ? 2 : 0
                            border.color: Appearance.colors.colPrimary

                            TextInput {
                                id: clipInput
                                anchors.fill: parent
                                horizontalAlignment: TextInput.AlignHCenter
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Appearance.font.family.main
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnLayer1
                                text: (Config.ready && Config.options.search) ? Config.options.search.clipboardPrefix : ">"
                                onEditingFinished: { if (Config.ready && Config.options.search) Config.options.search.clipboardPrefix = text; }
                            }
                        }
                    }
                }
        }

