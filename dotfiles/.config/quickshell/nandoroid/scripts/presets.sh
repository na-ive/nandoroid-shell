#!/usr/bin/env bash
# presets.sh - manage shell config presets
# Usage:
#   presets.sh --save <name> [description]
#   presets.sh --remove <name>
#   presets.sh --apply <name>

CONFIG_DIR="$HOME/.config/nandoroid"
CONFIG_FILE="$CONFIG_DIR/config.json"
PRESETS_DIR="$CONFIG_DIR/presets"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Matugen-generated files watched by Quickshell (see core/Directories.qml)
COLOR_JSON="$HOME/.local/state/quickshell/user/generated/colors.json"
LOCK_COLOR_JSON="$HOME/.local/state/quickshell/user/generated/lockscreencolors.json"

mkdir -p "$PRESETS_DIR"

# ---------------------------------------------------------------------------
# build_preset_json <source_file>
# Outputs a whitelist-filtered JSON suitable for sharing as a preset.
# Excluded: credentials (github token), personal data (profile, location),
#           runtime state (system, gameModeState), and machine-local paths
#           (autoCycleDirectory, customFolders, savePath, avatar_path, etc.).
# All widget positions, visibility, and lock states ARE included because
# they are part of the visual layout and are tied to wallpaper choice.
# ---------------------------------------------------------------------------
build_preset_json() {
    jq '
    def compact:
        if   type == "object" then with_entries(select(.value != null) | .value |= compact)
        elif type == "array"  then map(select(. != null) | compact)
        else .
        end;
    {
        appearance: {
            globalScale:  .appearance.globalScale,
            autoScale:    .appearance.autoScale,
            widgetZ:      .appearance.widgetZ,
            fonts:        .appearance.fonts,
            clockFonts:   .appearance.clockFonts,
            atAGlance:    .appearance.atAGlance,
            background: {
                wallpaperPath:      .appearance.background.wallpaperPath,
                darkmode:           .appearance.background.darkmode,
                matugen:            .appearance.background.matugen,
                matugenScheme:      .appearance.background.matugenScheme,
                matugenCustomColor: .appearance.background.matugenCustomColor,
                matugenThemeFile:   .appearance.background.matugenThemeFile,
                matugenSource:      .appearance.background.matugenSource,
                liveWallpaperPath:     .appearance.background.liveWallpaperPath,
                liveWallpaperBackend:  .appearance.background.liveWallpaperBackend,
                autoCycleEnabled:   .appearance.background.autoCycleEnabled,
                autoCycleInterval:  .appearance.background.autoCycleInterval,
                showCava:           .appearance.background.showCava,
                cavaOpacity:        .appearance.background.cavaOpacity,
                cavaBars:           .appearance.background.cavaBars,
                showGrid:           .appearance.background.showGrid,
                gridSpacing:        .appearance.background.gridSpacing,
                showSnapLines:      .appearance.background.showSnapLines,
                wallpaperTransition: .appearance.background.wallpaperTransition
                # excluded: autoCycleDirectory, customFolders (machine-local paths)
            },
            screenCorners: .appearance.screenCorners,
            clock:         .appearance.clock,
            mediaWidget:   .appearance.mediaWidget,
            systemMonitor: .appearance.systemMonitor,
            weatherWidget: .appearance.weatherWidget,
            currencyWidget: .appearance.currencyWidget,
            githubWidget:  .appearance.githubWidget,
            lyrics:        .appearance.lyrics
        },
        time:      .time,
        language:  .language,
        workspaces: .workspaces,
        bar: {
            show_distro_icon:     .bar.show_distro_icon,
            distroIcon:           .bar.distroIcon,
            show_network_speed:   .bar.show_network_speed,
            network_speed_unit:   .bar.network_speed_unit,
            networkSpeedInterval: .bar.networkSpeedInterval
            # excluded: avatar_path (local path)
        },
        statusBar: .statusBar,
        quickSettings: {
            showBanner:            .quickSettings.showBanner,
            showPerformanceStats:  .quickSettings.showPerformanceStats,
            quickActionsPosition:  .quickSettings.quickActionsPosition,
            toggles:               .quickSettings.toggles
            # excluded: caffeineActive (runtime state)
        },
        dock: {
            enable:            .dock.enable,
            autoHide:          .dock.autoHide,
            autoHideMode:      .dock.autoHideMode,
            showOnlyInDesktop: .dock.showOnlyInDesktop,
            backgroundStyle:   .dock.backgroundStyle,
            hoverRegionHeight: .dock.hoverRegionHeight,
            pinnedOnStartup:   .dock.pinnedOnStartup,
            monochromeIcons:   .dock.monochromeIcons,
            scale:             .dock.scale,
            showLauncher:      .dock.showLauncher,
            showOverview:      .dock.showOverview
            # excluded: pinnedApps, ignoredAppRegexes (user-specific)
        },
        powerProfile:  .powerProfile,
        nightMode:     .nightMode,
        weather: {
            enable:                   .weather.enable,
            showInNotificationCenter: .weather.showInNotificationCenter,
            unit:                     .weather.unit,
            provider:                 .weather.provider,
            showDailyForecast:        .weather.showDailyForecast,
            updateInterval:           .weather.updateInterval
            # excluded: location, autoLocation (personal data)
        },
        overview:      .overview,
        notifications: .notifications,
        battery:       .battery,
        panels:        .panels,
        search: {
            mathPrefix:      .search.mathPrefix,
            webPrefix:       .search.webPrefix,
            emojiPrefix:     .search.emojiPrefix,
            clipboardPrefix: .search.clipboardPrefix,
            filePrefix:      .search.filePrefix,
            commandPrefix:   .search.commandPrefix,
            toolsPrefix:     .search.toolsPrefix,
            settingsPrefix:  .search.settingsPrefix,
            iconShape:       .search.iconShape,
            enableGrouping:  .search.enableGrouping
            # excluded: enableUsageTracking, imageSearch (personal behaviour)
        },
        lock: {
            showCava:             .lock.showCava,
            cavaOpacity:          .lock.cavaOpacity,
            showMediaCard:        .lock.showMediaCard,
            showWeather:          .lock.showWeather,
            weather:              .lock.weather,
            security:             .lock.security,
            useSeparateWallpaper: .lock.useSeparateWallpaper,
            wallpaperPath:        .lock.wallpaperPath
            # excluded: launchOnStartup, useHyprlock (local/system config)
        },
        sounds:         .sounds,
        media:          .media,
        privacy:        .privacy,
        screenSnip:     .screenSnip,
        regionSelector: .regionSelector,
        screenshot: {
            autoSave:    .screenshot.autoSave,
            showPreview: .screenshot.showPreview,
            autoCopy:    .screenshot.autoCopy
            # excluded: savePath, recordPath (local paths)
        },
        wallpaperEngine: .wallpaperEngine,
        mpvpaper:        .mpvpaper,
        interactions:    .interactions,
        profile: {
            avatarPicture: .profile.avatarPicture,
            bannerImage:   .profile.bannerImage
            # excluded: displayName, descriptionText (personal identity)
        }
    } | compact
    ' "$1"
}

