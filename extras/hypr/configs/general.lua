-- --- General Appearance ---
-- Modularized and standardized following user examples

-- --- Gestures (Standard Syntax) ---
hl.config({
    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    }
})

-- --- Cursor ---
hl.config({
    cursor = {
        inactive_timeout = 3
    }
})

-- --- General ---
hl.config({
    general = {
        gaps_in = 7,
        gaps_out = 14,
        gaps_workspaces = 50,
        border_size = 1,
        ["col.active_border"] = "rgba(0DB7D455)",
        ["col.inactive_border"] = "rgba(31313600)",
        resize_on_border = true,
        no_focus_fallback = true,
        allow_tearing = true,
        layout = "dwindle",
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true
        }
    }
})

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false
    }
})

-- --- Decoration ---
hl.config({
    decoration = {
        rounding_power = 2.4,
        rounding = 18,
        blur = {
            enabled = true,
            xray = true,
            special = false,
            new_optimizations = true,
            size = 10,
            passes = 3,
            brightness = 1,
            noise = 0.05,
            contrast = 0.89,
            vibrancy = 0.5,
            vibrancy_darkness = 0.5,
            popups = false,
            popups_ignorealpha = 0.6,
            input_methods = true,
            input_methods_ignorealpha = 0.8
        },
        shadow = {
            enabled = true,
            ignore_window = true,
            range = 50,
            offset = "0 4",
            render_power = 10,
            color = "rgba(00000027)"
        },
        dim_inactive = true,
        dim_strength = 0.05,
        dim_special = 0.07
    }
})

-- --- Animations ---
hl.config({
    animations = {
        enabled = true,
        bezier = {
            "expressiveFastSpatial, 0.42, 1.67, 0.21, 0.90",
            "expressiveDefaultSpatial, 0.38, 1.21, 0.22, 1.00",
            "expressiveSlowSpatial, 0.39, 1.29, 0.35, 0.98",
            "expressiveEffects, 0.34, 0.80, 0.34, 1.00",
            "emphasized, 0.05, 0, 0.133, 0.06",
            "emphasizedAccel, 0.3, 0, 0.8, 0.15",
            "emphasizedDecel, 0.05, 0.7, 0.1, 1",
            "standard, 0.2, 0, 0, 1",
            "standardAccel, 0.3, 0, 1, 1",
            "standardDecel, 0, 0, 0, 1"
        },
        animation = {
            "windows, 1, 5, expressiveDefaultSpatial, slide",
            "windowsIn, 1, 4, emphasizedDecel, slide",
            "windowsOut, 1, 2, emphasizedAccel, slide",
            "windowsMove, 1, 5, expressiveDefaultSpatial, slide",
            "border, 1, 10, default",
            "borderangle, 1, 8, default",
            "fade, 1, 7, default",
            "workspaces, 1, 6.5, expressiveSlowSpatial, slidevert"
        }
    }
})

-- --- Input ---
hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7
        }
    }
})

-- --- Misc ---
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vfr = true,
        vrr = true,
        mouse_move_enables_dpms = false,
        key_press_enables_dpms = false,
        initial_workspace_tracking = false,
        focus_on_activate = true
    }
})
