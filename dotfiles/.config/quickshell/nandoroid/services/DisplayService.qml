pragma Singleton

import QtQuick
import Quickshell

/**
 * Service for managing monitor configurations via hyprctl.
 */
Singleton {
    id: root

    function setResolution(monitorName, resolution, refreshRate) {
        applyMonitorSettings({
            name: monitorName,
            resolution: resolution,
            refreshRate: refreshRate
        });
    }

    function setScale(monitorName, scale) {
        applyMonitorSettings({
            name: monitorName,
            scale: scale
        });
    }

    function setOrientation(monitorName, transform) {
        applyMonitorSettings({
            name: monitorName,
            transform: transform
        });
    }

    function setPosition(monitorName, x, y) {
        applyMonitorSettings({
            name: monitorName,
            x: x,
            y: y
        });
    }

    function applyMonitorSettings(opts) {
        const monitors = HyprlandData.monitors;
        const target = monitors.find(m => m.name === opts.name);
        
        if (!target && !opts.resolution && opts.x === undefined && !opts.mirror) return;

        const name = opts.name;
        
        // Handle Mirroring
        if (opts.mirror) {
            console.log(`[DisplayService] Mirroring ${name} to ${opts.mirror}`);
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", `${name},preferred,auto,1,mirror,${opts.mirror}`]);
            return;
        }

        const rawRes = opts.resolution || (target ? `${target.width}x${target.height}` : "preferred");
        const refresh = Math.round(opts.refreshRate || (target ? target.refreshRate : 60));
        
        let resCmd = rawRes;
        if (rawRes !== "preferred" && !rawRes.includes("@")) {
            resCmd = `${rawRes}@${refresh}`;
        }

        const x = opts.x !== undefined ? Math.round(opts.x) : (target ? target.x : 0);
        const y = opts.y !== undefined ? Math.round(opts.y) : (target ? target.y : 0);
        const pos = `${x}x${y}`;
        
        const scale = opts.scale !== undefined ? opts.scale : (target ? target.scale : 1.0);
        const transform = opts.transform !== undefined ? opts.transform : (target ? target.transform : 0);
        
        // Syntax: name,res@refresh,pos,scale
        // Transform and other args must use the form `,keyword,value`
        let cmd = `${name},${resCmd},${pos},${scale.toFixed(2)}`;
        if (transform !== 0) {
            cmd += `,transform,${transform}`;
        }
        
        console.log(`[DisplayService] Applying: hyprctl keyword monitor "${cmd}"`);
        
        // Use full path or ensuring environment
        Quickshell.execDetached(["hyprctl", "keyword", "monitor", cmd]);
    }

    function batchApply(allChanges) {
        console.log(`[DisplayService] Batch applying changes for ${Object.keys(allChanges).length} monitors`);
        for (const name in allChanges) {
            const opts = allChanges[name];
            opts.name = name;
            applyMonitorSettings(opts);
        }
    }
}