action="$1"
name="$2"

if [ -z "$name" ]; then
    echo "Error: missing preset name" >&2
    exit 1
fi

case "$action" in
    --save)
        description="$3"
        # Atomic write: build into tmp first, then rename, so watchers
        # (inotify/FolderListModel/FileView) never see an empty/half-written file
        tmp_file="$PRESETS_DIR/${name}.json.tmp"
        build_preset_json "$CONFIG_FILE" > "$tmp_file" \
            && mv "$tmp_file" "$PRESETS_DIR/${name}.json"
        if [ -n "$description" ]; then
            jq --arg desc "$description" '._presetMeta = {"description": $desc}' \
                "$PRESETS_DIR/${name}.json" > "$tmp_file" \
                && mv "$tmp_file" "$PRESETS_DIR/${name}.json"
        fi
        ;;
    --remove)
        rm -f "$PRESETS_DIR/${name}.json"
        ;;
    --apply)
        preset_file="$PRESETS_DIR/${name}.json"
        if [ ! -f "$preset_file" ]; then
            echo "Error: preset not found: $name" >&2
            exit 1
        fi

        # Filter the preset through the whitelist before merging.
        # This ensures backward compat with old presets that may contain
        # sensitive fields (e.g. github tokens, profile data, system state).
        filtered_preset=$(build_preset_json "$preset_file")
        merged_json=$(jq -s '.[0] * .[1] | del(._presetMeta)' "$CONFIG_FILE" - <<< "$filtered_preset")

        matugen_enabled=$(echo "$merged_json" | jq -r '.appearance.background.matugen // false')
        custom_color=$(echo "$merged_json" | jq -r '.appearance.background.matugenCustomColor // .appearance.palette.accentColor // .palette.accentColor // ""')
        theme_file=$(echo "$merged_json" | jq -r '.appearance.background.matugenThemeFile // ""')

        scheme=$(echo "$merged_json" | jq -r '.appearance.background.matugenScheme // "scheme-tonal-spot"')
        darkmode=$(echo "$merged_json" | jq -r '.appearance.background.darkmode // true')
        [ "$darkmode" = "true" ] && mode="dark" || mode="light"

        # Regenerate lockscreen colors, mirroring the Wallpapers service behavior.
        # Only needed when a separate lockscreen wallpaper is used; otherwise the
        # shell mirrors desktop colors to the lockscreen automatically.
        refresh_lock_colors() {
            lock_sep=$(echo "$merged_json" | jq -r '.lock.useSeparateWallpaper // false')
            [ "$lock_sep" = "true" ] || return 0

            # Custom accent colors always derive tonal-spot schemes (matches the
            # desktop generation in the custom-color branch and the Wallpapers service)
            lock_scheme="$scheme"
            if [ "$matugen_enabled" = "false" ]; then
                lock_scheme="scheme-tonal-spot"
            fi

            matugen_source=$(echo "$merged_json" | jq -r '.appearance.background.matugenSource // "desktop"')
            if [ "$matugen_source" = "lockscreen" ]; then
                # Desktop colors already derive from the lockscreen wallpaper
                cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
                return 0
            fi

            lock_wallpaper=$(echo "$merged_json" | jq -r '.lock.wallpaperPath // ""')
            lock_wallpaper="${lock_wallpaper#file://}"
            desktop_wallpaper=$(echo "$merged_json" | jq -r '.appearance.background.wallpaperPath // ""')
            desktop_wallpaper="${desktop_wallpaper#file://}"
            [ -n "$lock_wallpaper" ] && [ -f "$lock_wallpaper" ] || return 0

            if [ "$lock_wallpaper" = "$desktop_wallpaper" ]; then
                # Same wallpaper as desktop: reuse the just-generated desktop colors
                cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
            else
                # Different wallpaper: derive lockscreen colors from the lockscreen wallpaper
                lock_json=$(matugen --dry-run -t "$lock_scheme" -m "$mode" image "$lock_wallpaper" --source-color-index 0 -j hex --old-json-output 2>/dev/null)
                if [ -n "$lock_json" ]; then
                    echo "$lock_json" | jq --arg mode "$mode" '.colors | with_entries(.value = (.value[$mode] // .value["default"]))' > "$LOCK_COLOR_JSON"
                fi
            fi
        }

        if [ "$matugen_enabled" = "false" ] && [ -n "$theme_file" ] && [ "$theme_file" != "null" ] && [ "$theme_file" != '""' ]; then
            # Cache the theme colors so lockscreen mirroring stays consistent
            theme_source="$SCRIPT_DIR/../assets/themes/$theme_file"
            [ -f "$theme_source" ] && cp "$theme_source" "$COLOR_JSON"
            echo "$merged_json" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            # Basic themes: desktop uses the theme file. Lockscreen follows the
            # Wallpapers.applyTheme behavior — derive from the lockscreen
            # wallpaper when it differs, otherwise reuse the theme colors.
            if [ "$(echo "$merged_json" | jq -r '.lock.useSeparateWallpaper // false')" = "true" ]; then
                lock_wallpaper=$(echo "$merged_json" | jq -r '.lock.wallpaperPath // ""')
                lock_wallpaper="${lock_wallpaper#file://}"
                desktop_wallpaper=$(echo "$merged_json" | jq -r '.appearance.background.wallpaperPath // ""')
                desktop_wallpaper="${desktop_wallpaper#file://}"
                if [ -n "$lock_wallpaper" ] && [ -f "$lock_wallpaper" ] && [ "$lock_wallpaper" != "$desktop_wallpaper" ]; then
                    lock_json=$(matugen --dry-run -t "scheme-tonal-spot" -m "$mode" image "$lock_wallpaper" --source-color-index 0 -j hex --old-json-output 2>/dev/null)
                    if [ -n "$lock_json" ]; then
                        echo "$lock_json" | jq --arg mode "$mode" '.colors | with_entries(.value = (.value[$mode] // .value["default"]))' > "$LOCK_COLOR_JSON"
                    else
                        cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
                    fi
                else
                    cp "$COLOR_JSON" "$LOCK_COLOR_JSON"
                fi
            fi
        elif [ "$matugen_enabled" = "false" ] && [ -n "$custom_color" ] && [ "$custom_color" != "null" ] && [ "$custom_color" != '""' ]; then
            custom_color_clean="${custom_color#\#}"
            # Ensure both matugenCustomColor and palette.accentColor in merged_json have the '#' prefix
            merged_json=$(echo "$merged_json" | jq --arg c "#$custom_color_clean" '.appearance.background.matugenCustomColor = $c | .appearance.palette.accentColor = $c')
            
            # Generate theme files via Matugen first
            matugen -c ~/.config/matugen/config.toml -t "scheme-tonal-spot" -m "$mode" color hex "$custom_color_clean"
            
            # Write config.json after matugen finishes
            echo "$merged_json" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            refresh_lock_colors
        else
            wallpaper=$(echo "$merged_json" | jq -r '.appearance.background.wallpaperPath // ""')
            wallpaper="${wallpaper#file://}"
            if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
                matugen -c ~/.config/matugen/config.toml -t "$scheme" -m "$mode" image "$wallpaper" --source-color-index 0
            fi
            echo "$merged_json" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
            refresh_lock_colors
        fi
        ;;
    *)
        echo "Error: unknown action: $action" >&2
        exit 1
        ;;
esac
