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
        console.log("[Weather] Config update: Next refresh in " + updateInterval + " min");
        root.nextUpdateTime = Date.now() + (updateInterval * 60000);
    }

    // --- Cache Loading ---
    Process {
        id: readCacheProc
        command: ["bash", "-c", `mkdir -p "${root.cacheDir}" && [ -f "${root.cachePath}" ] && cat "${root.cachePath}" || exit 0`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (trimmed !== "" && trimmed.indexOf("{") === 0) {
                            const data = JSON.parse(trimmed);
                            processWeatherData(data);
                            console.log("[Weather] Cache loaded successfully");
                        }
                    } catch (e) {
                        console.error("[Weather] Cache parse error:", e);
                    }
                });
            }
        }
    }

    // --- Fetch Logic ---
    function fetch(silent = false) {
        if (Config.ready && Config.options.weather && !Config.options.weather.enable) {
            console.log("[Weather] Fetch aborted: Service is disabled.");
            return;
        }

        if (loading && !silent) {
            console.log("[Weather] Manual fetch ignored: update already in progress");
            return;
        }
        
        // Safety: if it's been loading for too long, reset it
        if (loading) console.log("[Weather] Fetching over existing process...");
        
        // Re-check health status (1 hour cooldown for wttr.in)
        const now = new Date().getTime();
        if (!wttrInHealthy && (now - lastWttrInFail > 3600000)) {
            console.log("[Weather] Retrying wttr.in after cooldown");
            wttrInHealthy = true;
        }

        console.log("[Weather] Fetching updated data...");
        root.status = "Connecting...";
        if (!silent) loading = true;
        
        weatherProc.running = false;
        ipLocProc.running = false;
        geocodingProc.running = false;
        openMeteoProc.running = false;
        
        if (wttrInHealthy) {
            weatherProc.running = true;
        } else {
            console.log("[Weather] wttr.in marked down, jumping to fallback");
            fallbackTrigger();
        }
    }

    function fallbackTrigger() {
        root.status = "Finding location...";
        console.log("[Weather] Starting fallback sequence...");
        console.log("[Weather] Manual Location String: '" + root.manualLocation + "'");
        
        if (root.autoLocation || root.manualLocation.trim() === "") {
            console.log("[Weather] Using IP location (Auto: " + root.autoLocation + ")");
            ipLocProc.running = false;
            ipLocProc.running = true;
        } else {
            console.log("[Weather] Using Geocoding for: " + root.manualLocation);
            geocodingProc.running = false;
            geocodingProc.running = true;
        }
    }

    Timer {
        id: watchdogTimer
        interval: 60000 // Check every minute
        running: true
        repeat: true
        onTriggered: {
            if (Config.ready && Config.options.weather && !Config.options.weather.enable) {
                return; // Do nothing if weather service is disabled
            }
            const now = Date.now();
            if (root.nextUpdateTime > 0) {
                const remainingSecs = Math.round((root.nextUpdateTime - now) / 1000);
                if (now >= root.nextUpdateTime) {
                    console.log("[Weather] Watchdog: TARGET REACHED! Fetching now...");
                    root.fetch(true);
                } else if (remainingSecs > 0 && remainingSecs <= 60 && remainingSecs % 20 === 0) {
                    // Log every 20s when under 1 minute
                    console.log("[Weather] Watchdog: Auto-refresh in " + remainingSecs + "s");
                } else if (remainingSecs > 60 && remainingSecs % 300 === 0) {
                    // Log every 5 minutes for long intervals
                    console.log("[Weather] Watchdog: Next update in ~" + Math.round(remainingSecs/60) + " minutes");
                }
            } else {
                root.nextUpdateTime = now + (root.updateInterval * 60000);
            }
        }
    }

    Component.onCompleted: {
        console.log("[Weather] Service started.");
        
        // 1. Synchronously read cache via FileView
        try {
            const cacheData = cacheFileWriter.text;
            if (cacheData && cacheData.trim() !== "" && cacheData.indexOf("{") === 0) {
                const data = JSON.parse(cacheData);
                root.processWeatherData(data);
                console.log("[Weather] Cache loaded synchronously");
            }
        } catch (e) {
            console.warn("[Weather] Sync cache read failed, falling back to process");
            readCacheProc.running = true;
        }
        
        // 2. Schedule first network update (silent)
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
            if (Config.ready) {
                root.fetch(true);
            } else {
                // Wait for config if needed
                interval = 500;
                start();
            }
        }
    }

    Process {
        id: weatherProc
        command: {
            const cleanLoc = root.autoLocation ? "" : root.manualLocation.split(',')[0].replace(/Regency/g, '').trim();
            const loc = encodeURIComponent(cleanLoc);
            return ["bash", "-c", `curl -sfL -m 8 --connect-timeout 4 "https://wttr.in/${loc}?format=j1"`];
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("[Weather] wttr.in failed (exit "+exitCode+"), marking down");
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
                    } catch (e) {
                        console.error("[Weather] JSON Parse Error:", e);
                    }
                });
            }
        }
    }

    FileView {
        id: cacheFileWriter
        path: root.cachePath
    }

    // --- Fallback Backend (Open-Meteo) ---
    Process {
        id: ipLocProc
        command: ["bash", "-c", "curl -sfL -m 8 http://ip-api.com/json/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (!results) throw "Empty response";
                        const data = JSON.parse(results);
                        if (data.status === "success") {
                            console.log("[Weather] Step: IP Loc successful ->", data.city);
                            root.fetchOpenMeteo(data.lat.toString(), data.lon.toString(), data.city);
                        } else {
                            throw data.message || "Unknown error";
                        }
                    } catch(e) { 
                        console.error("[Weather] Step: IP Loc failed:", e);
                        root.status = "Location Error";
                        root.loading = false;
                    }
                });
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0 && root.loading && root.status === "Finding location...") {
                console.error("[Weather] Step: IP Loc process exited with", exitCode);
                root.status = "Network Error";
                root.loading = false;
            }
        }
    }

    Process {
        id: geocodingProc
        command: {
            // Clean location string: 'Karanganyar Regency, ID' -> 'Karanganyar'
            let cleanLoc = root.manualLocation.split(',')[0].replace(/Regency/g, '').trim();
            const loc = encodeURIComponent(cleanLoc);
            console.log("[Weather] Step: Geocoding search for cleaned name: '" + cleanLoc + "'");
            return ["bash", "-c", `curl -sfL -m 15 "https://geocoding-api.open-meteo.com/v1/search?name=${loc}&count=1&language=en&format=json"`];
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
                            console.log("[Weather] Step: Geocoding successful ->", displayName);
                            root.fetchOpenMeteo(res.latitude.toString(), res.longitude.toString(), displayName);
                        } else {
                            console.warn("[Weather] Step: Geocoding no results, trying IP fallback");
                            ipLocProc.running = false;
                            ipLocProc.running = true;
                        }
                    } catch(e) { 
                        console.error("[Weather] Step: Geocoding parse error, trying IP fallback");
                        ipLocProc.running = false;
                        ipLocProc.running = true;
                    }
                });
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.warn("[Weather] Step: Geocoding process failed (exit " + exitCode + "), trying IP fallback");
                ipLocProc.running = false;
                ipLocProc.running = true;
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
            const latVal = openMeteoProc.lat;
            const lonVal = openMeteoProc.lon;
            if (!latVal || !lonVal) return ["true"];
            
            const tempUnit = root.unit === "F" ? "&temperature_unit=fahrenheit" : "";
            const windUnit = root.unit === "F" ? "&wind_speed_unit=mph" : "&wind_speed_unit=kmh";
            const url = `https://api.open-meteo.com/v1/forecast?latitude=${latVal}&longitude=${lonVal}${tempUnit}${windUnit}&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto`;
            
            console.log("[Weather] Step: Fetching forecast for " + latVal + "," + lonVal);
            // Increased timeout to 15s
            return ["bash", "-c", `mkdir -p "${root.cacheDir}" && curl -sfL -m 15 "${url}" > "${root.cachePath}.tmp" && jq -e . "${root.cachePath}.tmp" >/dev/null 2>&1 && mv "${root.cachePath}.tmp" "${root.cachePath}" && cat "${root.cachePath}"` ];
        }
        
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                console.error("[Weather] Step: Open-Meteo process failed (exit " + exitCode + ")");
                root.status = "API Error";
            }
            root.loading = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const results = this.text.trim();
                Qt.callLater(() => {
                    try {
                        if (!results) {
                            console.warn("[Weather] Step: Open-Meteo returned empty stdout");
                            return;
                        }
                        const data = JSON.parse(results);
                        processWeatherData(data); // Using the central processor that saves cache
                        console.log("[Weather] Step: UI and Cache update triggered");
                        root.status = "Updated via fallback";
                    } catch(e) {
                        console.error("[Weather] Step: Open-Meteo Parse Error:", e);
                    }
                });
            }
        }
    }

    function processWeatherData(data) {
        if (!data) return;
        const jsonStr = JSON.stringify(data);
        console.log("[Weather] Step: Processing data (" + jsonStr.length + " bytes)");
        
        try {
            // Quickshell.Io FileView uses setText for writing
            cacheFileWriter.setText(jsonStr);
            console.log("[Weather] Step: JSON Cache updated via FileView");
        } catch(e) {
            console.error("[Weather] Step: JSON Cache write error:", e);
        }

        // Schedule next update from this moment
        root.nextUpdateTime = Date.now() + (root.updateInterval * 60000);

        if (data.current_condition) {
            processWttrInData(data);
        } else if (data.current) {
            processOpenMeteoData(data);
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

        // Hourly
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

        // Daily
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
        root.lastUpdateTime = new Date();
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

        // Hourly
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
                    icon: mapWeatherIcon(wmoToWwo(hourly.weather_code[i]), i >= startIdx && i <= startIdx + 12 ? cur.is_day === 1 : true), // Simplified is_day for hourly
                    condition: wmoToDesc(hourly.weather_code[i])
                });
            }
        }
        root.hourly = hourlyList;

        // Daily
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
        root.lastUpdateTime = new Date();
    }

    function wmoToWwo(wmo) {
        if (wmo === 0) return 113; // Clear
        if (wmo === 1) return 113; // Mainly clear
        if (wmo === 2) return 116; // Partly cloudy
        if (wmo === 3) return 119; // Overcast
        if (wmo === 45 || wmo === 48) return 248; // Fog
        if (wmo >= 51 && wmo <= 55) return 266; // Drizzle
        if (wmo >= 61 && wmo <= 65) return 296; // Rain
        if (wmo >= 71 && wmo <= 75) return 332; // Snow
        if (wmo >= 80 && wmo <= 82) return 299; // Rain showers
        if (wmo >= 95) return 389; // Thunderstorm
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
