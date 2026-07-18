pragma ComponentBehavior: Bound
import "../../core"
import "../../services"
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Lock panel — Wayland session lock entry point.
 * Saves + restores Hyprland workspaces on lock/unlock.
 * Ported from the ii example's modules/ii/lock/Lock.qml.
 */
Scope {
    id: root

    // Monitor name → workspace id saved at lock time
    property var savedWorkspaces: ({})

    // Restore workspaces after compositor settles (timer matches end4-pC)
    function restoreWorkspaces() {
        var batch = ""
        for (var j = 0; j < Quickshell.screens.length; ++j) {
            var monName = Quickshell.screens[j].name
            var wsId = root.savedWorkspaces[monName]
            if (wsId !== undefined) {
                batch += `hyprctl dispatch '${HyprlandCompat.dspFocusMonitor(monName)}'; hyprctl dispatch '${HyprlandCompat.dspWorkspace(wsId)}';`
            }
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

    // WlSessionLock — actual Wayland lock protocol
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

    // Save workspaces on lock / re-focus lock screen
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Save workspaces and push to temp workspace
                var next = {}
                var batch = ""
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var screen = Quickshell.screens[i]
                    var mon = screen.name
                    var monitor = Hyprland.monitorFor(screen)
                    var ws = monitor?.activeWorkspace?.id ?? 1
                    next[mon] = ws
                    batch += `hyprctl dispatch '${HyprlandCompat.dspFocusMonitor(mon)}'; hyprctl dispatch '${HyprlandCompat.dspWorkspace(2147483647 - ws)}';`
                }
                root.savedWorkspaces = next
                if (batch.length > 0) Quickshell.execDetached(["bash", "-c", batch])
                // Reset auth state and try fingerprint
                LockContext.reset()
                LockContext.tryFingerUnlock()
            } else {
                restoreTimer.start()
            }
        }
    }

    // Post-authentication actions
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
            // Unlock first, then restore workspaces after compositor settles
            GlobalStates.screenLocked = false
            LockContext.reset()
        }
    }

    // Lock function
    function lock() {
        if (Config.options.lock.useHyprlock) {
            Quickshell.execDetached(["bash", "-c", "pidof hyprlock || hyprlock"])
            return
        }
        GlobalStates.screenLocked = true
    }

    // Global shortcut: Super+L to lock
    GlobalShortcut {
        name: "lock"
        description: "Lock the screen"
        onPressed: root.lock()
    }

    // IPC handler: `qs ipc call lock activate`
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
