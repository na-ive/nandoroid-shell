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
    
    readonly property string generatedPath: Directories.generatedMaterialThemePath
    readonly property string themesDir: "file://" + Directories.assetsPath + "/themes/"
    
    property string filePath: {
        if (!Config.ready) return generatedPath;
        const bg = Config.options.appearance.background;
        if (bg.matugen || bg.matugenThemeFile === "") return generatedPath;
        return themesDir + bg.matugenThemeFile;
    }

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                if (Appearance.m3colors.hasOwnProperty(m3Key)) {
                    Appearance.m3colors[m3Key] = json[key]
                }
            }
        }
        Appearance.m3colors.darkmode = Functions.ColorUtils.isDark(Appearance.m3colors.m3background)
    }

    function applyLockColors(fileContent) {
        const json = JSON.parse(fileContent)
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const m3Key = `m3${camelCaseKey}`
                if (Appearance.lockM3colors.hasOwnProperty(m3Key)) {
                    Appearance.lockM3colors[m3Key] = json[key]
                }
            }
        }
        Appearance.lockM3colors.darkmode = Functions.ColorUtils.isDark(Appearance.lockM3colors.m3background)
    }

    Timer {
        id: delayedFileRead
        interval: 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
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
                root.applyColors(fileContent)
            }
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {

                Wallpapers.initializeMatugen()
            }
        }
    }
}
