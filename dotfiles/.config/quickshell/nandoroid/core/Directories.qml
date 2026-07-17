pragma Singleton
pragma ComponentBehavior: Bound

import "functions" as Functions
import QtCore
import QtQuick
import Quickshell

Singleton {
    // XDG Dirs (with "file://")
    readonly property string home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property string documents: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
    readonly property string downloads: StandardPaths.standardLocations(StandardPaths.DownloadLocation)[0]
    readonly property string music: StandardPaths.standardLocations(StandardPaths.MusicLocation)[0]
    readonly property string pictures: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
    readonly property string videos: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string state: StandardPaths.standardLocations(StandardPaths.StateLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]
    readonly property string genericCache: Functions.FileUtils.trimFileProtocol(`${home}/.cache`)

    // NAnDoroid paths (without "file://")
    property string assetsPath: Quickshell.shellPath("assets")
    property string shellConfig: Functions.FileUtils.trimFileProtocol(`${home}/.config/nandoroid`)
    property string shellConfigName: "config.json"
    property string shellConfigPath: `${shellConfig}/${shellConfigName}`

    // Matugen colors path
    property string generatedMaterialThemePath: Functions.FileUtils.trimFileProtocol(`${state}/user/generated/colors.json`)

    // Notifications cache
    property string notificationsPath: Functions.FileUtils.trimFileProtocol(`${cache}/notifications/notifications.json`)

    // Favorites cache
    property string favoritesPathRaw: genericCache + "/nandoroid/favorites.json"
    property string favoritesPath: "file://" + favoritesPathRaw

    // Screenshots
    property string screenshotTemp: "/tmp/nandoroid/screenshots"
    property string screenshotDir: Functions.FileUtils.trimFileProtocol(`${pictures}/Screenshots`)

    // Ensure dirs and temp files exist (silences FileView warnings)
    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", `${shellConfig}`])
        Quickshell.execDetached(["mkdir", "-p", `${screenshotTemp}`])
        Quickshell.execDetached(["mkdir", "-p", `${cache.toString().substring(7)}/nandoroid`])
        
        // Ensure matugen output dir exists
        const matugenFile = generatedMaterialThemePath;
        const matugenDir = matugenFile.substring(0, matugenFile.lastIndexOf('/'));
        Quickshell.execDetached(["mkdir", "-p", matugenDir])

        // Pre-create temp files for FileView watchers
        Quickshell.execDetached(["touch", "/tmp/nandoroid_states.json"])
        Quickshell.execDetached(["touch", "/tmp/nandoroid_cava.conf"])
    }
}
