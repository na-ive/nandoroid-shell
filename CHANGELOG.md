# Nandoroid Shell v1.6.0 Release Notes

## Overview
Nandoroid Shell v1.6.0 is a major update focused on language access, daily productivity, and visual consistency. The shell is now fully translated into Indonesian and English, the Dashboard receives a complete Clock, Alarm, and Schedule revamp, and Settings has been reworked page by page for a more consistent feel. It also introduces the pC Dynamic Island, video wallpaper support, and a redesigned update experience.

## Changelog

**Language Support**
- Add complete English and Indonesian translations across the whole shell
- Add in-app language switcher with instant reload, no restart needed

**Dashboard, Clock & Alarm**
- Redesign Schedule as a simple today timeline with an event editor and reminders
- Add square cell calendar with a live schedule summary
- Add Clock suite with stopwatch, timer, and pomodoro, wired into the Dynamic Island
- Add Alarm tab with snooze, custom ringtone, repeat presets, per day scheduling, and visible alarm names on each card
- Rework Todo into a kanban board with drag and drop, plus a cleaner Notepad
- Redesign Translate view with side by side cards, smarter language swap, and romaji and pinyin transliteration

**Dynamic Island & Status Bar**
- Introduce pC Dynamic Island with idle info, timers, media, and notifications
- Mirror island status onto the lockscreen pill while the session is locked
- Add date and distro uptime on island hover, with newest notification focus
- Add random material shapes for the workspace indicator and full width wave

**Launcher, Dock & Overview**
- Add emoji picker grid with recents and keyboard navigation
- Add settings search, wallpaper and color sub commands, and quick system toggles
- Improve clipboard history with wide preview, search, and item deletion
- Add dual mode dock previews with live thumbnails and compact list
- Add Niri style vertical overview layout

**Wallpaper & Visuals**
- Add video wallpaper support through mpvpaper with per target desktop and lockscreen
- Separate desktop and lockscreen wallpaper commands and shortcuts
- Add selectable wallpaper transitions, including random material shapes
- Add desktop visualizer styles with bars, mirror, aurora, and dots options
- Rework weather card animations with calmer clouds and rain

**Settings**
- Refresh Settings layout with a cleaner top bar, responsive sidebar, and Material 3 polish
- Apply the new page standard to Display, Profile, About, System, Services, Widgets, and Customize
- Rework Network views with Android style details and password dialogs
- Rework Bluetooth views with a device details sidebar
- Add game mode auto toggles for do not disturb, keep awake, and performance
- Redesign the shell update page with grouped changelog and release history (thanks to @P3DROVFX for the design reference)
- Add NAnDoroid theme, a scheme picker in the accent overlay, and 6 new basic themes
- Add first day of week, notification duration, and alarm sound settings

**Sound, Feedback & Small Touches**
- Add system sounds settings with custom notification and ringtone picks
- Add notification modes with a dedicated Quick Settings panel
- Add global snackbar feedback with undo for deletes, copies, and screenshots
- Add global confirmation dialog and cleaner dialog buttons
- Add custom title and numbers fonts setting
- Add keyboard navigation and focus rings to Quick Settings, workspace selector, and notifications
- Add GitHub widget with contribution heatmap and live system monitor header stats
- Add Pixel clock style and new material loading indicators

**Installer & Update**
- Add installer dry run mode for a safe preview before changing anything
- Add shell only copy scope with timestamped config backups
- Guard updates on dev setups so symlinked checkouts are never overwritten silently

**Stability & Fixes**
- Keep OSD above the lockscreen, stop Overview from closing shell windows, and give it exclusive keyboard focus with absolute navigation
- Fix status bar module spacing, panel hitboxes, empty workspace pill sizing, and special workspace detection
- Fix Quick Settings blinking disk stats, hover leaks, and Bluetooth toggle issues
- Make clock dates update in real time and fix the battery tip color at full charge
- Fix media player icons and duplicate browser players
- Fix recording start spam notification and off screen image capture crash
- Fix clipboard delete behavior and backdrop clicks on polkit and dialog panels
- Fix lockscreen battery position and workspace evacuation on lock
- Persist desktop widget stacking order across restarts
- Lazy load the system monitor and onboarding to cut startup cost, with lighter disk polling
- Harden preset save and apply, including lockscreen colors
- Soften the installer on non Arch systems, guard Hyprland injection, and disable blur on fullscreen shell layers
- Tighten panel input masks so clicks no longer get swallowed around the status bar and corners

