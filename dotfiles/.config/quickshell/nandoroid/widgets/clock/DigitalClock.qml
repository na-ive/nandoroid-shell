import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import ".."

ColumnLayout {
    id: root
    spacing: 0

    property bool isLockscreen: false

    // Resolve which config object to use:
    // lockscreen with independent style → digitalLocked, otherwise → digital
    readonly property var cfg: {
        if (Config.ready && isLockscreen && !Config.options.appearance.clock.useSameStyle)
            return Config.options.appearance.clock.digitalLocked
        return Config.options.appearance.clock.digital
    }

    // ── Color ──────────────────────────────────────────────────
    readonly property color color: {
        if (isLockscreen) return Appearance.colors.colLockscreenClock
        if (!Config.ready) return Appearance.m3colors.m3onSurface
        const s = cfg.colorStyle
        if (s === "primary")   return Appearance.colors.colPrimary
        if (s === "secondary") return Appearance.colors.colSecondary
        if (s === "onSurface") return Appearance.m3colors.m3onSurface
        if (s === "surface")   return Appearance.m3colors.m3surfaceContainerHighest
        return Appearance.m3colors.m3onSurface
    }
    readonly property color dateColor: isLockscreen ? Appearance.colors.colLockscreenDate : color

    // ── Font helpers ───────────────────────────────────────────
    function fontW(w) {
        if (w === "Thin")     return Font.Thin
        if (w === "Light")    return Font.Light
        if (w === "Normal")   return Font.Normal
        if (w === "Medium")   return Font.Medium
        if (w === "DemiBold") return Font.DemiBold
        if (w === "Black")    return Font.Black
        return Font.Bold
    }

    // ── Config props ───────────────────────────────────────────
    readonly property real  cfgSize:       Config.ready ? cfg.fontSize     : 84
    readonly property real  cfgDateSize:   14
    readonly property int   cfgDateGap:    4
    readonly property string cfgWeight:    "Bold"
    readonly property string cfgDateWeight:"Medium"
    readonly property string cfgFamily:    Appearance.font.family.title

    readonly property bool isVertical: Config.ready && cfg.isVertical
    readonly property bool showDate:   Config.ready && Config.options.appearance.clock.showDate
    readonly property bool hideAmPm:   Config.ready && cfg.hideAmPm

    // ── Time strings ───────────────────────────────────────────
    readonly property string displayHours: {
        const h = DateTime.hours
        const is24 = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : true
        if (is24) return h.toString().padStart(2, "0")
        return (h % 12 || 12).toString().padStart(2, "0")
    }
    readonly property string displayMinutes: DateTime.minutes.toString().padStart(2, "0")
    readonly property string timeString: {
        let t = DateTime.currentTime
        if (hideAmPm) t = t.replace(/ [AP]M/i, "")
        return t
    }

    // ── Time (top / horizontal) ─────────────────────────────────
    Text {
        id: timeTextTop
        text:        root.isVertical ? root.displayHours : root.timeString
        color:       root.color
        font.pixelSize: root.cfgSize
        font.weight:    root.fontW(root.cfgWeight)
        font.family:    root.cfgFamily
        font.hintingPreference: Font.PreferDefaultHinting
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignHCenter
    }

    // ── Minutes (vertical only) ─────────────────────────────────
    Text {
        visible: root.isVertical
        text:    root.displayMinutes
        color:   root.color
        font.pixelSize: root.cfgSize
        font.weight:    root.fontW(root.cfgWeight)
        font.family:    root.cfgFamily
        font.hintingPreference: Font.PreferDefaultHinting
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -24
    }

    // ── Date ────────────────────────────────────────────────────
    Text {
        visible: root.showDate
        text:    DateTime.currentDate
        color:   root.dateColor
        font.pixelSize: root.cfgDateSize
        font.weight:    root.fontW(root.cfgDateWeight)
        font.family:    Appearance.font.family.main
        font.hintingPreference: Font.PreferDefaultHinting
        renderType: Text.NativeRendering
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: root.cfgDateGap
    }
}
