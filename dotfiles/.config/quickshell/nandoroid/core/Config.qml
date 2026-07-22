pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/* 
 * WIDGET CONFIGURATION GUIDE
 * ---------------------------------------------------------
 * To add a new widget in the future, follow these steps:
 * 1. In Config.qml, add 'locked', 'desktopX', and 'desktopY' properties
 *    into your widget's JsonObject.
 * 2. In DesktopWidgets.qml, when calling AbstractWidget, provide the config reference:
 *    `configObject: Config.ready ? Config.options.appearance.WIDGET_NAME : null`
 * 3. Inside your widget, call onRequestContextMenu like this:
 *    `desktopContextMenu.openAt(x, y, configObject, "Widget Display Name", "Settings Keyword")`
 * With these 3 steps, Drag & Drop and Context Menu (Lock/Settings) will work automatically!
 */

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false

    // Centralized Format Logic
    readonly property string timeFormat: {
        if (!ready) return "HH:mm"
        switch (options.time.timeStyle) {
            case "12H_pm": return "hh:mm ap"
            case "12H_PM": return "hh:mm AP"
            case "24H":    return "HH:mm"
            default:       return "HH:mm"
        }
    }

    readonly property string dateFormat: {
        if (!ready) return "ddd, dd/MM"
        switch (options.time.dateStyle) {
            case "DMY": return "ddd, dd/MM"
            case "MDY": return "ddd, MM/dd"
            case "YMD": return "yyyy/MM/dd" 
            default:    return "ddd, dd/MM"
        }
    }

    readonly property string longDateFormat: {
        if (!ready) return "ddd, d MMMM yyyy"
        switch (options.time.dateStyle) {
            case "DMY": return "ddd, d MMMM yyyy"
            case "MDY": return "ddd, MMMM d, yyyy"
            case "YMD": return "yyyy, MMMM d (ddd)"
            default:    return "ddd, d MMMM yyyy"
        }
    }

    Timer {
        id: fileReloadTimer
        interval: 50
        repeat: false
        onTriggered: configFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: 50
        repeat: false
        onTriggered: configFileView.writeAdapter()
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            root.ready = true;
        }
        onLoadFailed: error => {
            console.error("[Config] FileView load failed:", error);
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            // --- Time & Clock ---
            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property string dateFormat: "ddd, dd/MM"
                property string longDateFormat: "dd/MM/yyyy"
                property string timeStyle: "24H" 
                property string dateStyle: "DMY" 
            }

            // --- Appearance ---
            property JsonObject appearance: JsonObject {
                property real globalScale: 1.0
                property bool autoScale: true
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string monospace: "JetBrains Mono NF"
                }
                property JsonObject clockFonts: JsonObject {
                    property string desktopTimeFont: ""
                    property string desktopDateFont: ""
                    property string lockscreenTimeFont: ""
                    property string lockscreenDateFont: ""
                }
                property JsonObject atAGlance: JsonObject {
                    property bool show: false
                    property bool showGreeting: true
                    property bool showDate: true
                    property bool showQuote: true
                    property real desktopX: 64
                    property real desktopY: 64
                    property real customWidth: 0
                    property string alignment: "left"
                    property string fontFamily: ""
                    property int fontSize: 24
                    property string greetingColorStyle: "primary"
                    property string dateColorStyle: "onLayer1"
                    property string quoteColorStyle: "onLayer1"
                    property bool locked: false
                }
