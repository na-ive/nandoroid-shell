import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Shows the active window's app class and title.
 * Class in subtext color, title below in main color. Both truncated with elide.
 */
Item {
    id: root
    property HyprlandMonitor monitor
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
    readonly property var biggestWindow: HyprlandData.biggestWindowForWorkspace(
        HyprlandData.monitors[root.monitor?.id]?.activeWorkspace?.id ?? root.monitor?.activeWorkspace?.id ?? 1
    )

    property string appClassText: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.appId : (root.biggestWindow?.class) ?? "Desktop"

    property string appTitleText: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ?
                root.activeWindow?.title : (root.biggestWindow?.title) ?? `Workspace ${monitor?.activeWorkspace?.id ?? 1}`

    implicitWidth: titleColumn.implicitWidth
    implicitHeight: titleColumn.implicitHeight
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        id: titleColumn
        anchors.verticalCenter: parent.verticalCenter
        spacing: -2
        width: root.width

        StyledText {
            id: classText
            Layout.fillWidth: true
            Layout.maximumWidth: root.Layout.maximumWidth
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.colors.colStatusBarSubtext
            elide: Text.ElideRight
            text: root.appClassText
        }

        StyledText {
            id: titleText
            Layout.fillWidth: true
            Layout.maximumWidth: root.Layout.maximumWidth
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colStatusBarText
            elide: Text.ElideRight
            text: root.appTitleText
        }
    }
}
