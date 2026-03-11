pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"

/**
 * TaskbarApps Service
 * Manages the list of apps shown in the dock, including pinned apps
 * and currently running applications.
 * Ported from Illogical Impulse (ii) and adapted for NAnDoroid.
 */
Singleton {
    id: root

    function isPinned(appId) {
        if (!Config.ready) return false;
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (!Config.ready) return;
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.filter(id => id !== appId)
        } else {
            Config.options.dock.pinnedApps = Config.options.dock.pinnedApps.concat([appId])
        }
    }

    property list<var> apps: {
        if (!Config.ready) return [];
        
        var map = new Map();

        // Pinned apps
        const pinnedApps = Config.options.dock.pinnedApps ?? [];
        for (const appId of pinnedApps) {
            if (!map.has(appId.toLowerCase())) map.set(appId.toLowerCase(), ({
                pinned: true,
                toplevels: []
            }));
        }

        // Separator logic could go here, but let's keep it simple for now
        // or add a special entry if needed.

        // Ignored apps
        const ignoredRegexStrings = Config.options.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));
        
        // Open windows (ToplevelManager.toplevels.values is the Quickshell Wayland API)
        for (const toplevel of ToplevelManager.toplevels.values) {
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            
            const appId = (toplevel.appId || "unknown").toLowerCase();
            
            if (!map.has(appId)) {
                map.set(appId, ({
                    pinned: false,
                    toplevels: []
                }));
            }
            map.get(appId).toplevels.push(toplevel);
        }

        var values = [];

        for (const [key, value] of map) {
            values.push(appEntryComp.createObject(null, { 
                appId: key, 
                toplevels: value.toplevels, 
                pinned: value.pinned 
            }));
        }

        return values;
    }

    component TaskbarAppEntry: QtObject {
        id: wrapper
        required property string appId
        required property list<var> toplevels
        required property bool pinned
    }
    
    Component {
        id: appEntryComp
        TaskbarAppEntry {}
    }
}