For a complete list of changes, please refer to the git commit history.

---

# Nandoroid Shell v1.5.0 Release Notes

## Overview
Nandoroid Shell v1.5.0 introduces an interactive Desktop Widget and Choice A Grid Canvas system, a native Linux system monitoring engine with minimal background overhead, and flexible statusbar module reordering. This major update also features a unified Notepad and Todo deadline system, dedicated Microphone OSD, decoupled lockscreen color palettes, and extensive performance and stability enhancements across the shell.

## Changelog

**Desktop Widgets & Grid Canvas**
- Introduce Desktop Widgets with 12px snap-to-grid canvas positioning
- Add Desktop Media Widget featuring Material You styling, 5-line lyrics view, 2x2 layout variant, and drag-resize support
- Add Desktop System Monitor Widget with real-time resource visualization
- Redesign Desktop Weather Widget with 3 drag-resizable layout variants
- Add setting to disable desktop widget interactions when application windows are focused
- Add 250ms right-click delay after workspace switching to prevent accidental context menu closure

**Native System Monitoring (SysMon)**
- Refactor System Monitor engine to pure native Linux APIs (`/proc`, `/sys`) with on-demand process tracking, significantly reducing idle CPU/GPU consumption
- Add automatic native `ps` fallback when dgop is not installed
- Add animated sidebar navigation pill and asynchronous page loading for responsive tab switching
- Redesign CPU, GPU, Memory, Disk, and Battery monitoring pages with hardware specification cards

**Status Bar & Customization**
- Implement flexible dynamic module ordering and placement in Status Bar settings
- Redesign workspace indicator with smooth sliding tab animations and dynamic special workspace overlay
- Support dynamic text alignment for active window titles based on cluster placement, with automatic width truncation when System Monitor is active
- Relocate notification counter to the left side of status bar with smooth crossfade transitions
- Consolidate Do-Not-Disturb (DND) indicator into the status icons cluster
- Limit maximum modules per cluster to 5 in Status Bar settings
- Prevent statusbar module overlap in centered mode

**Notepad & Todo Management**
- Rewrite Notepad with a unified Notepad/Todo model supporting deadlines, priorities, and state persistence
- Integrate `DashNotepad` widget into the main Dashboard panel

**OSD & Input Controls**
- Add gamma dimming support below zero brightness for lower night-time luminance
- Introduce dedicated Microphone Mute OSD visualizer
- Redesign system sliders with segmented visual dividers and tactile handles
- Add customizable banner image picker with toggle switch in QuickSettings header
- Add user avatar and display name configuration to base statusbar and profile settings

**Performance & Efficiency**
- Implement lazy-loading for visualizers and weather animations to completely eliminate off-screen GPU rendering
- Optimize CAVA framerate to 30fps while expanding spectrum resolution to 128 bars
- Reduce MPRIS position polling interval to 3000ms to minimize background timer overhead

**Theme & Preset Management**
- Decouple Lockscreen Matugen color palette from desktop wallpaper to allow independent lockscreen color themes
- Ensure Matugen colors regenerate immediately after applying accent presets and prevent fallback color overrides
- Standardize system toggles across all panels with Material 3 styling

**Desktop Gestures**
- Add 3-region swipe down gestures to open Notification Center, Dashboard, and QuickSettings

**Time & Date Pickers**
- Add a TimePicker component with clock dial and input modes, including a 24-hour dial option
- Align DatePicker and TimePicker with the system date/time format settings
- Use the new picker in the Dashboard schedule editor and improve date validation

**Fonts & Typography**
- Add a live font preview panel and a refresh button that reloads the fonts cache
- Filter out symbol, icon, and emoji fonts from font selectors

**Onboarding**
- Redesign the IPC setup step and refine the setup modal layout

