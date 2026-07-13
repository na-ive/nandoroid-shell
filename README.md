<div align="center">

# 【 NAnDoroid-shell 】

[![Last Commit](https://img.shields.io/github/last-commit/na-ive/nandoroid-shell?style=for-the-badge&logo=git&color=8bd5ca&logoColor=D9E0EE&labelColor=303446)](https://github.com/na-ive/nandoroid-shell/commits/main)
[![Stars](https://img.shields.io/github/stars/na-ive/nandoroid-shell?style=for-the-badge&logo=github&color=c6a0f6&logoColor=D9E0EE&labelColor=303446)](https://github.com/na-ive/nandoroid-shell/stargazers)
[![Repo Size](https://img.shields.io/github/repo-size/na-ive/nandoroid-shell?style=for-the-badge&logo=folder&color=8caaee&logoColor=D9E0EE&labelColor=303446)](https://github.com/na-ive/nandoroid-shell)
[![Tako Support](https://img.shields.io/badge/SUPPORT-TAKO-FF69B4?style=for-the-badge&logo=kofi&logoColor=white&labelColor=555555)](https://tako.id/naive)

A Quickshell-based desktop shell for Hyprland adopting Android 16 design elements.

</div>

> **Note**: This shell and its dependencies are designed strictly for **Arch Linux based distributions** (Arch, CachyOS, EndeavourOS, etc.).

**Version:** v1.4.0
**License:** AGPL-3.0

## Key Features

- **Universal Dynamic Island:** Displays media playback indicators, workspace switching, pomodoro timers, and popup notifications inside a single central notch.
- **Deep Customizability:** Extensive personalization options (clocks, lockscreen visuals, UI sizing) accessible directly via the built-in Settings panel.
- **Auto-generated Colors:** Entire shell theme dynamically generated from your wallpaper's colors using Material 3 design tokens (via Matugen).
- **Online Wallpaper Collections:** Browse and apply wallpapers from Wallhaven and personal GitHub collections directly from the shell.
- **...and So Much More:** Dive into a seamless ecosystem packed with built-in OCR tools, smart screen recording, intuitive system monitors, and countless micro-interactions crafted to elevate your desktop experience.

## Screenshots

|                                  Stacked Clock & Centered Bar                                 |                                  Dynamic Island & Spotlight                                   |
| :-------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------: |
| <img src="https://github.com/user-attachments/assets/2f2aab8c-5420-43e1-b5da-dfe3a7f014d1" /> | <img src="https://github.com/user-attachments/assets/58850360-0ca7-4b0b-9fb1-19008abb51b8" /> |
|                                 **Settings & System Monitor**                                 |                                    **Minimal Lockscreen**                                     |
| <img src="https://github.com/user-attachments/assets/952f0c90-28a2-46a1-9bd2-f12a995893bd" /> | <img src="https://github.com/user-attachments/assets/3685b0fc-92d3-4182-9134-3e10d1469d7b" /> |
<details>
<summary><b>View More Panel Previews</b></summary>
<br>

|                                   **Notification Center**                                     |                                      **Quick Settings**                                       |
| :-------------------------------------------------------------------------------------------: | :-------------------------------------------------------------------------------------------: |
| <img src="https://github.com/user-attachments/assets/bf4dd19e-848c-4fde-b214-9900058c8c69" /> | <img src="https://github.com/user-attachments/assets/09d8322d-d27f-44ab-ac5c-e75353f20d22" /> |
|                                  **Spotlight Launcher**                                       |                                    **App Grid Launcher**                                      |
| <img src="https://github.com/user-attachments/assets/12ef3312-c6a8-475c-8c5f-5326c4573e87" /> | <img src="https://github.com/user-attachments/assets/f84d3ef5-5bfe-4291-bf60-41bf01cfb7d9" /> |
|                                       **Dashboard**                                           |                                      **Workspace Overview**                                   |
| <img src="https://github.com/user-attachments/assets/7ef022bd-4f7a-446f-be19-35e740e45058" /> | <img src="https://github.com/user-attachments/assets/b79e0d26-5fb2-4da4-ab62-675de7c05835" /> |
|                                   **Nandoroid Settings**                                      |                                       **System Monitor**                                      |
| <img src="https://github.com/user-attachments/assets/60462d4c-f6fe-4e4e-bee3-8cdea03473d4" /> | <img src="https://github.com/user-attachments/assets/12368d1e-b831-480d-8c6c-bbd16bd27750" /> |
|                                       **Smart Dock**                                          |                                     **Quick Actions HUD**                                     |
| <img src="https://github.com/user-attachments/assets/37ceff8d-597d-4459-8af6-cee1c4f30286" /> | <img src="https://github.com/user-attachments/assets/b3eb7522-b7a4-4135-8f8f-bd95b710b399" /> |

</details>

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
| **GTK Theme** | `adw-gtk-theme` | Libadwaita-like theme for GTK3 applications. |
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
| **Wallpaper Eng.** | `linux-wallpaperengine-git` | Steam Wallpaper Engine support (Optional). |
| **Effects** | `easyeffects` | Audio effects and equalization management. |
| **Picker** | `hyprpicker` | System-wide color picker tool. |
| **Lock** | `hyprlock` | The lock screen provider. |
| **Night Light** | `hyprsunset` | Blue light filter functionality. |
| **Search** | `fd` | Fast file search functionality in Spotlight. |
| **Calculator** | `libqalculate` | Math calculator functionality in Spotlight (`qalc`). |
| **Dialogs** | `zenity` | File and directory selection dialogs. |
| **QR Scan** | `zbar` | QR code scanning functionality (`zbarimg`). |
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
- **`extras/`**: Clean base configurations for Hyprland and Fish, including essential environment variables for dynamic theming.
- **`nandoroid-cli`**: (Optional) A powerful command-line interface to control shell panels, media, and system settings. Available at [na-ive/nandoroid-cli](https://github.com/na-ive/nandoroid-cli).

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
| **Sys. Monitor (Direct)**| `systemmonitor` | `open_direct`| `qs -c nandoroid ipc call systemmonitor open_direct`|
| **Overview Panel**      | `overview`      | `toggle` | `qs -c nandoroid ipc call overview toggle`      |
| **Session (Power)**     | `session`       | `toggle` | `qs -c nandoroid ipc call session toggle`       |
| **Dashboard**           | `dashboard`     | `toggle` | `qs -c nandoroid ipc call dashboard toggle`     |
| **Quick Actions**       | `quickactions`  | `toggle` | `qs -c nandoroid ipc call quickactions toggle`  |
| **Nandoroid Settings**  | `settings`      | `toggle` | `qs -c nandoroid ipc call settings toggle`      |
| **Settings (Direct)**   | `settings`      | `open_direct`| `qs -c nandoroid ipc call settings open_direct` |

### Region Tools (Screenshots & Recording)

Trigger selection-based actions.

| Action                | Target   | Method            | Terminal Command                                  |
| :-------------------- | :------- | :---------------- | :------------------------------------------------ |
| **Region Screenshot** | `region` | `screenshot`      | `qs -c nandoroid ipc call region screenshot`      |
| **Visual Search**     | `region` | `search`          | `qs -c nandoroid ipc call region search`          |
| **Text OCR**          | `region` | `ocr`             | `qs -c nandoroid ipc call region ocr`             |
| **QR Code Scan**      | `region` | `qrcode`          | `qs -c nandoroid ipc call region qrcode`          |
| **Record Region**     | `region` | `record`          | `qs -c nandoroid ipc call region record`          |
| **Record w/ Audio**   | `region` | `recordWithSound` | `qs -c nandoroid ipc call region recordWithSound` |

### Media & System

Control specific system services.

| Feature              | Target       | Method        | Terminal Command                                 |
| :------------------- | :----------- | :------------ | :----------------------------------------------- |
| **Brightness +**     | `brightness` | `increment`   | `qs -c nandoroid ipc call brightness increment`  |
| **Brightness -**     | `brightness` | `decrement`   | `qs -c nandoroid ipc call brightness decrement`  |
| **Pomodoro Start**   | `pomodoro`   | `start`       | `qs -c nandoroid ipc call pomodoro start`        |
| **Pomodoro Pause**   | `pomodoro`   | `pause`       | `qs -c nandoroid ipc call pomodoro pause`        |
| **Pomodoro Stop**    | `pomodoro`   | `stop`        | `qs -c nandoroid ipc call pomodoro stop`         |
| **Pomodoro Reset**   | `pomodoro`   | `reset`       | `qs -c nandoroid ipc call pomodoro reset`        |
| **Wallpaper (Home)** | `wallpaper`  | `openDesktop` | `qs -c nandoroid ipc call wallpaper openDesktop` |
| **Wallpaper (Lock)** | `wallpaper`  | `openLock`    | `qs -c nandoroid ipc call wallpaper openLock`    |
| **Change Avatar**    | `spotlight`  | `browse_avatar`| `qs -c nandoroid ipc call spotlight browse_avatar`|

### Global Shortcuts (Native Quickshell)

Nandoroid uses native Quickshell Global Shortcuts for specialized tool operations. These are triggered using the `global` dispatcher in Hyprland with the format `quickshell:<name>`.

| Shortcut Name           | Description                      | Hyprland Lua Bind Example                                                                  |
| :---------------------- | :------------------------------- | :----------------------------------------------------------------------------------------- |
| `spotlightFiles`        | Open Spotlight in File search    | `hl.bind("SUPER + F", hl.dsp.global("quickshell:spotlightFiles"))`                         |
| `spotlightCommand`      | Open Spotlight in Quick Commands | `hl.bind("SUPER + G", hl.dsp.global("quickshell:spotlightCommand"))`                       |
| `spotlightTools`        | Open Spotlight in Tools mode     | `hl.bind("SUPER + T", hl.dsp.global("quickshell:spotlightTools"))`                         |
| `spotlightClipboard`    | Open Spotlight in Clipboard mode | `hl.bind("SUPER + V", hl.dsp.global("quickshell:spotlightClipboard"))`                     |
| `spotlightEmoji`        | Open Spotlight in Emoji mode     | `hl.bind("SUPER + E", hl.dsp.global("quickshell:spotlightEmoji"))`                         |
| `quickActions`          | Toggle Quick Actions HUD         | `hl.bind("SUPER + X", hl.dsp.global("quickshell:quickActions"))`                           |
| `regionScreenshot`      | Capture selected region          | `hl.bind("SUPER + S", hl.dsp.global("quickshell:regionScreenshot"))`                       |
| `regionOcr`             | Extract text from region         | `hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionOcr"))`                      |
| `regionSearch`          | Visual search from region        | `hl.bind("SUPER + Z", hl.dsp.global("quickshell:regionSearch"))`                           |
| `regionQRCode`          | Scan QR code from region         | `hl.bind("SUPER + SHIFT + Z", hl.dsp.global("quickshell:regionQRCode"))`                   |
| `regionRecord`          | Record selected region           | `hl.bind("SUPER + R", hl.dsp.global("quickshell:regionRecord"))`                           |
| `regionRecordWithSound` | Record region with audio         | `hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecordWithSound"))`          |

</details>

## Credits

### Core Framework

- **[Quickshell](https://github.com/outfoxxed)** - The QML-based framework powering this shell environment.

### Design References & Special Thanks

This project is a personal creation heavily inspired by the following developers and their repositories:

- **[end-4](https://github.com/end-4)** - Architecture and shell logic inspired by [dots-hyprland](https://github.com/end-4/dots-hyprland).
- **[pC](https://github.com/pctrade)** - Design and layout references from [end4-pC](https://github.com/pctrade/end4-pC).
- **[vaguesyntax (Vynx)](https://github.com/vaguesyntax)** - Design and layout references from [ii-vynx](https://github.com/vaguesyntax/ii-vynx).
- **[AvengeMedia](https://github.com/AvengeMedia)** - System monitoring logic from [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) and [dgop](https://github.com/AvengeMedia/dgop).
- **[Axenide](https://github.com/Axenide)** - Notch concept and spatial references from [Ambxst](https://github.com/Axenide/Ambxst).

### Assets

- **Weather Icons:** Sourced from [mrdarrengriffin/google-weather-icons](https://github.com/mrdarrengriffin/google-weather-icons).
