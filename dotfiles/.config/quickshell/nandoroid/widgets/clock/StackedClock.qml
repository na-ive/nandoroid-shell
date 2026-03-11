import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../services"

ColumnLayout {
    id: root
    spacing: 0
    
    property bool isLockscreen: false

    // Internal default config to ensure we never have undefined access
    readonly property var defaultCfg: ({
        fontSize: 64,
        labelFontSize: 24,
        fontFamily: "sans",
        fontWeight: "Bold",
        labelFontWeight: "Normal",
        alignment: "center",
        colorStyle: "primary",
        textColorStyle: "onSurface",
        showDate: true
    })

    // Safely resolve the config object
    readonly property var cfg: {
        if (!Config.ready || !Config.options || !Config.options.appearance || !Config.options.appearance.clock) 
            return defaultCfg;
        
        const clockCfg = Config.options.appearance.clock;
        let target = (isLockscreen && !clockCfg.useSameStyle) ? clockCfg.stackedLocked : clockCfg.stacked;
        
        return target || defaultCfg;
    }

    readonly property bool showDate: Config.ready && Config.options.appearance.clock.showDate

    readonly property color mainColor: {
        if (!Config.ready || !cfg) return Appearance.colors.colPrimary
        const s = cfg.colorStyle
        if (s === "primary") return Appearance.colors.colPrimary
        if (s === "secondary") return Appearance.colors.colSecondary
        if (s === "tertiary") return Appearance.colors.colTertiary
        if (s === "error") return Appearance.m3colors.m3error
        return Appearance.m3colors.m3onSurface
    }

    readonly property color labelColor: {
        if (!Config.ready || !cfg) return Appearance.m3colors.m3onSurface
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

    function mapTextAlign(a) {
        if (a === "right") return Text.AlignRight
        if (a === "center") return Text.AlignHCenter
        return Text.AlignLeft
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
        visible: root.showDate
        text: root.dayName
        font.pixelSize: cfg.labelFontSize || 24
        font.family: cfg.fontFamily || "sans"
        font.weight: root.fontW(cfg.labelFontWeight)
        color: root.labelColor
        opacity: 0.8
        Layout.alignment: root.mapAlign(cfg.alignment)
        horizontalAlignment: root.mapTextAlign(cfg.alignment)
    }

    Text {
        visible: root.showDate
        text: root.dayNumber
        font.pixelSize: cfg.fontSize || 64
        font.family: cfg.fontFamily || "sans"
        font.weight: root.fontW(cfg.labelFontWeight)
        color: root.labelColor
        Layout.alignment: root.mapAlign(cfg.alignment)
        horizontalAlignment: root.mapTextAlign(cfg.alignment)
        Layout.topMargin: - ((cfg.fontSize || 64) * 0.2)
    }

    Text {
        text: root.displayHours + ":" + root.displayMinutes
        font.pixelSize: cfg.fontSize || 64
        font.family: cfg.fontFamily || "sans"
        font.weight: root.fontW(cfg.fontWeight)
        color: root.mainColor
        Layout.alignment: root.mapAlign(cfg.alignment)
        horizontalAlignment: root.mapTextAlign(cfg.alignment)
        Layout.topMargin: - ((cfg.fontSize || 64) * 0.2)
    }

    Text {
        visible: !root.is24H
        text: root.amPm
        font.pixelSize: (cfg.labelFontSize || 24) + 6
        font.family: cfg.fontFamily || "sans"
        font.weight: root.fontW(cfg.labelFontWeight)
        color: root.labelColor
        opacity: 0.8
        Layout.alignment: root.mapAlign(cfg.alignment)
        horizontalAlignment: root.mapTextAlign(cfg.alignment)
        Layout.topMargin: - ((cfg.labelFontSize || 24) * 0.3)
    }
}
