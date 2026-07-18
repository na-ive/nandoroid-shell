import "../core"
import "../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    width: mainLayout.width
    height: mainLayout.height

    // ── Properties ──
    property bool interactive: true

    // Configuration shortcuts
    readonly property var cfg: Config.options.appearance.atAGlance
    readonly property string fontFamily: cfg.fontFamily !== "" ? cfg.fontFamily : Appearance.font.family.main
    readonly property int fontSize: cfg.fontSize
    
    // Time & Date bindings
    readonly property int currentHour: DateTime.hours
    readonly property string dateString: {
        var dummy = DateTime.currentDate;
        return Qt.formatDate(new Date(), "dddd, MMMM d");
    }
    
    // State
    property var quotesData: ({})
    property string currentGreeting: "Good day"
    property string _displayedQuote: ""
    property string _pendingQuote: ""
    property real _quoteContentOpacity: 1

    // Determine time period
    property string timePeriod: {
        if (currentHour >= 5 && currentHour < 12) return "morning";
        if (currentHour >= 12 && currentHour < 17) return "afternoon";
        if (currentHour >= 17 && currentHour < 22) return "evening";
        return "midnight";
    }

    // ── Schedule Integration ──
    property var scheduleEvents: ScheduleService.events
    property int _minuteTrigger: DateTime.minutes
    property var todayEvents: []
    property var nextEvent: null
    property int _scheduleVersion: 0
    property string _displayedScheduleTitle: ""
    property string _displayedScheduleDesc: ""
    property string _pendingScheduleTitle: ""
    property string _pendingScheduleDesc: ""
    property real _scheduleContentOpacity: 1

    onScheduleEventsChanged: updateScheduleInfo()
    on_MinuteTriggerChanged: updateScheduleInfo()

    Timer { id: scheduleFadeTimer; interval: 200; onTriggered: { _displayedScheduleTitle = _pendingScheduleTitle; _displayedScheduleDesc = _pendingScheduleDesc; _scheduleContentOpacity = 1; } }
    Timer { id: quoteFadeTimer; interval: 200; onTriggered: { _displayedQuote = _pendingQuote; _quoteContentOpacity = 1; } }

    function updateScheduleInfo() {
        const now = new Date();
        const nowDateStr = Qt.formatDate(now, "yyyy-MM-dd");
        const todayDay = now.getDay();
        const todayDate = now.getDate();

        let events = ScheduleService.events.filter(event => {
            if (!event.date) return false;
            if (event.date === nowDateStr) return true;
            if (event.recurrence === "daily") return true;
            if (event.recurrence === "weekly") {
                const d = new Date(event.date + "T00:00:00");
                return d && d.getDay() === todayDay;
            }
            if (event.recurrence === "monthly") {
                const d = new Date(event.date + "T00:00:00");
                return d && d.getDate() === todayDate;
            }
            return false;
        }).sort((a, b) => a.time.localeCompare(b.time));

        todayEvents = events;

        const UPCOMING_WINDOW = 120; // minutes — show upcoming events only within this window
        const nowMs = now.getHours() * 60 + now.getMinutes();
        let next = null;
        for (const ev of events) {
            const [h, m] = ev.time.split(":").map(Number);
            const startMs = h * 60 + m;
            let endMs;
            if (ev.endTime) {
                const [eh, em] = ev.endTime.split(":").map(Number);
                endMs = eh * 60 + em;
            } else {
                endMs = startMs + 60;
            }
            const isOngoing = nowMs >= startMs && nowMs < endMs;
            const isUpcomingInWindow = nowMs < startMs && (startMs - nowMs) <= UPCOMING_WINDOW;
            if (isOngoing || isUpcomingInWindow) {
                next = ev;
                break;
            }
        }

        const wasVisible = nextEvent !== null;
        const newNext = next ? {
            title: next.title,
            time: next.time,
            endTime: next.endTime,
            description: next.description
        } : null;

        let label = "";
        let desc = "";
        if (newNext) {
            const [h, m] = newNext.time.split(":").map(Number);
            const startMs = h * 60 + m;
            const isOngoing = nowMs >= startMs;
            const prefix = isOngoing ? "Now" : "Up next";
            let timeStr = newNext.time;
            if (newNext.endTime) timeStr += "\u2013" + newNext.endTime;
            label = prefix + ": " + newNext.title + " \u00b7 " + timeStr;
            desc = newNext.description || "";
        }

        if (wasVisible && newNext) {
            _pendingScheduleTitle = label;
            _pendingScheduleDesc = desc;
            _scheduleContentOpacity = 0;
            nextEvent = newNext;
            _scheduleVersion++;
            scheduleFadeTimer.restart();
        } else {
            _displayedScheduleTitle = label;
            _displayedScheduleDesc = desc;
            _scheduleContentOpacity = newNext ? 1 : 0;
            nextEvent = newNext;
            _scheduleVersion++;
        }
    }

    Component.onCompleted: updateScheduleInfo()

    // Colors
    function getColorForStyle(style) {
        switch (style) {
            case "primary": return Appearance.colors.colPrimary;
            case "secondary": return Appearance.colors.colSecondary;
            case "tertiary": return Appearance.colors.colTertiary;
            case "error": return Appearance.colors.colError;
            case "onSurface": return Appearance.m3colors.m3onSurface;
            case "surface": return Appearance.m3colors.m3surface;
            case "onLayer0": return Appearance.colors.colOnLayer0;
            case "onLayer1": return Appearance.colors.colOnLayer1;
            case "surfaceContainerHigh": return Appearance.m3colors.m3surfaceContainerHigh;
            default: return Appearance.colors.colPrimary;
        }
    }

    property color greetingColor: getColorForStyle(cfg.greetingColorStyle)
    property color dateColor: getColorForStyle(cfg.dateColorStyle)
    property color quoteColor: getColorForStyle(cfg.quoteColorStyle)

    // Timer for quote refresh (10 minutes)
    Timer {
        interval: 10 * 60 * 1000 // 10 minutes in ms
        running: true
        repeat: true
        onTriggered: updateQuoteOnly()
    }

    // Load Quotes JSON via Process
    Process {
        id: quotesLoader
        command: ["cat", Quickshell.shellPath("data/quotes.json")]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.quotesData = JSON.parse(this.text);
                    root.updateText();
                } catch(e) {
                    console.error("Failed to parse quotes:", e);
                }
            }
        }
    }

    onTimePeriodChanged: updateText()

    function updateQuoteOnly() {
        if (!quotesData) return;
        let quotesList = quotesData[timePeriod] || [];
        let newQuote = "";
        if (quotesList.length > 0) {
            newQuote = quotesList[Math.floor(Math.random() * quotesList.length)];
        } else if (quotesData["general"] && quotesData["general"].length > 0) {
            newQuote = quotesData["general"][Math.floor(Math.random() * quotesData["general"].length)];
        }
        if (!newQuote) return;
        if (nextEvent === null && _displayedQuote !== "") {
            _pendingQuote = newQuote;
            _quoteContentOpacity = 0;
            quoteFadeTimer.restart();
        } else {
            _displayedQuote = newQuote;
            _quoteContentOpacity = 1;
        }
    }

    function updateText() {
        if (!quotesData) return;
        
        // Greetings
        if (timePeriod === "morning") currentGreeting = "Good morning";
        else if (timePeriod === "afternoon") currentGreeting = "Good afternoon";
        else if (timePeriod === "evening") currentGreeting = "Good evening";
        else currentGreeting = "Good night";
        
        // Quotes
        updateQuoteOnly();
    }

    // ── Layout ──
    ColumnLayout {
        id: mainLayout
        width: cfg.customWidth > 0 ? cfg.customWidth : implicitWidth
        spacing: 8 * Appearance.effectiveScale

        StyledText {
            visible: cfg.showGreeting
            text: currentGreeting + "."
            font.pixelSize: Math.round(fontSize * 1.2 * Appearance.effectiveScale)
            font.family: fontFamily
            font.weight: Font.DemiBold
            color: greetingColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: cfg.customWidth > 0
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)
            horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
        }

        StyledText {
            visible: cfg.showDate
            text: "It's " + dateString
            font.pixelSize: Math.round(fontSize * Appearance.effectiveScale)
            font.family: fontFamily
            color: dateColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: cfg.customWidth > 0
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)
            horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
        }

        // ── Next Schedule (when events exist) ──
        ColumnLayout {
            spacing: 2 * Appearance.effectiveScale
            Layout.fillWidth: cfg.customWidth > 0
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)
            opacity: cfg.showQuote && nextEvent !== null ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            StyledText {
                text: _displayedScheduleTitle
                opacity: _scheduleContentOpacity
                font.pixelSize: Math.round((fontSize * 0.8) * Appearance.effectiveScale)
                font.family: fontFamily
                color: quoteColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: cfg.customWidth > 0
                Layout.maximumWidth: cfg.customWidth > 0 ? cfg.customWidth : 400 * Appearance.effectiveScale
                horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            StyledText {
                text: _displayedScheduleDesc
                opacity: _scheduleContentOpacity * 0.7
                font.pixelSize: Math.round((fontSize * 0.65) * Appearance.effectiveScale)
                font.family: fontFamily
                font.italic: true
                color: dateColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: cfg.customWidth > 0
                Layout.maximumWidth: cfg.customWidth > 0 ? cfg.customWidth : 400 * Appearance.effectiveScale
                horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        // ── Quote (idle state) ──
        RowLayout {
            spacing: 8 * Appearance.effectiveScale
            Layout.fillWidth: cfg.customWidth > 0
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)
            opacity: cfg.showQuote && nextEvent === null && _displayedQuote !== "" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            StyledText {
                text: _displayedQuote
                opacity: _quoteContentOpacity
                font.pixelSize: Math.round((fontSize * 0.8) * Appearance.effectiveScale)
                font.family: fontFamily
                color: quoteColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: cfg.customWidth > 0
                Layout.maximumWidth: cfg.customWidth > 0 ? cfg.customWidth : 400 * Appearance.effectiveScale
                horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    HoverHandler {
        id: widgetHoverHandler
    }

    // ── Resize Handle ──
    Rectangle {
        id: resizeHandle
        visible: root.interactive && !cfg.locked && (widgetHoverHandler.hovered || resizeArea.containsMouse)
        width: 24 * Appearance.effectiveScale
        height: 24 * Appearance.effectiveScale
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -8 * Appearance.effectiveScale
        color: Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer
        radius: 8 * Appearance.effectiveScale

        MaterialSymbol {
            anchors.centerIn: parent
            text: "swap_horiz"
            iconSize: 15 * Appearance.effectiveScale
            color: Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer
        }

        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            
            property real startGlobalX
            property real startWidth
            
            onPressed: (mouse) => {
                let globalPos = mapToItem(null, mouse.x, mouse.y)
                startGlobalX = globalPos.x
                startWidth = root.width
            }
            
            onPositionChanged: (mouse) => {
                if (pressed) {
                    let globalPos = mapToItem(null, mouse.x, mouse.y)
                    let deltaX = globalPos.x - startGlobalX
                    let newWidth = Math.max(100 * Appearance.effectiveScale, startWidth + deltaX)
                    Config.options.appearance.atAGlance.customWidth = newWidth
                }
            }
        }
    }
}
