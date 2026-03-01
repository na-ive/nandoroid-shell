pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Provides current date and time as properties that auto-update.
 */
Singleton {
    id: root
    property string currentTime: ""
    property string currentDate: ""
    property string uptime: "0m"
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string time12h: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            
            // Manual formatting to ensure leading zeros for 12h mode as requested
            const h = now.getHours()
            const m = now.getMinutes()
            const is24 = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : true
            
            if (is24) {
                root.currentTime = h.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0")
            } else {
                const upper = Config.options.time.timeStyle === "12H_PM"
                const ap = h >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am")
                const h12 = h % 12 || 12
                root.currentTime = h12.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0") + " " + ap
            }
            
            root.currentDate = Qt.formatDate(now, Config.dateFormat)
            root.hours = h
            root.minutes = m
            root.seconds = now.getSeconds()
            
            // Always provide a standard 12h string for accessories
            const h12_raw = h % 12 || 12
            root.time12h = h12_raw.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0") + " " + (h >= 12 ? "pm" : "am")
        }
    }

    // Uptime from /proc/uptime
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fileUptime.reload()
            const text = fileUptime.text()
            const secs = Number(text.split(" ")[0] ?? 0)
            const d = Math.floor(secs / 86400)
            const h = Math.floor((secs % 86400) / 3600)
            const m = Math.floor((secs % 3600) / 60)
            let fmt = ""
            if (d > 0) fmt += `${d}d`
            if (h > 0) fmt += `${fmt ? ", " : ""}${h}h`
            if (m > 0 || !fmt) fmt += `${fmt ? ", " : ""}${m}m`
            root.uptime = fmt
        }
    }

    FileView {
        id: fileUptime
        path: "/proc/uptime"
    }
}
