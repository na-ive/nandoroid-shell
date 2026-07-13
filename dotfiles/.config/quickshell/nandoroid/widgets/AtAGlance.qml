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

    // Load Quotes JSON
    FileView {
        id: quotesFile
        path: Directories.shellConfigPath + "/data/quotes.json"
        
        JsonAdapter {
            id: quotesAdapter
            property var morning: []
            property var afternoon: []
            property var evening: []
            property var midnight: []
        }
        
        onLoaded: {
            // Need to convert QJSValue/arrays to proper JS arrays if needed, 
            // but direct assignment usually works in QML for iteration
            root.quotesData = {
                morning: quotesAdapter.morning,
                afternoon: quotesAdapter.afternoon,
                evening: quotesAdapter.evening,
                midnight: quotesAdapter.midnight
            };
            root.updateText();
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

        RowLayout {
            spacing: 12 * Appearance.effectiveScale
            Layout.alignment: cfg.alignment === "center" ? Qt.AlignHCenter : (cfg.alignment === "right" ? Qt.AlignRight : Qt.AlignLeft)

            MaterialSymbol {
                visible: cfg.showIcon
                text: "wb_sunny" // You can bind this to weather service if you want
                iconSize: fontSize * 1.5 * Appearance.effectiveScale
                color: textColor
            }

            ColumnLayout {
                spacing: 2 * Appearance.effectiveScale
                
                StyledText {
                    visible: cfg.showGreeting || cfg.showDate
                    text: {
                        let parts = [];
                        if (cfg.showGreeting) parts.push(currentGreeting + ".");
                        if (cfg.showDate) parts.push("It's " + dateString + ".");
                        return parts.join(" ");
                    }
                    font.pixelSize: fontSize * Appearance.effectiveScale
                    font.family: fontFamily
                    font.weight: Font.DemiBold
                    color: textColor
                }

                StyledText {
                    visible: cfg.showQuote && currentQuote !== ""
                    text: currentQuote
                    font.pixelSize: (fontSize * 0.75) * Appearance.effectiveScale
                    font.family: fontFamily
                    color: Appearance.colors.colOnLayer2
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: 400 * Appearance.effectiveScale
                }
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
