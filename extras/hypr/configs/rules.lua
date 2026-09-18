-- --- Window Rules ---

-- Dialogs & File Pickers
hl.window_rule({ match = { title = "^(Open File)(.*)$" },            center = 1, float = 1 })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" },         center = 1, float = 1 })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" },      center = 1, float = 1 })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" },           center = 1, float = 1 })
hl.window_rule({ match = { title = "^(Save As)(.*)$" },               center = 1, float = 1 })
hl.window_rule({ match = { title = "^(Library)(.*)$" },               center = 1, float = 1 })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" },           center = 1, float = 1 })

-- System Tools
hl.window_rule({ match = { class = "^(pavucontrol)$" },               float = 1, center = 1, size = { "monitor_w*0.45", "monitor_h*0.45" } })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" },      float = 1, center = 1, size = { "monitor_w*0.45", "monitor_h*0.45" } })

-- Portals
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = 1 })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" },               float = 1 })
hl.window_rule({ match = { class = "xdg-desktop-portal-hyprland" },             float = 1 })

-- Picture-in-Picture
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = 1, pin = 1 })

-- NAnDoroid Panels (Native Floating)
hl.window_rule({ match = { title = "^(Settings)$" },       float = 1, center = 1, border_size = 0 })
hl.window_rule({ match = { title = "^(System Monitor)$" },  float = 1, center = 1, border_size = 0 })
hl.window_rule({ match = { title = "^(Welcome to NAnDoroid)$" }, float = 1, center = 1, border_size = 0 })

-- NAnDoroid Layer Surfaces (no blur: blurred content bleeds color while fading)
hl.layer_rule({ match = { namespace = "quickshell:spotlight" }, blur = 0 })
hl.layer_rule({ match = { namespace = "quickshell:launcher" }, blur = 0 })

-- NAnDoroid Fullscreen Layers (no blur: backdrop blur would recompute every frame)
hl.layer_rule({ match = { namespace = "quickshell:background" }, blur = 0 })
hl.layer_rule({ match = { namespace = "quickshell:desktop-widgets" }, blur = 0 })
