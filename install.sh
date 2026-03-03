#!/bin/bash

# Nandoroid Shell Smart Installation Script
set -e

echo "Welcome to the Nandoroid Shell Installer!"

# 1. Prompt for installation path
read -p "Where do you want to clone the repository? (Default: ~/.local/src/nandoroid) " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/src/nandoroid}"
# Expand tilde
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

# 2. Clone or Update
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists."
    read -p "Do you want to update it now? (Y/n) " UPDATE_CHOICE
    UPDATE_CHOICE="${UPDATE_CHOICE:-y}"
    if [[ "$UPDATE_CHOICE" =~ ^[Yy] ]]; then
        cd "$INSTALL_DIR"
        git pull origin main
    fi
else
    echo "Cloning repository..."
    git clone https://github.com/na-ive/nandoroid-shell.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR" || exit 1

# 3. Install Dependencies
read -p "Do you want to install required dependencies (including 'paru' as AUR helper)? (y/N) " DEP_CHOICE
if [[ "$DEP_CHOICE" =~ ^[Yy] ]]; then
    echo "Checking for paru..."
    if ! command -v paru >/dev/null 2>&1; then
        echo "paru not found. Installing paru..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/paru.git /tmp/paru
        cd /tmp/paru
        makepkg -si --noconfirm
        cd "$INSTALL_DIR"
        rm -rf /tmp/paru
    fi
    
    echo "Installing shell dependencies via paru..."
    # You can customize this list based on the full dependency requirement.
    DEPENDENCIES=(
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
        "jq"
        "xdg-utils"
        "wl-clipboard"
        "kitty"
        "fish"
        "starship"
    )
    paru -S --needed --noconfirm "${DEPENDENCIES[@]}"
    echo "Dependencies installed."
fi

# 4. Copy dotfiles
echo "Copying dotfiles to ~/.config..."
mkdir -p "$HOME/.config"
cp -r dotfiles/.config/* "$HOME/.config/"

# 5. Prompt for Injection
read -p "Do you want to inject Nandoroid settings into your existing configurations (e.g., hypr, kitty, cava)? (y/N) " INJECT_CHOICE
INJECT=false
if [[ "$INJECT_CHOICE" =~ ^[Yy] ]]; then
    INJECT=true
    
    # Kitty Injection
    if [ -f "$HOME/.config/kitty/kitty.conf" ]; then
        if ! grep -q "include current-theme.conf" "$HOME/.config/kitty/kitty.conf"; then
            echo "include current-theme.conf" >> "$HOME/.config/kitty/kitty.conf"
            echo "Injected kitty theme include."
        fi
    fi
    
    # Fish Injection
    if [ -f "$HOME/.config/fish/config.fish" ]; then
        if ! grep -q "starship init fish" "$HOME/.config/fish/config.fish"; then
            echo 'starship init fish | source' >> "$HOME/.config/fish/config.fish"
            echo "Injected starship prompt into fish config."
        fi
    fi

    # Hyprland Injection
    if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
        # Check if already injected
        if ! grep -q "nandoroid" "$HOME/.config/hypr/hyprland.conf"; then
            mkdir -p "$HOME/.config/hypr/nandoroid"
            # Create sub-config for nandoroid specific window rules / execs
            cat > "$HOME/.config/hypr/nandoroid/nandoroid.conf" << 'EOF'
# Nandoroid specific settings
exec-once = quickshell -c nandoroid

# Layer rules for Nandoroid panels
# Example: layerrule = blur, quickshell
EOF
            echo 'source = ~/.config/hypr/nandoroid/nandoroid.conf' >> "$HOME/.config/hypr/hyprland.conf"
            echo "Injected nandoroid config into hyprland."
        fi
    fi

    echo "Injection complete."
fi

# 6. Ask for Update Channel
read -p "Which update channel do you prefer? (stable/Canary) [Default: stable] " CHANNEL_CHOICE
CHANNEL="stable"
if [[ "$CHANNEL_CHOICE" =~ ^[Cc] ]]; then
    CHANNEL="canary"
fi

# 7. Save State
echo "Saving installation state..."
mkdir -p "$HOME/.config/nandoroid"
STATE_FILE="$HOME/.config/nandoroid/install_state.json"
cat > "$STATE_FILE" << EOF
{
  "inject": $INJECT,
  "install_dir": "$INSTALL_DIR",
  "channel": "$CHANNEL"
}
EOF

echo "Installation complete!"
echo "Please restart Hyprland or manually run 'quickshell -c nandoroid' to start."
