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
    spacing: 0
    
    SearchHandler { 
        searchString: "Disk Monitoring"
        aliases: ["Storage", "Disk Space", "Drives", "Usage", "Mount Point", "Disk"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "storage"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Disk Monitoring")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
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
                    implicitHeight: Math.max(64 * Appearance.effectiveScale, diskRow.implicitHeight)
                    orientation: Qt.Vertical
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    // Manual rounding for joined list
                    forceFirst: index === 0
                    forceLast: false
                    forceNotStandalone: true

                    RowLayout {
                        id: diskRow
                        anchors.fill: parent
                        anchors {
                            leftMargin: 16 * Appearance.effectiveScale
                            rightMargin: 12 * Appearance.effectiveScale
                        }
                        spacing: 16 * Appearance.effectiveScale

                        ColumnLayout {
                            spacing: 2 * Appearance.effectiveScale
                            StyledText {
                                text: modelData.alias !== "" ? modelData.alias : modelData.path
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                text: modelData.alias !== "" ? modelData.path : ""
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                visible: modelData.alias !== ""
                            }
                        }

                        Item { Layout.fillWidth: true }

                        RippleButton {
                            implicitWidth: 40 * Appearance.effectiveScale
                            implicitHeight: 40 * Appearance.effectiveScale
                            buttonRadius: 20 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: {
                                let list = [];
                                for (let d of Config.options.system.monitoredDisks) {
                                    if (d.path !== modelData.path) {
                                        list.push(d);
                                    }
                                }
                                Config.options.system.monitoredDisks = list;
                            }
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                iconSize: 20 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }
        }

        // Add disk section
        SegmentedWrapper {
            Layout.fillWidth: true
            Layout.topMargin: 0 // Joined to above
            implicitHeight: addDiskInner.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            smallRadius: 8 * Appearance.effectiveScale
            fullRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            forceFirst: (Config.ready && Config.options.system) ? Config.options.system.monitoredDisks.length === 0 : true
            forceLast: true
            forceNotStandalone: true

            ColumnLayout {
                id: addDiskInner
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                RowLayout {
                    spacing: 16 * Appearance.effectiveScale
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 12 * Appearance.effectiveScale
                        Layout.fillWidth: true

                        StyledTextInput {
                            id: addDiskPathInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * Appearance.effectiveScale
                            inputRadius: 24
                            placeholder: I18nService.tr("Mount path (e.g. /home)")
                        }

                        StyledTextInput {
                            id: addDiskAliasInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * Appearance.effectiveScale
                            inputRadius: 24
                            placeholder: I18nService.tr("Alias (e.g. Work)")
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
}
