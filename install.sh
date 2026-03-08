#!/bin/bash

# Nandoroid Shell Smart Installation Script
set -e

# Reset terminal colors on exit or crash
trap 'echo -ne "\033[0m"' EXIT

# ─────────────────────────────────────────────────────────────────────────────
#  Color Palette (RGB for premium pastel look)
# ─────────────────────────────────────────────────────────────────────────────

C_MAIN='\033[38;2;202;169;224m'
C_ACCENT='\033[38;2;145;177;240m'
C_DIM='\033[38;2;129;122;150m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_RED='\033[38;2;231;130;132m'
C_WHITE='\033[38;2;205;214;244m'
C_BOLD='\033[1m'
C_RST='\033[0m'

# ─────────────────────────────────────────────────────────────────────────────
#  UI Helpers
# ─────────────────────────────────────────────────────────────────────────────

banner() {
    echo -e "${C_MAIN}${C_BOLD}"
    echo ' _   _                 _                 _     _'
    echo '| \ | | __ _ _ __   __| | ___  _ __ ___ (_) __| |'
    echo '|  \| |/ _` | '"'"'_ \ / _` |/ _ \| '"'"'__/ _ \| |/ _` |'
    echo '| |\  | (_| | | | | (_| | (_) | | | (_) | | (_| |'
    echo '|_| \_|\__,_|_| |_|\__,_|\___/|_|  \___/|_|\__,_|'
    echo -e "${C_RST}"
    echo -e " ${C_MAIN}${C_BOLD}╭──────────────────────────────────────────╮${C_RST}"
    echo -e " ${C_MAIN}${C_BOLD}│            * SHELL INSTALLER *           │${C_RST}"
    echo -e " ${C_MAIN}${C_BOLD}╰──────────────────────────────────────────╯${C_RST}"
    echo ""
}

finished() {
    echo ""
    echo -e " ${C_GREEN}${C_BOLD}╭──────────────────────────────────────────╮${C_RST}"
    echo -e " ${C_GREEN}${C_BOLD}│         INSTALLATION COMPLETE!           │${C_RST}"
    echo -e " ${C_GREEN}${C_BOLD}╰──────────────────────────────────────────╯${C_RST}"
    echo ""
}

info() {
    echo -e "${C_MAIN}${C_BOLD} ╭─ $1${C_RST}"
}

substep() {
    echo -e "${C_MAIN}${C_BOLD} │  ${C_DIM}> ${C_RST}$1"
}

success() {
    echo -e "${C_MAIN}${C_BOLD} ╰─ ${C_GREEN}+ ${C_RST}$1"
    echo ""
}

error() {
    echo -e "${C_MAIN}${C_BOLD} ╰─ ${C_RED}x ${C_RST}$1"
    echo ""
}

ask() {
    echo -ne "${C_MAIN}${C_BOLD} ╰─ ${C_YELLOW}? ${C_RST}$1 "
}

choice() {
    echo -e "${C_MAIN}${C_BOLD} │  ${C_ACCENT}$1 ${C_DIM}> ${C_RST}$2"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Main Script
# ─────────────────────────────────────────────────────────────────────────────

banner

# 1. Installation path
info "Installation path..."
ask "Where to clone? (default: ~/.local/src/nandoroid)"
echo ""
read -rp "     > " INSTALL_DIR < /dev/tty
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/src/nandoroid}"
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
substep "Target: ${C_ACCENT}$INSTALL_DIR${C_RST}"

# 2. Clone or Update
if [ -d "$INSTALL_DIR" ]; then
    info "Repository already exists."
    ask "Update it now? (Y/n)"
    read -r UPDATE_CHOICE < /dev/tty
    UPDATE_CHOICE="${UPDATE_CHOICE:-y}"
    if [[ "$UPDATE_CHOICE" =~ ^[Yy] ]]; then
        substep "Pulling latest changes..."
        cd "$INSTALL_DIR"
        git pull origin main
        success "Repository updated."
    else
        success "Skipped."
    fi
else
    info "Cloning repository..."
    git clone https://github.com/na-ive/nandoroid-shell.git "$INSTALL_DIR"
    success "Repository cloned."
fi

cd "$INSTALL_DIR" || exit 1

# 3. Dependencies
info "Dependency installation..."
ask "Install required dependencies? (y/N)"
read -r DEP_CHOICE < /dev/tty
if [[ "$DEP_CHOICE" =~ ^[Yy] ]]; then

    # Confirm mode
    CONFIRM_FLAG=""
    info "Installation mode..."
    choice "1" "Manual confirm  ${C_DIM}(review each package, resolve conflicts)${C_RST}"
    choice "2" "Auto confirm    ${C_DIM}(faster, no prompts)${C_RST}"
    ask "Choose mode (1/2, default: 1)"
    read -r CONFIRM_MODE < /dev/tty
    CONFIRM_MODE="${CONFIRM_MODE:-1}"
    if [[ "$CONFIRM_MODE" == "2" ]]; then
        CONFIRM_FLAG="--noconfirm"
        substep "${C_YELLOW}Auto confirm enabled. Conflicts will be skipped automatically.${C_RST}"
    else
        substep "Manual confirm. You will be prompted for each action."
    fi

    # paru check
    if ! command -v paru >/dev/null 2>&1; then
        info "Installing paru (AUR helper)..."
        sudo pacman -S --needed $CONFIRM_FLAG base-devel git < /dev/tty
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si $CONFIRM_FLAG < /dev/tty
        cd "$INSTALL_DIR"
        rm -rf /tmp/paru
        success "paru installed."
    else
        substep "paru already available."
    fi

    # 3a. Core
    info "Core shell dependencies..."
    substep "Required for the shell to function."

    CORE_DEPS=(
        "hyprland"
        "quickshell-git"
        "qt6-declarative"
        "qt6-svg"
        "qt6-wayland"
        "pipewire"
        "networkmanager"
        "bluez"
        "bluez-utils"
        "libnotify"
        "polkit"
        "xdg-desktop-portal-hyprland"
        "xdg-desktop-portal-gtk"
        "python3"
        "dgop"
        "brightnessctl"
        "ddcutil"
        "playerctl"
        "matugen-bin"
        "grim"
        "slurp"
        "wf-recorder"
        "imagemagick"
        "ffmpeg"
        "songrec"
        "cava"
        "easyeffects"
        "hyprpicker"
        "hyprlock"
        "hyprsunset"
        "fd"
        "libqalculate"
        "jq"
        "xdg-utils"
        "wl-clipboard"
    )
    paru -S --needed $CONFIRM_FLAG "${CORE_DEPS[@]}" < /dev/tty
    success "Core dependencies installed."

    # 3b. Fonts
    info "Font installation..."
    choice "1" "Google Sans Flex   ${C_DIM}(UI font, from GitHub)${C_RST}"
    choice "2" "Material Symbols   ${C_DIM}(icon font, from AUR)${C_RST}"
    choice "3" "JetBrains Mono NF  ${C_DIM}(monospace, from AUR)${C_RST}"
    ask "Install required fonts? (Y/n)"
    read -r FONT_CHOICE < /dev/tty
    FONT_CHOICE="${FONT_CHOICE:-y}"
    if [[ "$FONT_CHOICE" =~ ^[Yy] ]]; then
        # Google Sans Flex from GitHub
        if ! fc-list | grep -qi "Google Sans Flex"; then
            substep "Cloning Google Sans Flex from GitHub..."
            FONT_SRC="/tmp/google-sans-flex"
            FONT_TARGET="$HOME/.local/share/fonts/nandoroid-google-sans-flex"
            rm -rf "$FONT_SRC"
            git clone --depth 1 https://github.com/end-4/google-sans-flex.git "$FONT_SRC"
            mkdir -p "$FONT_TARGET"
            cp -r "$FONT_SRC"/* "$FONT_TARGET"/
            rm -rf "$FONT_SRC"
            fc-cache -fv
        else
            substep "Google Sans Flex already installed."
        fi

        # Official & AUR fonts
        FONT_DEPS=(
            "ttf-material-symbols-variable-git"
            "ttf-jetbrains-mono-nerd"
            "noto-fonts-emoji"
        )
        paru -S --needed $CONFIRM_FLAG "${FONT_DEPS[@]}" < /dev/tty
        success "All fonts installed."
    else
        success "Skipped."
    fi

    # 3c. Optional terminal tools
    info "Terminal aesthetic (optional)..."
    choice "1" "kitty     ${C_DIM}- terminal with theme injection${C_RST}"
    choice "2" "fish      ${C_DIM}- interactive shell${C_RST}"
    choice "3" "starship  ${C_DIM}- cross-shell prompt${C_RST}"
    ask "Install optional terminal tools? (y/N)"
    read -r TERM_CHOICE < /dev/tty
    if [[ "$TERM_CHOICE" =~ ^[Yy] ]]; then
        TERM_DEPS=(
            "kitty"
            "fish"
            "starship"
        )
        paru -S --needed $CONFIRM_FLAG "${TERM_DEPS[@]}" < /dev/tty
        success "Terminal tools installed."
    else
        success "Skipped."
    fi
else
    success "Skipped."
fi

# 4. Copy dotfiles
info "Copying configuration files..."
substep "Copying dotfiles to ~/.config..."
mkdir -p "$HOME/.config"
cp -r dotfiles/.config/* "$HOME/.config/"
success "Configuration files copied."

# 5. Injection
info "Configuration injection..."
substep "Appends settings into your existing configs."
substep "Will ${C_WHITE}${C_BOLD}NOT${C_RST} overwrite existing configurations."
ask "Inject Nandoroid into existing configs? (y/N)"
read -r INJECT_CHOICE < /dev/tty
INJECT=false
if [[ "$INJECT_CHOICE" =~ ^[Yy] ]]; then
    INJECT=true

    # Kitty
    mkdir -p "$HOME/.config/kitty"
    touch "$HOME/.config/kitty/kitty.conf"
    if ! grep -q "include current-theme.conf" "$HOME/.config/kitty/kitty.conf"; then
        echo "" >> "$HOME/.config/kitty/kitty.conf"
        echo "include current-theme.conf" >> "$HOME/.config/kitty/kitty.conf"
        substep "Injected kitty theme include."
    else
        substep "Kitty already injected."
    fi

    # Fish
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    if ! grep -q "starship init fish" "$HOME/.config/fish/config.fish"; then
        echo "" >> "$HOME/.config/fish/config.fish"
        echo 'starship init fish | source' >> "$HOME/.config/fish/config.fish"
        substep "Injected starship prompt into fish."
    else
        substep "Fish already injected."
    fi

    # Hyprland
    mkdir -p "$HOME/.config/hypr"
    touch "$HOME/.config/hypr/hyprland.conf"
    if ! grep -q "nandoroid" "$HOME/.config/hypr/hyprland.conf"; then
        echo "" >> "$HOME/.config/hypr/hyprland.conf"
        echo 'source = ~/.config/hypr/nandoroid/nandoroid.conf' >> "$HOME/.config/hypr/hyprland.conf"
        substep "Injected nandoroid config into hyprland."
    else
        substep "Hyprland already injected."
    fi

    success "Injection complete."
else
    success "Skipped."
fi

# 6. Update Channel
info "Update channel..."
choice "1" "stable ${C_DIM}- follows git tags (release versions)${C_RST}"
choice "2" "canary ${C_DIM}- follows latest commit on main${C_RST}"
ask "Preferred channel? [stable/canary] (default: stable)"
read -r CHANNEL_CHOICE < /dev/tty
CHANNEL="stable"
if [[ "$CHANNEL_CHOICE" =~ ^[Cc] ]]; then
    CHANNEL="canary"
fi
substep "Selected: ${C_ACCENT}${C_BOLD}$CHANNEL${C_RST}"

# 7. Save State
substep "Saving installation state..."
mkdir -p "$HOME/.config/nandoroid"
STATE_FILE="$HOME/.config/nandoroid/install_state.json"
cat > "$STATE_FILE" << EOF
{
  "inject": $INJECT,
  "install_dir": "$INSTALL_DIR",
  "channel": "$CHANNEL"
}
EOF
success "State saved."

# Done
finished
substep "Nandoroid Shell is a ${C_WHITE}${C_BOLD}shell${C_RST}, not full dotfiles."
substep "File pickers / screen sharing require XDG portals."
substep "Make sure ${C_ACCENT}xdg-desktop-portal-hyprland${C_RST} and"
substep "${C_ACCENT}xdg-desktop-portal-gtk${C_RST} are installed."
echo ""
echo -e " ${C_GREEN}${C_BOLD} > ${C_RST}Run ${C_WHITE}${C_BOLD}quickshell -c nandoroid${C_RST} or restart Hyprland."
echo ""
