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
        visible: GlobalStates.quickSettingsOpen
        exclusiveZone: (Config.options?.panels?.keep_right_sidebar_loaded && GlobalStates.quickSettingsOpen && contentLoader.item) ? contentLoader.item.implicitWidth : 0
        WlrLayershell.namespace: "nandoroid:quicksettings"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.quickSettingsOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            right: true
        }

        implicitWidth: contentLoader.item ? contentLoader.item.implicitWidth : 0
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

        HyprlandFocusGrab {
            id: focusGrab
            active: panelWindow.visible && !GlobalStates.isPickingFile
            windows: [panelWindow]
            onCleared: {
                if (!GlobalStates.isPickingFile) {
                    if (contentLoader.item) contentLoader.item.close();
                    else GlobalStates.quickSettingsOpen = false;
                }
            }
        }

        Connections {
            target: GlobalStates
            function onQuickSettingsOpenChanged() {
                if (!GlobalStates.quickSettingsOpen && contentLoader.item) contentLoader.item.close();
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: GlobalStates.quickSettingsOpen || Config.options?.panels?.keep_right_sidebar_loaded
            sourceComponent: QuickSettingsContent {
                onClosed: {
                    GlobalStates.quickSettingsOpen = false;
                    GlobalStates.quickSettingsEditMode = false;
                }
            }
        }
    }
}
