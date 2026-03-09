# Installation Guide

This guide walks you through installing Nandoroid Shell on a **clean Arch Linux** or **CachyOS** system with Hyprland.

## Important: What This Is (and Isn't)

Nandoroid Shell is a **desktop shell** that provides panels, notifications, OSD, quick settings, and a dynamic island for Hyprland. It is **not** a full dotfiles package.

**What Nandoroid provides:**

- Status bar, dynamic island, notification center
- Quick settings panel (Wi-Fi, Bluetooth, brightness, etc.)
- App launcher and spotlight search
- Settings panel, system monitor, overview
- Lockscreen with media visualization
- OSD for volume, brightness, power modes
- Material 3 theme generation (wallpaper-based colors via Matugen)

**What it does NOT provide:**

- File picker / screen sharing dialogs (you need `xdg-desktop-portal-hyprland` and `xdg-desktop-portal-gtk`, included in dependencies)
- Window manager keybinds (you configure these in `hyprland.conf` yourself)
- Terminal emulator / shell (kitty, fish, starship are optional aesthetic add-ons)
- Full DE environment (file manager, app store, etc.)

## Prerequisites

- **Arch Linux**, **CachyOS**, or any Arch-based distro
- **Hyprland** installed and running as your compositor
- **An AUR helper** (the installer will install `paru` if not found)
- `git`, `curl`, and `base-devel` (for building AUR packages)

## Quick Install

Run this single command to start the interactive installer:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/na-ive/nandoroid-shell/main/install.sh)"
```

The script will prompt you through each step:

### Step 1: Choose Install Location

Default: `~/.local/src/nandoroid`

### Step 2: Install Dependencies

The installer separates dependencies into three groups:

| Group        | Required?   | What's Included                                                                   |
| :----------- | :---------- | :-------------------------------------------------------------------------------- |
| **Core**     | Yes         | Hyprland, Quickshell, Pipewire, NetworkManager, Matugen, CLI tools, Python3, etc. |
| **Fonts**    | Recommended | Google Sans Flex, Material Symbols Rounded, JetBrains Mono NF                     |
| **Terminal** | Optional    | Kitty, Fish, Starship (for themed terminal aesthetic)                             |

> **Note on Python:** The shell uses a Python3 script (`apply_terminal_colors.sh`) to apply dynamic colors to your terminal emulators. Python3 is included in the core dependencies.

### Step 3: Copy Config Files

Copies the required config files to `~/.config/`:

- `quickshell/nandoroid/`: the shell itself
- `matugen/`: template configs for theme generation
- `starship.toml`: prompt config (only useful if starship is installed)

### Step 4: Injection (Optional)

Appends source/include lines to your existing configs (**non-destructive**):

- **Kitty**: Adds `include current-theme.conf` for dynamic Matugen colors
- **Fish**: Adds `starship init fish | source` for the prompt
- **Hyprland**: Creates `~/.config/hypr/nandoroid/nandoroid.conf` and sources it

### Step 5: Update Channel

- **Stable**: Follows git tags (release versions)
- **Canary**: Follows the latest commit on `main`

## Post-Installation

### Start the Shell

```bash
# If injection was done, just restart Hyprland
# Otherwise, start manually:
quickshell -c nandoroid
```

### Environment Portals

For file pickers, screen sharing, and other desktop integration features to work, ensure you have the portals running. These are installed by the dependency step, but you may need to enable them:

```bash
# These should auto-start on Hyprland sessions, but verify:
systemctl --user status xdg-desktop-portal-hyprland
systemctl --user status xdg-desktop-portal-gtk
```

If they're not running:

```bash
systemctl --user enable --now xdg-desktop-portal-hyprland
systemctl --user enable --now xdg-desktop-portal-gtk
```

### Generate Initial Theme

On first launch, the shell will use default colors. To generate your theme:

1. Set a wallpaper through the shell's Quick Settings or Settings panel
2. Matugen will automatically generate Material 3 colors from your wallpaper

## Updating

```bash
# Update everything (shell + matugen templates + starship config)
~/.local/src/nandoroid/update.sh all

# Update shell only (won't touch matugen/starship/hyprland configs)
~/.local/src/nandoroid/update.sh shell
```

The `all` mode uses `cp -r` to overlay new files and will **not** delete your existing configurations. Your personal Hyprland keybinds, fish functions, kitty settings, etc. remain untouched.

## Troubleshooting

| Issue                            | Solution                                                             |
| :------------------------------- | :------------------------------------------------------------------- |
| Icons show as squares/missing    | Install `ttf-material-symbols-variable-git` from AUR                 |
| Font looks wrong / fallback font | Install Google Sans Flex via the install script (cloned from GitHub) |
| No file picker popup             | Ensure `xdg-desktop-portal-gtk` is running                           |
| No screen share dialog           | Ensure `xdg-desktop-portal-hyprland` is running                      |
| Terminal colors not applying     | Check that `python3` is installed                                    |
| Terminal context menu not opening| Ensure `kitty` is installed (default terminal used in context menu)  |
| Audio effects not applying       | Ensure `easyeffects --daemon` is running in background               |
| DND not syncing with events      | Check if "Focus" is enabled for your event in the Dashboard          |
| Shell won't start                | Run `quickshell -c nandoroid` from terminal and check errors         |
