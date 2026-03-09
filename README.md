# NAnDoroid-shell

A Quickshell-based desktop shell for Hyprland adopting Android 16 design elements.

> **Note**: This shell and its dependencies are designed strictly for **Arch Linux based distributions** (Arch, CachyOS, EndeavourOS, etc.).

**Version:** v1.1
**License:** AGPL-3.0

## Key Features

- **Universal Dynamic Island:** Displays media playback indicators, workspace switching, pomodoro timers, and popup notifications inside a single central notch.
- **Deep Customizability:** Extensive personalization options (clocks, lockscreen visuals, UI sizing) accessible directly via the built-in Settings panel.
- **Auto-generated Colors:** Entire shell theme dynamically generated from your wallpaper's colors using Material 3 design tokens (via Matugen).

## Screenshots

|                                  Desktop with stacked clock                                   |                                  Settings and System monitor                                  |
| :-------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------: |
| <img src="https://github.com/user-attachments/assets/34d9e88e-dcf7-4916-9797-38b6429dfbae" /> | <img src="https://github.com/user-attachments/assets/ea81d8aa-ecf0-4fd8-8d23-3619f01a35f7" /> |
|                                      **Quick Settings**                                       |                                    **Notification Center**                                    |
| <img src="https://github.com/user-attachments/assets/35d98451-e5d3-44ad-9872-8efc4394ff1c" /> | <img src="https://github.com/user-attachments/assets/b968526c-f6e8-4220-8dd9-0acb86a3dc0c" /> |

## Installation

> **Nandoroid Shell is a _shell_, not a full dotfiles package.** It replaces your desktop panels, notifications, and system controls, but does not provide file pickers, screen sharing dialogs, or a file manager. See the guides below for details.

