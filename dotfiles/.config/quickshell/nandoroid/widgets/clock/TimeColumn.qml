pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../core"
import "../../services"

Column {
    id: root

    // Split "HH:MM" or "HH:MM AM" → parts
    readonly property var clockParts: DateTime.currentTime.split(/[: ]/)
    property color color: Appearance.m3colors.m3onSurfaceVariant
    property bool isLockscreen: false
    readonly property string timeFontFamily: isLockscreen ? Appearance.font.family.lockscreenTimeFont : Appearance.font.family.desktopTimeFont

    readonly property bool hourMarksEnabled: Config.ready && Config.options.appearance.clock.analog.hourMarks
    spacing: -12

    Repeater {
        model: root.clockParts

        delegate: Text {
            required property string modelData
            required property int index

            property bool isAmPm: modelData.match(/^[AP]M$/i) !== null
            property real baseSize: (isAmPm ? 24 : (root.hourMarksEnabled ? 48 : 64)) * Appearance.effectiveScale

            anchors.horizontalCenter: root.horizontalCenter
            text: isAmPm ? modelData : modelData.padStart(2, "0")
            color: root.color
            font.family: root.timeFontFamily
            font.weight: Font.DemiBold
            font.pixelSize: baseSize
            font.hintingPreference: Font.PreferDefaultHinting
            renderType: Text.NativeRendering

            Behavior on font.pixelSize {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
        }
    }
}
