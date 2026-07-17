pragma Singleton

import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool loading: false
    property var rates: ({
        "USD": 0.0,
        "EUR": 0.0,
        "JPY": 0.0,
        "GBP": 0.0
    })

    property string baseCurrency: (Config.ready && Config.options.appearance.currencyWidget) ? Config.options.appearance.currencyWidget.baseCurrency : "IDR"
    property string quote1: (Config.ready && Config.options.appearance.currencyWidget) ? Config.options.appearance.currencyWidget.quote1 : "USD"
    property string quote2: (Config.ready && Config.options.appearance.currencyWidget) ? Config.options.appearance.currencyWidget.quote2 : "EUR"
    property string quote3: (Config.ready && Config.options.appearance.currencyWidget) ? Config.options.appearance.currencyWidget.quote3 : "JPY"
    property string quote4: (Config.ready && Config.options.appearance.currencyWidget) ? Config.options.appearance.currencyWidget.quote4 : "GBP"

    onBaseCurrencyChanged: refresh()
    onQuote1Changed: refresh()
    onQuote2Changed: refresh()
    onQuote3Changed: refresh()
    onQuote4Changed: refresh()

    // Helper to parse Qalc output
    function parseQalcOutput(text) {
        // Strip any currency prefixes/symbols to extract number cleanly
        // e.g. "IDR 17992.49694" -> "17992.49694"
        let clean = text.replace(/[^0-9.]/g, "");
        let val = parseFloat(clean);
        return isNaN(val) ? 0.0 : val;
    }

    // Process executor for qalc queries using absolute executable paths
    Process {
        id: qalcProc
        property var activeQueue: []
        property var activeResults: ({})

        command: ["/usr/bin/qalc", "-t", "1 USD to IDR"]
        
        onExited: (exitCode) => {
            // Read output via collector then advance queue
            let outText = collector.text.trim();
            
            let currentItem = qalcProc.activeQueue.shift();
            if (currentItem) {
                let rateVal = root.parseQalcOutput(outText);
                qalcProc.activeResults[currentItem.quote] = rateVal;
            }
            processNext();
        }

        stdout: StdioCollector {
            id: collector
        }

        function queueQueries(queries) {
            activeQueue = queries;
            activeResults = {};
            processNext();
        }

        function processNext() {
            if (activeQueue.length === 0) {
                root.rates = Object.assign({}, activeResults);
                root.loading = false;
                return;
            }

            let item = activeQueue[0];
            let expr = "1 " + item.quote + " to " + item.base;
            command = ["/usr/bin/qalc", "-t", expr];
            running = true;
        }
    }

    // Debounce timer to group multiple rapid property changes (especially during startup)
    Timer {
        id: debounceTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: root.doRefresh()
    }

    function refresh() {
        debounceTimer.restart();
    }

    function doRefresh() {
        loading = true;
        qalcProc.running = false; // Terminate any running query

        let queries = [
            { quote: quote1, base: baseCurrency },
            { quote: quote2, base: baseCurrency },
            { quote: quote3, base: baseCurrency },
            { quote: quote4, base: baseCurrency }
        ];

        qalcProc.queueQueries(queries);
    }

    // Refresh every 30 minutes
    Timer {
        id: autoRefreshTimer
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