**Settings**
- Refine the dependency scanner card and shell update page layout

**Stability & Core Fixes**
- Automatically re-apply saved Bluetooth toggle state after system sleep/wake cycles
- Preserve notification action buttons across popup toasts, sidebar panel, and shell restarts
- Fix screen recording process detection via `pidof` and enforce exact selection geometry
- Fix Calendar event tooltip dismissal on outside click and auto-advance schedule end date when end time wraps past midnight
- Smooth width and opacity enter/exit animations on Privacy Indicator
- Fix duplicate terminal keybinding in Hyprland Lua extra configuration (thanks to @starsprinter92)

For a complete list of changes, please refer to the git commit history.

---

# Nandoroid Shell v1.4.0 Release Notes

## Overview
This major release migrates the core Hyprland configurations to Lua, introduces a unified and restructured System Settings page, and implements a deep integration with Steam's Wallpaper Engine. It also enhances the notification system with swipe-to-dismiss feedback, smart routing, and horizontal actions scrolling, alongside significant performance optimizations that minimize background CPU/GPU overhead.

## Changelog

**Hyprland Lua Migration**
- Migrate core Hyprland configurations to Lua format (compatible with Hyprland 0.55+)
- Implement a robust compatibility layer to handle newer Hyprland updates
- Align Settings controls (Display, Layout, GameMode) with the Lua backend

**System Settings & UI**
- Introduce a dedicated System Settings module to centralize system-related panels
- Integrate the System page into the global settings search registry and navigation
- Clean up Services and WallpaperStyle layouts and fix double margins on connection cards

**Wallpaper Engine & Selector**
- Implement Wallpaper Engine workshop discovery, custom property editor, and search/sort
- Add high-performance webp thumbnail caching using grabToImage
- Refactor WallpaperSelector to an elegant "Island" layout and make sidebar scrollable
- Add error detection, forced-resume logic, and automatic favorite wallpaper fallback
- Implement custom accent color picker using hyprpicker

**Notification System**
- Implement swipe-to-dismiss feedback and dynamic input masks for popup notifications
- Add smart 'View' actions and internal routing for About page sub-sections
- Add horizontal scrolling for actions and enforce maximum expansion heights on popups
- Resolve hover-based timer pause issues and restore precise click-through masks

**Performance & Game Mode**
- Implement Game Mode persistence and smart performance adjustments for live wallpapers
- Optimize Matugen color application to run asynchronously, removing synchronous wait lag
- Isolate wallpaper color cache between lockscreen and desktop previews
- Refine background tracking services to reduce CPU and GPU overhead

**Stability & Core Fixes**
- Prevent CAVA visualizer freezing during theme changes and shell restarts via direct process management
- Synchronize system tray context menus and improve desktop right-click menu behavior
- Resolve Wallhaven 403 Forbidden errors by adding a standard User-Agent header
- Add global Escape key handling to close the Overview workspace panel
- Implement adaptive smart rounding for global scaling across all widgets

---

# Nandoroid Shell v1.3.1 Release Notes

## Overview
This maintenance update addresses critical path resolution issues for screenshot storage and shell versioning. It also introduces significant typographic refinements for better visual balance and improves the interactivity of the About page. Stability is further enhanced with improved search indexing and a reliable temporal auto-hide logic for status bar hints.

## Changelog

**System & Path Resolution**
- Resolve shell metadata and versioning path issues by centralizing files in `~/.config/nandoroid/`
- Fix default screenshot and recording save paths by ensuring they are protocol-free (removing `file:///` conflicts)
- Implement automatic protocol trimming when manually entering storage paths in settings
- Update installer and updater scripts to handle new metadata locations correctly

**UI/UX & Typography**
- Globally refine typography by transitioning from `Font.Bold` to `Font.DemiBold` for a cleaner look across all scales
- Standardize header sizes and weights across Settings, About, and Service panels
- Unify "Off" state colors for system interface toggles to match Material 3 container standards
- Improve About page link cards with full clickability and precise hover rounding that respects segmented boundaries

