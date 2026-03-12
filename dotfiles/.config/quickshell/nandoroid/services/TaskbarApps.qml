pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"

/**
 * TaskbarApps Service
 * Fixed version: Restored automatic binding for reliable app list updates.
 */
Singleton {
    id: root

    // Cache for desktop entries
    readonly property var _entryCache: ({})

    function getDesktopEntry(appId) {
        if (!appId) return null;
        if (_entryCache[appId]) return _entryCache[appId];
        
        const entry = DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
        if (entry) _entryCache[appId] = entry;
        return entry;
    }

    function isPinned(appId) {
        if (!Config.ready) return false;
        return Config.options.dock.pinnedApps.indexOf(appId) !== -1;
    }

    function togglePin(appId) {
        if (!Config.ready) return;
        let pinned = Config.options.dock.pinnedApps;
        if (root.isPinned(appId)) {
            Config.options.dock.pinnedApps = pinned.filter(id => id !== appId);
        } else {
            Config.options.dock.pinnedApps = pinned.concat([appId]);
        }
    }

    // --- The Model ---
    // Using a binding-driven list for maximum reliability with pooling for stability
    property list<var> apps: {
        if (!Config.ready) return [];
        
        // This triggers the binding when windows or pinned apps change
        const _toplevels = ToplevelManager.toplevels.values;
        const pinnedApps = Config.options.dock.pinnedApps ?? [];
        const ignoredRegexStrings = Config.options.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));

        const map = new Map();

        // 1. Pinned Apps
        for (const appId of pinnedApps) {
            const lowerId = appId.toLowerCase();
            if (!map.has(lowerId)) {
                map.set(lowerId, { appId: lowerId, pinned: true, toplevels: [] });
            }
        }

        // 2. Running Windows
        for (const toplevel of _toplevels) {
            if (!toplevel || !toplevel.appId) continue;
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            
            const lowerId = toplevel.appId.toLowerCase();
            if (!map.has(lowerId)) {
                map.set(lowerId, { appId: lowerId, pinned: false, toplevels: [] });
            }
            map.get(lowerId).toplevels.push(toplevel);
        }

        // 3. Sync with Pool
        let newApps = [];
        for (const [key, data] of map) {
            let wrapper = null;
            // Check existing pool
            for (let i = 0; i < pool.length; i++) {
                if (pool[i] && pool[i].appId === key) {
                    wrapper = pool[i];
                    break;
                }
            }

            if (!wrapper) {
                wrapper = appEntryComp.createObject(root, { appId: key });
                pool.push(wrapper);
            }

            wrapper.toplevels = data.toplevels;
            wrapper.pinned = data.pinned;
            newApps.push(wrapper);
        }

        // 4. Cleanup unused wrappers later to avoid disrupting current frame
        Qt.callLater(() => {
            for (let i = pool.length - 1; i >= 0; i--) {
                if (!newApps.includes(pool[i])) {
                    const old = pool.splice(i, 1)[0];
                    if (old) old.destroy();
                }
            }
        });

        return newApps;
    }

    // Use 'var' for the pool to support JS array methods like push/splice
    property var pool: []

    Component {
        id: appEntryComp
        QtObject {
            property string appId: ""
            property list<var> toplevels: []
            property bool pinned: false
        }
    }
}
