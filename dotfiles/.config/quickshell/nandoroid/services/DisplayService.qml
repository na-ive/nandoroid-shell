pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "."

/**
 * Service for managing monitor configurations via hyprctl.
 * Persists monitor settings to ~/.config/hypr/nandoroid/user_persistence.conf
 */
Singleton {
    id: root

    readonly property string persistencePath: HyprlandCompat.isLua
        ? "~/.config/hypr/nandoroid/user_persistence.lua"
        : "~/.config/hypr/nandoroid/user_persistence.conf"

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
        
        if (HyprlandCompat.isLua) {
            // Build Lua eval block
            let evalBlock = `hl.monitor({\n` +
                            `    output = "${name}",\n` +
                            `    mode = "${opts.mirror ? "preferred" : (opts.resolution ? opts.resolution : (target ? `${target.width}x${target.height}` : "preferred"))}",\n` +
                            `    position = "${opts.mirror ? "auto" : (opts.x !== undefined ? `${Math.round(opts.x)}x${Math.round(opts.y)}` : (target ? `${target.x}x${target.y}` : "auto"))}",\n` +
                            `    scale = "${opts.mirror ? "1.00" : (opts.scale !== undefined ? opts.scale.toFixed(2) : (target ? target.scale.toFixed(2) : "1.00"))}"`
            if (opts.mirror) {
                evalBlock += `,\n    mirror = "${opts.mirror}"`
            } else {
                const transform = opts.transform !== undefined ? opts.transform : (target ? target.transform : 0);
                if (transform !== 0) {
                    evalBlock += `,\n    transform = ${transform}`
                }
            }
            evalBlock += `\n})`

            Quickshell.execDetached(["hyprctl", "eval", evalBlock]);
            
            // Persist
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
            persistMonitor(name, "", opts, resCmd, pos, scale, transform);
        } else {
            // Handle Mirroring Legacy
            if (opts.mirror) {
                const mirrorCmd = `${name},preferred,auto,1,mirror,${opts.mirror}`;
                Quickshell.execDetached(["hyprctl", "keyword", "monitor", mirrorCmd]);
                persistMonitor(name, mirrorCmd, opts);
            } else {
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
                
                let cmd = `${name},${resCmd},${pos},${scale.toFixed(2)}`;
                if (transform !== 0) {
                    cmd += `,transform,${transform}`;
                }
                Quickshell.execDetached(["hyprctl", "keyword", "monitor", cmd]);
                persistMonitor(name, cmd, opts, resCmd, pos, scale, transform);
            }
        }
        HyprlandData.updateMonitors();
        HyprlandData.updateMonitorsDelayed(800);
    }

    function persistMonitor(monitorName, configString, opts, resCmd, pos, scale, transform) {
        if (HyprlandCompat.isLua) {
            let luaBlock = `-- MONITOR_${monitorName}_START\n` +
                           `hl.monitor({\n` +
                           `    output = "${monitorName}",\n` +
                           `    mode = "${(opts && opts.mirror) ? "preferred" : (resCmd || "preferred")}",\n` +
                           `    position = "${(opts && opts.mirror) ? "auto" : (pos || "auto")}",\n` +
                           `    scale = "${(opts && opts.mirror) ? "1.00" : (scale !== undefined ? scale.toFixed(2) : "1.00")}"`
            if (opts && opts.mirror) {
                luaBlock += `,\n    mirror = "${opts.mirror}"`
            } else if (transform !== undefined && transform !== 0) {
                luaBlock += `,\n    transform = ${transform}`
            }
            luaBlock += `\n})\n` +
                        `-- MONITOR_${monitorName}_END`

            const pyCmd = `import sys, re; path = sys.argv[1]; name = sys.argv[2]; new_block = sys.argv[3]\n` +
                          `try:\n` +
                          `    content = open(path).read()\n` +
                          `except Exception:\n` +
                          `    content = ""\n` +
                          `pattern = r"-- MONITOR_" + re.escape(name) + r"_START.*?-- MONITOR_" + re.escape(name) + r"_END\\s*"\n` +
                          `content = re.sub(pattern, "", content, flags=re.DOTALL)\n` +
                          `content = content.strip()\n` +
                          `if content:\n` +
                          `    content += chr(10) + chr(10)\n` +
                          `content += new_block + chr(10)\n` +
                          `open(path, "w").write(content)`

            const realPath = root.persistencePath.replace(/^~/, Directories.home.replace("file://", ""));
            Quickshell.execDetached(["python3", "-c", pyCmd, realPath, monitorName, luaBlock]);
        } else {
            const cmd = `sed -i "/^monitor = ${monitorName},/d" ${root.persistencePath} 2>/dev/null || true; echo "monitor = ${configString}" >> ${root.persistencePath}`;
            Quickshell.execDetached(["bash", "-c", cmd]);
        }
    }

    function batchApply(allChanges) {
        for (const name in allChanges) {
            const opts = Object.assign({}, allChanges[name], { name: name });
            applyMonitorSettings(opts);
        }
    }
}
