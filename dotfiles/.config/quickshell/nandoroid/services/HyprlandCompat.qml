pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Compatibility layer for Hyprland Lua (>=0.55) vs Legacy (.conf) dispatch syntax.
 * Uses Quickshell's built-in Hyprland.usingLua detection (via IPC j/status configProvider).
 * All dispatch helpers return strings suitable for both Hyprland.dispatch() and execDetached.
 *
 * NOTE: Lua expressions must NOT be wrapped in single quotes. Hyprland.dispatch() uses
 * IPC socket directly (no shell), and execDetached with arrays also bypasses the shell.
 */
Singleton {
    id: root

    // Built-in detection from Quickshell IPC — no custom logic needed
    readonly property bool isLua: Hyprland.usingLua

    // ── Helper: build nested Lua table from colon-separated key path ──
    // e.g. _nestedLua("decoration", "shadow:enabled", 0)
    //   → "hl.config({ decoration = { shadow = { enabled = 0 } } })"
    function _nestedLua(section, key, value) {
        const parts = key.split(":");
        let inner = String(value);
        for (let i = parts.length - 1; i >= 0; i--) {
            inner = `{ ${parts[i]} = ${inner} }`;
        }
        return `hl.config({ ${section} = ${inner} })`;
    }

    // ── Simple Dispatchers (no arguments) ──

    // e.g. dsp("exit", "exit") or dsp("killactive", "killActive")
    function dsp(legacyCmd, luaFunc) {
        return isLua ? `hl.dsp.${luaFunc}()` : legacyCmd
    }

    // ── Focus Dispatchers ──

    // Workspace: dspWorkspace("3"), dspWorkspace("r+1"), dspWorkspace("r-1")
    function dspWorkspace(value) {
        if (isLua) return `hl.dsp.focus({ workspace = "${value}" })`
        return `workspace ${value}`
    }

    // Focus window: dspFocusWindow("address:0xABC"), dspFocusWindow("class:firefox")
    function dspFocusWindow(selector) {
        if (isLua) return `hl.dsp.focus({ window = "${selector}" })`
        return `focuswindow ${selector}`
    }

    // Focus monitor: dspFocusMonitor("eDP-1")
    function dspFocusMonitor(monitor) {
        if (isLua) return `hl.dsp.focus({ monitor = "${monitor}" })`
        return `focusmonitor ${monitor}`
    }

    // ── Window Operations ──

    // Close window: dspClose("address:0xABC")
    function dspClose(selector) {
        if (isLua) return `hl.dsp.window.close({ window = "${selector}" })`
        return `closewindow ${selector}`
    }

    // Move to workspace (silent): dspMoveToWsSilent("3", "address:0xABC")
    function dspMoveToWsSilent(ws, windowSelector) {
        if (isLua)
            return `hl.dsp.window.move({ workspace = "${ws}", window = "${windowSelector}", follow = false })`
        return `movetoworkspacesilent ${ws}, ${windowSelector}`
    }

    // Move window pixel: dspMoveWindowPixel("exact 50% 50%", "address:0xABC")
    function dspMoveWindowPixel(pixelExpr, windowSelector) {
        if (isLua)
            return `hl.dsp.window.move({ pixel = "${pixelExpr}", window = "${windowSelector}" })`
        return `movewindowpixel ${pixelExpr}, ${windowSelector}`
    }

    // Toggle special workspace: dspToggleSpecial() or dspToggleSpecial("name")
    function dspToggleSpecial(name) {
        if (isLua) {
            if (name) return `hl.dsp.workspace.toggle_special("${name}")`
            return `hl.dsp.workspace.toggle_special()`
        }
        if (name) return `togglespecialworkspace ${name}`
        return `togglespecialworkspace`
    }

    // Lower window: dspLower("class:.*wallpaperengine.*")
    function dspLower(selector) {
        if (isLua) {
            if (selector) return `hl.dsp.window.alter_zorder({ action = "bottom", window = "${selector}" })`
            return `hl.dsp.window.alter_zorder({ action = "bottom" })`
        }
        if (selector) return `lower ${selector}`
        return `lower`
    }

    // Exec command: dspExec("kitty")
    function dspExec(cmd) {
        if (isLua) return `hl.dsp.exec_cmd("${cmd}")`
        return `exec ${cmd}`
    }

    // ── Keyword / Config Setters ──

    // Returns command array: keyword("general", "layout", '"dwindle"')
    // Handles nested keys: keyword("decoration", "shadow:enabled", 0)
    function keyword(section, key, value) {
        if (isLua)
            return ["hyprctl", "eval", root._nestedLua(section, key, value)]
        return ["hyprctl", "keyword", `${section}:${key}`, String(value)]
    }

    // Returns raw string for batch joining: keywordStr("animations", "enabled", 0)
    // Handles nested keys: keywordStr("decoration", "shadow:enabled", 0)
    function keywordStr(section, key, value) {
        if (isLua)
            return `eval ${root._nestedLua(section, key, value)}`
        return `keyword ${section}:${key} ${value}`
    }

    // Simple keyword (e.g. windowrule, layerrule) — takes name and value directly
    // Returns raw string for batch: rawKeywordStr("windowrule", "float,class:kitty")
    function rawKeywordStr(name, value) {
        // windowrule/layerrule syntax is the same in both modes
        // In Lua, hyprctl keyword still works for runtime rule additions
        return `keyword ${name} ${value}`
    }

    // ── Batch Builder ──

    // Returns command array: batch(["dispatch exit", "dispatch workspace 1"])
    function batch(commands) {
        return ["hyprctl", "--batch", commands.join(" ; ")]
    }
}
