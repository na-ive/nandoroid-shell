import "../../../../core"
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
        searchString: "Wallpaper Auto-Cycle"
        aliases: ["Auto Cycle", "Slideshow", "Wallpaper Timer"]
    }

    // ── Helper for Folder Selection ──

    Process {
        id: folderPickerProc
        command: ["zenity", "--file-selection", "--directory", "--title=Select Wallpapers Directory"]
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
        Layout.fillWidth: true
        implicitHeight: cycleMainRow.implicitHeight + (36 * Appearance.effectiveScale)
        orientation: Qt.Vertical
        maxRadius: 20 * Appearance.effectiveScale
        pillOnActive: false
        color: Appearance.m3colors.m3surfaceContainerHigh
        active: Config.ready && Config.options.appearance.background.autoCycleEnabled
        
        RowLayout {
            id: cycleMainRow
            anchors.fill: parent
            anchors.margins: 16 * Appearance.effectiveScale
            spacing: 20 * Appearance.effectiveScale
            MaterialSymbol { text: "auto_mode"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            StyledText { text: "Wallpaper Auto-Cycle"; Layout.fillWidth: true; color: Appearance.colors.colOnLayer1 }
            AndroidToggle {
                checked: Config.ready && Config.options.appearance.background.autoCycleEnabled
                onToggled: Wallpapers.setAutoCycle(!checked)
            }
        }
    }

    // ── Expanded Cycle Settings ────
    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: intervalRow.implicitHeight + (36 * Appearance.effectiveScale)
        orientation: Qt.Vertical
        maxRadius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: Config.ready && Config.options.appearance.background.autoCycleEnabled
        RowLayout {
            id: intervalRow
            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
            spacing: 20 * Appearance.effectiveScale

            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                Layout.preferredWidth: 70 * Appearance.effectiveScale
                MaterialSymbol { text: "schedule"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                StyledText { 
                    text: "Cycle Interval"
                    Layout.fillWidth: true
                    color: Appearance.colors.colOnLayer1 
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                from: 1; to: 120; stepSize: 1
                value: (Config.ready && Config.options.appearance.background.autoCycleInterval !== undefined) ? Config.options.appearance.background.autoCycleInterval : 30
                onMoved: Wallpapers.setAutoCycleInterval(Math.round(value))
            }
            StyledText {
                text: `${(Config.ready && Config.options.appearance.background.autoCycleInterval !== undefined) ? Config.options.appearance.background.autoCycleInterval : 30}m`
                color: Appearance.colors.colOnLayer1
                Layout.preferredWidth: 40 * Appearance.effectiveScale
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    SegmentedWrapper {
        Layout.fillWidth: true
        implicitHeight: directoryRow.implicitHeight + (36 * Appearance.effectiveScale)
        orientation: Qt.Vertical
        maxRadius: 20 * Appearance.effectiveScale
        color: Appearance.m3colors.m3surfaceContainerHigh
        visible: Config.ready && Config.options.appearance.background.autoCycleEnabled
        RowLayout {
            id: directoryRow
            anchors.fill: parent; anchors.margins: 16 * Appearance.effectiveScale
            spacing: 20 * Appearance.effectiveScale
            MaterialSymbol { text: "folder_open"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                StyledText { text: "Source folder"; color: Appearance.colors.colOnLayer1 }
                StyledText {
                    text: {
                        const dir = Config.ready ? Config.options.appearance.background.autoCycleDirectory : "";
                        return dir === "" || dir === undefined ? "Not selected" : dir;
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
                colBackground: Appearance.m3colors.m3surfaceContainerLow
                color: Appearance.m3colors.m3primary
                onClicked: folderPickerProc.running = true
            }
        }
    }
}
