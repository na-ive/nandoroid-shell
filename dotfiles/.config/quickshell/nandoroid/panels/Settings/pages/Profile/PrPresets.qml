import "../../../../core"
import "../../../../core/functions" as Functions
import "../../../../services"
import "../../../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

ColumnLayout {
    id: prRoot
    Layout.fillWidth: true
    spacing: 0

    property var wallpaperCache: ({})

    SearchHandler {
        searchString: "Presets"
        aliases: ["Save Config", "Load Config", "Configuration Snapshots", "Backup Settings"]
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 * Appearance.effectiveScale

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.bottomMargin: 8 * Appearance.effectiveScale
            MaterialSymbol {
                text: "wall_art"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Presets")
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.title
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer1
            }
        }

        SegmentedWrapper {
            id: saveCard
            Layout.fillWidth: true
            implicitHeight: saveRow.implicitHeight + (24 * Appearance.effectiveScale)
            orientation: Qt.Vertical
            maxRadius: 20 * Appearance.effectiveScale
            color: Appearance.m3colors.m3surfaceContainerHigh

            RippleButton {
                id: saveClickArea
                anchors.fill: parent
                colBackground: Appearance.m3colors.m3surfaceContainerHigh
                colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                buttonRadius: 0
                topLeftRadius: saveCard.rTopLeft
                topRightRadius: saveCard.rTopRight
                bottomLeftRadius: saveCard.rBottomLeft
                bottomRightRadius: saveCard.rBottomRight
                onClicked: presetNameInput.forceActiveFocus()

                StyledToolTip {
                    extraVisibleCondition: parent.hovered || parent.realHovered
                    text: I18nService.tr("Save a snapshot of your current config.")
                }
            }

            RowLayout {
                id: saveRow
                anchors.fill: parent
                anchors {
                    leftMargin: 16 * Appearance.effectiveScale
                    rightMargin: 16 * Appearance.effectiveScale
                    topMargin: 12 * Appearance.effectiveScale
                    bottomMargin: 12 * Appearance.effectiveScale
                }
                spacing: 16 * Appearance.effectiveScale

                MaterialSymbol {
                    text: "save"
                    iconSize: 24 * Appearance.effectiveScale
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    text: I18nService.tr("Save Current Config")
                    color: Appearance.colors.colOnLayer1
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 4 * Appearance.effectiveScale

                    StyledTextInput {
                        id: presetNameInput
                        inputRadius: 24
                        placeholder: I18nService.tr("Preset name")
                        onEditingFinished: savePreset()
                    }

                    RippleButton {
                        implicitWidth: 48 * Appearance.effectiveScale
                        implicitHeight: 48 * Appearance.effectiveScale
                        buttonRadius: 24 * Appearance.effectiveScale
                        colBackground: Appearance.m3colors.m3primaryContainer
                        enabled: presetNameInput.text.trim().replace(/\s/g, "_").length > 0

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "save"
                            iconSize: 22 * Appearance.effectiveScale
                            color: parent.enabled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colSubtext
                        }
                        onClicked: savePreset()
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: 24 * Appearance.effectiveScale
            visible: presetsModel.count === 0
            horizontalAlignment: Text.AlignHCenter
            text: I18nService.tr("No presets yet")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.normal
        }

        Flow {
            id: presetsFlow
            Layout.fillWidth: true
            Layout.topMargin: 16 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale
            visible: presetsModel.count > 0

            property real cardWidth: 240 * Appearance.effectiveScale

            onWidthChanged: Qt.callLater(() => {
                const sp = presetsFlow.spacing
                const available = presetsFlow.width - 2 * sp
                if (available > 0) presetsFlow.cardWidth = Math.floor(available / 3)
            })
            Component.onCompleted: presetsFlow.widthChanged()

            Repeater {
                model: presetsModel

                delegate: Rectangle {
                    id: card
                    required property string fileName
                    required property string filePath
                    required property date fileModified

                    readonly property string fileBaseName: fileName.replace(".json", "")
                    readonly property string presetName: fileBaseName.replace(/_/g, " ")
                    property string presetWallpaper: ""

                    readonly property string cardDate: {
                        try {
                            const d = fileModified
                            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                            return months[d.getMonth()] + " " + d.getDate() + ", " + d.getFullYear()
                        } catch (e) {
                            return I18nService.tr("Unknown date")
                        }
                    }

                    readonly property real cardRadius: 20 * Appearance.effectiveScale
                    readonly property real imgHeight: 120 * Appearance.effectiveScale

                    width: presetsFlow.cardWidth
                    radius: cardRadius
                    color: Appearance.m3colors.m3surfaceContainerHigh

                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: card.width
                            height: card.height
                            radius: card.radius
                        }
                    }

                    Component.onCompleted: {
                        const c = prRoot.wallpaperCache[fileName]
                        if (c !== undefined) presetWallpaper = c
                    }

                    Timer {
                        id: wallpaperRetryTimer
                        interval: 500
                        repeat: false
                        property int attempts: 0
                        onTriggered: {
                            if (card.presetWallpaper !== "" || attempts >= 6) return
                            attempts += 1
                            presetFileView.reload()
                        }
                    }

                    function readPresetWallpaper() {
                        try {
                            const data = JSON.parse(presetFileView.text())
                            const wp = data?.appearance?.background?.wallpaperPath ?? ""
                            if (wp !== "") {
                                presetWallpaper = wp
                                prRoot.wallpaperCache[fileName] = wp
                                return
                            }
                        } catch (e) {}
                        // Empty or half-written file (save race) — retry shortly.
                        // Capped so a preset genuinely without wallpaper doesn't poll forever.
                        if (wallpaperRetryTimer.attempts < 6) wallpaperRetryTimer.restart()
                    }

                    FileView {
                        id: presetFileView
                        path: filePath
                        // presets.sh writes via `jq … > file`: inotify fires on the
                        // empty file first, so watch for the completed write too
                        watchChanges: true
                        onLoaded: card.readPresetWallpaper()
                        onLoadFailed: {
                            if (wallpaperRetryTimer.attempts < 6) wallpaperRetryTimer.restart()
                        }
                    }

                    ColumnLayout {
                        id: cardColumn
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            id: imgCard
                            Layout.fillWidth: true
                            Layout.preferredHeight: imgHeight
                            Layout.bottomMargin: 16 * Appearance.effectiveScale
                            radius: cardRadius
                            color: Appearance.m3colors.m3surfaceContainerLow

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: imgCard.width
                                    height: imgCard.height
                                    radius: imgCard.radius
                                }
                            }

                            Image {
                                id: presetThumb
                                anchors.fill: parent
                                source: presetWallpaper
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(480, 240)
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: presetThumb.status !== Image.Ready
                                text: "wallpaper"
                                iconSize: 40 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12 * Appearance.effectiveScale
                            Layout.rightMargin: 12 * Appearance.effectiveScale
                            Layout.bottomMargin: 10 * Appearance.effectiveScale
                            spacing: 4 * Appearance.effectiveScale

                            StyledText {
                                Layout.fillWidth: true
                                text: presetName
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.family: Appearance.font.family.title
                                font.weight: Font.Normal
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: I18nService.tr("Saved ") + cardDate
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colSubtext
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 8 * Appearance.effectiveScale
                                spacing: 8 * Appearance.effectiveScale

                                Item { Layout.fillWidth: true }

                                RippleButton {
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colLayer2Hover
                                    onClicked: {
                                        // Capture values now — after deleteProc runs, this delegate
                                        // is gone and the Undo callback can only use captured locals
                                        const trashDir = Functions.FileUtils.trimFileProtocol(Directories.cache) + "/presets-trash";
                                        const presetsDir = Directories.presetsPath;
                                        const undoSource = trashDir + "/" + fileBaseName + ".json";
                                        const proc = undoProc;
                                        deleteProc.command = ["bash", "-c", 'mkdir -p "$2" && mv "$1" "$2/"', "sh",
                                            presetsDir + "/" + fileBaseName + ".json", trashDir];
                                        deleteProc.running = true;
                                        SnackbarService.show(
                                            I18nService.tr("Preset deleted"),
                                            I18nService.tr("Undo"),
                                            () => {
                                                proc.command = ["bash", "-c", 'mkdir -p "$2" && mv "$1" "$2/" || true', "sh",
                                                    undoSource, presetsDir];
                                                proc.running = true;
                                            },
                                            SnackbarService.undoDuration
                                        );
                                    }
                                    contentItem: StyledText {
                                        text: I18nService.tr("Delete")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colError
                                    }
                                }

                                RippleButton {
                                    implicitHeight: 36 * Appearance.effectiveScale
                                    buttonRadius: Appearance.rounding.full
                                    colBackground: "transparent"
                                    colBackgroundHover: Appearance.colors.colLayer2Hover
                                    onClicked: {
                                        GlobalStates.settingsOpen = false
                                        Quickshell.execDetached(["bash", Directories.presetsScriptPath, "--apply", fileBaseName])
                                    }
                                    contentItem: StyledText {
                                        text: I18nService.tr("Apply")
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.weight: Font.Medium
                                        color: Appearance.colors.colPrimary
                                    }
                                }
                            }
                        }
                    }

                    height: cardColumn.implicitHeight
                }
            }
        }
    }

    function savePreset() {
        let name = presetNameInput.text.trim().replace(/\s/g, "_")
        if (name.length === 0) return

        saveProc.command = ["bash", Directories.presetsScriptPath, "--save", name]
        saveProc.running = true
        presetNameInput.text = ""
        // No manual refresh needed — FolderListModel watches the directory via
        // inotify and auto-adds the new file without destroying other delegates
    }

    FolderListModel {
        id: presetsModel
        folder: "file://" + Directories.presetsPath
        showDirs: false
        nameFilters: ["*.json"]
        sortField: FolderListModel.Time
        sortReversed: false
        // FolderListModel uses inotify to watch the directory. File additions and
        // deletions are reflected as insertRows/removeRows — only the affected
        // delegate is created/destroyed. Scroll position is preserved naturally.
    }

    Process { id: saveProc }
    Process { id: deleteProc }
    Process { id: undoProc }
}
