pragma Singleton

import "../core"
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Singleton service for fetching and managing weather data from wttr.in.
 * Optimized for sub-millisecond local cache loading on startup.
 */
Singleton {
    id: root

    // --- State ---
    property bool loading: false
    property var current: ({
        temp: "--",
        condition: "Checking...",
        icon: "cloudy",
        humidity: "--",
        windSpeed: "--",
        feelsLike: "--"
    })
    
    property list<var> hourly: [] 
    property list<var> daily: []  
    property string location: ""
    property var lastUpdateTime: null
    
    property string todayHigh: "--"
    property string todayLow: "--"
    property string status: "Idle"
    property bool wttrInHealthy: true
    property var lastWttrInFail: 0

    // --- Paths (Cleaned from file:// for shell compatibility) ---
    function cleanPath(p) {
        let s = p.toString();
        if (s.indexOf("file://") === 0) return s.substring(7);
        return s;
    }

    readonly property string cacheDir: cleanPath(Directories.home) + "/.cache/nandoroid"
    readonly property string cachePath: cacheDir + "/weather.json"

    // --- Config Helpers ---
    readonly property string unit: (Config.ready && Config.options.weather) ? (Config.options.weather.unit || "C") : "C"
    readonly property bool autoLocation: (Config.ready && Config.options.weather) ? Config.options.weather.autoLocation : true
    readonly property string manualLocation: (Config.ready && Config.options.weather) ? (Config.options.weather.location || "") : ""
    readonly property int updateInterval: {
        if (!Config.ready || !Config.options.weather) return 30;
        const val = parseInt(Config.options.weather.updateInterval);
        return (isNaN(val) || val <= 0) ? 30 : val;
    }

    property double nextUpdateTime: 0

    onUpdateIntervalChanged: {
        root.nextUpdateTime = Date.now() + (updateInterval * 60000);
    }

    // --- Cache Loading ---
    Process {
        id: readCacheProc
        command: ["sh", "-c", 'mkdir -p "$1" && [ -f "$2" ] && cat "$2" || exit 0', "sh", root.cacheDir, root.cachePath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (trimmed !== "" && trimmed.indexOf("{") === 0) {
                            const data = JSON.parse(trimmed);
                            processWeatherData(data);
                        }
                    } catch (e) {}
                });
            }
        }
    }

    // --- Fetch Logic ---
    function fetch(silent = false) {
        if (Config.ready && Config.options.weather && !Config.options.weather.enable) {
            return;
        }

        if (loading && !silent) {
            return;
        }

        // Prevent redundant fetching if data is fresh (less than 5 mins old)
        // unless it's a manual refresh (silent = false)
        if (silent && lastUpdateTime !== null) {
            const diff = (new Date().getTime() - lastUpdateTime.getTime()) / 60000;
            if (diff < 5) return; 
        }
        
        const now = new Date().getTime();
        if (!wttrInHealthy && (now - lastWttrInFail > 3600000)) {
            wttrInHealthy = true;
        }

        root.status = "Connecting...";
        if (!silent) loading = true;
        
        weatherProc.running = false;
        ipLocProc.running = false;
        geocodingProc.running = false;
        openMeteoProc.running = false;
        
        if (wttrInHealthy) {
            weatherProc.running = true;
        } else {
            fallbackTrigger();
        }
    }

    function fallbackTrigger() {
        root.status = "Finding location...";
        
        if (root.autoLocation || root.manualLocation.trim() === "") {
            ipLocProc.running = false;
            ipLocProc.running = true;
        } else {
            geocodingProc.running = false;
            geocodingProc.running = true;
        }
    }

    Timer {
        id: watchdogTimer
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            if (Config.ready && Config.options.weather && !Config.options.weather.enable) return;
            const now = Date.now();
            if (root.nextUpdateTime > 0) {
                if (now >= root.nextUpdateTime) root.fetch(true);
            } else {
                root.nextUpdateTime = now + (root.updateInterval * 60000);
            }
        }
    }

    Component.onCompleted: {
        try {
            const cacheData = cacheFileWriter.text;
            if (cacheData && cacheData.trim() !== "" && cacheData.indexOf("{") === 0) {
                const data = JSON.parse(cacheData);
                root.processWeatherData(data);
            }
        } catch (e) {
            readCacheProc.running = true;
        }
        startupFetchTimer.start();
    }

    Component.onDestruction: {
        readCacheProc.terminate();
        weatherProc.terminate();
        ipLocProc.terminate();
        geocodingProc.terminate();
        openMeteoProc.terminate();
    }

    Timer {
        id: startupFetchTimer
        interval: 100 
        onTriggered: {
            if (Config.ready) root.fetch(true);
            else { interval = 500; start(); }
        }
    }

    Process {
        id: weatherProc
        command: {
            const cleanLoc = root.autoLocation ? "" : root.manualLocation.split(',')[0].replace(/Regency/g, '').trim();
            const url = "https://wttr.in/" + cleanLoc + "?format=j1";
            return ["curl", "-sfL", "-m", "10", "--connect-timeout", "5", url];
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.wttrInHealthy = false;
                root.lastWttrInFail = new Date().getTime();
                fallbackTrigger();
            } else {
                root.status = "Updated via wttr.in";
                root.loading = false;
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (results === "") return;
                        const data = JSON.parse(results);
                        processWeatherData(data);
                    } catch (e) {}
                });
            }
        }
    }

    FileView {
        id: cacheFileWriter
        path: root.cachePath
    }

    Process {
        id: ipLocProc
        command: ["curl", "-sfL", "-m", "10", "http://ip-api.com/json/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (!results) throw "Empty response";
                        const data = JSON.parse(results);
                        if (data.status === "success") {
                            root.fetchOpenMeteo(data.lat.toString(), data.lon.toString(), data.city);
                        } else {
                            throw data.message || "Unknown error";
                        }
                    } catch(e) { 
                        root.status = "Location Error";
                        root.loading = false;
                    }
                });
            }
        }
    }

    Process {
        id: geocodingProc
        command: {
            let cleanLoc = root.manualLocation.split(',')[0].replace(/Regency/g, '').trim();
            const url = "https://geocoding-api.open-meteo.com/v1/search?name=" + cleanLoc + "&count=1&language=en&format=json";
            return ["curl", "-sfL", "-m", "15", url];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text.trim();
                Qt.callLater(() => {
                    try {
                        const data = results ? JSON.parse(results) : null;
                        if (data && data.results && data.results.length > 0) {
                            const res = data.results[0];
                            const displayName = res.admin1 ? (res.name + ", " + res.admin1) : res.name;
                            root.fetchOpenMeteo(res.latitude.toString(), res.longitude.toString(), displayName);
                        } else {
                            ipLocProc.running = false;
                            ipLocProc.running = true;
                        }
                    } catch(e) { 
                        ipLocProc.running = false;
                        ipLocProc.running = true;
                    }
                });
            }
        }
    }

    function fetchOpenMeteo(lat, lon, cityName) {
        root.location = cityName;
        openMeteoProc.lat = lat;
        openMeteoProc.lon = lon;
        openMeteoProc.running = true;
    }

    Process {
        id: openMeteoProc
        property string lat: ""
        property string lon: ""
        command: {
            if (!lat || !lon) return ["true"];
            const tempUnit = root.unit === "F" ? "&temperature_unit=fahrenheit" : "";
            const windUnit = root.unit === "F" ? "&wind_speed_unit=mph" : "&wind_speed_unit=kmh";
            const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}${tempUnit}${windUnit}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto`;
            return ["sh", "-c", 'mkdir -p "$1" && curl -sfL -m 15 "$2" > "$3.tmp" && jq -e . "$3.tmp" >/dev/null 2>&1 && mv "$3.tmp" "$3" && cat "$3"', "sh", root.cacheDir, url, root.cachePath];
        }
        
        onExited: (exitCode) => {
            if (exitCode !== 0) root.status = "API Error";
            root.loading = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (!results) return;
                        const data = JSON.parse(results);
                        processWeatherData(data); 
                        root.status = "Updated via fallback";
                    } catch(e) {}
                });
            }
        }
    }

    function processWeatherData(data) {
        if (!data) return;
        
        let actualData = data;
        if (data.data && !data.current_condition && !data.current) {
            actualData = data.data;
        }

        try {
            cacheFileWriter.setText(JSON.stringify(data));
        } catch(e) {}

        root.nextUpdateTime = Date.now() + (root.updateInterval * 60000);
        root.lastUpdateTime = new Date();

        if (actualData.current_condition) {
            processWttrInData(actualData);
        } else if (actualData.current) {
            processOpenMeteoData(actualData);
        }
    }

    function processWttrInData(data) {
        const cur = data.current_condition[0];
        root.location = data.nearest_area ? (data.nearest_area[0].areaName[0].value) : "Unknown";
        
        root.current = {
            temp: root.unit === "C" ? cur.temp_C : cur.temp_F,
            feelsLike: root.unit === "C" ? cur.FeelsLikeC : cur.FeelsLikeF,
            condition: cur.weatherDesc[0].value,
            icon: mapWeatherIcon(cur.weatherCode, true),
            humidity: cur.humidity,
            windSpeed: root.unit === "C" ? cur.windspeedKmph : cur.windspeedMiles
        }

        let hourlyList = [];
        if (data.weather && data.weather.length > 0) {
            const today = data.weather[0];
            root.todayHigh = root.unit === "C" ? today.maxtempC : today.maxtempF;
            root.todayLow = root.unit === "C" ? today.mintempC : today.mintempF;
            
            const todayHourly = today.hourly || [];
            const tomorrow = data.weather[1] ? (data.weather[1].hourly || []) : [];
            const allHourly = todayHourly.concat(tomorrow);
            
            const nowHour = new Date().getHours() * 100;
            let startIndex = allHourly.findIndex(h => parseInt(h.time) >= nowHour);
            if (startIndex === -1) startIndex = 0;

            for (let i = startIndex; i < startIndex + 6 && i < allHourly.length; i++) {
                const h = allHourly[i];
                hourlyList.push({
                    time: formatHour(h.time),
                    temp: root.unit === "C" ? h.tempC : h.tempF,
                    icon: mapWeatherIcon(h.weatherCode, isDaytime(h.time)),
                    condition: h.weatherDesc[0].value
                });
            }
        }
        root.hourly = hourlyList;

        let dailyList = [];
        if (data.weather) {
            for (let i = 0; i < Math.min(data.weather.length, 3); i++) {
                const d = data.weather[i];
                dailyList.push({
                    date: i === 0 ? "Today" : formatDate(d.date),
                    maxTemp: root.unit === "C" ? d.maxtempC : d.maxtempF,
                    minTemp: root.unit === "C" ? d.mintempC : d.mintempF,
                    icon: mapWeatherIcon(d.hourly[4]?.weatherCode || "113", true)
                });
            }
        }
        root.daily = dailyList;
    }

    function processOpenMeteoData(data) {
        const cur = data.current;
        const daily = data.daily;
        const hourly = data.hourly;

        root.current = {
            temp: Math.round(cur.temperature_2m).toString(),
            feelsLike: Math.round(cur.apparent_temperature).toString(),
            condition: wmoToDesc(cur.weather_code),
            icon: mapWeatherIcon(wmoToWwo(cur.weather_code), cur.is_day === 1),
            humidity: Math.round(cur.relative_humidity_2m).toString(),
            windSpeed: Math.round(cur.wind_speed_10m).toString()
        }

        if (daily && daily.temperature_2m_max && daily.temperature_2m_max.length > 0) {
            root.todayHigh = Math.round(daily.temperature_2m_max[0]).toString();
            root.todayLow = Math.round(daily.temperature_2m_min[0]).toString();
        }

        let hourlyList = [];
        if (hourly && hourly.time) {
            const now = new Date();
            const nowIdx = hourly.time.findIndex(t => new Date(t) > now) || 0;
            const startIdx = Math.max(0, nowIdx - 1);
            
            for (let i = startIdx; i < startIdx + 6; i++) {
                if (!hourly.time[i]) break;
                hourlyList.push({
                    time: formatHour(((new Date(hourly.time[i]).getHours()) * 100).toString()),
                    temp: Math.round(hourly.temperature_2m[i]).toString(),
                    icon: mapWeatherIcon(wmoToWwo(hourly.weather_code[i]), i >= startIdx && i <= startIdx + 12 ? cur.is_day === 1 : true),
                    condition: wmoToDesc(hourly.weather_code[i])
                });
            }
        }
        root.hourly = hourlyList;

        let dailyList = [];
        if (daily && daily.time) {
            for (let i = 0; i < Math.min(daily.time.length, 3); i++) {
                dailyList.push({
                    date: i === 0 ? "Today" : formatDate(daily.time[i]),
                    maxTemp: Math.round(daily.temperature_2m_max[i]).toString(),
                    minTemp: Math.round(daily.temperature_2m_min[i]).toString(),
                    icon: mapWeatherIcon(wmoToWwo(daily.weather_code[i]), true)
                });
            }
        }
        root.daily = dailyList;
    }

    function wmoToWwo(wmo) {
        if (wmo === 0) return 113;
        if (wmo === 1) return 113;
        if (wmo === 2) return 116;
        if (wmo === 3) return 119;
        if (wmo === 45 || wmo === 48) return 248;
        if (wmo >= 51 && wmo <= 55) return 266;
        if (wmo >= 61 && wmo <= 65) return 296;
        if (wmo >= 71 && wmo <= 75) return 332;
        if (wmo >= 80 && wmo <= 82) return 299;
        if (wmo >= 95) return 389;
        return 119;
    }

    function wmoToDesc(wmo) {
        const map = {
            0: "Clear Sky", 1: "Mainly Clear", 2: "Partly Cloudy", 3: "Overcast",
            45: "Foggy", 48: "Rime Fog",
            51: "Light Drizzle", 53: "Moderate Drizzle", 55: "Dense Drizzle",
            56: "Light Freezing Drizzle", 57: "Dense Freezing Drizzle",
            61: "Slight Rain", 63: "Moderate Rain", 65: "Heavy Rain",
            66: "Light Freezing Rain", 67: "Heavy Freezing Rain",
            71: "Slight Snowfall", 73: "Moderate Snowfall", 75: "Heavy Snowfall",
            77: "Snow Grains",
            80: "Slight Rain Showers", 81: "Moderate Rain Showers", 82: "Violent Rain Showers",
            85: "Slight Snow Showers", 86: "Heavy Snow Showers",
            95: "Thunderstorm", 96: "Thunderstorm with Hail", 99: "Thunderstorm with Heavy Hail"
        }
        return map[wmo] || "Cloudy";
    }

    function isDaytime(timeStr) {
        let h = parseInt(timeStr) / 100;
        return h >= 6 && h <= 18;
    }

    function formatHour(timeStr) {
        let h = parseInt(timeStr) / 100;
        if (h === 0) return "12 AM";
        if (h === 12) return "12 PM";
        return h > 12 ? (h - 12) + " PM" : h + " AM";
    }

    function formatDate(dateStr) {
        const date = new Date(dateStr);
        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[date.getDay()];
    }

    function mapWeatherIcon(code, isDay) {
        const c = parseInt(code);
        if (c === 113) return isDay ? "clear_day" : "clear_night";
        if (c === 116) return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
        if (c === 119 || c === 122) return "cloudy";
        if ([143, 248, 260].includes(c)) return "haze_fog_dust_smoke";
        if ([176, 263, 266, 293, 296].includes(c)) return isDay ? "rain_with_sunny_light" : "rain_with_cloudy_light";
        if ([299, 302, 305, 308, 353, 356, 359].includes(c)) return "heavy_rain";
        if ([311, 314].includes(c)) return "mixed_rain_hail_sleet";
        if ([179, 323, 326, 368].includes(c)) return isDay ? snow_with_sunny_light : "snow_with_cloudy_light";
        if ([227, 230, 329, 332, 335, 338, 371].includes(c)) return "heavy_snow";
        if ([317, 320, 362, 365].includes(c)) return "mixed_rain_snow";
        if ([200, 386, 389, 392, 395].includes(c)) return "strong_thunderstorms";
        return "cloudy";
    }
}
