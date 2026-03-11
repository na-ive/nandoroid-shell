import QtQuick
import QtQuick.Layouts
import "../../core"

/**
 * Simple vertical separator for the dock.
 */
Rectangle {
    id: root
    // Using simple anchoring and margins for now, will refine in Dock.qml
    Layout.fillHeight: true
    implicitWidth: 1
    color: Appearance.colors.colOutlineVariant
    opacity: 0.5
}
