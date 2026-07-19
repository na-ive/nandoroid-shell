#!/bin/bash

# Nandoroid Shell State-Aware OTA Update Script
set -e

# Get the directory where the script is located to use as project root
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODE=$1
CHANNEL=$2

STATE_FILE="$HOME/.config/nandoroid/install_state.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "Error: install_state.json not found. Please run the install script first."
    exit 1
fi

# Use regular expressions to extract values, since jq might not be installed
# We still read INSTALL_DIR but will prefer PROJECT_ROOT for file operations
INSTALL_DIR=$(grep -oP '"install_dir": "\K[^"]*' "$STATE_FILE" || echo "")
JSON_CHANNEL=$(grep -oP '"channel": "\K[^"]*' "$STATE_FILE" || echo "")

if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$PROJECT_ROOT"
fi

if [ -z "$CHANNEL" ]; then
    CHANNEL=$JSON_CHANNEL
fi
if [ -z "$CHANNEL" ]; then
    CHANNEL="stable"
fi

cd "$INSTALL_DIR" || exit 1

echo "Fetching latest updates..."
git fetch origin

if [ "$CHANNEL" == "stable" ]; then
    echo "Switching to Release channel (latest tag)..."
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
    if [ -n "$LATEST_TAG" ]; then
        git checkout "$LATEST_TAG"
    else
        echo "No tags found. Falling back to main branch."
        git checkout main
        git pull origin main
    fi
else
    echo "Switching to Latest channel (latest commit)..."
    git checkout main
    git pull origin main
fi

# Copying files based on mode
CONFIG_PATH="$HOME/.config/quickshell/nandoroid/core/Config.qml"
if [ -f "$CONFIG_PATH" ]; then
    BACKUP_NAME="Config_$(date +%Y%m%d_%H%M%S).bak"
    echo "Backing up existing configuration to $BACKUP_NAME..."
    cp "$CONFIG_PATH" "$(dirname "$CONFIG_PATH")/$BACKUP_NAME"
fi

if [ "$MODE" == "all" ]; then
    echo "Updating all configs..."
    
    for item in "$PROJECT_ROOT/dotfiles/.config/"*; do
        item_name=$(basename "$item")
        
        if [[ "$item_name" == "matugen" ]] && [ -e "$HOME/.config/matugen" ]; then
            if [ -f "$HOME/.config/matugen/config.toml" ] && grep -q "# Nandoroid Configuration" "$HOME/.config/matugen/config.toml"; then
                : # It's ours, let it update
            else
                echo "Warning: You already have your own matugen configuration. Skipping update for matugen."
                continue
            fi
        fi
        
        if [[ "$item_name" == "starship.toml" ]] && [ -e "$HOME/.config/starship.toml" ]; then
            if grep -q "# Nandoroid Configuration" "$HOME/.config/starship.toml"; then
                : # It's ours, let it update
            else
                echo "Warning: You already have your own starship configuration. Skipping update for starship."
                continue
            fi
        fi
        
        cp -r "$item" "$HOME/.config/"
    done
elif [ "$MODE" == "shell" ]; then
    echo "Updating shell only..."
    mkdir -p "$HOME/.config/quickshell/nandoroid"
    cp -r "$PROJECT_ROOT/dotfiles/.config/quickshell/nandoroid/"* "$HOME/.config/quickshell/nandoroid/"
else
    echo "Usage: $0 [all|shell] [stable|canary]"
    exit 1
fi

# Ensure dependencies.json is always copied as real file from project root
echo "Updating shell metadata (dependencies)..."
mkdir -p "$HOME/.config/quickshell/nandoroid/data"
cp "$PROJECT_ROOT/data/dependencies.json" "$HOME/.config/quickshell/nandoroid/data/dependencies.json"

# Migration / Config Injection
HYPR_CONF="$HOME/.config/hypr/hyprland.lua"
if [ -f "$HYPR_CONF" ]; then
    if ! grep -q 'require("nandoroid/user_persistence")' "$HYPR_CONF"; then
        echo "Injecting user_persistence.lua into hyprland.lua..."
        echo 'require("nandoroid/user_persistence")' >> "$HYPR_CONF"
    fi
fi
mkdir -p "$HOME/.config/hypr/nandoroid"
touch "$HOME/.config/hypr/nandoroid/user_persistence.lua"

echo "Update successful!"
