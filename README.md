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

| Component | Package | Description |
| :--- | :--- | :--- |
| **Compositor** | `hyprland` | The tiling Wayland compositor hosting the shell. |
| **Framework** | `quickshell` | The engine (0.5.0+) used to build and run the shell. |
| **Monitor** | `dgop` | System monitoring (CPU, RAM, Temp) stats. |
| **Theme** | `matugen` | Material 3 theme generation from wallpapers. |
| **Scripting** | `python3` | Used by terminal color scripts and utilities. |
| **JSON** | `jq` | Command-line JSON processor for configs and state. |

### System Services & Protocols

| Service | Command | Description |
| :--- | :--- | :--- |
| **Audio** | `pipewire` | Audio management via `wpctl`. |
| **Network** | `networkmanager` | Wi-Fi and Ethernet controls via `nmcli`. |
| **Bluetooth** | `bluez` | Bluetooth management via `bluetoothctl`. |
| **Notify** | `libnotify` | System notifications via `notify-send`. |
| **Auth** | `polkit` | Privileged actions via `pkexec`. |
| **Session** | `systemd` | Power management and session locking. |
| **Portal (H)** | `xdg-desktop-portal-hyprland` | Screen sharing and desktop integration. |
| **Portal (G)** | `xdg-desktop-portal-gtk` | File picker and standard desktop integration. |

### CLI Utilities (Functional)

| Utility | Command | Description |
| :--- | :--- | :--- |
| **Backlight** | `brightnessctl` | Internal screen brightness control. |
| **External Br.** | `ddcutil` | External monitor brightness control. |
| **Media** | `playerctl` | MPRIS media playback controls. |
| **Screenshot** | `grim` | Wayland screenshot utility. |
| **Region** | `slurp` | Region selection for screenshots/recording. |
| **Recorder** | `wf-recorder` | Screen recording functionality. |
| **Image** | `imagemagick` | Color detection and image processing (`magick`). |
| **Sound** | `ffmpeg` | System sounds playback via `ffplay`. |
| **Clipboard** | `wl-clipboard` | Wayland clipboard operations. |
| **Clip. Hist.** | `cliphist` | Clipboard history management in Spotlight. |
| **Recognition** | `songrec` | Shazam-like music recognition feature. |
| **Visualizer** | `cava` | Audio visualization in the shell. |
| **Effects** | `easyeffects` | Audio effects and equalization management. |
| **Picker** | `hyprpicker` | System-wide color picker tool. |
| **Lock** | `hyprlock` | The lock screen provider. |
| **Night Light** | `hyprsunset` | Blue light filter functionality. |
| **Search** | `fd` | Fast file search functionality in Spotlight. |
| **Calculator** | `libqalculate` | Math calculator functionality in Spotlight (`qalc`). |
| **Dialogs** | `zenity` | File and directory selection dialogs. |
| **OCR (Opt.)** | `tesseract` | OCR functionality in region tools. |
| **Biometric (Opt.)** | `fprintd` | Fingerprint sensor support on lockscreen. |
| **VPN (Opt.)** | `warp-cli` | Cloudflare WARP client integration. |

### Fonts

| Font | Package | Source / Purpose |
| :--- | :--- | :--- |
| **UI Font** | `Google Sans Flex` | Primary variable font (from GitHub). |
| **Icons** | `ttf-material-symbols-variable-git` | Material Symbols icon font. |
| **Monospace** | `ttf-jetbrains-mono-nerd` | Default monospace and nerd font. |

### Shell & Terminal (Optional)

| Tool | Package | Purpose |
| :--- | :--- | :--- |
| **Terminal** | `kitty` | Terminal emulator with theme injection support. |
| **Shell** | `fish` | Interactive shell. |
| **Prompt** | `starship` | Cross-shell prompt. |
| **Utils** | `bash`, `awk`, `grep` | Standard Unix utilities used by core scripts. |

</details>

## Configuration

The `.config/` directory distributed with this repository contains necessary supplementary configurations:

- **`quickshell/nandoroid/`**: The shell itself.
- **`matugen/`**: Template configs for Material 3 theme generation.
- **`starship.toml`**: Prompt configuration (requires starship).
- **`fish/completions/nandoroid.fish`**: Tab-completion for IPC commands in fish shell. *(Note: Currently under development and may not be fully functional yet; evolving alongside nandoroid-cli)*.

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
