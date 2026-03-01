import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"

ColumnLayout {
    id: root
    spacing: 0
    
    property bool isLockscreen: false

    readonly property var cfg: {
        if (Config.ready && isLockscreen && !Config.options.appearance.clock.useSameStyle)
            return Config.options.appearance.clock.stackedLocked
        return Config.options.appearance.clock.stacked
    }

    readonly property color mainColor: {
        if (!Config.ready) return Appearance.m3colors.m3error
        const s = cfg.colorStyle
        if (s === "primary") return Appearance.colors.colPrimary
        if (s === "secondary") return Appearance.colors.colSecondary
        if (s === "tertiary") return Appearance.colors.colTertiary
        if (s === "error") return Appearance.m3colors.m3error
        return Appearance.m3colors.m3onSurface
    }
    readonly property color labelColor: {
        if (!Config.ready) return Appearance.m3colors.m3onSurface
        const s = cfg.textColorStyle
        if (s === "primary") return Appearance.colors.colPrimary
        if (s === "secondary") return Appearance.colors.colSecondary
        if (s === "tertiary") return Appearance.colors.colTertiary
        if (s === "onSurface") return Appearance.m3colors.m3onSurface
        if (s === "surface") return Appearance.m3colors.m3surface
        return Appearance.m3colors.m3onSurface
    }

    function fontW(w) {
        if (w === "Thin")     return Font.Thin
        if (w === "Light")    return Font.Light
        if (w === "Normal")   return Font.Normal
        if (w === "Medium")   return Font.Medium
        if (w === "DemiBold") return Font.DemiBold
        if (w === "Bold")     return Font.Bold
        if (w === "Black")    return Font.Black
        return Font.Normal
    }

    function getOrdinal(n) {
        const s = ["th", "st", "nd", "rd"];
        const v = n % 100;
        const suffix = (s[(v - 20) % 10] || s[v] || s[0]);
        return n.toString().padStart(2, "0") + suffix;
    }

    function mapAlign(a) {
        if (a === "right") return Qt.AlignRight
        if (a === "center") return Qt.AlignHCenter
        return Qt.AlignLeft
    }

    readonly property date now: new Date()
    readonly property string dayName: Qt.formatDate(now, "ddd").toLowerCase()
    readonly property string dayNumber: getOrdinal(now.getDate()).toLowerCase()
    
    readonly property bool is24H: Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : true
    readonly property string displayHours: {
        const h = DateTime.hours
        if (is24H) return h.toString().padStart(2, "0")
        return (h % 12 || 12).toString().padStart(2, "0")
    }
    readonly property string displayMinutes: DateTime.minutes.toString().padStart(2, "0")
    readonly property string amPm: DateTime.hours >= 12 ? "PM" : "AM"

    Text {
        text: root.dayName
        font.pixelSize: cfg.labelFontSize
        font.family: cfg.fontFamily
        font.weight: root.fontW(cfg.labelFontWeight)
        color: root.labelColor
        opacity: 0.8
        Layout.alignment: root.mapAlign(cfg.alignment)
    }

    Text {
        text: root.dayNumber
        font.pixelSize: cfg.fontSize
        font.family: cfg.fontFamily
        font.weight: root.fontW(cfg.labelFontWeight)
        color: root.labelColor
        Layout.alignment: root.mapAlign(cfg.alignment)
        Layout.topMargin: - (cfg.fontSize * 0.2)
    }

    Text {
        text: root.displayHours + ":" + root.displayMinutes
        font.pixelSize: cfg.fontSize
        font.family: cfg.fontFamily
        font.weight: root.fontW(cfg.fontWeight)
        color: root.mainColor
        Layout.alignment: root.mapAlign(cfg.alignment)
        Layout.topMargin: - (cfg.fontSize * 0.2)
    }

    Text {
        visible: !root.is24H
        text: root.amPm
        font.pixelSize: cfg.labelFontSize + 6
        font.family: cfg.fontFamily
        font.weight: root.fontW(cfg.labelFontWeight)
        color: root.labelColor
        opacity: 0.8
        Layout.alignment: root.mapAlign(cfg.alignment)
        Layout.topMargin: - (cfg.labelFontSize * 0.3)
    }
}
