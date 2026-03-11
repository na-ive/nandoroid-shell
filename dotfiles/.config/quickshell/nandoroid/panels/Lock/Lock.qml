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

    // Restore workspaces after a short delay (compositor needs to settle)
    Timer {
        id: restoreTimer
        interval: 150
        repeat: false
        onTriggered: {
            var batch = ""
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var monName = Quickshell.screens[j].name
                var wsId = root.savedWorkspaces[monName]
                if (wsId !== undefined) {
                    batch += "dispatch focusmonitor " + monName + "; dispatch workspace " + wsId + "; "
                }
            }
            if (batch.length > 0) {
                Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
            }
        }
    }

    // WlSessionLock — actual Wayland lock protocol
    WlSessionLock {
        id: wlLock
        locked: GlobalStates.screenLocked
        surface: Component {
            WlSessionLockSurface {
                color: "transparent"
                Loader {
                    active: GlobalStates.screenLocked
                    anchors.fill: parent
                    opacity: active ? 1 : 0
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

    // Save workspaces on lock / restore on unlock / re-focus lock screen
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Save workspaces and push to temp workspace
                var next = {}
                var batch = "keyword animation workspaces,1,7,default,slidevert; "
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var mon = Quickshell.screens[i].name
                    var mData = HyprlandData.monitors.find(m => m.name === mon)
                    var ws = (mData?.activeWorkspace?.id ?? 1)
                    next[mon] = ws
                    batch += "dispatch focusmonitor " + mon + "; dispatch workspace " + (2147483647 - ws) + "; "
                }
                root.savedWorkspaces = next
                Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
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
            // Plain unlock
            GlobalStates.screenLocked = false
            Quickshell.execDetached(["bash", "-c",
                `sleep 0.2; hyprctl --batch "dispatch togglespecialworkspace; dispatch togglespecialworkspace"`])
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
