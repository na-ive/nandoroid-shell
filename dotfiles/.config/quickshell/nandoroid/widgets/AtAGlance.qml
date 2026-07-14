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
    readonly property string fontFamily: cfg.fontFamily !== "" ? cfg.fontFamily : Appearance.font.family
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
    property string currentQuote: ""
    
    // Determine time period
    property string timePeriod: {
        if (currentHour >= 5 && currentHour < 12) return "morning";
        if (currentHour >= 12 && currentHour < 17) return "afternoon";
        if (currentHour >= 17 && currentHour < 22) return "evening";
        return "midnight";
    }

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
        if (quotesList.length > 0) {
            let randomIndex = Math.floor(Math.random() * quotesList.length);
            currentQuote = quotesList[randomIndex];
        } else if (quotesData["general"] && quotesData["general"].length > 0) {
            let randomIndex = Math.floor(Math.random() * quotesData["general"].length);
            currentQuote = quotesData["general"][randomIndex];
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

        RowLayout {
            visible: cfg.showQuote && currentQuote !== ""
            spacing: 8 * Appearance.effectiveScale
            Layout.fillWidth: cfg.customWidth > 0
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)

            StyledText {
                text: currentQuote
                font.pixelSize: Math.round((fontSize * 0.8) * Appearance.effectiveScale)
                font.family: fontFamily
                color: quoteColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: cfg.customWidth > 0
                Layout.maximumWidth: cfg.customWidth > 0 ? cfg.customWidth : 400 * Appearance.effectiveScale
                horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
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
        width: 32 * Appearance.effectiveScale
        height: 32 * Appearance.effectiveScale
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4 * Appearance.effectiveScale
        color: resizeArea.containsMouse ? Appearance.m3colors.m3surfaceContainerHigh : Appearance.m3colors.m3surfaceContainer
        radius: 8 * Appearance.effectiveScale

        MaterialSymbol {
            anchors.centerIn: parent
            text: "swap_horiz"
            iconSize: 18 * Appearance.effectiveScale
            color: Appearance.colors.colOnLayer1
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
