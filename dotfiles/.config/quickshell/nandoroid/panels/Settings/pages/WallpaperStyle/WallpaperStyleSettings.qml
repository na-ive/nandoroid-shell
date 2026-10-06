import "../../../../core"
import "../../../../services"
import "../../../../widgets"
import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

/**
 * Wallpaper & Style settings page.
 * Phase 1: Wallpaper Management (Refactored)
 */
Flickable {
    id: root
    anchors.fill: parent
    contentHeight: mainCol.implicitHeight + (48 * Appearance.effectiveScale)
    clip: true
    
    property bool isOnboarding: false
    
    ScrollBar.vertical: StyledScrollBar {}

    SequentialAnimation {
        id: highlightAnim
        property var target: null
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 1; to: 0.3; duration: 200 }
        NumberAnimation { target: highlightAnim.target; property: "opacity"; from: 0.3; to: 1; duration: 400 }
    }

    // Delegated to shared service (single cache for Settings + Launcher)
    readonly property var matugenSchemes: MatugenPreviewService.matugenSchemes
    readonly property var basicColors: MatugenPreviewService.basicColors

    // ── Shared preview service (single cache for Settings + Launcher) ──
    readonly property var matugenPreviews: MatugenPreviewService.previews
    readonly property bool isPreviewLoading: MatugenPreviewService.loading
    function refreshPreviews() { MatugenPreviewService.refreshPreviews() }
    Connections {
        target: Config.ready ? Config.options.appearance.background : null
        function onWallpaperPathChanged() { MatugenPreviewService.refreshPreviews() }
    }
    Connections {
        target: WallpaperEngineService
        function onScreenshotVersionChanged() { MatugenPreviewService.refreshPreviews() }
    }


    IpcHandler {
        target: "settings_wallpaper"
        function test() {
        }
    }

    ColumnLayout {
        id: mainCol
        width: parent.width - (24 * Appearance.effectiveScale)
        spacing: 24 * Appearance.effectiveScale
        anchors.margins: 4 * Appearance.effectiveScale
        visible: Config.ready
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // RESET LOGS ON LOAD

        // ── Header ──
        ColumnLayout {
            spacing: 4 * Appearance.effectiveScale
            visible: !root.isOnboarding
            StyledText {
                text: I18nService.tr("Customize")
                font.pixelSize: Appearance.font.pixelSize.huge
                font.family: Appearance.font.family.title
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: I18nService.tr("Personalize your desktop and lock screen.")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colSubtext
            }
        }

        // ── Wallpaper Style Options Group ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale // Loose between separate features (like About nav); tight 4 stays inside each unit

            // ── Wallpaper Auto-Cycle ──
            WsWallpaperCycle {
                Layout.fillWidth: true
                visible: !root.isOnboarding
            }

            // ── Wallpaper Transition ──
            WsWallpaperTransition {
                Layout.fillWidth: true
                visible: !root.isOnboarding
            }

            // ── Use Same Wallpaper for Lock Screen ──
            SegmentedWrapper {
                id: syncCard
                Layout.fillWidth: true
                implicitHeight: Math.max(64 * Appearance.effectiveScale, syncToggleRow.implicitHeight)
                orientation: Qt.Vertical
                color: Appearance.m3colors.m3surfaceContainerHigh

                RippleButton {
                    anchors.fill: parent
                    colBackground: Appearance.m3colors.m3surfaceContainerHigh
                    colBackgroundHover: Appearance.m3colors.m3surfaceContainerHigh
                    buttonRadius: 0
                    topLeftRadius: syncCard.rTopLeft
                    topRightRadius: syncCard.rTopRight
                    bottomLeftRadius: syncCard.rBottomLeft
                    bottomRightRadius: syncCard.rBottomRight
                    onClicked: {
                        if (Config.ready && Config.options.lock) {
                            const current = Config.options.lock.useSeparateWallpaper
                            Config.options.lock.useSeparateWallpaper = !current
                            if (current) {
                                let targetPath = Config.options.appearance.background.wallpaperPath;
                                if (WallpaperEngineService.active) {
                                    targetPath = "file://" + WallpaperEngineService.screenshotPath;
                                } else if (MpvpaperService.active) {
                                    targetPath = "file://" + MpvpaperService.framePath;
                                }
                                Wallpapers.selectForLockscreen(targetPath, false)
                            }
                        }
                    }
                }

                RowLayout {
                    id: syncToggleRow
                    anchors.fill: parent
                    anchors {
                        leftMargin: 16 * Appearance.effectiveScale
                        rightMargin: 16 * Appearance.effectiveScale
                    }
                    spacing: 16 * Appearance.effectiveScale

                    RowLayout {
                        spacing: 16 * Appearance.effectiveScale
                        MaterialSymbol {
                            text: "sync"
                            iconSize: 24 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                        }
                        StyledText {
                            text: I18nService.tr("Use same wallpaper for lock screen")
                            color: Appearance.colors.colOnLayer1
                            Layout.fillWidth: true
                        }
                    }

                    AndroidToggle {
                        id: syncToggle
                        checked: Config.ready && (Config.options.lock ? !Config.options.lock.useSeparateWallpaper : false)
                        onToggled: {
                            if (Config.ready && Config.options.lock) {
                                const current = Config.options.lock.useSeparateWallpaper
                                Config.options.lock.useSeparateWallpaper = !current
                                if (current) { // Was true (separate), now false (synced)
                                    // If Live Wallpaper is active, sync with the sharp screenshot instead of thumbnail
                                    let targetPath = Config.options.appearance.background.wallpaperPath;
                                    if (WallpaperEngineService.active) {
                                        targetPath = "file://" + WallpaperEngineService.screenshotPath;
                                    } else if (MpvpaperService.active) {
                                        targetPath = "file://" + MpvpaperService.framePath;
                                    }
                                    Wallpapers.selectForLockscreen(targetPath, false)
                                }
                            }
                        }
                    }
                }
            }
        }

        SearchHandler {
            searchString: "Wallpaper"
            aliases: ["Background"]
        }

        // ── Wallpaper Previews ──
        RowLayout {
            id: previewRow
            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            property string selection: "desktop"

                WallpaperPreview {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: I18nService.tr("Desktop wallpaper")
                    source: {
                        if (WallpaperEngineService.active) return "file://" + WallpaperEngineService.screenshotPath + "?v=" + WallpaperEngineService.screenshotVersion;
                        if (MpvpaperService.active) return MpvpaperService.livePreviewSource();
                        return (Config.ready && Config.options.appearance && Config.options.appearance.background) ? Config.options.appearance.background.wallpaperPath : "";
                    }
                    showCheckmark: false
                    clickable: true
                    onClicked: {
                        GlobalStates.wallpaperSelectorTarget = "desktop";
                        GlobalStates.wallpaperSelectorOpen = true;
                    }
                }

                WallpaperPreview {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    title: I18nService.tr("Lock screen wallpaper")
                    source: {
                        if (!Config.ready || !Config.options.lock) return "";
                        if (!Config.options.lock.useSeparateWallpaper) {
                            if (WallpaperEngineService.active) return "file://" + WallpaperEngineService.screenshotPath + "?v=" + WallpaperEngineService.screenshotVersion;
                            if (MpvpaperService.active) return MpvpaperService.livePreviewSource();
                            return (Config.options.appearance && Config.options.appearance.background ? Config.options.appearance.background.wallpaperPath : "");
                        }
                        return Config.options.lock.wallpaperPath;
                    }
                     showCheckmark: Config.ready && (Config.options.lock ? !Config.options.lock.useSeparateWallpaper : false)
                     clickable: true
                     onClicked: {
                         GlobalStates.wallpaperSelectorTarget = "lock";
                         GlobalStates.wallpaperSelectorOpen = true;
                     }
                }
        }

        // Theme (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 500 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsThemeColor {}
            searchEntries: [["Theme Color", ["Colors", "Matugen", "Material You", "Accent Color"]]]
        }

        // Launcher (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 400 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsLauncher {}
            searchEntries: [["Launcher", ["App Launcher", "Search Bar", "Drawer"]], ["Icon Shapes", ["Icons", "Shapes", "App Icons"]]]
        }

        // Dock (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 600 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsDock {}
            searchEntries: [["Dock", ["Taskbar", "App Dock", "Pinned Apps"]]]
        }

        // Overview (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 400 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsOverview {}
            searchEntries: [["Overview", ["Workspaces", "Window Manager", "Expose"]]]
        }

        // Visualizer (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 800 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsCava {}
            searchEntries: [["Visualizer", ["Cava", "Audio", "Desktop Cava", "Lockscreen Cava"]]]
        }

        // Lockscreen (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 400 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsLockscreen {}
            searchEntries: [["Lockscreen", ["Lock", "Lock Screen"]], ["Lockscreen Clock", ["Clock", "Time", "Watch", "Clock Style"]]]
        }

        // Overlay (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 400 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsOverlay {}
            searchEntries: [["Overlays", ["Notification Center", "Quick Settings", "Media Card", "Weather Card", "Performance Stats", "System Monitor", "Banner Image"]]]
        }

        // Status bar (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 2200 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsStatusBar {}
            searchEntries: [["Status Bar", ["Bar", "Top Bar", "Panel", "Statusbar", "Distro Icon", "Notification Counter", "Notification Position"]]]
        }

        // Screen decor (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 350 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsScreenDecor {}
            searchEntries: [["Screen Decor", ["Corners", "Borders", "Rounding"]]]
        }

        // Typography (lazy)
        LazySection {
            Layout.fillWidth: true
            visible: !root.isOnboarding
            estimate: 500 * Appearance.effectiveScale
            viewportY: root.contentY
            viewportH: root.height
            content: WsTypography {}
            searchEntries: [["Typography", ["Font", "Fonts", "Typeface", "Font Family"]]]
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 32 * Appearance.effectiveScale }
    }
}
