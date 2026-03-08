# Migration Guide: From KDE/GNOME to Nandoroid Shell

This guide helps you transition from a full desktop environment (KDE Plasma, GNOME, etc.) to Hyprland + Nandoroid Shell.

## What Changes

Moving from a DE to Nandoroid means you're replacing the **shell** (panels, notifications, system controls) but keeping much of your existing environment infrastructure.

### What Nandoroid Replaces

| KDE/GNOME Feature               | Nandoroid Equivalent                                       |
| :------------------------------ | :--------------------------------------------------------- |
| Top/bottom panel (taskbar)      | Dynamic Island + Status Bar                                |
| System tray                     | Integrated into Status Bar                                 |
| Notification center             | Notification Center (sidebar with gestures)                |
| Quick settings / control center | Quick Settings panel                                       |
| App launcher / menu             | App Launcher + Spotlight Search                            |
| Volume / brightness OSD         | Custom OSD overlays                                        |
| Lock screen                     | Hyprlock with Nandoroid customization                      |
| Display settings                | Built-in Display Settings (resolution, scale, arrangement) |
| Bluetooth / Wi-Fi settings      | Built-in Quick Settings + Settings panel                   |
| System monitor                  | Built-in System Monitor (dgop-based)                       |

### What Nandoroid Does NOT Replace

These components are provided by your environment/portals, **not** by Nandoroid:

| Feature                    | You Still Need                                                                            |
| :------------------------- | :---------------------------------------------------------------------------------------- |
| **File picker dialog**     | `xdg-desktop-portal-gtk` (or portal of choice)                                            |
| **Screen sharing dialog**  | `xdg-desktop-portal-hyprland`                                                             |
| **File manager**           | Dolphin, Nautilus, Thunar, etc. (your choice)                                             |
| **Text editor / IDE**      | Your existing editor                                                                      |
| **GTK/Qt theming**         | Matugen generates GTK3/GTK4 CSS, but you may want `nwg-look` or `qt6ct` for extra control |
| **Authentication prompts** | Nandoroid includes its own Polkit agent                                                   |
| **Clipboard manager**      | Built into Spotlight (via `wl-clipboard`)                                                 |
| **Screenshot tool**        | Built-in via `grim` + `slurp`                                                             |

## Setup Your Environment

### 1. Install Hyprland

If you haven't already, install and configure Hyprland as your compositor:

```bash
sudo pacman -S hyprland
```

A minimal `~/.config/hypr/hyprland.conf` should include:

- Monitor configuration
- Input settings (keyboard layout, touchpad)
- Your preferred keybinds
- Window rules

> **Tip:** You can keep your existing Hyprland config. The installer creates a separate `nandoroid.conf` file and sources it, so it won't overwrite your keybinds or rules.

### 2. Portal Setup

This is critical. Without portals, file pickers and screen sharing won't work:

```bash
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

Add to your `hyprland.conf` (or let the Nandoroid installer do it):

```ini
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
```

Verify they're running after login:

```bash
systemctl --user status xdg-desktop-portal-hyprland
systemctl --user status xdg-desktop-portal-gtk
```

### 3. Install Nandoroid

Run the installer:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/na-ive/nandoroid-shell/main/install.sh)"
```

When prompted:

- **Core deps**: Yes (required)
- **Fonts**: Yes (recommended, the shell looks broken without them)
- **Terminal tools**: Your choice (kitty/fish/starship are for terminal aesthetics)
- **Injection**: Yes if you want Nandoroid to add `exec-once = quickshell -c nandoroid` and theme includes

### 4. Migrate Your Keybinds

Nandoroid uses IPC calls for its panels. Add these to your `hyprland.conf`:

```ini
# Nandoroid Shell Controls
bind = SUPER, Space, exec, qs -c nandoroid ipc call launcher toggle
bind = SUPER, N, exec, qs -c nandoroid ipc call notifications toggle
bind = SUPER, A, exec, qs -c nandoroid ipc call quicksettings toggle
bind = SUPER, M, exec, qs -c nandoroid ipc call systemmonitor toggle
bind = SUPER, Tab, exec, qs -c nandoroid ipc call overview toggle

# Brightness (repeatable)
bindle = , XF86MonBrightnessUp, exec, qs -c nandoroid ipc call brightness increment
bindle = , XF86MonBrightnessDown, exec, qs -c nandoroid ipc call brightness decrement

# Quickshell Global Shortcuts
bindd = SUPER, V, Clipboard history, global, quickshell:spotlightClipboard
bindd = SUPER, E, Emoji picker, global, quickshell:spotlightEmoji
bindd = SUPER, S, Region screenshot, global, quickshell:regionScreenshot
bindd = SUPER SHIFT, S, Region OCR, global, quickshell:regionOcr
bindd = SUPER, R, Record region, global, quickshell:regionRecord
```

See the [IPC Commands](../README.md#ipc-commands) section for the full list.

## Coming from KDE Specifically

If you're migrating from KDE Plasma on Hyprland:

1. **Remove KDE autostart entries** that conflict (plasmashell, kwin, etc.)
2. **Keep `qt6ct`** if you use it for Qt app theming. Matugen generates colors that work alongside it
3. **Dolphin** continues to work as your file manager
4. **KDE Connect** is independent and still works

## Coming from GNOME Specifically

If you're migrating from GNOME:

1. **Portal**: Switch from `xdg-desktop-portal-gnome` to `xdg-desktop-portal-gtk` (the GTK portal works on Hyprland, the GNOME one doesn't)
2. **Nautilus/Files** continues to work as your file manager
3. **GNOME extensions** are not applicable. Nandoroid provides equivalent shell features

## What About Updates?

When you update Nandoroid, your personal configs stay safe:

- `update.sh shell`: Only updates `~/.config/quickshell/nandoroid/` (the shell itself)
- `update.sh all`: Also updates matugen templates and starship config

Neither mode deletes or overwrites your Hyprland keybinds, fish functions, kitty settings, or any other personal configuration files.

## Troubleshooting

| Symptom                      | Likely Cause            | Fix                                               |
| :--------------------------- | :---------------------- | :------------------------------------------------ |
| No file picker when saving   | Missing portal          | Install and enable `xdg-desktop-portal-gtk`       |
| Screen share shows no dialog | Missing Hyprland portal | Install and enable `xdg-desktop-portal-hyprland`  |
| Old KDE panel showing up     | Plasma still running    | Remove `plasmashell` from autostart               |
| GTK apps look unstyled       | No GTK theme applied    | Matugen auto-generates GTK CSS, or use `nwg-look` |
| Terminal context menu not opening| Required terminal missing| Ensure `kitty` is installed (default terminal)    |
| Icons missing in shell       | Font not installed      | Install `ttf-material-symbols-variable-git`       |
