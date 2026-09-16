#!/bin/bash

# Nandoroid Shell Smart Installation Script
set -e

# Flags: --dry-run walks all prompts but only prints what WOULD change.
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
    esac
done

# Wrapper: announce in dry-run mode, execute otherwise.
run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        substep "[dry-run] would run: $*"
    else
        "$@"
    fi
}

# Append helper (plain >> cannot go through run() — the redirection would
# still execute in dry-run mode).
add_line() {
    if [[ "$DRY_RUN" == "1" ]]; then
        substep "[dry-run] would append to $1: $2"
    else
        printf '%s\n' "$2" >> "$1"
    fi
}

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
    # "NANDOROID" in 3D block letters (xero 3d FIGlet font, baked in —
    # no runtime deps). Single color on purpose; one echo sets it so no
    # stray blank lines slip between art rows.
    echo -e "${C_MAIN}${C_BOLD}"
    echo ' ████     ██     ██     ████     ██ ███████     ███████   ███████     ███████   ██ ███████'
    echo '░██░██   ░██    ████   ░██░██   ░██░██░░░░██   ██░░░░░██ ░██░░░░██   ██░░░░░██ ░██░██░░░░██'
    echo '░██░░██  ░██   ██░░██  ░██░░██  ░██░██    ░██ ██     ░░██░██   ░██  ██     ░░██░██░██    ░██'
    echo '░██ ░░██ ░██  ██  ░░██ ░██ ░░██ ░██░██    ░██░██      ░██░███████  ░██      ░██░██░██    ░██'
    echo '░██  ░░██░██ ██████████░██  ░░██░██░██    ░██░██      ░██░██░░░██  ░██      ░██░██░██    ░██'
    echo '░██   ░░████░██░░░░░░██░██   ░░████░██    ██ ░░██     ██ ░██  ░░██ ░░██     ██ ░██░██    ██'
    echo '░██    ░░███░██     ░██░██    ░░███░███████   ░░███████  ░██   ░░██ ░░███████  ░██░███████'
    echo '░░      ░░░ ░░      ░░ ░░      ░░░ ░░░░░░░     ░░░░░░░   ░░     ░░   ░░░░░░░   ░░ ░░░░░░░'
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

if [[ "$DRY_RUN" == "1" ]]; then
    substep "${C_YELLOW}DRY-RUN MODE: answering prompts only, no changes will be made.${C_RST}"
fi

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
        run git pull origin main
        success "Repository updated."
    else
        success "Skipped."
    fi
else
    info "Cloning repository..."
    run git clone https://github.com/na-ive/nandoroid-shell.git "$INSTALL_DIR"
    success "Repository cloned."
fi

if ! cd "$INSTALL_DIR" 2>/dev/null; then
    if [[ "$DRY_RUN" == "1" ]]; then
        substep "${C_YELLOW}Target dir missing, staying put (repo-relative steps will show placeholders).${C_RST}"
    else
        exit 1
    fi
fi

# 3. Dependencies
info "Dependency installation..."
ask "Install required dependencies? (y/N)"
read -r DEP_CHOICE < /dev/tty
if [[ "$DEP_CHOICE" =~ ^[Yy] ]]; then
    # Nandoroid is Arch-based only; fail soft with a clear message instead of
    # dying halfway through sudo pacman on other distros.
    if ! command -v pacman >/dev/null 2>&1; then
        substep "${C_YELLOW}pacman not found — nandoroid supports Arch-based systems only.${C_RST}"
        substep "Skipping dependency installation; install packages manually."
        DEP_CHOICE="n"
    fi
