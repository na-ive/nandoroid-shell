#!/usr/bin/env bash
# apply_theme.sh - wrapper for apply_theme.py (exact theme mode).
# Usage: apply_theme.sh <theme-file> [dark|light] [wallpaper-path]
# Resolves theme file, renders all matugen templates exactly, then applies
# system targets (GTK gsettings, KDE static schemes, kitty reload, live
# terminal sequences broadcast). Replaces the matugen approximation path
# (matugenColorProc) when a theme file is active.

set -u
THEME_ARG="${1:-}"
MODE_FLAG="${2:-dark}"
WALLPAPER="${3:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/../../assets/themes"

if [[ -z "$THEME_ARG" ]]; then
    echo "Usage: apply_theme.sh <theme-file> [dark|light] [wallpaper-path]" >&2
    exit 1
fi

# Resolve theme path (bare name -> assets/themes/)
THEME_PATH="$THEME_ARG"
if [[ "$THEME_PATH" != *"/"* ]]; then
    THEME_PATH="$THEMES_DIR/$THEME_PATH"
fi
if [[ ! -f "$THEME_PATH" ]]; then
    echo "[apply_theme.sh] theme not found: $THEME_PATH" >&2
    exit 1
fi

# Fall back to current wallpaper for {{image}} tokens
if [[ -z "$WALLPAPER" && -f "$HOME/.config/nandoroid/config.json" ]]; then
    WALLPAPER=$(python3 -c "import json; print(json.load(open('$HOME/.config/nandoroid/config.json')).get('appearance',{}).get('background',{}).get('wallpaperPath',''))" 2>/dev/null | sed 's|^file://||')
fi

python3 "$SCRIPT_DIR/apply_theme.py" \
    --theme "$THEME_PATH" \
    --mode "$MODE_FLAG" \
    --image "$WALLPAPER" || exit 1

# --- GTK dark/light switch (mirrors apply_system_theme.sh) ---
if [[ "$MODE_FLAG" == "dark" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null
    cur=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    if [[ "$cur" == "adw-gtk3" || "$cur" == "adw-gtk3-dark" || -z "$cur" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null
    fi
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null
    cur=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
    if [[ "$cur" == "adw-gtk3" || "$cur" == "adw-gtk3-dark" || -z "$cur" ]]; then
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" 2>/dev/null
    fi
fi

# --- KDE static schemes (exact). Kill the approximation daemon so it
# --- doesn't overwrite our 1:1 files on its next tick.
pkill -f "kde-material-you-colors" 2>/dev/null || true
if command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    plasma-apply-colorscheme NandoroidNamed2 >/dev/null 2>&1
    plasma-apply-colorscheme NandoroidNamed >/dev/null 2>&1
fi

# --- Terminal: kitty live reload (existing behavior) ---
if command -v kitty >/dev/null 2>&1; then
    kitty @ set-colors -a -c ~/.config/kitty/current-theme.conf >/dev/null 2>&1 &
fi

# --- Terminal: broadcast escape sequences to live ptys (end4 applycolor.sh
# --- port). Makes foot/wezterm/konsole pick up the theme without restart.
SEQ="$HOME/.local/state/quickshell/user/generated/terminal/sequences.txt"
if [[ -f "$SEQ" ]]; then
    for pts in /dev/pts/[0-9]*; do
        { cat "$SEQ" >"$pts"; } & disown 2>/dev/null || true
    done
fi
