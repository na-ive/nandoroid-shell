# Nandoroid Shell v1.2 Release Notes

## Overview
This update focuses on significant performance enhancements, massive stability improvements, a fully integrated auto-hiding Dock, and a variety of visual refinements across the shell. Memory leaks have been patched, system dependencies have been streamlined, and the UI has been polished to adhere closer to Material Design 3 guidelines.

## Changelog

**Dock Implementation**
- Add fully integrated dock with auto-hide functionality
- Implement hover reveals, single-window previews, and tactile click effects
- Add premium context menus featuring Jump Lists for quick actions
- Replace fixed height constraints with proportional scaling for different screens

**Status Bar & Dynamic Island**
- Implement Centered Layout (HUD) mode optimized for ultrawide monitors
- Add true adaptive coloring for all sub-widgets based on background wallpaper
- Implement lightweight Waterdrop style and balanced media 'ear' widths for the Dynamic Island
- Add support for auto-hide status bar with precise hover detection

**System Monitor**
- Redesign the System Monitor panel with a clean Android-style aesthetic
- Integrate real-time CPU, RAM, GPU, and Storage tracking with smooth animations
- Add per-core frequency and temperature monitoring

**Notifications & Settings**
- Refine Notification system UI/UX with smooth dismissal and reliable memory management
- Implement "Pull or Close" logic for Settings and System Monitor panels
- Restructure On-Screen Displays (OSD) and fix rendering artifacts

**Theming & Visuals**
- Add automatic KDE/Qt theming integration alongside standard GTK theming
- Integrate subtle ambient shadows, MD3 outlines, and tonal scrim backdrops
- Add Roman numeral clock style and pulse charging animations
- Consolidate color logic to synchronize panels (e.g., MediaNotchPopup slider colors match MediaCard)

**Other Additions**
- Add modular Hyprland and Fish configurations to `extras/`
- Introduce optional `nandoroid-cli` for streamlined terminal control
- Transition away from legacy fish completions
- Implement per-app volume control and translation tooltips within the Dashboard

## Dependency Updates
- **Added:** `adw-gtk-theme` (replaces adw-gtk3), `qt5ct`, `qt6ct`, `nwg-look`, `plasma-integration`, `breeze`, `breeze-icons`
- **Optional:** `nandoroid-cli` (GitHub installer added to `install.sh`)


# Nandoroid Shell v1.2.1 Release Notes

## Overview
This maintenance update introduces an expandable system tray with multiple styles, restores core Overview functionality, and focuses on cleaning up internal QML warnings to improve shell performance and reliability.

## Changelog

**Status Bar & System Tray**
- Implement expandable system tray with pop-up overflow
- Add three tray display modes: 'All', 'Adaptive' (show max 3 icons), and 'Hide'
- Integrate tray style selection into Status Bar settings

**Overview & Workspace**
- Restore standard grid window layout and fix drag-and-drop logic
- Refine centering math for workspace previews
- Prevent accidental panel closure when interacting with workspace cards

**System Stability & Fixes**
- Resolve numerous QML warnings related to missing icons and shader effects
- Improve Brave Browser icon resolution with additional fallback logic
- Fix appearance property references and refine the shell restart script
- Fix Image Search (Google Lens) reliability by improving URL handling and preventing browser download prompts

**Dashboard & Productivity**
- Clean up HTML tags in Notepad summaries to prevent empty list items in the sidebar
- Improve reliability of image uploads for search functions
