pragma Singleton
import QtQuick
import Quickshell

/**
 * AppSearch.qml
 * Service for matching Hyprland window classes to system icons.
 * Case-insensitive optimized for performance and reliability.
 */
Singleton {
    id: root

    // Normalized substitutions (all keys must be lowercase)
    readonly property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "brave-browser": "brave-desktop",
        "brave": "brave-desktop",
        "com.brave.browser": "brave-desktop",
        "google-chrome": "google-chrome",
        "microsoft-edge": "microsoft-edge",
        "spotify": "spotify",
        "spotify-client": "spotify",
        "com.spotify.client": "spotify",
        "kitty": "kitty",
        "org.wezfurlong.wezterm": "org.wezfurlong.wezterm",
        "upscayl": "org.upscayl.Upscayl"
    })

    function iconExists(iconName) {
        if (!iconName) return false;
        try {
            const path = Quickshell.iconPath(iconName, "image-missing");
            return !!path && path !== "" && !path.includes("image-missing");
        } catch (e) {
            return false;
        }
    }

    readonly property int _entryCount: DesktopEntries.applications.values.length

    function guessIcon(clientClass, initialClass, title) {
        let dummy = root._entryCount; 
        
        if (!clientClass && !initialClass && !title) return "application-x-executable";
        
        // 1. Normalize all inputs to lowercase once (Better performance)
        const lowClass = (clientClass || "").toLowerCase();
        const lowInitial = (initialClass || "").toLowerCase();
        const lowTitle = (title || "").toLowerCase();

        // 2. Precise Desktop Entry Lookup (Using normalized ID)
        // Some systems store desktop IDs in mixed case, so we try raw first then lower
        const entry = DesktopEntries.byId(clientClass) || 
                      DesktopEntries.byId(initialClass) ||
                      DesktopEntries.byId(lowClass) ||
                      DesktopEntries.byId(lowInitial);
        
        if (entry && entry.icon) return entry.icon;

        // 3. Manual Substitutions (Now lightning fast with single lookup)
        if (substitutions[lowClass]) return substitutions[lowClass];
        if (substitutions[lowInitial]) return substitutions[lowInitial];

        // 4. Reverse domain parts (e.g., "org.upscayl.Upscayl" -> "upscayl")
        const parts = lowClass.split('.');
        if (parts.length > 1) {
            const lastPart = parts[parts.length - 1];
            if (iconExists(lastPart)) return lastPart;
        }

        // 5. Common Keywords (Already normalized)
        if (lowClass.includes("brave") || lowTitle.includes("brave")) {
            if (iconExists("brave-desktop")) return "brave-desktop";
            if (iconExists("brave")) return "brave";
            if (iconExists("brave-browser")) return "brave-browser";
            return "brave-desktop"; // Fallback to a common name
        }
        if (lowClass.includes("chrome") || lowTitle.includes("chrome")) return "google-chrome";
        if (lowClass.includes("edge") || lowTitle.includes("edge")) return "microsoft-edge";
        if (lowClass.includes("kitty")) return "kitty";
        if (lowClass.includes("code") || lowClass.includes("vsc")) return "visual-studio-code";
        if (lowClass.includes("discord")) return "discord";
        if (lowClass.includes("terminal")) return "utilities-terminal";
        if (lowClass.includes("thunar") || lowClass.includes("dolphin")) return "system-file-manager";

        // 6. Direct Icon System Check
        if (iconExists(lowClass)) return lowClass;
        if (iconExists(lowInitial)) return lowInitial;

        // 7. Last resort: Heuristic lookup (Expensive but thorough)
        const entryAlt = DesktopEntries.heuristicLookup(clientClass || initialClass || title || "");
        if (entryAlt && entryAlt.icon) return entryAlt.icon;

        return "application-x-executable";
    }
}
