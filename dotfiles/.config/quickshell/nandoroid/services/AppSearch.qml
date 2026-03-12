pragma Singleton
import QtQuick
import Quickshell

/**
 * AppSearch.qml
 * Service for matching Hyprland window classes to system icons.
 */
Singleton {
    id: root

    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "wps": "wps-office2019-kprometheus",
        "wpsoffice": "wps-office2019-kprometheus",
        "footclient": "foot",
        "Brave-browser": "brave-browser",
        "google-chrome": "google-chrome",
        "Microsoft-edge": "microsoft-edge",
        "kitty": "kitty",
        "org.wezfurlong.wezterm": "org.wezfurlong.wezterm"
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

    // Reactive trigger to force re-evaluation when desktop entries are loaded
    readonly property int _entryCount: DesktopEntries.applications.values.length

    function guessIcon(clientClass, initialClass, title) {
        // Accessing _entryCount makes this function reactive to DesktopEntries changes
        let dummy = root._entryCount; 
        
        if (!clientClass && !initialClass && !title) return "application-x-executable";
        
        let cClass = clientClass || "";
        let iClass = initialClass || "";
        let tTitle = title || "";

        // 1. Precise Desktop Entry Lookup
        const entry = DesktopEntries.byId(cClass) || DesktopEntries.byId(iClass);
        if (entry && entry.icon) return entry.icon;

        // 2. Manual Substitutions
        if (substitutions[cClass]) return substitutions[cClass];
        if (substitutions[iClass]) return substitutions[iClass];
        
        let lowerClass = cClass.toLowerCase();
        let lowerInitial = iClass.toLowerCase();
        if (substitutions[lowerClass]) return substitutions[lowerClass];
        if (substitutions[lowerInitial]) return substitutions[lowerInitial];

        // 3. Keyword Heuristics (Common Apps)
        let allText = (cClass + " " + iClass + " " + tTitle).toLowerCase();
        if (allText.includes("brave")) return "brave-browser";
        if (allText.includes("chrome")) return "google-chrome";
        if (allText.includes("edge")) return "microsoft-edge";
        if (allText.includes("kitty")) return "kitty";
        if (allText.includes("code") || allText.includes("vsc")) return "visual-studio-code";
        if (allText.includes("discord")) return "discord";
        if (allText.includes("terminal")) return "utilities-terminal";
        if (allText.includes("thunar")) return "system-file-manager";
        if (allText.includes("dolphin")) return "system-file-manager";

        // 4. Case-insensitive variant of the class name
        if (iconExists(cClass)) return cClass;
        if (iconExists(lowerClass)) return lowerClass;
        if (iconExists(iClass)) return iClass;
        if (iconExists(lowerInitial)) return lowerInitial;

        // 5. Reverse domain parts (e.g., "org.gnome.Nautilus" -> "Nautilus")
        const parts = (cClass || iClass).split('.');
        const lastPart = parts[parts.length - 1];
        if (iconExists(lastPart)) return lastPart;
        if (iconExists(lastPart.toLowerCase())) return lastPart.toLowerCase();

        // 6. Last resort heuristic lookup
        const entryAlt = DesktopEntries.heuristicLookup(cClass || tTitle || "");
        if (entryAlt && entryAlt.icon) return entryAlt.icon;

        return "application-x-executable";
    }
}