### Quick Install

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/na-ive/nandoroid-shell/main/install.sh)"
```

The interactive installer guides you through dependency installation, config copying, and optional injection into your existing Hyprland/Kitty/Fish setup.

- **[Installation Guide (Clean Arch/CachyOS)](docs/INSTALL.md)**: Step-by-step from a fresh system
- **[Migration Guide (from KDE/GNOME)](docs/MIGRATION.md)**: What gets replaced, portal setup, keybind migration

## Requirements & Dependencies

<details>
<summary>Click to view full dependency list</summary>

### Core Components

- **Hyprland**: The tiling Wayland compositor that hosts the shell.
- **Quickshell (0.5.0+)**: The engine used to build and run the shell.
- **Qt 6**: The base framework for the UI (QtQuick, Qt Background, etc.).
- **Python 3**: Used by the terminal color application script.

### System Services & Protocols

- **Pipewire**: For audio management.
- **NetworkManager (`nmcli`)**: For Wi-Fi and Ethernet controls.
- **BlueZ (`bluetoothctl`)**: For Bluetooth management.
- **libnotify (`notify-send`)**: For system notifications and temporary popups.
- **Polkit (`pkexec`)**: For privileged actions (like password recovery).
- **Systemd (`systemctl`)**: For power management (suspend, etc.).
- **xdg-desktop-portal-hyprland**: For screen sharing dialogs.
- **xdg-desktop-portal-gtk**: For file picker dialogs.

### CLI Utilities (Functional)

- **dgop**: Essential for system monitoring, CPU, RAM, and temperature stats.
- **brightnessctl**: For controlling screen backlight.
- **ddcutil**: For controlling external monitor brightness.
- **playerctl**: For media playback (MPRIS) controls.
- **matugen**: Crucial for Material 3 theme generation from wallpapers.
- **grim**: For taking screenshots and color detection.
- **slurp**: For region selection (screenshots, recording, OCR).
- **wf-recorder**: For screen recording functionality.
- **ImageMagick (`magick`)**: Used for color detection, resizing, and image processing.
- **ffmpeg (`ffplay`)**: Used for system sounds.
- **wl-clipboard**: For Wayland clipboard operations.
- **songrec**: Required for the Shazam-like music recognition feature.
- **cava**: Used for audio visualization in the shell.
- **easyeffects**: For audio effects and equalization management.
- **hyprpicker**: For the color picker tool.
- **hyprlock**: The lock screen provider.
- **hyprsunset**: For the blue light filter (night light) functionality.
- **fd**: Required for the file search functionality in Spotlight/Launcher.
- **libqalculate (`qalc`)**: Required for the math calculator functionality in Spotlight/Launcher.
- **jq**: For parsing and generating JSON (configs and state files).
- **xdg-utils (`xdg-open`)**: For opening URLs and files in external apps.
- **warp-cli** _(Optional)_: Cloudflare WARP client for VPN integration.

### Fonts

- **Google Sans Flex** (from [GitHub](https://github.com/end-4/google-sans-flex)): The primary variable font for the interface.
- **Material Symbols Rounded** (`ttf-material-symbols-variable-git`): The icon font for all system symbols.
- **JetBrains Mono NF** (`ttf-jetbrains-mono-nerd`): The default monospace font.

### Shell & Terminal _(Optional)_

These are not required for the shell to function, but enhance the terminal experience with dynamic Matugen colors:

- **kitty**: Terminal emulator with theme injection support.
- **fish**: Interactive shell.
- **starship**: Cross-shell prompt.
- **bash / awk / grep / cut / sed**: Standard Unix utilities utilized by core scripts _(required)_.

</details>

## Configuration

The `.config/` directory distributed with this repository contains necessary supplementary configurations:

- **`quickshell/nandoroid/`**: The shell itself
- **`matugen/`**: Template configs for Material 3 theme generation
- **`starship.toml`**: Prompt configuration (requires starship)
- **`fish/completions/nandoroid.fish`**: Tab-completion for IPC commands in fish shell

## IPC Commands

<details>
<summary>Click to view IPC commands & Keybinds</summary>

The basic syntax for calling a command via terminal is:

```bash
qs -c nandoroid ipc call <target> <method>
```

_(Note: `qs` is an alias for `quickshell`. Replace it if you use the full command.)_

### Sidebar & Panels

Manage the visibility of all UI panels.

| Feature                 | Target          | Method   | Terminal Command                                |
| :---------------------- | :-------------- | :------- | :---------------------------------------------- |
| **App Launcher**        | `launcher`      | `toggle` | `qs -c nandoroid ipc call launcher toggle`      |
| **Spotlight Search**    | `spotlight`     | `toggle` | `qs -c nandoroid ipc call spotlight toggle`     |
| **Notification Center** | `notifications` | `toggle` | `qs -c nandoroid ipc call notifications toggle` |
| **Quick Settings**      | `quicksettings` | `toggle` | `qs -c nandoroid ipc call quicksettings toggle` |
| **System Monitor**      | `systemmonitor` | `toggle` | `qs -c nandoroid ipc call systemmonitor toggle` |
| **Overview Panel**      | `overview`      | `toggle` | `qs -c nandoroid ipc call overview toggle`      |
| **Session (Power)**     | `session`       | `toggle` | `qs -c nandoroid ipc call session toggle`       |
| **Dashboard**           | `dashboard`     | `toggle` | `qs -c nandoroid ipc call dashboard toggle`     |
| **Nandoroid Settings**  | `settings`      | `toggle` | `qs -c nandoroid ipc call settings toggle`      |

### Region Tools (Screenshots & Recording)

Trigger selection-based actions.

| Action                | Target   | Method            | Terminal Command                                  |
| :-------------------- | :------- | :---------------- | :------------------------------------------------ |
| **Region Screenshot** | `region` | `screenshot`      | `qs -c nandoroid ipc call region screenshot`      |
| **Visual Search**     | `region` | `search`          | `qs -c nandoroid ipc call region search`          |
| **Text OCR**          | `region` | `ocr`             | `qs -c nandoroid ipc call region ocr`             |
| **Record Region**     | `region` | `record`          | `qs -c nandoroid ipc call region record`          |
| **Record w/ Audio**   | `region` | `recordWithSound` | `qs -c nandoroid ipc call region recordWithSound` |

### Media & System

Control specific system services.

| Feature              | Target       | Method        | Terminal Command                                 |
| :------------------- | :----------- | :------------ | :----------------------------------------------- |
| **Brightness +**     | `brightness` | `increment`   | `qs -c nandoroid ipc call brightness increment`  |
| **Brightness -**     | `brightness` | `decrement`   | `qs -c nandoroid ipc call brightness decrement`  |
| **Pomodoro Start**   | `pomodoro`   | `start`       | `qs -c nandoroid ipc call pomodoro start`        |
| **Wallpaper (Home)** | `wallpaper`  | `openDesktop` | `qs -c nandoroid ipc call wallpaper openDesktop` |
| **Wallpaper (Lock)** | `wallpaper`  | `openLock`    | `qs -c nandoroid ipc call wallpaper openLock`    |

### Global Shortcuts (Native Quickshell)

Nandoroid uses native Quickshell Global Shortcuts for specialized tool operations. These are triggered using the `global` dispatcher in Hyprland with the format `quickshell:<name>`.

| Shortcut Name           | Description                      | Hyprland Bind Example                                                                      |
| :---------------------- | :------------------------------- | :----------------------------------------------------------------------------------------- |
| `spotlightFiles`        | Open Spotlight in File search    | `bindd = SUPER, F, File search, global, quickshell:spotlightFiles`                         |
| `spotlightCommand`      | Open Spotlight in Quick Commands | `bindd = SUPER, G, Quick commands, global, quickshell:spotlightCommand`                     |
| `spotlightClipboard`    | Open Spotlight in Clipboard mode | `bindd = SUPER, V, Clipboard history, global, quickshell:spotlightClipboard`               |
| `spotlightEmoji`        | Open Spotlight in Emoji mode     | `bindd = SUPER, E, Emoji picker, global, quickshell:spotlightEmoji`                        |
| `regionScreenshot`      | Capture selected region          | `bindd = SUPER, S, Region screenshot, global, quickshell:regionScreenshot`                 |
| `regionOcr`             | Extract text from region         | `bindd = SUPER SHIFT, S, Region OCR, global, quickshell:regionOcr`                         |
| `regionSearch`          | Visual search from region        | `bindd = SUPER, Z, Visual search, global, quickshell:regionSearch`                         |
| `regionRecord`          | Record selected region           | `bindd = SUPER, R, Record region, global, quickshell:regionRecord`                         |
| `regionRecordWithSound` | Record region with audio         | `bindd = SUPER SHIFT, R, Record region w/ audio, global, quickshell:regionRecordWithSound` |

</details>

## Credits

### Core Framework

- **[Quickshell](https://github.com/outfoxxed)** - The QML-based framework powering this shell environment.

### Design References & Special Thanks

This project is a personal creation heavily inspired by the following developers and their repositories:

- **[end-4](https://github.com/end-4)** - Architecture and shell logic inspired by [dots-hyprland](https://github.com/end-4/dots-hyprland).
- **[vaguesyntax (Vynx)](https://github.com/vaguesyntax)** - Quickshell translation references from [ii-vynx](https://github.com/vaguesyntax/ii-vynx).
- **[AvengeMedia](https://github.com/AvengeMedia)** - System monitoring logic from [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [dgop](https://github.com/AvengeMedia/dgop).
- **[Axenide](https://github.com/Axenide)** - Notch concept and spatial references from [Ambxst](https://github.com/Axenide/Ambxst) (AGPL-3.0).

### Assets

- **Weather Icons:** Sourced from [mrdarrengriffin/google-weather-icons](https://github.com/mrdarrengriffin/google-weather-icons).
  - _Disclaimer: These icons are property of Google. Used here for aesthetic purposes in this community project._
