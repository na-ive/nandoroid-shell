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
    spacing: 0
    
    SearchHandler { 
        searchString: "Screenshot"
        aliases: ["Screen Record", "Screen Capture", "Screen Snip", "Capture", "Recording", "Save Path", "Storage", "Screenshot Path", "Recording Path"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "screenshot"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: "Screenshot & Screen Record"
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        // 1. Auto Save Switch
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: autoSaveRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: autoSaveRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Auto Save Screenshots"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Automatically save screenshots to the storage folder."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                        checked: (Config.ready && Config.options.screenshot && Config.options.screenshot.autoSave)
                        onToggled: {
                            if (Config.ready && Config.options.screenshot) {
                                Config.options.screenshot.autoSave = !Config.options.screenshot.autoSave;
                    }
                    }
                }
            }
        }

        // 2. Auto Copy Switch
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: autoCopyRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: autoCopyRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Auto Copy to Clipboard"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Automatically copy the screenshot to your clipboard."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                        checked: (Config.ready && Config.options.screenshot && Config.options.screenshot.autoCopy)
                        onToggled: {
                            if (Config.ready && Config.options.screenshot) {
                                Config.options.screenshot.autoCopy = !Config.options.screenshot.autoCopy;
                    }
                    }
                }
            }
        }

        // 3. Show Preview Switch
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: previewRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            
            RowLayout {
                id: previewRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                ColumnLayout {
                    spacing: 2 * Appearance.effectiveScale
                    StyledText {
                        text: "Show Android-style Preview"
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: "Display a floating preview overlay after capturing."
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                AndroidToggle {
                        checked: (Config.ready && Config.options.screenshot && Config.options.screenshot.showPreview)
                        onToggled: {
                            if (Config.ready && Config.options.screenshot) {
                                Config.options.screenshot.showPreview = !Config.options.screenshot.showPreview;
                    }
                    }
                }
            }
        }

        // 4. Screenshot Save Path
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: pathRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale

            RowLayout {
                id: pathRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                StyledText {
                    text: "Screenshot Path"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.preferredWidth: 200 * Appearance.effectiveScale
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    radius: 12 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerLow
                    border.width: pathInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                    border.color: Appearance.colors.colPrimary

                    TextInput {
                        id: pathInput
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        text: (Config.ready && Config.options.screenshot) ? Config.options.screenshot.savePath : ""
                        onEditingFinished: {
                            if (Config.ready && Config.options.screenshot) {
                                Config.options.screenshot.savePath = Functions.FileUtils.trimFileProtocol(text);
                            }
                        }
                        
                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Enter screenshot directory path"
                            color: Appearance.colors.colSubtext
                            visible: pathInput.text === "" && !pathInput.activeFocus
                        }
                    }
                }
            }
        }

        // 5. Recording Save Path
        SegmentedWrapper {
            Layout.fillWidth: true
            implicitHeight: recordPathRow.implicitHeight + 40 * Appearance.effectiveScale
            orientation: Qt.Vertical
            color: Appearance.m3colors.m3surfaceContainerHigh
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale

            RowLayout {
                id: recordPathRow
                anchors.fill: parent
                anchors.margins: 20 * Appearance.effectiveScale
                spacing: 20 * Appearance.effectiveScale

                StyledText {
                    text: "Recording Path"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    Layout.preferredWidth: 200 * Appearance.effectiveScale
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * Appearance.effectiveScale
                    radius: 12 * Appearance.effectiveScale
                    color: Appearance.m3colors.m3surfaceContainerLow
                    border.width: recordPathInput.activeFocus ? Math.max(1, 2 * Appearance.effectiveScale) : 0
                    border.color: Appearance.colors.colPrimary

                    TextInput {
                        id: recordPathInput
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Appearance.font.family.main
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer1
                        text: (Config.ready && Config.options.screenshot) ? Config.options.screenshot.recordPath : ""
                        onEditingFinished: {
                            if (Config.ready && Config.options.screenshot) {
                                Config.options.screenshot.recordPath = Functions.FileUtils.trimFileProtocol(text);
                            }
                        }
                        
                        StyledText {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Enter recording directory path"
                            color: Appearance.colors.colSubtext
                            visible: recordPathInput.text === "" && !recordPathInput.activeFocus
                        }
                    }
                }
            }
        }
    }
}