**Functional Fixes**
- Implement 3-second temporal auto-hide for Status Bar ScrollHints to prevent visual "freezing"
- Enhance search indexing for Screenshot and Recording settings in the global search bar
- Implement substring matching in SearchHandler for more intuitive settings discovery

---

# Nandoroid Shell v1.3.0 Release Notes

## Overview
This major update introduces a comprehensive global scaling system, enhancing usability across high-resolution displays. It features a new Quick Actions HUD for rapid system tasks, a revamped Wallpaper Selector with online collection support and custom folder management, and an enhanced Weather service with primary provider selection.

## Changelog

**Global Scaling & UI**
- Implement comprehensive global scaling across all panels, widgets, and sub-components
- Refine visualizers and layout constraints to maintain fill behavior when scaled
- Ensure precise interaction zones for autohide panels through dynamic input masking

**Quick Actions & HUD**
- Implement floating Quick Actions HUD with keyboard navigation and animated stretch-highlights
- Add Super+G shortcut for rapid access to common system tools and screen utilities

**Wallpaper Selector**
- Integrate NA-ive Walls online collection with lightweight webp thumbnails
- Implement persistent custom folder management with automated system-dialog workflow
- Add stable A-Z/Z-A sorting and separate search states for different categories
- Refine UI with a unique Sunny-shaped sorting button and improved vertical alignment

**Weather Service**
- Implement weather provider selection (Open-Meteo or wttr.in) in system settings
- Set Open-Meteo as the new high-accuracy primary option with automatic location detection
- Implement robust fallback cycles for maximum data reliability

**Clock & Kustomization**
- Add Pill and Text clock styles for further desktop personalization
- Implement date font size customization for digital clocks
- Refine analog clock face shapes and UI markers for sliders

**System & Stability**
- Implement smart dependency management and categorization in About page
- General maintenance including memory optimization and QML warning cleanup
- Improve contrast for notification counters and system tray icons

---

# Nandoroid Shell v1.2.2 Release Notes

## Overview
This update introduces a fully integrated Wallhaven service with smart features, enhances audio device management by filtering virtual nodes, and provides several UI/UX refinements across the lockscreen and system panels. Stability remains a focus with improved CAVA visualizer logic, OTA metadata handling, and secure command execution.

## Changelog

**Media Player & UI**
- Refactor MediaCard for better alignment and consistent gaps
- Implement monospace font for timers and remove hover highlights on skip buttons
- Improve vertical alignment for track info and playback controls
- Optimize art downloader to clear pending tasks on playback stop

**Wallhaven & Wallpapers**
- Implement Wallhaven service with infinite scroll, random initial search, and smart download (duplicate prevention)
- Add wallpaper favorites and improved panel synchronization
- Optimize memory usage by clearing online results on panel close and using adaptive cache buffer
- Implement randomized and optimized wallpaper transitions

**Audio & System**
- Filter out dummy nodes (Dummy Output/Input) from device lists for a cleaner UI
- Implement persistent monitor settings, layout, and game mode via config injection
- Improve OTA stability by resolving broken version metadata during updates
- Secure various shell commands (weather, SongRec, mpris, clipboard) and prevent redundant refreshes
- Fix CAVA process stability and frozen visualizers with robust ref-counting and error handling

**Region Selector & Screenshots**
- Fix TypeError in ScreenshotAction by adding default imageSearch configuration
- Resolve image search engine URL property access and improve command construction

**UI/UX & Minor Fixes**
- Fix ActiveWindowTitle layout to prevent text overflow in the status bar
- Implement WrapAnywhere for notification content to handle long text
- Resolve various QML warnings related to undefined properties and type assignments
- Redesign lockscreen unlock button with a pill-shaped aesthetic
- Implement adaptive colors for lockscreen status bar and weather
- Improve contrast for selected items in style selectors and settings
- Fix battery indicator behavior to hide when no battery is available
- Resolve stuck scroll hints by adding panel-state-based auto-hiding logic

**Refactoring & Architecture**
- Move MediaCard, WeatherCard, and WeatherAnimation to the unified widgets directory for better project organization
- Consolidate widget management through the global qmldir for consistent component loading

---

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

---

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
