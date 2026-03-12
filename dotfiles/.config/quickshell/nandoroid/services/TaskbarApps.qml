pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../core"

/**
 * TaskbarApps Service
 * Fixed: Ensured new apps are immediately detected and added to the model.
 */
Singleton {
    id: root

    readonly property var _entryCache: ({})
    property list<string> unpinnedOrder: []

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
        let pinned = Array.from(Config.options.dock.pinnedApps);
        const idx = pinned.indexOf(appId);
        if (idx !== -1) pinned.splice(idx, 1);
        else pinned.push(appId);
        Config.options.dock.pinnedApps = pinned;
    }

    function moveApp(appId, direction) {
        if (!appId || !Config.ready) return;
        const pinnedApps = Array.from(Config.options.dock.pinnedApps);
        const isPinned = pinnedApps.includes(appId);
        
        if (isPinned) {
            const idx = pinnedApps.indexOf(appId);
            const target = idx + direction;
            if (target >= 0 && target < pinnedApps.length) {
                pinnedApps.splice(idx, 1);
                pinnedApps.splice(target, 0, appId);
                Config.options.dock.pinnedApps = pinnedApps;
            }
        } else {
            const unpinned = Array.from(root.unpinnedOrder);
            const idx = unpinned.indexOf(appId.toLowerCase());
            if (idx === -1) return;
            const target = idx + direction;
            if (target >= 0 && target < unpinned.length) {
                unpinned.splice(idx, 1);
                unpinned.splice(target, 0, appId.toLowerCase());
                root.unpinnedOrder = unpinned;
            }
        }
    }

    // Main Model Binding
    property list<var> apps: {
        if (!Config.ready) return [];
        
        // FORCED TRIGGERS: Ensure any change in toplevels triggers a rebuild
        const _count = ToplevelManager.toplevels.values.length; 
        const _toplevels = ToplevelManager.toplevels.values;
        const pinnedApps = Config.options.dock.pinnedApps ?? [];
        const ignoredRegexStrings = Config.options.dock.ignoredAppRegexes ?? [];
        const ignoredRegexes = ignoredRegexStrings.map(pattern => new RegExp(pattern, "i"));

        const map = new Map();
        let currentRunningIds = [];

        // 1. Process Pinned Apps
        for (const appId of pinnedApps) {
            const id = appId.toLowerCase();
            if (!map.has(id)) {
                map.set(id, { appId: id, pinned: true, toplevels: [] });
            }
        }

        // 2. Process Running Windows (Wayland Toplevels)
        for (const toplevel of _toplevels) {
            if (!toplevel || !toplevel.appId) continue;
            if (ignoredRegexes.some(re => re.test(toplevel.appId))) continue;
            
            const id = toplevel.appId.toLowerCase();
            if (!currentRunningIds.includes(id)) currentRunningIds.push(id);

            if (!map.has(id)) {
                map.set(id, { appId: id, pinned: false, toplevels: [] });
            }
            
            // Add toplevel if not already present in the list for this appId
            const existingToplevels = map.get(id).toplevels;
            if (!existingToplevels.includes(toplevel)) {
                existingToplevels.push(toplevel);
            }
        }

        // 3. Sync unpinnedOrder
        let updatedUnpinnedOrder = root.unpinnedOrder.filter(id => {
            // Keep if still running and not pinned
            return currentRunningIds.includes(id) && !pinnedApps.map(p => p.toLowerCase()).includes(id);
        });

        // Add any NEWLY opened apps to the end of the unpinned order
        for (const id of currentRunningIds) {
            if (!pinnedApps.map(p => p.toLowerCase()).includes(id) && !updatedUnpinnedOrder.includes(id)) {
                updatedUnpinnedOrder.push(id);
            }
        }

        // Apply unpinned order update if it changed
        if (JSON.stringify(updatedUnpinnedOrder) !== JSON.stringify(root.unpinnedOrder)) {
            Qt.callLater(() => { root.unpinnedOrder = updatedUnpinnedOrder; });
        }

        // 4. Final Ordered List of IDs
        let orderedIds = [];
        for (const id of pinnedApps) orderedIds.push(id.toLowerCase());
        for (const id of updatedUnpinnedOrder) {
            if (!orderedIds.includes(id)) orderedIds.push(id);
        }

        // 5. Map to persistent Pool Objects
        let finalResult = [];
        for (const id of orderedIds) {
            const data = map.get(id);
            if (!data) continue;

            let wrapper = null;
            for (let i = 0; i < pool.length; i++) {
                if (pool[i] && pool[i].appId === id) {
                    wrapper = pool[i];
                    break;
                }
            }

            if (!wrapper) {
                wrapper = appEntryComp.createObject(root, { appId: id });
                pool.push(wrapper);
            }

            wrapper.toplevels = data.toplevels;
            wrapper.pinned = data.pinned;
            finalResult.push(wrapper);
        }

        // 6. Cleanup Pool (Deferred)
        Qt.callLater(() => {
            for (let i = pool.length - 1; i >= 0; i--) {
                if (pool[i] && !finalResult.includes(pool[i])) {
                    const old = pool.splice(i, 1)[0];
                    if (old) old.destroy();
                }
            }
        });

        return finalResult;
    }

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