property JsonObject background: JsonObject {
                property string wallpaperPath: "file://" + Directories.assetsPath + "/wallpapers/default_wallpaper.png"
                property bool darkmode: true
                property bool matugen: true
                property string matugenScheme: "scheme-content"
                property string matugenCustomColor: "#3F51B5"
                property string matugenThemeFile: ""
                property string matugenSource: "desktop"
                property string liveWallpaperPath: ""
                property bool autoCycleEnabled: false
                property string autoCycleDirectory: Directories.home + "/Pictures/Wallpapers"
                property int autoCycleInterval: 30 
                property list<string> customFolders: []
                property bool showCava: false
                property real cavaOpacity: 0.15
                property int cavaBars: 128
                property bool showGrid: false
                property int gridSpacing: 12
                property bool showSnapLines: true
            }
                property JsonObject screenCorners: JsonObject {
                    property int mode: 1
                    property int radius: 20
                }
                property JsonObject clock: JsonObject {
                    property string style: "digital"
                    property string styleLocked: "digital"
                    property bool showOnDesktop: true
                    property bool showDesktopDate: true
                    property bool showLockscreenDate: true
                    property bool useSameStyle: true
                    property int offsetX: 0
                    property int offsetY: -50
                    property real desktopX: -1
                    property real desktopY: -1
                    property real desktopCenterX: -1
                    property real desktopCenterY: -1
                    property real desktopRightX: -1
                    property bool locked: false

                    property JsonObject digital: JsonObject {
                        property bool isVertical: false
                        property string colorStyle: "primary"
                        property int fontSize: 84
                        property int dateFontSize: 24
                        property int dateGap: 4
                        property bool hideAmPm: false
                        property string alignment: "center"
                    }
                    property JsonObject digitalLocked: JsonObject {
                        property bool isVertical: false
                        property string colorStyle: "primary"
                        property int fontSize: 84
                        property int dateFontSize: 24
                        property int dateGap: 4
                        property bool hideAmPm: false
                        property string alignment: "center"
                    }
                    property JsonObject analog: JsonObject {
                        property bool constantlyRotate: false
                        property string backgroundStyle: "shape" 
                        property int sides: 12
                        property string backgroundShape: "Circle" 
                        property string shape: "Circle" 
                        property bool showMarks: true
                        property bool hourMarks: false
                        property bool timeIndicators: false
                        property string dateStyle: "bubble" 
                        property string handStyle: "modern" 
                        property string hourHandStyle: "fill" 
                        property string minuteHandStyle: "bold" 
                        property string secondHandStyle: "dot" 
                        property string dialStyle: "dots" 
                        property int size: 240
                    }
                    property JsonObject analogLocked: JsonObject {
                        property bool constantlyRotate: false
                        property string backgroundStyle: "shape"
                        property int sides: 12
                        property string backgroundShape: "Circle"
                        property string shape: "Circle"
                        property bool showMarks: true
                        property bool hourMarks: false
                        property bool timeIndicators: false
                        property string dateStyle: "bubble"
                        property string handStyle: "modern"
                        property string hourHandStyle: "fill"
                        property string minuteHandStyle: "bold"
                        property string secondHandStyle: "dot"
                        property string dialStyle: "dots"
                        property int size: 240
                    }
                    property JsonObject code: JsonObject {
                        property string valueColorStyle: "primary"
                        property string keywordColorStyle: "tertiary"
                        property string blockColorStyle: "primary"
                        property int fontSize: 18
                        property string blockType: "js"
                        property string fontFamily: "JetBrainsMono Nerd Font"
                    }
                    property JsonObject codeLocked: JsonObject {
                        property string valueColorStyle: "primary"
                        property string keywordColorStyle: "tertiary"
                        property string blockColorStyle: "primary"
                        property int fontSize: 18
                        property string blockType: "js"
                        property string fontFamily: "JetBrainsMono Nerd Font"
                    }
                    property JsonObject stacked: JsonObject {
                        property string colorStyle: "error"
                        property string textColorStyle: "onSurface"
                        property int fontSize: 84
                        property int labelFontSize: 42
                        property string fontFamily: "Google Sans Flex"
                        property string fontWeight: "Medium"
                        property string labelFontWeight: "Light"
                        property string alignment: "left"
                    }
                    property JsonObject stackedLocked: JsonObject {
                        property string colorStyle: "error"
                        property string textColorStyle: "onSurface"
                        property int fontSize: 84
                        property int labelFontSize: 42
                        property string fontFamily: "Google Sans Flex"
                        property string fontWeight: "Medium"
                        property string labelFontWeight: "Light"
                        property string alignment: "left"
                    }
                    property JsonObject text: JsonObject {
                        property int fontSize: 42
                        property int dateFontSize: 18
                        property string alignment: "center"
                        property string timeColorStyle: "onSurface"
                        property string dateColorStyle: "primary"
                    }
                    property JsonObject textLocked: JsonObject {
                        property int fontSize: 42
                        property int dateFontSize: 18
                        property string alignment: "center"
                        property string timeColorStyle: "onSurface"
                        property string dateColorStyle: "primary"
                    }
                    property JsonObject pill: JsonObject {
                        property int size: 120
                        property bool isVertical: false
                        property bool showBackground: true
                        property string timeColorStyle: "onLayer0"
                        property string dateColorStyle: "primary"
                        property string pillColorStyle: "surfaceContainerHigh"
                    }
                    property JsonObject pillLocked: JsonObject {
                        property int size: 120
                        property bool isVertical: false
                        property bool showBackground: true
                        property string timeColorStyle: "onLayer0"
                        property string dateColorStyle: "primary"
                        property string pillColorStyle: "surfaceContainerHigh"
                    }
                }
                
                property JsonObject mediaWidget: JsonObject {
                    property bool showOnDesktop: false
                    property bool locked: false
                    property real desktopX: -1
                    property real desktopY: -1
                    property real desktopCenterX: -1
                    property real desktopCenterY: -1
                    property real desktopRightX: -1
                    property bool showLyrics: false
                }

                property JsonObject systemMonitor: JsonObject {
                    property bool showOnDesktop: false
                    property bool locked: false
                    property bool vertical: false
                    property int updateInterval: 3000
                    property real desktopX: -1
                    property real desktopY: -1
                }

                property JsonObject weatherWidget: JsonObject {
                    property bool showOnDesktop: false
                    property bool locked: false
                    property string sizeMode: "3x1" // Supports "1x1", "2x1", "3x1"
                    property real desktopX: -1
                    property real desktopY: -1
                }

                property JsonObject currencyWidget: JsonObject {
                    property bool showOnDesktop: false
                    property bool locked: false
                    property string sizeMode: "2x1" // Supports "1x1", "2x1"
                    property real desktopX: -1
                    property real desktopY: -1
                    property string baseCurrency: "IDR"
                    property string quote1: "USD"
                    property string quote2: "EUR"
                    property string quote3: "JPY"
                    property string quote4: "GBP"
                }
                
                property JsonObject lyrics: JsonObject {
                    property bool showFloatingLyrics: false
                    property bool lyricsPinned: false
                    property bool lyricsUseRomaji: false
                    property real desktopX: -1
                    property real desktopY: -1
                    property real desktopCenterX: -1
                    property real desktopCenterY: -1
                    property string fontFamily: ""
                    property int fontSize: 36
                    property int contextLines: 3
                    property real customWidth: -1
                }
            }

            // --- Language ---
            property JsonObject language: JsonObject {
                property string ui: "auto"
                property JsonObject translator: JsonObject {
                    property string sourceLanguage: "auto"
                    property string targetLanguage: "en"
                }
            }

            // --- Workspaces ---
            property JsonObject workspaces: JsonObject {
                property int max_shown: 5
                property string indicatorStyle: "pill" 
                property string indicatorLabel: "none" 
            }

            // --- Bar ---
            property JsonObject bar: JsonObject {
                property bool show_distro_icon: true
                property string distroIcon: "" 
                property string avatar_path: ""
                property bool show_network_speed: false
                property string network_speed_unit: "KB"
                property int networkSpeedInterval: 1000
            }

            // --- Status Bar ---
            property JsonObject statusBar: JsonObject {
                property string moduleStyle: "base"
                property real height: 40
                property string layoutStyle: "standard" 
                property int centeredWidth: 1200
                property string clockPosition: "center" 
                property string activeWindowPosition: "left"
                property string systemMonitorPosition: "hidden"
                property bool showSystemMonitorCpu: true
                property bool showSystemMonitorRam: true
                property bool showSystemMonitorSwap: false
                property bool showSystemMonitorTemp: true
                property bool showSystemMonitorText: false
                property string systemMonitorStyle: "outline"
                property string textColorMode: "adaptive" 
                property bool useGradient: true
                property int backgroundStyle: 0
                property int backgroundCornerRadius: 20
                property string islandStyle: "pill" 
                property bool autoHide: false
                property string trayStyle: "adaptive"
                property bool showVolumeIndicator: true
            }

            // --- Quick Settings ---
            property JsonObject quickSettings: JsonObject {
                property bool caffeineActive: false
                property bool showPerformanceStats: true
                property string quickActionsPosition: "top" 
                property list<var> toggles: [
                    { "type": "wifi", "size": 2 },
                    { "type": "bluetooth", "size": 2 },
                    { "type": "dnd", "size": 1 },
                    { "type": "darkMode", "size": 1 },
                    { "type": "caffeine", "size": 1 },
                    { "type": "nightLight", "size": 1 },
                    { "type": "colorPicker", "size": 1 },
                    { "type": "screenSnip", "size": 1 },
                    { "type": "gameMode", "size": 1 },
                    { "type": "screenRecord", "size": 1 },
                    { "type": "musicRecognition", "size": 1 },
                    { "type": "easyEffects", "size": 1 },
                    { "type": "conservationMode", "size": 1 },
                    { "type": "warp", "size": 2 },
                    { "type": "audioOutput", "size": 1 },
                    { "type": "audioInput", "size": 1 },
                    { "type": "powerProfile", "size": 2 }
                ]
            }

            // --- Dock ---
            property JsonObject dock: JsonObject {
                property bool enable: true
                property bool autoHide: false
                property int autoHideMode: 0 
                property bool showOnlyInDesktop: true
                property int backgroundStyle: 1 
                property int hoverRegionHeight: 5
                property bool pinnedOnStartup: false
                property bool monochromeIcons: true
                property list<string> pinnedApps: ["kitty", "org.kde.dolphin"]
                property list<string> ignoredAppRegexes: ["^xwaylandvideobridge$"]
                property real scale: 1.0
                property bool showLauncher: true
                property bool showOverview: true
            }

            // --- Power Profile ---
            property JsonObject powerProfile: JsonObject {
                property bool enabled: false
                property string customPath: "/tmp/ryzen_mode"
            }

            // --- Night Mode ---
            property JsonObject nightMode: JsonObject {
                property bool active: false
                property int colorTemperature: 4000
            }

            // --- Weather ---
            property JsonObject weather: JsonObject {
                property bool enable: true
                property bool showInNotificationCenter: true
                property bool autoLocation: true
                property string location: ""
                property string unit: "C" 
                property string provider: "open-meteo" 
                property bool showDailyForecast: true
                property int updateInterval: 30 
            }

            // --- Overview Panel ---
            property QtObject overview: QtObject {
                property int rows: 2
                property int columns: 5
                property real scale: 0.15
                property real workspaceSpacing: 10
            }

            // --- Notifications ---
            property JsonObject notifications: JsonObject {
                property int timeout_ms: 2000
                property string counterStyle: "counter" 
                property string position: "right" 
            }

            // --- Battery ---
            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
            }

            // --- Panels ---
            property JsonObject panels: JsonObject {
                property bool keep_left_sidebar_loaded: false
                property bool keep_right_sidebar_loaded: true
            }

            // --- Search & Launcher ---
            property JsonObject search: JsonObject {
                property string mathPrefix: "="
                property string webPrefix: "!"
                property string emojiPrefix: ":"
                property string clipboardPrefix: ";"
                property string filePrefix: "?"
                property string commandPrefix: ">"
                property string toolsPrefix: "."
                property string iconShape: "Square"
                property bool enableGrouping: false
                property bool enableUsageTracking: true
                property JsonObject imageSearch: JsonObject {
                    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
                }
            }

            // --- Lock ---
            property JsonObject lock: JsonObject {
                property bool launchOnStartup: false
                property bool useHyprlock: false
                property string wallpaperPath: ""
                property bool useSeparateWallpaper: false
                property bool showCava: true
                property real cavaOpacity: 0.15
                property bool showMediaCard: true
                property bool showWeather: true
                property JsonObject weather: JsonObject { property string textColorMode: "adaptive" }
                property JsonObject security: JsonObject { property bool requirePasswordToPower: true }
            }

            // --- System ---
            property JsonObject system: JsonObject {
                property string lastUpdateCheckDate: ""
                property bool easyeffectsEnabled: false
                property bool bluetoothEnabled: true
                property bool onboardingCompleted: false
                property bool dndActive: false
                property list<var> monitoredDisks: [ { "path": "/", "alias": "System" } ]
            }

            // --- Media ---
            property JsonObject media: JsonObject {
                property string priority: ""
                property bool showMediaCard: true
                property bool enableMediaHover: true
                property string notchMediaStyle: "mini" 
            }

            // --- Privacy ---
            property JsonObject privacy: JsonObject { property bool enable: true }

            // --- Screen Snip ---
            property JsonObject screenSnip: JsonObject { property string savePath: "" }

            // --- Region Selector ---
            property JsonObject regionSelector: JsonObject {
                property bool showOnlyOnFocusedMonitor: false
                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: true
                    property bool images: true
                    property int selectionPadding: 5
                }
                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                    property int strokeWidth: 1
                    property real opacity: 0.2
                }
                property JsonObject circle: JsonObject { property int strokeWidth: 6 }
                property JsonObject annotationSymbol: JsonObject { property bool showIcons: true }
                property JsonObject annotation: JsonObject { property bool useSatty: false }
            }

            // --- GitHub ---
            property JsonObject github: JsonObject { property string githubUsername: ""; property string githubToken: "" }

            // --- Screenshot & Recording ---
            property JsonObject screenshot: JsonObject {
                property bool autoSave: true
                property string savePath: Directories.home.replace("file://", "") + "/Pictures/Screenshots"
                property string recordPath: Directories.home.replace("file://", "") + "/Videos/Recordings"
                property bool showPreview: true
                property bool autoCopy: true
            }

            // --- Wallpaper Engine ---
            property JsonObject wallpaperEngine: JsonObject {
                property int fps: 30
                property int volume: 15
                property bool silent: false
                property bool autoPause: true
                property bool disableParticles: true
                property bool disableParallax: false
                property bool disableMouse: false
                property bool disableAudioProcessing: false
                property string scaling: "fill" // stretch, fit, fill, cover
                property bool noPbo: false
            }

            // --- Game Mode State ---
            property JsonObject gameModeState: JsonObject {
                property string previousLiveWallpaperPath: ""
                property string previousLayout: ""
            }
        }
    }
}
