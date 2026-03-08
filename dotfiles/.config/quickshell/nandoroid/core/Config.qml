pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

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
            case "YMD": return "yyyy/MM/dd" // Short YMD usually uses dots or dashes but let's stick to slash for consistency or use YYYY-MM-DD
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
            console.log("[Config] FileView onLoaded. quickSettings present:", !!configOptionsJsonAdapter.quickSettings);
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
                property string timeStyle: "24H" // 12H_pm, 12H_PM, 24H
                property string dateStyle: "DMY" // DMY, MDY, YMD
            }

            // --- Appearance ---
            property JsonObject appearance: JsonObject {
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string monospace: "JetBrains Mono NF"
                }
                property JsonObject background: JsonObject {
                    property string wallpaperPath: "file://" + Directories.assetsPath + "/wallpapers/default_wallpaper.png"
                    property bool darkmode: true
                    property bool matugen: true
                    property string matugenScheme: "scheme-content"
                    property string matugenCustomColor: "#3F51B5"
                    property string matugenThemeFile: ""
                    property string matugenSource: "desktop"
                }
                property JsonObject screenCorners: JsonObject {
                    // mode: 0 (Off), 1 (On, hide on fullscreen), 2 (Always On)
                    property int mode: 1
                    property int radius: 20
                }
                property JsonObject clock: JsonObject {
                    property string style: "digital"
                    property string styleLocked: "digital"
                    property bool showOnDesktop: true
                    property bool useSameStyle: true
                    property int offsetX: 0
                    property int offsetY: -50
                    property bool locked: false

                    property JsonObject digital: JsonObject {
                        property bool isVertical: false
                        property string colorStyle: "primary"
                        property int fontSize: 84
                        property bool showDate: true
                        property bool hideAmPm: false
                    }

                    // Independent lockscreen digital settings (used when useSameStyle is false)
                    property JsonObject digitalLocked: JsonObject {
                        property bool isVertical: false
                        property string colorStyle: "primary"
                        property int fontSize: 84
                        property bool showDate: true
                        property bool hideAmPm: false
                    }

                    property JsonObject analog: JsonObject {
                        property bool constantlyRotate: false
                        property string backgroundStyle: "shape" // shape, cookie, sine, none
                        property int sides: 12
                        property string backgroundShape: "Circle" 
                        property string shape: "Circle" // alias for backgroundShape
                        property bool showMarks: true
                        property bool hourMarks: false
                        property bool timeIndicators: false
                        property bool showDate: true
                        property string dateStyle: "bubble" // bubble, border, rect, none
                        property string handStyle: "modern" // fallback
                        property string hourHandStyle: "fill" // fill, classic, hollow, none
                        property string minuteHandStyle: "bold" // bold, medium, thin, classic, none
                        property string secondHandStyle: "dot" // dot, line, classic, none
                        property string dialStyle: "dots" // dots, numbers, full, none
                        property int size: 240
                    }

                    // Independent lockscreen analog settings (used when useSameStyle is false)
                    property JsonObject analogLocked: JsonObject {
                        property bool constantlyRotate: false
                        property string backgroundStyle: "shape"
                        property int sides: 12
                        property string backgroundShape: "Circle"
                        property string shape: "Circle"
                        property bool showMarks: true
                        property bool hourMarks: false
                        property bool timeIndicators: false
                        property bool showDate: true
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
                        property bool showDate: true
                        property string fontFamily: "JetBrainsMono Nerd Font"
                    }

                    // Independent lockscreen code settings (used when useSameStyle is false)
                    property JsonObject codeLocked: JsonObject {
                        property string valueColorStyle: "primary"
                        property string keywordColorStyle: "tertiary"
                        property string blockColorStyle: "primary"
                        property int fontSize: 18
                        property string blockType: "js"
                        property bool showDate: true
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
                }
            }

            // --- Workspaces ---
            property JsonObject workspaces: JsonObject {
                property int max_shown: 5
            }

            // --- Bar ---
            property JsonObject bar: JsonObject {
                property bool show_distro_icon: true
                property string distroIcon: "" // manual override, e.g. "cachyos-symbolic"
                property string avatar_path: ""
                property bool show_network_speed: false
                property string network_speed_unit: "KB" // B, KB, MB
            }

            // --- Status Bar ---
            property JsonObject statusBar: JsonObject {
                property real height: 40
                property string textColorMode: "adaptive" // adaptive, light, dark
                property bool useGradient: true
                // 0 = None (transparent), 1 = Always (solid), 2 = Adaptive (show when window active)
                property int backgroundStyle: 0
                property int backgroundCornerRadius: 20
            }

            // --- Quick Settings ---
            property JsonObject quickSettings: JsonObject {
                property bool caffeineActive: false
                property bool showPerformanceStats: true
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
                property bool autoLocation: true
                property string location: ""
                property string unit: "C" // C or F
                property bool showDailyForecast: true
                property int updateInterval: 30 // in minutes
            }

            // ──────────────────────────────────────────────
            // Overview Panel
            // ──────────────────────────────────────────────
            property QtObject overview: QtObject {
                property int rows: 2
                property int columns: 5
                property real scale: 0.15
                property real workspaceSpacing: 10
            }

            ///////////////////////////////////
            /// Signals & Functions
            ///////////////////////////////////
            // --- Notifications ---
            property JsonObject notifications: JsonObject {
                property int timeout_ms: 2000
                property string counterStyle: "counter" // counter, simple, hidden
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
                property string iconShape: "Square"
            }

            // --- Lock ---
            property JsonObject lock: JsonObject {
                property bool launchOnStartup: false
                property bool useHyprlock: false
                property string wallpaperPath: ""
                property bool useSeparateWallpaper: false
                property bool showCava: true
                property bool showMediaCard: true
                property JsonObject security: JsonObject {
                    property bool requirePasswordToPower: true
                }
            }
            // --- System ---
            property JsonObject system: JsonObject {
                property list<var> monitoredDisks: [
                    { "path": "/", "alias": "System" }
                ]
            }
            // --- Media ---
            property JsonObject media: JsonObject {
                property string priority: ""
            }

            // --- Privacy ---
            property JsonObject privacy: JsonObject {
                property bool enable: true
            }

            // --- Screen Snip ---
            property JsonObject screenSnip: JsonObject {
                property string savePath: "" // only copy to clipboard when empty
            }

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
                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                }
                property JsonObject annotationSymbol: JsonObject {
                    property bool showIcons: true
                }
                property JsonObject annotation: JsonObject {
                    property bool useSatty: false // Use swappy by default
                }
            }

            // --- GitHub ---
            property JsonObject github: JsonObject {
                property string githubUsername: ""
                property string githubToken: "" // Personal access token (optional, for private repos)
            }

        }
    }
}
