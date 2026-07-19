pragma Singleton

import "../core"
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool loading: false
    property string errorMessage: ""
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

    function buildUrl() {
        if (!root.baseCurrency) return ""
        var baseLo = root.baseCurrency.toLowerCase()
        return "https://latest.currency-api.pages.dev/v1/currencies/" + encodeURIComponent(baseLo) + ".json"
    }

    function doRefresh() {
        var url = buildUrl()
        if (!url) {
            root.errorMessage = "No base currency"
            return
        }

        root.loading = true
        root.errorMessage = ""

        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.loading = false
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        var baseLo = root.baseCurrency.toLowerCase()
                        var r = data[baseLo] || {}
                        var out = {}
                        for (var key in r) {
                            out[key.toUpperCase()] = r[key] ? (1 / r[key]) : 0.0
                        }
                        root.rates = out
                        root.errorMessage = ""
                    } catch (e) {
                        root.errorMessage = "Parse error"
                    }
                } else {
                    root.errorMessage = xhr.status === 0 ? "No network" : "HTTP " + xhr.status
                }
            }
        }
        xhr.send()
    }

    Timer {
        id: debounceTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: root.doRefresh()
    }

    function refresh() {
        debounceTimer.restart()
    }

    readonly property bool widgetEnabled: Config.ready && Config.options.appearance.currencyWidget && Config.options.appearance.currencyWidget.showOnDesktop

    Timer {
        id: autoRefreshTimer
        interval: 30 * 60 * 1000
        running: root.widgetEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
