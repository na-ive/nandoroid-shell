#!/bin/bash

# Nandoroid Shell State-Aware OTA Update Script
set -e

MODE=$1
CHANNEL=$2

STATE_FILE="$HOME/.config/nandoroid/install_state.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "Error: install_state.json not found. Please run the install script first."
    exit 1
fi

# Use regular expressions to extract values, since jq might not be installed
INSTALL_DIR=$(grep -oP '"install_dir": "\K[^"]*' "$STATE_FILE" || echo "")
JSON_CHANNEL=$(grep -oP '"channel": "\K[^"]*' "$STATE_FILE" || echo "")

if [ -z "$INSTALL_DIR" ]; then
    echo "Error: install_dir not found in install_state.json."
    exit 1
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
    echo "Switching to stable channel (latest tag)..."
    LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))
    if [ -n "$LATEST_TAG" ]; then
        git checkout "$LATEST_TAG"
    else
        echo "No tags found. Falling back to main branch."
        git checkout main
        git pull origin main
    fi
else
    echo "Switching to canary channel (latest commit)..."
    git checkout main
    git pull origin main
fi

# Copying files based on mode
if [ "$MODE" == "all" ]; then
    echo "Updating all configs..."
    cp -r dotfiles/.config/* "$HOME/.config/"
elif [ "$MODE" == "shell" ]; then
    echo "Updating shell only..."
    mkdir -p "$HOME/.config/quickshell/nandoroid"
    cp -r dotfiles/.config/quickshell/nandoroid/* "$HOME/.config/quickshell/nandoroid/"
else
    echo "Usage: $0 [all|shell] [stable|canary]"
    exit 1
fi

echo "Update successful!"
