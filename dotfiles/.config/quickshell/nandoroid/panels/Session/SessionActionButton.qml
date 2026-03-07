import "../../core"
import "../../widgets"
import QtQuick
import QtQuick.Layouts

/**
 * Android 16 Style Session Action Button
 * Guaranteed 1:1 aspect ratio to prevent "gepeng" (flattened) look.
 */
RippleButton {
    id: root
    
    property string iconName
    property string actionText
    
    // Scale relative to height to maintain consistent vertical size across resolutions
    readonly property real baseScale: Appearance.sizes.screen.height / 1080
    readonly property real buttonSize: 128 * baseScale
    
    // Hard-set width and height to force 1:1
    width: buttonSize
    height: buttonSize
    
    // Also set layouts properties just in case
    Layout.preferredWidth: buttonSize
    Layout.preferredHeight: buttonSize
    Layout.minimumWidth: buttonSize
    Layout.minimumHeight: buttonSize
    Layout.maximumWidth: buttonSize
    Layout.maximumHeight: buttonSize
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
    
    onHoveredChanged: if (root.hovered) root.forceActiveFocus()

    // Circular when active
    buttonRadius: (root.activeFocus || root.down) ? (buttonSize / 2) : (28 * baseScale)

    colBackground: root.activeFocus ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHighest
    colBackgroundHover: Appearance.m3colors.m3primary
    colRipple: Appearance.m3colors.m3onPrimary

    property color contentColor: (root.down || root.activeFocus) ?
                                Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12 * baseScale

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: root.iconName
            iconSize: 32 * baseScale
            color: root.contentColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: buttonSize - (16 * baseScale)
            text: root.actionText
            font.pixelSize: Math.max(10, 12 * baseScale)
            font.weight: Font.Medium
            color: root.contentColor
            opacity: 0.9
            elide: Text.ElideRight
            
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }
    }
    
    Keys.onPressed: (event) => {

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.clicked()
            event.accepted = true
        }
    }

    Behavior on buttonRadius {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuart }
    }
}
