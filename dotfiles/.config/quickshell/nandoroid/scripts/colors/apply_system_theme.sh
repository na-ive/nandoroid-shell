#!/usr/bin/env bash

# Advanced Matugen Integration: Apply colors to KDE, GTK, and other system-wide targets.
# This script is called as a post-hook in matugen config.toml.

CONFIG_FILE="$HOME/.config/nandoroid/config.json"
VENV_PATH="$HOME/.local/share/nandoroid/venv"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
COLOR_FILE="$XDG_STATE_HOME/quickshell/user/generated/color.txt"

# Extract settings from config.json using python
get_config_val() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$2"
        return
    fi
    python3 -c "import json, sys; print(json.load(open('$CONFIG_FILE')).get('appearance', {}).get('background', {}).get('$1', '$2'))" 2>/dev/null || echo "$2"
}

MATUGEN_SCHEME=$(get_config_val "matugenScheme" "scheme-tonal-spot")
# Convert to lowercase to handle Python's "True"/"False"
DARK_MODE=$(get_config_val "darkmode" "true" | tr '[:upper:]' '[:lower:]')

# 1. Update GTK Themes
current_gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
if [[ "$current_gtk_theme" == "adw-gtk3-dark" || "$current_gtk_theme" == "adw-gtk3" ]]; then
    if [[ "$DARK_MODE" == "true" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"
    fi
fi

# 2. Update KDE
if [[ -d "$VENV_PATH" && -f "$COLOR_FILE" ]]; then
    COLOR=$(tr -d '\n' < "$COLOR_FILE")
    
    # Force ignore external virtualenv variable to avoid conflicts
    unset ILLOGICAL_IMPULSE_VIRTUAL_ENV
    
    case "$MATUGEN_SCHEME" in
        scheme-content) sv_num=0 ;;
        scheme-expressive) sv_num=1 ;;
        scheme-fidelity) sv_num=2 ;;
        scheme-monochrome) sv_num=3 ;;
        scheme-neutral) sv_num=4 ;;
        scheme-tonal-spot) sv_num=5 ;;
        scheme-vibrant) sv_num=6 ;;
        scheme-rainbow) sv_num=7 ;;
        scheme-fruit-salad) sv_num=8 ;;
        *) sv_num=5 ;;
    esac

    MODE_FLAG="-l"
    [[ "$DARK_MODE" == "true" ]] && MODE_FLAG="-d"

    # Run in background as it might take a moment to apply
    "$VENV_PATH/bin/kde-material-you-colors" "$MODE_FLAG" --color "$COLOR" -sv "$sv_num" &
fi
