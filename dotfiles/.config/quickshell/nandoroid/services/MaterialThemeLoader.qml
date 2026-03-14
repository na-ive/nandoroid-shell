pragma Singleton
pragma ComponentBehavior: Bound

import "../core"
import "../core/functions" as Functions
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Watches Matugen-generated colors.json and applies M3 color tokens to Appearance.m3colors.
 * Call reapplyTheme() on startup since Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                // Convert snake_case to camelCase, then prefix with m3
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                Appearance.m3colors[m3Key] = json[key]
            }
        }
        Appearance.m3colors.darkmode = Functions.ColorUtils.isDark(Appearance.m3colors.m3background)

    }

    Timer {
        id: delayedFileRead
        interval: 100
        repeat: false
        running: false
        onTriggered: {
            // Only auto-apply from generated file if matugen (wallpaper mode) is active
            if (Config.ready && Config.options.appearance.background.matugen) {
                root.applyColors(themeFileView.text())
            } else {

            }
        }
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            if (fileContent.trim() !== "") {
                // Only auto-apply from generated file if matugen (wallpaper mode) is active
                if (Config.ready && Config.options.appearance.background.matugen) {
                    root.applyColors(fileContent)
                }
            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {

                Wallpapers.initializeMatugen()
            }
        }
    }
}
