import QtQuick
import Quickshell
import Quickshell.Io
import "functions" as Functions
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property QtObject m3colors
    property QtObject colors
    property QtObject rounding
    property QtObject font
    property QtObject sizes
    property QtObject animation
    property QtObject animationCurves

    // --- Material 3 Color Tokens (populated by MaterialThemeLoader) ---
    m3colors: QtObject {
        property bool darkmode: true
        property color m3background: "#141313"
        property color m3onBackground: "#e6e1e1"
        property color m3surface: "#141313"
        property color m3surfaceDim: "#141313"
        property color m3surfaceBright: "#3a3939"
        property color m3surfaceContainerLowest: "#0f0e0e"
        property color m3surfaceContainerLow: "#1c1b1c"
        property color m3surfaceContainer: "#201f20"
        property color m3surfaceContainerHigh: "#2b2a2a"
        property color m3surfaceContainerHighest: "#363435"
        property color m3onSurface: "#e6e1e1"
        property color m3surfaceVariant: "#49464a"
        property color m3onSurfaceVariant: "#cbc5ca"
        property color m3inverseSurface: "#e6e1e1"
        property color m3inverseOnSurface: "#313030"
        property color m3outline: "#948f94"
        property color m3outlineVariant: "#49464a"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#cbc4cb"
        property color m3primary: "#cbc4cb"
        property color m3onPrimary: "#322f34"
        property color m3primaryContainer: "#2d2a2f"
        property color m3onPrimaryContainer: "#bcb6bc"
        property color m3inversePrimary: "#615d63"
        property color m3secondary: "#cac5c8"
        property color m3onSecondary: "#323032"
        property color m3secondaryContainer: "#4d4b4d"
        property color m3onSecondaryContainer: "#ece6e9"
        property color m3tertiary: "#d1c3c6"
        property color m3onTertiary: "#372e30"
        property color m3tertiaryContainer: "#31292b"
        property color m3onTertiaryContainer: "#c1b4b7"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3primaryFixed: "#e7e0e7"
        property color m3primaryFixedDim: "#cbc4cb"
        property color m3onPrimaryFixed: "#1d1b1f"
        property color m3onPrimaryFixedVariant: "#49454b"
        property color m3secondaryFixed: "#e6e1e4"
        property color m3secondaryFixedDim: "#cac5c8"
        property color m3onSecondaryFixed: "#1d1b1d"
        property color m3onSecondaryFixedVariant: "#484648"
        property color m3tertiaryFixed: "#eddfe1"
        property color m3tertiaryFixedDim: "#d1c3c6"
        property color m3onTertiaryFixed: "#211a1c"
        property color m3onTertiaryFixedVariant: "#4e4447"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"

        // Base16
        property color m3base00: "#141313"
        property color m3base01: "#1c1b1c"
        property color m3base02: "#201f20"
        property color m3base03: "#2b2a2a"
        property color m3base04: "#363435"
        property color m3base05: "#e6e1e1"
        property color m3base06: "#49464a"
        property color m3base07: "#948f94"
        property color m3base08: "#cbc4cb"
        property color m3base09: "#e7e0e7"
        property color m3base0a: "#cac5c8"
        property color m3base0b: "#d1c3c6"
        property color m3base0c: "#ffb4ab"
        property color m3base0d: "#cbc4cb"
        property color m3base0e: "#e6e1e4"
        property color m3base0f: "#eddfe1"
    }

    // --- Derived Layer Colors ---
    colors: QtObject {
        property color colSubtext: m3colors.m3outline
        // Layer 0 (background)
        property color colLayer0: m3colors.m3background
        property color colOnLayer0: m3colors.m3onBackground
        property color colLayer0Hover: Functions.ColorUtils.mix(colLayer0, colOnLayer0, 0.92)
        property color colLayer0Active: Functions.ColorUtils.mix(colLayer0, colOnLayer0, 0.85)
        // Layer 1
        property color colLayer1: m3colors.m3surfaceContainerLow
        property color colOnLayer1: m3colors.m3onSurfaceVariant
        property color colLayer1Hover: Functions.ColorUtils.mix(colLayer1, colOnLayer1, 0.92)
        property color colLayer1Active: Functions.ColorUtils.mix(colLayer1, colOnLayer1, 0.85)
        // Layer 2
        property color colLayer2: m3colors.m3surfaceContainer
        property color colOnLayer2: m3colors.m3onSurface
        property color colLayer2Hover: Functions.ColorUtils.mix(colLayer2, colOnLayer2, 0.90)
        property color colLayer2Active: Functions.ColorUtils.mix(colLayer2, colOnLayer2, 0.80)
        // Layer 3
        property color colLayer3: m3colors.m3surfaceContainerHigh
        property color colOnLayer3: m3colors.m3onSurface
        property color colLayer3Hover: Functions.ColorUtils.mix(colLayer3, colOnLayer3, 0.90)
        property color colLayer3Active: Functions.ColorUtils.mix(colLayer3, colOnLayer3, 0.80)
        // Primary
        property color colPrimary: m3colors.m3primary
        property color colOnPrimary: m3colors.m3onPrimary
        property color colPrimaryHover: Functions.ColorUtils.mix(colPrimary, colOnPrimary, 0.92)
        property color colPrimaryActive: Functions.ColorUtils.mix(colPrimary, colOnPrimary, 0.85)
        property color colPrimaryContainer: m3colors.m3primaryContainer
        property color colOnPrimaryContainer: m3colors.m3onPrimaryContainer
        // Secondary
        property color colSecondary: m3colors.m3secondary
        property color colOnSecondary: m3colors.m3onSecondary
        property color colSecondaryContainer: m3colors.m3secondaryContainer
        property color colOnSecondaryContainer: m3colors.m3onSecondaryContainer
        property color colSecondaryHover: Functions.ColorUtils.mix(colSecondary, colOnSecondary, 0.92)
        property color colSecondaryContainerHover: Functions.ColorUtils.mix(colSecondaryContainer, colOnSecondaryContainer, 0.90)
        // Tertiary
        property color colTertiary: m3colors.m3tertiary
        property color colOnTertiary: m3colors.m3onTertiary
        property color colTertiaryContainer: m3colors.m3tertiaryContainer
        property color colOnTertiaryContainer: m3colors.m3onTertiaryContainer
        property color colTertiaryContainerHover: Functions.ColorUtils.mix(colTertiaryContainer, colOnTertiaryContainer, 0.90)
        // Error
        property color colError: m3colors.m3error
        property color colOnError: m3colors.m3onError
        property color colErrorContainer: m3colors.m3errorContainer
        property color colOnErrorContainer: m3colors.m3onErrorContainer
        // Misc
        property color colOutline: m3colors.m3outline
        property color colOutlineVariant: m3colors.m3outlineVariant
        property color colScrim: Functions.ColorUtils.applyAlpha(m3colors.m3scrim, 0.5)
        property color colShadow: m3colors.m3shadow
        // Smart Status Bar (adaptive text color based on wallpaper lightness)
        property bool statusBarDarkText: false

        // When background is shown, gradient + adaptive text mode are ignored
        readonly property bool statusBarBgActive: Config.ready && Config.options.statusBar
            ? (Config.options.statusBar.backgroundStyle ?? 0) > 0
            : false

        // Gradient is only active when backgroundStyle = 0 AND useGradient = true
        readonly property bool statusBarGradientActive: !statusBarBgActive
            && (Config.ready && Config.options.statusBar ? (Config.options.statusBar.useGradient ?? true) : true)

        // Resolved dark text: locked to wallpaper-based detection if bg is active (theme decides),
        // otherwise respects user setting
        readonly property bool resolvedStatusBarDarkText: {
            if (statusBarBgActive) return false; // background mode: use theme text (always on surface)
            if (!Config.ready || !Config.options.statusBar) return statusBarDarkText;
            const mode = Config.options.statusBar.textColorMode ?? "adaptive";
            if (mode === "dark") return true;
            if (mode === "light") return false;
            return statusBarDarkText; // adaptive
        }

        property color colStatusBarText: statusBarBgActive
            ? m3colors.m3onSurface
            : (resolvedStatusBarDarkText ? "#1E1E1E" : "#F5F5F5")
        property color colStatusBarSubtext: Functions.ColorUtils.applyAlpha(colStatusBarText, 0.7)
        property color colStatusBarGradientStart: {
            if (!statusBarGradientActive) return "transparent";
            let baseColor = resolvedStatusBarDarkText ? "#FFFFFF" : "#000000";
            return Functions.ColorUtils.applyAlpha(baseColor, resolvedStatusBarDarkText ? 0.35 : 0.45);
        }
        property color colStatusBarGradientEnd: "transparent"
        // Solid bar color (used when backgroundStyle > 0)
        property color colStatusBarSolid: m3colors.m3surfaceContainerLow

        // Smart Lockscreen Text
        property bool lockscreenDarkText: false
        property color colLockscreenClock: lockscreenDarkText ? "#1E1E1E" : "#F5F5F5"
        property color colLockscreenDate: Functions.ColorUtils.applyAlpha(colLockscreenClock, 0.8)

        // Notch specific (always dark context)
        property color colNotchText: "#E2E2E2" // Modern M3 off-white
        property color colNotchSubtext: Functions.ColorUtils.applyAlpha("#E2E2E2", 0.7)
        property color colNotchPrimary: m3colors.m3primary // Use dynamic primary from matugen
    }

    // Process to determine the top color of the wallpaper
    Process {
        id: wpLightnessProc
        property string wpPath: {
            if (!Config.ready || !Config.options.appearance || !Config.options.appearance.background) return "";
            return Config.options.appearance.background.wallpaperPath.toString().replace("file://", "");
        }
        
        command: wpPath ? [
            "magick", wpPath, 
            "-gravity", "North", 
            "-crop", "100%x40+0+0",
            "-colorspace", "Gray",
            "-scale", "1x1!", 
            "-format", "%[fx:mean]", 
            "info:"
        ] : []
        
        Component.onCompleted: {
            if (wpPath !== "") running = true;
        }
        
        onWpPathChanged: {
            if (wpPath !== "") {
                if (running) {
                    running = false;
                    Qt.callLater(() => { running = true; });
                } else {
                    running = true;
                }
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                let meanStr = this.text.trim();
                let mean = parseFloat(meanStr);
                if (!isNaN(mean)) {
                    // if mean lightness > 0.6, consider the wallpaper light and use dark text
                    root.colors.statusBarDarkText = mean > 0.6;
                }
            }
        }
    }

    // Process to determine the overall lightness of the lockscreen wallpaper
    Process {
        id: lockLightnessProc
        property string wpPath: {
            if (!Config.ready) return "";
            if (Config.options.lock && Config.options.lock.useSeparateWallpaper && Config.options.lock.wallpaperPath !== "") {
                return Config.options.lock.wallpaperPath.toString().replace("file://", "");
            }
            if (!Config.options.appearance || !Config.options.appearance.background) return "";
            return Config.options.appearance.background.wallpaperPath.toString().replace("file://", "");
        }
        
        command: wpPath ? ["magick", wpPath, "-gravity", "North", "-crop", "50%x30%+0+30%", "-scale", "1x1!", "-format", "%[fx:mean]", "info:"] : []
        
        Component.onCompleted: {
            if (wpPath !== "") running = true;
        }
                
        onWpPathChanged: {
            if (wpPath !== "") {
                if (running) {
                    running = false;
                    Qt.callLater(() => { running = true; });
                } else {
                    running = true;
                }
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                let meanStr = this.text.trim();
                let mean = parseFloat(meanStr);
                if (!isNaN(mean)) {
                    // if mean lightness > 0.55 (slightly adjusted to account for scrim), use dark text
                    root.colors.lockscreenDarkText = mean > 0.55;
                }
            }
        }
    }

    rounding: QtObject {
        property int unsharpen: 2
        property int unsharpenmore: 6
        property int verysmall: 8
        property int small: 12
        property int normal: 18
        property int large: 24
        property int extraLarge: 32
        property int full: 9999
        property int statusBar: 0      // Status bar has no rounding (full-width)
        property int panel: 28         // Quick Settings / Notification panels
        property int card: 24          // Individual cards within panels
        property int button: 20        // Buttons and toggles
    }

    // --- Typography ---
    font: QtObject {
        property QtObject family: QtObject {
            id: typoFamily
            property string main: Config.ready ? Config.options.appearance.fonts.main : "Google Sans Flex"
            property string numbers: Config.ready ? Config.options.appearance.fonts.numbers : "Google Sans Flex"
            property string title: Config.ready ? Config.options.appearance.fonts.title : "Google Sans Flex"
            property string iconMaterial: "Material Symbols Rounded"
            property string expressive: typoFamily.title
            property string monospace: Config.ready ? Config.options.appearance.fonts.monospace : "JetBrains Mono NF"
        }
        property QtObject variableAxes: QtObject {
            id: typoAxes
            property var expressive: typoAxes.title
            property var main: ({
                "wght": 450,
                "wdth": 100,
            })
            property var numbers: ({
                "wght": 450,
            })
            property var title: ({
                "wght": 550,
            })
        }
        property QtObject pixelSize: QtObject {
            property int smallest: 10
            property int smaller: 12
            property int small: 14
            property int normal: 16
            property int large: 18
            property int larger: 20
            property int huge: 24
            property int title: 22
        }
    }

    // --- Sizes ---
    sizes: QtObject {
        readonly property var screen: Quickshell.screens[0]
        property real statusBarHeight: 40
        property real touchTarget: 48
        
        // Dynamic Sidebar Panel sizing
        property real quickSettingsWidth: Math.min(420, screen.width * 0.35)
        property real quickSettingsMaxHeight: Math.min(800, screen.height * 0.85)
        
        property real notificationCenterWidth: Math.min(420, screen.width * 0.35)
        property real notificationCenterMaxHeight: Math.min(800, screen.height * 0.85)

        // New scaling tokens for internal components
        property real notificationIslandMaxHeight: Math.min(450, screen.height * 0.5)
        property real lockClockSize: Math.min(120, screen.width * 0.1)
        property real lockInputWidth: Math.min(300, screen.width * 0.25)
        
        property real toggleTileSize: 72
        property real sliderHeight: 48
        property real iconSize: 20

        // Calendar
        property real calendarWidth: Math.min(360, screen.width * 0.3)
        property real calendarSpacing: 4
        property real calendarCellSize: Math.floor((calendarWidth - 48 - (calendarSpacing * 6)) / 7)

        // Dashboard (Calendar panel redesign)
        property real dashboardWidth: Math.min(860, screen.width * 0.68)
        property real dashboardHeight: Math.min(450, screen.height * 0.75)
    }

    // --- Animation Curves (M3 Expressive) ---
    animationCurves: QtObject {
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.80, 0.34, 1.00, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
    }

    animation: QtObject {
        property QtObject elementMove: QtObject {
            property int duration: 500
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveDefaultSpatial
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    duration: root.animation.elementMove.duration
                    easing.type: root.animation.elementMove.type
                    easing.bezierCurve: root.animation.elementMove.bezierCurve
                }
            }
        }
        property QtObject elementMoveEnter: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveEnter.duration
                    easing.type: root.animation.elementMoveEnter.type
                    easing.bezierCurve: root.animation.elementMoveEnter.bezierCurve
                }
            }
        }
        property QtObject elementMoveExit: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedAccel
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveExit.duration
                    easing.type: root.animation.elementMoveExit.type
                    easing.bezierCurve: root.animation.elementMoveExit.bezierCurve
                }
            }
        }
        property QtObject elementMoveFast: QtObject {
            property int duration: 200
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.expressiveEffects
            property int velocity: 850
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
            property Component colorAnimation: Component {
                ColorAnimation {
                    duration: root.animation.elementMoveFast.duration
                    easing.type: root.animation.elementMoveFast.type
                    easing.bezierCurve: root.animation.elementMoveFast.bezierCurve
                }
            }
        }
        property QtObject elementResize: QtObject {
            property int duration: 300
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasized
            property int velocity: 650
            property Component numberAnimation: Component {
                NumberAnimation {
                    alwaysRunToEnd: true
                    duration: root.animation.elementResize.duration
                    easing.type: root.animation.elementResize.type
                    easing.bezierCurve: root.animation.elementResize.bezierCurve
                }
            }
        }
        property QtObject scroll: QtObject {
            property int duration: 400
            property int type: Easing.BezierSpline
            property list<real> bezierCurve: animationCurves.emphasizedDecel
        }
    }
}
