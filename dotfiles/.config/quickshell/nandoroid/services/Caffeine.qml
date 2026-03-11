pragma Singleton
import "../core"
import Quickshell
import Quickshell.Wayland
import QtQuick

/**
 * Caffeine service to prevent the system from idling.
 * Uses IdleInhibitor to block screen dimming/locking.
 */
Singleton {
    id: root

    property bool active: Config.options.quickSettings.caffeineActive
    property bool startupReady: false

    // Actual inhibition state combines user setting and startup delay
    readonly property bool inhibited: active && startupReady

    onActiveChanged: {
        if (Config.ready) {
            Config.options.quickSettings.caffeineActive = active
        }
    }

    // Ensure the inhibitor kicks in after a short delay on startup/restart
    // to ensure the compositor connection and windows are fully stable.
    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: root.startupReady = true
    }

    Connections {
        target: Config.options
        function onQuickSettingsChanged() {
            if (active !== Config.options.quickSettings.caffeineActive) {
                active = Config.options.quickSettings.caffeineActive
            }
        }
    }

    IdleInhibitor {
        id: inhibitor
        enabled: root.inhibited
        window: PanelWindow {
            id: window
            implicitWidth: 0
            implicitHeight: 0
            visible: true
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "nandoroid:caffeine"
            
            mask: Region {}
        }
    }
}
