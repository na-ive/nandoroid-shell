import QtQuick
import QtQuick.Layouts
import ".."
import "../../core"
import "../../services"

ColumnLayout {
    id: root
    spacing: 2 * Appearance.effectiveScale

    readonly property string alignment: "left"
    property bool isLockscreen: false

    // Resolve which config object to use:
    // lockscreen with independent style → codeLocked, otherwise → code
    readonly property var cfg: {
        if (Config.ready && isLockscreen && !Config.options.appearance.clock.useSameStyle)
            return Config.options.appearance.clock.codeLocked
        return Config.options.appearance.clock.code
    }

    // ── Color resolver ──────────────────────────────────────────
    function resolveColor(style) {
        if (isLockscreen) return Appearance.colors.colLockscreenClock
        switch (style) {
            case "primary":   return Appearance.colors.colPrimary
            case "secondary": return Appearance.colors.colSecondary
            case "tertiary":  return Appearance.colors.colTertiary
            case "onSurface": return Appearance.m3colors.m3onSurface
            case "surface":   return Appearance.m3colors.m3surfaceContainerHighest
            default:          return Appearance.m3colors.m3onSurface
        }
    }

    // ── Three independent colors ────────────────────────────────
    readonly property color valueColor:   resolveColor(Config.ready ? cfg.valueColorStyle   : "primary")
    readonly property color keywordColor: resolveColor(Config.ready ? cfg.keywordColorStyle : "tertiary")
    readonly property color blockColor:   resolveColor(Config.ready ? cfg.blockColorStyle   : "primary")

    // ── Config ──────────────────────────────────────────────────
    readonly property int    cfgSize:    Config.ready ? cfg.fontSize  : 18 * Appearance.effectiveScale
    readonly property string blockType:  Config.ready ? cfg.blockType : "js"
    readonly property bool showDate: Config.ready ? (root.isLockscreen ? (Config.options.appearance.clock.useSameStyle ? Config.options.appearance.clock.showDesktopDate : Config.options.appearance.clock.showLockscreenDate) : Config.options.appearance.clock.showDesktopDate) : true
    readonly property string customTimeFont: root.isLockscreen ? Config.options.appearance.clockFonts.lockscreenTimeFont : Config.options.appearance.clockFonts.desktopTimeFont
    readonly property string fontFamily: (Config.ready && customTimeFont !== "") ? customTimeFont : Appearance.font.family.monospace

    readonly property string currentTime: DateTime.currentTime
    readonly property string currentDate: DateTime.currentDate

    // ── Language templates ──────────────────────────────────────
    readonly property var lang: {
        switch (blockType) {
            case "python":
                return { open: ["while True:"], indent: "    ", close: [] }
            case "rust":
                return { open: ["fn main() {"], indent: "    ", close: ["}"] }
            case "c":
                return { open: ["int main() {"], indent: "    ", close: ["    return 0;", "}"] }
            case "kotlin":
                return { open: ["fun main() {"], indent: "    ", close: ["}"] }
            default: // js
                return { open: ["while (life) {"], indent: "    ", close: ["}"] }
        }
    }

    // ── Reusable code line component ────────────────────────────
    component CodeLine: RowLayout {
        id: cl
        property string keyword: ""
        property string value: ""
        property bool   isValue: true  // larger font for value string
        spacing: 6 * Appearance.effectiveScale

        // indent spacer
        Text {
            text: root.lang.indent
            color: "transparent"
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.cfgSize)
            renderType: Text.NativeRendering
        }
        // "time" or "date" keyword
        Text {
            text: cl.keyword
            color: root.keywordColor
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.cfgSize)
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
        // "=" operator
        Text {
            text: "="
            color: root.keywordColor
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.cfgSize)
            renderType: Text.NativeRendering
        }
        // quoted value
        Text {
            text: "\"" + cl.value + "\""
            color: root.valueColor
            font.family: root.fontFamily
            font.pixelSize: cl.isValue ? Math.max(root.cfgSize * 1.45, 22 * Appearance.effectiveScale) : root.cfgSize
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    // ── Opening block lines ─────────────────────────────────────
    Repeater {
        model: lang.open
        delegate: Text {
            required property string modelData
            text: modelData
            color: root.blockColor
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.cfgSize)
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    // ── time = "..." ────────────────────────────────────────────
    CodeLine {
        keyword: "time"
        value:   root.currentTime
        isValue: true
    }

    // ── date = "..." ────────────────────────────────────────────
    CodeLine {
        visible: root.showDate
        keyword: "date"
        value:   root.currentDate
        isValue: false
    }

    // ── Closing block lines ─────────────────────────────────────
    Repeater {
        model: lang.close
        delegate: Text {
            required property string modelData
            text: modelData
            color: root.blockColor
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.cfgSize)
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }
}
