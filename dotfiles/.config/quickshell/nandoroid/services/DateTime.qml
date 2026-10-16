pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"

/**
 * Provides current date and time using Quickshell's native C++ SystemClock
 * with declarative QML property bindings.
 */
Singleton {
    id: root

    property var clock: SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property date now: clock.date ?? new Date()
    readonly property int hours: (clock.date ?? new Date()).getHours()
    readonly property int minutes: (clock.date ?? new Date()).getMinutes()
    readonly property int seconds: (clock.date ?? new Date()).getSeconds()

    readonly property var _shortDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var _longDays: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var _shortMonths: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var _longMonths: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    readonly property string currentDate: {
        const d = clock.date ?? new Date()
        const dayIdx = d.getDay()
        const monthIdx = d.getMonth()

        const shortDay = I18nService.tr(_shortDays[dayIdx])
        const longDay = I18nService.tr(_longDays[dayIdx])
        const shortMonth = I18nService.tr(_shortMonths[monthIdx])
        const longMonth = I18nService.tr(_longMonths[monthIdx])

        const dd = d.getDate().toString().padStart(2, "0")
        const mm = (monthIdx + 1).toString().padStart(2, "0")
        const yyyy = d.getFullYear().toString()
        const yy = yyyy.slice(-2)

        const rawFmt = Config.ready ? Config.dateFormat : "ddd, dd/MM"

        return rawFmt
            .replace(/dddd/g, longDay)
            .replace(/ddd/g, shortDay)
            .replace(/dd/g, dd)
            .replace(/MMMM/g, longMonth)
            .replace(/MMM/g, shortMonth)
            .replace(/MM/g, mm)
            .replace(/yyyy/g, yyyy)
            .replace(/yy/g, yy)
    }

    readonly property string currentTime: {
        const h = root.hours
        const m = root.minutes
        const is24 = Config.ready && Config.options.time ? Config.options.time.timeStyle === "24H" : true

        if (is24) {
            return h.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0")
        } else {
            const upper = Config.ready && Config.options.time ? Config.options.time.timeStyle === "12H_PM" : true
            const ap = h >= 12 ? (upper ? "PM" : "pm") : (upper ? "AM" : "am")
            const h12 = h % 12 || 12
            return h12.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0") + " " + ap
        }
    }

    readonly property string time12h: {
        const h = root.hours
        const m = root.minutes
        const h12 = h % 12 || 12
        return h12.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0") + " " + (h >= 12 ? "pm" : "am")
    }

    // Uptime calculation from /proc/uptime
    property string uptime: "0m"

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
