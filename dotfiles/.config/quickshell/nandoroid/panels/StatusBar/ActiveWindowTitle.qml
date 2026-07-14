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
    property color color: Appearance.colors.colStatusBarText
    property color subtextColor: Appearance.colors.colStatusBarSubtext
    
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name

    property int textAlignment: Text.AlignLeft

    property string appClassText: root.focusingThisMonitor && root.activeWindow?.activated ?
                (root.activeWindow?.appId ?? "Desktop") : (HyprlandData.activeWindow?.class ?? "Desktop")

    property string appTitleText: root.focusingThisMonitor && root.activeWindow?.activated ?
                (root.activeWindow?.title ?? "Overview") : (HyprlandData.activeWindow?.title ?? `Workspace ${monitor?.activeWorkspace?.id ?? 1}`)

    implicitWidth: titleColumn.implicitWidth
    implicitHeight: titleColumn.implicitHeight
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.OutCubic
        }
    }

    readonly property real maxWidth: root.parent && root.parent.Layout ? root.parent.Layout.maximumWidth : 400 * Appearance.effectiveScale

    ColumnLayout {
        id: titleColumn
        anchors.verticalCenter: parent.verticalCenter
        spacing: -2 * Appearance.effectiveScale
        width: Math.min(implicitWidth, root.maxWidth)

        StyledText {
            id: classText
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxWidth
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: root.subtextColor
            elide: root.textAlignment === Text.AlignRight ? Text.ElideLeft : Text.ElideRight
            horizontalAlignment: root.textAlignment
            text: root.appClassText
        }

        StyledText {
            id: titleText
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxWidth
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.color
            elide: root.textAlignment === Text.AlignRight ? Text.ElideLeft : Text.ElideRight
            horizontalAlignment: root.textAlignment
            text: root.appTitleText
        }
    }
}
