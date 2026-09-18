import "../../../../core"
import "../../../../core/functions" as Functions
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

ColumnLayout {
    Layout.fillWidth: true
    spacing: 4 * Appearance.effectiveScale

    SearchHandler { 
        searchString: "Wallpaper Slideshow"
        aliases: ["Auto Cycle", "Slideshow", "Wallpaper Timer", "Desktop Slideshow"]
    }

    // ── Helper for Folder Selection ──

    Process {
        id: folderPickerProc
        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpapers Directory", "--modal"]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") {
                    Wallpapers.setAutoCycleDirectory(path);
                }
            }
        }
    }

    // ── Cycle Toggle ────────────
    SegmentedWrapper {
        id: cycleCard
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, cycleMainRow.implicitHeight)
        orientation: Qt.Vertical
        pillOnActive: false
        color: Appearance.m3colors.m3surfaceContainerHigh
        active: Config.ready && Config.options.appearance.background.autoCycleEnabled

        RippleButton {
            anchors.fill: parent
            colBackground: "transparent"
            buttonRadius: 0
            topLeftRadius: cycleCard.rTopLeft
            topRightRadius: cycleCard.rTopRight
            bottomLeftRadius: cycleCard.rBottomLeft
            bottomRightRadius: cycleCard.rBottomRight
            onClicked: {
                if (Config.ready) Wallpapers.setAutoCycle(!Config.options.appearance.background.autoCycleEnabled)
            }
        }

        RowLayout {
            id: cycleMainRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol {
                text: "auto_mode"
                iconSize: 24 * Appearance.effectiveScale
                color: Appearance.colors.colPrimary
            }
            StyledText {
                text: I18nService.tr("Desktop wallpaper slideshow")
                color: Appearance.colors.colOnLayer1
                Layout.fillWidth: true
            }

            AndroidToggle {
                checked: Config.ready && Config.options.appearance.background.autoCycleEnabled
                onToggled: Wallpapers.setAutoCycle(!checked)
            }
        }
    }

    // ── Expanded Cycle Settings ────
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, intervalRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: Config.ready && Config.options.appearance.background.autoCycleEnabled
        RowLayout {
            id: intervalRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale

            MaterialSymbol { text: "schedule"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            StyledText {
                text: I18nService.tr("Interval")
                Layout.fillWidth: true
                color: Appearance.colors.colOnLayer1
            }

            StyledStepper {
                Layout.alignment: Qt.AlignVCenter
                from: 1; to: 120; stepSize: 1
                decimals: 0
                suffix: "m"
                value: (Config.ready && Config.options.appearance.background.autoCycleInterval !== undefined) ? Config.options.appearance.background.autoCycleInterval : 30
                onValueChanged: Wallpapers.setAutoCycleInterval(Math.round(value))
            }
        }
    }

    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: Math.max(64 * Appearance.effectiveScale, directoryRow.implicitHeight)
        orientation: Qt.Vertical
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: Config.ready && Config.options.appearance.background.autoCycleEnabled
        RowLayout {
            id: directoryRow
            anchors.fill: parent
            anchors {
                leftMargin: 16 * Appearance.effectiveScale
                rightMargin: 16 * Appearance.effectiveScale
            }
            spacing: 16 * Appearance.effectiveScale
            MaterialSymbol { text: "folder_open"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                StyledText { text: I18nService.tr("Source folder"); color: Appearance.colors.colOnLayer1 }
                StyledText {
                    text: {
                        const dir = Config.ready ? Config.options.appearance.background.autoCycleDirectory : "";
                        if (dir === "" || dir === undefined) return I18nService.tr("Not selected");
                        return Functions.FileUtils.shortenHomePath(dir);
                    }
                    font.pixelSize: (Appearance.font && Appearance.font.pixelSize) ? Appearance.font.pixelSize.smallest : 10 * Appearance.effectiveScale
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
            M3IconButton {
                iconName: "edit"
                iconSize: 20 * Appearance.effectiveScale
                implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale
                buttonRadius: 18 * Appearance.effectiveScale
                colBackground: Appearance.colors.colPrimary
                color: Appearance.colors.colOnPrimary
                onClicked: folderPickerProc.running = true
            }
        }
    }
}
