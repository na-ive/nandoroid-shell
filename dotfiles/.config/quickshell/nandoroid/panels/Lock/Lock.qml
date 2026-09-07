pragma ComponentBehavior: Bound
import "../../core"
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property var savedWorkspaces: ({})

    function findNearestEmptyWorkspace(fromId, used) {
        for (var d = 1; d < 100; ++d) {
            var up = fromId + d
            var down = fromId - d
            if (up >= 1 && up <= 100 && !used[up])
                return up
            if (down >= 1 && !used[down])
                return down
        }
        for (var i = 1; i <= 100; ++i) {
            if (!used[i] && i !== fromId)
                return i
        }
        return 2147483647 - fromId
    }

    function restoreWorkspaces() {
        var batch = ""
        var multi = Quickshell.screens.length > 1
        for (var j = 0; j < Quickshell.screens.length; ++j) {
            var monName = Quickshell.screens[j].name
            var wsId = root.savedWorkspaces[monName]
            if (wsId === undefined) continue
            var cur = Hyprland.monitorFor(Quickshell.screens[j])?.activeWorkspace?.id
            if (cur === wsId) continue
            if (multi) batch += `hyprctl dispatch '${HyprlandCompat.dspFocusMonitor(monName)}';`
            batch += `hyprctl dispatch '${HyprlandCompat.dspWorkspace(wsId)}';`
        }
        if (batch.length > 0)
            Quickshell.execDetached(["bash", "-c", batch])
    }

    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: root.restoreWorkspaces()
    }

    WlSessionLock {
        id: wlLock
        locked: GlobalStates.screenLocked
                surface: Component {
                    WlSessionLockSurface {
                        color: "transparent"
                        Loader {
                            active: true
                            anchors.fill: parent
                            opacity: GlobalStates.screenLocked ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.animation.elementMoveFast.duration
                                    easing.type: Appearance.animation.elementMoveFast.type
                                }
                            }
                            sourceComponent: Component {
                                LockSurface {
                                    context: LockContext
                                }
                            }
                        }
                    }
                }
    }

    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                var next = {}
                var batch = ""
                var used = {}
                var wsValues = []
                if (typeof HyprlandData !== "undefined" && HyprlandData.workspaces && HyprlandData.workspaces.length > 0) {
                    wsValues = HyprlandData.workspaces
                } else if (Hyprland.workspaces && Hyprland.workspaces.values && Hyprland.workspaces.values.length > 0) {
                    wsValues = Hyprland.workspaces.values
                }
                for (var k = 0; k < wsValues.length; ++k) {
                    var w = wsValues[k]
                    var wid = w.id
                    if (wid < 1 || wid > 100) continue
                    var wc = w.windows
                    if (wc === undefined) wc = w.windowsCount
                    if (wc === undefined) {
                        used[wid] = true
                    } else if (wc > 0) {
                        used[wid] = true
                    }
                }
                for (var c = 0; c < Quickshell.screens.length; ++c) {
                    var m = Hyprland.monitorFor(Quickshell.screens[c])
                    var curId = m?.activeWorkspace?.id
                    if (curId !== undefined && curId >= 1 && curId <= 100) used[curId] = true
                }
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var screen = Quickshell.screens[i]
                    var mon = screen.name
                    var monitor = Hyprland.monitorFor(screen)
                    var ws = monitor?.activeWorkspace?.id ?? 1
                    next[mon] = ws
                    var hasWindows = true
                    var foundWs = false
                    for (var wi = 0; wi < wsValues.length; ++wi) {
                        if (wsValues[wi].id === ws) {
                            foundWs = true
                            var cc = wsValues[wi].windows
                            if (cc === undefined) cc = wsValues[wi].windowsCount
                            if (cc !== undefined) hasWindows = cc > 0
                            else hasWindows = true
                            break
                        }
                    }
                    if (!foundWs) {
                        hasWindows = false
                        if (typeof HyprlandData !== "undefined" && HyprlandData.windowList) {
                            for (var wj = 0; wj < HyprlandData.windowList.length; ++wj) {
                                if (HyprlandData.windowList[wj].workspace.id === ws) { hasWindows = true; break }
                            }
                        } else if (wsValues.length === 0) {
                            hasWindows = true
                        }
                    } else if (!hasWindows && typeof HyprlandData !== "undefined" && HyprlandData.windowList) {
                        for (var wj2 = 0; wj2 < HyprlandData.windowList.length; ++wj2) {
                            if (HyprlandData.windowList[wj2].workspace.id === ws) { hasWindows = true; break }
                        }
                    }
                    if (!hasWindows) continue
                    var tmpWs = root.findNearestEmptyWorkspace(ws, used)
                    used[tmpWs] = true
                    if (Quickshell.screens.length > 1)
                        batch += `hyprctl dispatch '${HyprlandCompat.dspFocusMonitor(mon)}';`
                    batch += `hyprctl dispatch '${HyprlandCompat.dspWorkspace(tmpWs)}';`
                }
                root.savedWorkspaces = next
                if (batch.length > 0) Quickshell.execDetached(["bash", "-c", batch])
                LockContext.reset()
                LockContext.tryFingerUnlock()
            } else {
                restoreTimer.start()
            }
        }
    }

    Connections {
        target: LockContext
        function onUnlocked(targetAction) {
            if (targetAction === LockContext.ActionEnum.Poweroff) {
                Quickshell.execDetached(["systemctl", "poweroff"])
                return
            } else if (targetAction === LockContext.ActionEnum.Reboot) {
                Quickshell.execDetached(["systemctl", "reboot"])
                return
            } else if (targetAction === LockContext.ActionEnum.Suspend) {
                Quickshell.execDetached(["systemctl", "suspend"])
                return
            }
            GlobalStates.screenLocked = false
            LockContext.reset()
        }
    }

    function lock() {
        if (Config.options.lock.useHyprlock) {
            Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"])
            return
        }
        GlobalStates.screenLocked = true
    }

    GlobalShortcut {
        name: "lock"
        description: "Lock the screen"
        onPressed: root.lock()
    }

    IpcHandler {
        target: "lock"

        function activate(): void {
            root.lock()
        }

        function focus(): void {
            LockContext.shouldReFocus()
        }
    }
}