fi
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
        run sudo pacman -S --needed $CONFIRM_FLAG base-devel git
        run git clone https://aur.archlinux.org/paru.git /tmp/paru
        if [[ "$DRY_RUN" == "1" ]]; then
            substep "[dry-run] would build paru in /tmp/paru."
        else
            cd /tmp/paru
        fi
        run makepkg -si $CONFIRM_FLAG
        cd "$INSTALL_DIR" 2>/dev/null || [[ "$DRY_RUN" == "1" ]]
        run rm -rf /tmp/paru
        success "paru installed."
    else
        substep "paru already available."
    fi

    # 3a. Core, Services, Utilities, and Theming
    info "Mandatory shell dependencies..."
    substep "Required for the shell and system to function."
    run ./scripts/install_deps.sh core "$CONFIRM_FLAG"
    run ./scripts/install_deps.sh services "$CONFIRM_FLAG"
    run ./scripts/install_deps.sh utilities "$CONFIRM_FLAG"
    run ./scripts/install_deps.sh theming "$CONFIRM_FLAG"
    success "Mandatory dependencies installed."

    # 3b. KDE Material You Venv (Optional but recommended)
    info "KDE Material You integration..."
    ask "Setup Python venv for KDE theming? (y/N)"
    read -r VENV_CHOICE < /dev/tty
    if [[ "$VENV_CHOICE" =~ ^[Yy] ]]; then
        VENV_PATH="$HOME/.local/share/nandoroid/venv"
        substep "Creating venv in ${C_ACCENT}$VENV_PATH${C_RST}..."
        run mkdir -p "$(dirname "$VENV_PATH")"
        run python3 -m venv "$VENV_PATH"
        substep "Installing kde-material-you-colors..."
        run "$VENV_PATH/bin/pip" install --upgrade pip
        run "$VENV_PATH/bin/pip" install "materialyoucolor<3.0.0"
        run "$VENV_PATH/bin/pip" install kde-material-you-colors
        run "$VENV_PATH/bin/pip" install pykakasi korean_romanizer
        success "KDE theming venv ready."
    else
        success "Skipped."
    fi

    # 3c. Fonts
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
            run rm -rf "$FONT_SRC"
            run git clone --depth 1 https://github.com/end-4/google-sans-flex.git "$FONT_SRC"
            run mkdir -p "$FONT_TARGET"
            run cp -r "$FONT_SRC"/* "$FONT_TARGET"/
            run rm -rf "$FONT_SRC"
            run fc-cache -fv
        else
            substep "Google Sans Flex already installed."
        fi

        # Official & AUR fonts
        run ./scripts/install_deps.sh fonts "$CONFIRM_FLAG"
        success "All fonts installed."
    else
        success "Skipped."
    fi

    # 3c. Optional terminal tools
    info "Terminal aesthetic (optional)..."
    choice "1" "kitty     ${C_DIM}- terminal with theme injection${C_RST}"
    choice "2" "fish      ${C_DIM}- interactive shell${C_RST}"
    choice "3" "starship  ${C_DIM}- cross-shell prompt${C_RST}"
    ask "Install optional tools? (y/N)"
    read -r TERM_CHOICE < /dev/tty
    if [[ "$TERM_CHOICE" =~ ^[Yy] ]]; then
        run ./scripts/install_deps.sh optional "$CONFIRM_FLAG"
        success "Optional tools installed."
    else
        success "Skipped."
    fi
else
    success "Skipped."
fi

# 4. Copy dotfiles
info "Copying configuration files..."
choice "1" "All configs  ${C_DIM}(quickshell + hypr + matugen + starship)${C_RST}"
choice "2" "Shell only   ${C_DIM}(quickshell/nandoroid, for power users)${C_RST}"
choice "3" "Skip         ${C_DIM}(copy nothing)${C_RST}"
ask "Copy scope? (1/2/3, default: 1)"
read -r SCOPE_CHOICE < /dev/tty
SCOPE_CHOICE="${SCOPE_CHOICE:-1}"
run mkdir -p "$HOME/.config"

# Timestamped backup so user tweaks survive updates (e.g. edits directly
# under ~/.config/quickshell/nandoroid would otherwise be silently lost).
backup_target() {
    local name="$1"
    if [ -e "$HOME/.config/$name" ]; then
        local dest="$HOME/.config/nandoroid/backups/$(date +%Y%m%d-%H%M%S)/$name"
        if [[ "$DRY_RUN" == "1" ]]; then
            substep "[dry-run] would back up ${C_ACCENT}$name${C_RST} to ${C_DIM}$dest${C_RST}"
        else
            mkdir -p "$(dirname "$dest")"
            cp -r "$HOME/.config/$name" "$dest"
            substep "Backed up existing ${C_ACCENT}$name${C_RST} to ${C_DIM}$dest${C_RST}"
        fi
    fi
}

COPY_GLOB=(dotfiles/.config/*)
if [[ "$SCOPE_CHOICE" == "2" ]]; then
    if [ -e "dotfiles/.config/quickshell" ]; then
        COPY_GLOB=(dotfiles/.config/quickshell)
    else
        substep "${C_YELLOW}quickshell config not found in repo, nothing to copy.${C_RST}"
        COPY_GLOB=()
    fi
elif [[ "$SCOPE_CHOICE" == "3" ]]; then
    COPY_GLOB=()
fi

if [ ${#COPY_GLOB[@]} -eq 0 ]; then
    success "Skipped."
else
for item in "${COPY_GLOB[@]}"; do
    item_name=$(basename "$item")
    
    if [[ "$item_name" == "matugen" ]] && [ -e "$HOME/.config/matugen" ]; then
        if [ -f "$HOME/.config/matugen/config.toml" ] && grep -q "# Nandoroid Configuration" "$HOME/.config/matugen/config.toml"; then
            : # It's ours, let it copy (replace)
        else
            substep "${C_YELLOW}Warning: You already have your own matugen configuration.${C_RST}"
            substep "To use nandoroid config, you can copy from: ${C_ACCENT}$INSTALL_DIR/dotfiles/.config/matugen${C_RST}"
            continue
        fi
    fi
    
    if [[ "$item_name" == "starship.toml" ]] && [ -e "$HOME/.config/starship.toml" ]; then
        if grep -q "# Nandoroid Configuration" "$HOME/.config/starship.toml"; then
            : # It's ours, let it copy
        else
            substep "${C_YELLOW}Warning: You already have your own starship configuration.${C_RST}"
            substep "To use nandoroid config, you can copy from: ${C_ACCENT}$INSTALL_DIR/dotfiles/.config/starship.toml${C_RST}"
            continue
        fi
    fi
    
    backup_target "$item_name"
    run cp -r "$item" "$HOME/.config/"
done
success "Configuration files copied."
fi

# Ensure shell config directory exists
substep "Setting up config directory..."
run mkdir -p "$HOME/.config/nandoroid"

# 5. Nandoroid CLI Installation (Optional)
info "Nandoroid CLI Installation..."
ask "Install Nandoroid CLI for terminal control? (y/N)"
read -r CLI_CHOICE < /dev/tty
if [[ "$CLI_CHOICE" =~ ^[Yy] ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
        substep "[dry-run] would install Nandoroid CLI from GitHub."
    else
        substep "Running CLI installer from GitHub..."
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/na-ive/nandoroid-cli/main/install.sh)"
    fi
    success "Nandoroid CLI installed."
else
    success "Skipped CLI installation."
fi

# 6. Injection
info "Configuration injection..."
substep "Appends settings into your existing configs."
substep "Will ${C_WHITE}${C_BOLD}NOT${C_RST} overwrite existing configurations."
ask "Inject Nandoroid into existing configs? (y/N)"
read -r INJECT_CHOICE < /dev/tty
INJECT=false
if [[ "$INJECT_CHOICE" =~ ^[Yy] ]]; then
    INJECT=true

    # Kitty
    run mkdir -p "$HOME/.config/kitty"
    run touch "$HOME/.config/kitty/kitty.conf"
    if ! grep -q "include current-theme.conf" "$HOME/.config/kitty/kitty.conf"; then
        add_line "$HOME/.config/kitty/kitty.conf" ""
        add_line "$HOME/.config/kitty/kitty.conf" "include current-theme.conf"
        substep "Injected kitty theme include."
    else
        substep "Kitty already injected."
    fi

    # Fish
    run mkdir -p "$HOME/.config/fish"
    run touch "$HOME/.config/fish/config.fish"
    if ! grep -q "starship init fish" "$HOME/.config/fish/config.fish"; then
        add_line "$HOME/.config/fish/config.fish" ""
        add_line "$HOME/.config/fish/config.fish" 'starship init fish | source'
        substep "Injected starship prompt into fish."
    else
        substep "Fish already injected."
    fi

    # Hyprland (needs hypr/nandoroid from step 4; in dry-run it would exist
    # unless the user chose Copy: skip).
    HYPR_MOD_PRESENT=false
    if [ -d "$HOME/.config/hypr/nandoroid" ]; then
        HYPR_MOD_PRESENT=true
    elif [[ "$DRY_RUN" == "1" && "$SCOPE_CHOICE" != "3" ]]; then
        HYPR_MOD_PRESENT=true
    fi
    if [[ "$HYPR_MOD_PRESENT" == "true" ]]; then
        run mkdir -p "$HOME/.config/hypr"
        run touch "$HOME/.config/hypr/hyprland.lua"
        if ! grep -q 'require("nandoroid/nandoroid")' "$HOME/.config/hypr/hyprland.lua"; then
            add_line "$HOME/.config/hypr/hyprland.lua" ""
            add_line "$HOME/.config/hypr/hyprland.lua" 'require("nandoroid/nandoroid")'
            substep "Injected nandoroid config into hyprland."
        fi

        if ! grep -q 'require("nandoroid/user_persistence")' "$HOME/.config/hypr/hyprland.lua"; then
            add_line "$HOME/.config/hypr/hyprland.lua" 'require("nandoroid/user_persistence")'
            substep "Injected user persistence config into hyprland."
        fi

        # Ensure persistence directory and file exist
        run mkdir -p "$HOME/.config/hypr/nandoroid"
        run touch "$HOME/.config/hypr/nandoroid/user_persistence.lua"
    else
        substep "${C_YELLOW}Skipping hypr injection (hypr/nandoroid not installed).${C_RST}"
    fi

    success "Injection complete."
else
    success "Skipped."
fi

# 7. Update Channel
info "Update channel..."
choice "1" "latest  ${C_DIM}- (Recommended) rolling updates, fastest bug fixes${C_RST}"
choice "2" "release ${C_DIM}- milestone updates only, based on git tags${C_RST}"
ask "Preferred channel? [latest/release] (default: latest)"
read -r CHANNEL_CHOICE < /dev/tty
CHANNEL="canary"
if [[ "$CHANNEL_CHOICE" =~ ^[Rr] ]]; then
    CHANNEL="stable"
fi
substep "Selected: ${C_ACCENT}${C_BOLD}$CHANNEL${C_RST}"

# 8. Save State
substep "Saving installation state..."
run mkdir -p "$HOME/.config/nandoroid"
STATE_FILE="$HOME/.config/nandoroid/install_state.json"
if [[ "$DRY_RUN" == "1" ]]; then
    substep "[dry-run] would write $STATE_FILE"
else
cat > "$STATE_FILE" << EOF
{
  "inject": $INJECT,
  "install_dir": "$INSTALL_DIR",
  "channel": "$CHANNEL"
}
EOF
fi
success "State saved."

# Done
finished
substep "Nandoroid Shell is a ${C_WHITE}${C_BOLD}shell${C_RST}, not full dotfiles."
substep "Check ${C_ACCENT}extras/${C_RST} for clean, modular Hyprland and Fish configs."
substep "File pickers / screen sharing require XDG portals."
substep "Make sure ${C_ACCENT}xdg-desktop-portal-hyprland${C_RST} and"
substep "${C_ACCENT}xdg-desktop-portal-gtk${C_RST} are installed."
echo ""
echo -e " ${C_GREEN}${C_BOLD} > ${C_RST}Run ${C_WHITE}${C_BOLD}quickshell -c nandoroid${C_RST} or restart Hyprland."
echo ""
