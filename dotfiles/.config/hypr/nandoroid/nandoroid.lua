-- ─────────────────────────────────────────────────────────────────────────────
--  Nandoroid Shell: Keybinds & Layer Rules
--  Sourced automatically by hyprland.conf
-- ─────────────────────────────────────────────────────────────────────────────

local nandoroid = "quickshell -c nandoroid ipc call"
local scripts = "~/.config/quickshell/nandoroid/scripts"

-- Start Nandoroid Shell
hl.on("hyprland.start", function() hl.exec_cmd("quickshell -c nandoroid") end)

-- ─────────────────────────────────────────────────────────────────────────────
--  Unbinds (Prevent conflicts with default configs)
-- ─────────────────────────────────────────────────────────────────────────────
hl.unbind("SUPER + Q")
hl.unbind("SUPER + T")
hl.unbind("SUPER + Return")
hl.unbind("SUPER + W")
hl.unbind("SUPER + E")
hl.unbind("CTRL + ALT + Delete")
hl.unbind("XF86MonBrightnessUp")
hl.unbind("XF86MonBrightnessDown")
hl.unbind("SUPER + Period")
hl.unbind("SUPER + V")
hl.unbind("SUPER + G")
hl.unbind("SUPER + SHIFT + S")
hl.unbind("SUPER + SHIFT + R")
hl.unbind("SUPER + SHIFT + X")
hl.unbind("SUPER + Tab")

-- ─────────────────────────────────────────────────────────────────────────────
--  Default App Binds
-- ─────────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + T", hl.dsp.exec_cmd(scripts .. "/launch_first_available.sh kitty foot alacritty"))
hl.bind("SUPER + Return", hl.dsp.exec_cmd(scripts .. "/launch_first_available.sh kitty foot alacritty"))
hl.bind("SUPER + Enter", hl.dsp.exec_cmd(scripts .. "/launch_first_available.sh kitty foot alacritty"))
hl.bind("SUPER + W", hl.dsp.exec_cmd(scripts .. "/launch_first_available.sh zen-browser firefox chromium google-chrome-stable"))
hl.bind("SUPER + E", hl.dsp.exec_cmd(scripts .. "/launch_first_available.sh dolphin nautilus thunar thunar-mobile"))

-- ─────────────────────────────────────────────────────────────────────────────
--  Panel Toggles (via CLI)
-- ─────────────────────────────────────────────────────────────────────────────
-- Tapping Super opens Spotlight
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd(nandoroid .. " spotlight toggle"), { release = true })

hl.bind("SUPER + Space", hl.dsp.exec_cmd(nandoroid .. " launcher toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd(nandoroid .. " spotlight toggle clipboard"))
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd(nandoroid .. " quickwallpaper toggle"))
hl.bind("SUPER + A", hl.dsp.exec_cmd(nandoroid .. " notifications toggle"))
hl.bind("SUPER + N", hl.dsp.exec_cmd(nandoroid .. " quicksettings toggle"))
hl.bind("SUPER + G", hl.dsp.exec_cmd(nandoroid .. " quickactions toggle"))
hl.bind("SUPER + D", hl.dsp.exec_cmd(nandoroid .. " dashboard toggle"))
hl.bind("SUPER + I", hl.dsp.exec_cmd(nandoroid .. " settings toggle"))
hl.bind("SUPER + Tab", hl.dsp.exec_cmd(nandoroid .. " overview toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd(nandoroid .. " lock activate"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(nandoroid .. " systemmonitor toggle"))

-- ─────────────────────────────────────────────────────────────────────────────
--  Region Tools (Screenshots & Recording)
-- ─────────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + SHIFT + S", hl.dsp.global("quickshell:regionScreenshot"))
hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true })
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"))

-- ─────────────────────────────────────────────────────────────────────────────
--  Spotlight Specifics
-- ─────────────────────────────────────────────────────────────────────────────
hl.bind("SUPER + Period", hl.dsp.global("quickshell:spotlightEmoji"), { description = "Emoji >> clipboard" })
hl.bind("SUPER + V", hl.dsp.global("quickshell:spotlightClipboard"), { description = "Clipboard history >> clipboard" })

-- ─────────────────────────────────────────────────────────────────────────────
--  Utility & Power
-- ─────────────────────────────────────────────────────────────────────────────
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd(scripts .. "/restartshell.sh"))

-- ─────────────────────────────────────────────────────────────────────────────
--  Brightness & OSD
-- ─────────────────────────────────────────────────────────────────────────────
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(nandoroid .. " brightness increment"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(nandoroid .. " brightness decrement"), { locked = true, repeating = true })

-- ─────────────────────────────────────────────────────────────────────────────
--  Layer Rules
-- ─────────────────────────────────────────────────────────────────────────────
hl.config({
    layerrule = {
        "blur, quickshell:.*",
        "ignore_alpha 0.79, quickshell:.*",
        "blur, notifications",
        "ignore_alpha 0.69, notifications",
        "blur, launcher",
        "ignore_alpha 0.5, launcher",
        "no_anim, overview",
        "blur, session",
        
        -- Instantly show region tools
        "no_anim, quickshell:regionSelector",
        "blur off, quickshell:regionSelector",
        "no_anim, quickshell:recordingMarker",
        "blur off, quickshell:recordingMarker"
    }
})
