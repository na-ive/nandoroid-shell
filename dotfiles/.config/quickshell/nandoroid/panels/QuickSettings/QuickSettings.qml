import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Quick Settings panel — positioned top-right, directly below the status bar.
 * Uses HyprlandFocusGrab for click-outside-to-close (same pattern as NotificationCenter).
 */
Scope {
    id: root


    PanelWindow {
        id: panelWindow
        // Always visible (mapped) to fix Wayland jitter. The internal content toggles opacity.
        // Wait, if it's always visible as Top layer with OnDemand focus, it might block inputs.
        // Let's rely on content opacity driving the actual visual rect.
        visible: true
        exclusiveZone: (Config.options?.panels?.keep_right_sidebar_loaded && GlobalStates.quickSettingsOpen) ? content.implicitWidth : 0
        WlrLayershell.namespace: "nandoroid:quicksettings"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.quickSettingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
        }

        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight

        HyprlandFocusGrab {
            id: focusGrab
            active: GlobalStates.quickSettingsOpen && !GlobalStates.isPickingFile
            windows: [panelWindow]
            onCleared: {
                if (!GlobalStates.isPickingFile) {
                    content.close();
                }
            }
        }

        Connections {
            target: GlobalStates
            function onQuickSettingsOpenChanged() {
                if (!GlobalStates.quickSettingsOpen) content.close();
            }
        }

        QuickSettingsContent {
            id: content
            anchors.fill: parent
            visible: GlobalStates.quickSettingsOpen || Config.options?.panels?.keep_right_sidebar_loaded
            onClosed: {
                GlobalStates.quickSettingsOpen = false;
                GlobalStates.quickSettingsEditMode = false;
            }
        }
    }
}
