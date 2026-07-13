import "../core"
import "../services"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    width: mainLayout.implicitWidth
    height: mainLayout.implicitHeight

    // ── Properties ──
    property bool interactive: true
    signal requestContextMenu(real x, real y)

    // Configuration shortcuts
    readonly property var cfg: Config.options.appearance.atAGlance
    readonly property string colorMode: cfg.colorMode
    readonly property string customColor: cfg.customColor
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
    property color textColor: {
        if (colorMode === "primary") return Appearance.colors.colPrimary;
        if (colorMode === "on-layer1") return Appearance.colors.colOnLayer1;
        if (colorMode === "custom") return customColor;
        return Appearance.colors.colPrimary; // fallback
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

    function updateText() {
        if (!quotesData) return;
        
        // Greetings
        if (timePeriod === "morning") currentGreeting = "Good morning";
        else if (timePeriod === "afternoon") currentGreeting = "Good afternoon";
        else if (timePeriod === "evening") currentGreeting = "Good evening";
        else currentGreeting = "Good night";
        
        // Quotes
        let quotesList = quotesData[timePeriod] || [];
        if (quotesList.length > 0) {
            let randomIndex = Math.floor(Math.random() * quotesList.length);
            currentQuote = quotesList[randomIndex];
        } else if (quotesData["general"] && quotesData["general"].length > 0) {
            let randomIndex = Math.floor(Math.random() * quotesData["general"].length);
            currentQuote = quotesData["general"][randomIndex];
        }
    }

    // ── Layout ──
    ColumnLayout {
        id: mainLayout
        spacing: 8 * Appearance.effectiveScale

        StyledText {
            visible: cfg.showGreeting
            text: currentGreeting + "."
            font.pixelSize: fontSize * 1.2 * Appearance.effectiveScale
            font.family: fontFamily
            font.weight: Font.DemiBold
            color: textColor
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)
            horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
        }

        StyledText {
            visible: cfg.showDate
            text: "It's " + dateString
            font.pixelSize: fontSize * Appearance.effectiveScale
            font.family: fontFamily
            color: Appearance.colors.colOnLayer1
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)
            horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
        }

        RowLayout {
            visible: cfg.showQuote && currentQuote !== ""
            spacing: 8 * Appearance.effectiveScale
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)

            StyledText {
                text: currentQuote
                font.pixelSize: (fontSize * 0.8) * Appearance.effectiveScale
                font.family: fontFamily
                color: Appearance.colors.colOnLayer1
                wrapMode: Text.WordWrap
                Layout.maximumWidth: 400 * Appearance.effectiveScale
                horizontalAlignment: cfg.alignment === "center" ? Text.AlignHCenter : (cfg.alignment === "right" ? Text.AlignRight : Text.AlignLeft)
            }
        }
    }

    // Context Menu Area
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            if (root.interactive && mouse.button === Qt.RightButton) {
                let p = mapToGlobal(mouse.x, mouse.y);
                root.requestContextMenu(p.x, p.y);
            }
        }
    }
}
