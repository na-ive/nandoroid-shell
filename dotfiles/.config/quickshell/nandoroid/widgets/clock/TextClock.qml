import QtQuick
import QtQuick.Layouts
import ".."
import "../../core"
import "../../services"

/**
 * TextClock.qml
 * DEFINITIVE FIX: Stable position (Fixed Width) and reactive alignment.
 */
ColumnLayout {
    id: root
    spacing: 2 * Appearance.effectiveScale
    
    // implicitWidth hack removed as DesktopWidgets now handles anchoring dynamically
    
    property bool isLockscreen: false
    
    readonly property string timeFontFamily: root.isLockscreen ? Appearance.font.family.lockscreenTimeFont : Appearance.font.family.desktopTimeFont
    readonly property string dateFontFamily: root.isLockscreen ? Appearance.font.family.lockscreenDateFont : Appearance.font.family.desktopDateFont
    
    readonly property var cfg: {
        if (!Config.ready) return { fontSize: 42, dateFontSize: 18, alignment: "center", timeColorStyle: "onSurface", dateColorStyle: "primary" }
        return isLockscreen && !Config.options.appearance.clock.useSameStyle 
            ? (Config.options.appearance.clock.textLocked || { fontSize: 42, dateFontSize: 18, alignment: "center" })
            : (Config.options.appearance.clock.text || { fontSize: 42, dateFontSize: 18, alignment: "center" })
    }

    readonly property string alignment: root.cfg.alignment || "center"
    
    readonly property color timeColor: {
        if (!Config.ready || !cfg) return Appearance.colors.colOnLayer0
        const s = cfg.timeColorStyle
        if (s === "primary") return Appearance.colors.colPrimary
        if (s === "secondary") return Appearance.colors.colSecondary
        if (s === "tertiary") return Appearance.colors.colTertiary
        if (s === "error") return Appearance.m3colors.m3error
        if (s === "onSurface") return Appearance.m3colors.m3onSurface
        if (s === "surface") return Appearance.m3colors.m3surface
        return isLockscreen ? Appearance.colors.colLockscreenClock : Appearance.colors.colOnLayer0
    }

    readonly property color dateColor: {
        if (!Config.ready || !cfg) return Appearance.colors.colPrimary
        const s = cfg.dateColorStyle
        if (s === "primary") return Appearance.colors.colPrimary
        if (s === "secondary") return Appearance.colors.colSecondary
        if (s === "tertiary") return Appearance.colors.colTertiary
        if (s === "error") return Appearance.m3colors.m3error
        if (s === "onSurface") return Appearance.m3colors.m3onSurface
        if (s === "surface") return Appearance.m3colors.m3surface
        return Appearance.colors.colPrimary
    }

    readonly property real fontSize: (root.cfg.fontSize || 42) * Appearance.effectiveScale
    readonly property int qmlAlign: root.alignment === "left" ? Qt.AlignLeft : (root.alignment === "right" ? Qt.AlignRight : Qt.AlignHCenter)
    readonly property int textHAlign: root.alignment === "left" ? Text.AlignLeft : (root.alignment === "right" ? Text.AlignRight : Text.AlignHCenter)

    function numberToWords(n) {
        if (n === undefined || n === null) return "";
        const words = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", 
                       "ELEVEN", "TWELVE", "THIRTEEN", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN",
                       "TWENTY", "TWENTY ONE", "TWENTY TWO", "TWENTY THREE", "TWENTY FOUR", "TWENTY FIVE", "TWENTY SIX", "TWENTY SEVEN", "TWENTY EIGHT", "TWENTY NINE",
                       "THIRTY", "THIRTY ONE", "THIRTY TWO", "THIRTY THREE", "THIRTY FOUR", "THIRTY FIVE", "THIRTY SIX", "THIRTY SEVEN", "THIRTY EIGHT", "THIRTY NINE",
                       "FORTY", "FORTY ONE", "FORTY TWO", "FORTY THREE", "FORTY FOUR", "FORTY FIVE", "FORTY SIX", "FORTY SEVEN", "FORTY EIGHT", "FORTY NINE",
                       "FIFTY", "FIFTY ONE", "FIFTY TWO", "FIFTY THREE", "FIFTY FOUR", "FIFTY FIVE", "FIFTY SIX", "FIFTY SEVEN", "FIFTY EIGHT", "FIFTY NINE"];
        return words[n] || n.toString();
    }

    function getPeriodWords() {
        const h = DateTime.hours;
        if (h >= 21 || h < 4) return "AT NIGHT";
        if (h >= 18) return "IN THE EVENING";
        if (h >= 12) return "IN THE AFTERNOON";
        return "IN THE MORNING";
    }

    // --- Line 1: IT'S [MINUTE] AFTER ---
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: root.qmlAlign
        spacing: 12 * Appearance.effectiveScale
        
        Item { visible: root.alignment === "right"; Layout.fillWidth: true }

        StyledText {
            text: "IT'S"
            font.pixelSize: root.fontSize
            font.weight: Font.Light
            font.family: root.timeFontFamily
            color: root.timeColor
            opacity: 0.7
        }
        StyledText {
            readonly property int m: DateTime.minutes
            text: m === 15 ? "QUARTER" : (m === 30 ? "HALF" : root.numberToWords(m))
            font.pixelSize: root.fontSize
            font.weight: Font.DemiBold
            font.family: root.timeFontFamily
            color: root.timeColor
            visible: text !== "ZERO"
        }
        StyledText {
            text: "AFTER"
            font.pixelSize: root.fontSize
            font.weight: Font.Light
            font.family: root.timeFontFamily
            color: root.timeColor
            opacity: 0.7
            visible: DateTime.minutes !== 0
        }

        Item { visible: root.alignment === "left"; Layout.fillWidth: true }
    }

    // --- Line 2: [HOUR] [PERIOD] ---
    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: root.qmlAlign
        spacing: 12 * Appearance.effectiveScale
        
        Item { visible: root.alignment === "right"; Layout.fillWidth: true }

        StyledText {
            text: root.numberToWords(DateTime.hours % 12 || 12)
            font.pixelSize: root.fontSize
            font.weight: Font.DemiBold
            font.family: root.timeFontFamily
            color: root.timeColor
        }
        StyledText {
            text: getPeriodWords()
            font.pixelSize: root.fontSize
            font.weight: Font.Light
            font.family: root.timeFontFamily
            color: root.timeColor
            opacity: 0.7
        }

        Item { visible: root.alignment === "left"; Layout.fillWidth: true }
    }

    // --- Line 3: DATE ---
    RowLayout {
        spacing: 8 * Appearance.effectiveScale
        Layout.alignment: root.qmlAlign
        
        readonly property real dateSize: (root.cfg.dateFontSize || 18) * Appearance.effectiveScale
        readonly property var now: new Date()
        readonly property var days: ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"]
        readonly property var months: ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
        readonly property var ordinals: ["", "FIRST", "SECOND", "THIRD", "FOURTH", "FIFTH", "SIXTH", "SEVENTH", "EIGHTH", "NINTH", "TENTH", "ELEVENTH", "TWELFTH", "THIRTEENTH", "FOURTEEN", "FIFTEEN", "SIXTEEN", "SEVENTEEN", "EIGHTEEN", "NINETEEN", "TWENTIETH", "TWENTY FIRST", "TWENTY SECOND", "TWENTY THIRD", "TWENTY FOURTH", "TWENTY FIFTH", "TWENTY SIXTH", "TWENTY SEVENTH", "TWENTY EIGHTH", "TWENTY NINTH", "THIRTIETH", "THIRTY FIRST"]

        StyledText { text: "ON"; font.pixelSize: parent.dateSize; font.weight: Font.Light; font.family: root.dateFontFamily; color: root.dateColor; opacity: 0.7 }
        StyledText { text: parent.days[parent.now.getDay()]; font.pixelSize: parent.dateSize; font.weight: Font.DemiBold; font.family: root.dateFontFamily; color: root.dateColor }
        StyledText { text: "THE"; font.pixelSize: parent.dateSize; font.weight: Font.Light; font.family: root.dateFontFamily; color: root.dateColor; opacity: 0.7 }
        StyledText { text: parent.ordinals[parent.now.getDate()]; font.pixelSize: parent.dateSize; font.weight: Font.DemiBold; font.family: root.dateFontFamily; color: root.dateColor }
        StyledText { text: "OF"; font.pixelSize: parent.dateSize; font.weight: Font.Light; font.family: root.dateFontFamily; color: root.dateColor; opacity: 0.7 }
        StyledText { text: parent.months[parent.now.getMonth()]; font.pixelSize: parent.dateSize; font.weight: Font.DemiBold; font.family: root.dateFontFamily; color: root.dateColor }
    }
}
