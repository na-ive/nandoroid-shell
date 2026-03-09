pragma Singleton

/**
 * ╔════════════ SEARCH INDEX REGISTRY ════════════╗
 * ║                                               ║
 * ║ IMPORTANT: When adding new settings pages or  ║
 * ║ sub-components, you MUST register the .qml    ║
 * ║ file path in the startIndexing() function     ║
 * ║ below to make it searchable.                  ║
 * ║                                               ║
 * ╚═══════════════════════════════════════════════╝
 */

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "."

Item {
    id: root

    property string currentSearch: ""
    property var sections: []
    property bool isIndexing: pageFile.currentIndex < pageFile.files.length && pageFile.files.length > 0

    function startIndexing() {
        sections = []
        pageFile.startIndex([
            { file: "panels/Settings/pages/Network/NetworkSettings.qml", pageIndex: 0 },
            { file: "panels/Settings/pages/Network/NetworkMainView.qml", pageIndex: 0 },
            { file: "panels/Settings/pages/Network/NetworkSavedView.qml", pageIndex: 0 },
            { file: "panels/Settings/pages/Network/NetworkWiredView.qml", pageIndex: 0 },
            { file: "panels/Settings/pages/Bluetooth/BluetoothSettings.qml", pageIndex: 1 },
            { file: "panels/Settings/pages/Audio/AudioSettings.qml", pageIndex: 2 },
            { file: "panels/Settings/pages/Display/DisplaySettings.qml", pageIndex: 3 },
            { file: "panels/Settings/pages/Display/DisplayEyeCare.qml", pageIndex: 3 },
            { file: "panels/Settings/pages/WallpaperStyle/WallpaperStyleSettings.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsThemeColor.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsLauncher.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsOverview.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsClock.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsLockscreen.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsStatusBar.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsScreenDecor.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsTypography.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsDateTime.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/WallpaperStyle/WsWallpaperCycle.qml", pageIndex: 4 },
            { file: "panels/Settings/pages/Services/ServicesSettings.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesWeather.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesSearch.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesNetwork.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesDisk.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesPerformance.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesMedia.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesPower.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesSystem.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/Services/ServicesGitHub.qml", pageIndex: 5 },
            { file: "panels/Settings/pages/About/AboutSettings.qml", pageIndex: 6 },
            { file: "panels/Settings/pages/About/AboutCredits.qml", pageIndex: 6 },
            { file: "panels/Settings/pages/About/AboutDependency.qml", pageIndex: 6 },
            { file: "panels/Settings/pages/About/AboutUpdate.qml", pageIndex: 6 },
            { file: "panels/Settings/pages/About/AboutMainView.qml", pageIndex: 6 }
        ])
    }

    Component.onCompleted: startIndexing()

    Connections {
        target: Translation
        function onLanguageCodeChanged() {
            startIndexing()
        }
    }

    FileView {
        id: pageFile
        property var files: []
        property int currentIndex: 0

        function startIndex(filesArray) {
            files = filesArray
            currentIndex = 0
            loadNext()
        }

        function loadNext() {
            if (currentIndex >= files.length) return
            path = Quickshell.shellPath(files[currentIndex].file)
            reload()
        }

        onLoaded: {
            const content = text();
            if (content) {
                root.indexQmlFile(content, files[currentIndex].pageIndex);
            }
            currentIndex++
            if (currentIndex < files.length) {
                Qt.callLater(() => loadNext())
            }
        }
        
        onLoadFailed: (error) => {
            console.error("[SearchRegistry] Failed to load file:", path, "Error:", error);
            currentIndex++;
            if (currentIndex < files.length) Qt.callLater(() => loadNext());
        }
    }

    function indexQmlFile(qmlText, pageIndex) {
        if (!qmlText) return

        // 1. First, find all SearchHandlers to identify "Portals"
        let handlerRegex = /SearchHandler\s*\{[\s\S]*?searchString\s*:\s*["']([^"']+)["'](?:[\s\S]*?aliases\s*:\s*\[([\s\S]*?)\])?/g
        let handlerMatch
        let portals = []
        while ((handlerMatch = handlerRegex.exec(qmlText)) !== null) {
            let canonical = handlerMatch[1]
            let aliasStr = handlerMatch[2] || ""
            let aliases = aliasStr.split(",").map(s => s.replace(/["']/g, "").trim()).filter(s => s !== "")
            portals.push({ canonical: canonical, aliases: aliases })
        }

        // 2. If no portals found, use page title as fallback
        if (portals.length === 0) {
            portals.push({ canonical: getPageName(pageIndex), aliases: [] })
        }

        // 3. Find all searchable strings
        let propRegex = /(?:title|text|buttonText|placeholderText|mainText|label|name|description|hint|headerText)\s*:\s*(?:(?:Translation\.tr|qsTr|qsTranslate)\s*\(\s*)?["']([^"']+)["']/g
        let propMatch
        let allStrings = []
        while ((propMatch = propRegex.exec(qmlText)) !== null) {
            let str = propMatch[1]
            if (str.length >= 2 && !allStrings.includes(str)) allStrings.push(str)
        }

        // Register each portal as a searchable section
        portals.forEach(portal => {
            registerSection({
                pageIndex: pageIndex,
                title: getPageName(pageIndex),
                canonical: portal.canonical,
                aliases: portal.aliases,
                contentStrings: allStrings // Map all strings in file to these portals for now
            })
        })
    }

    function getPageName(index) {
        const names = ["Network", "Bluetooth", "Audio", "Display", "Wallpaper & Style", "Services", "About"]
        return names[index] || "Unknown"
    }

    function registerSection(data) {
        let tokens = new Set()
        
        // Add canonical, aliases, and content to tokens
        tokenize(data.canonical).forEach(t => tokens.add(t))
        data.aliases.forEach(a => tokenize(a).forEach(t => tokens.add(t)))
        
        // contentStrings help finding the portal even if user doesn't type canonical name
        data.contentStrings.forEach(s => tokenize(s).forEach(t => tokens.add(t)))
        
        data.tokens = Array.from(tokens)
        data.translatedTitle = Translation.tr(data.title)
        
        let newSections = sections.slice()
        newSections.push(data)
        sections = newSections
    }

    function tokenize(text) {
        if (!text) return []
        return text.toLowerCase().split(/[^a-z0-9_]+/).filter(t => t.length >= 2)
    }

    function levenshtein(a, b) {
        if (a.length === 0) return b.length;
        if (b.length === 0) return a.length;
        let matrix = [];
        for (let i = 0; i <= b.length; i++) matrix[i] = [i];
        for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
        for (let i = 1; i <= b.length; i++) {
            for (let j = 1; j <= a.length; j++) {
                if (b.charAt(i - 1) === a.charAt(j - 1)) matrix[i][j] = matrix[i - 1][j - 1];
                else matrix[i][j] = Math.min(matrix[i - 1][j - 1] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j] + 1);
            }
        }
        return matrix[b.length][a.length];
    }

    function getResultsRanked(query) {
        if (!query || query.trim() === "") return []
        query = query.toLowerCase().trim()
        let queryTokens = tokenize(query)
        
        let results = []
        for (let section of sections) {
            let score = 0
            
            // Priority 1: Canonical match
            if (section.canonical.toLowerCase() === query) score += 10000
            else if (section.canonical.toLowerCase().includes(query)) score += 5000
            
            // Priority 2: Alias match
            section.aliases.forEach(a => {
                if (a.toLowerCase() === query) score += 8000
                else if (a.toLowerCase().includes(query)) score += 4000
            })
            
            // Priority 3: Token match
            for (let qToken of queryTokens) {
                for (let sToken of section.tokens) {
                    if (sToken === qToken) score += 1000
                    else if (sToken.includes(qToken)) score += 200
                }
            }
            
            if (score > 0) {
                results.push({
                    pageIndex: section.pageIndex,
                    title: section.translatedTitle,
                    matchedString: section.canonical, // Always return the canonical portal name
                    score: score
                })
            }
        }
        
        results.sort((a, b) => b.score - a.score)
        
        // --- STRICT DEDUPLICATION ---
        let uniqueResults = []
        let seenTargets = new Set()
        
        for (let res of results) {
            // deduplicate by page + canonical target
            let key = res.pageIndex + "|" + res.matchedString.toLowerCase()
            if (!seenTargets.has(key)) {
                uniqueResults.push(res)
                seenTargets.add(key)
            }
        }
        
        return uniqueResults
    }

    function getBestResult(query) {
        let results = getResultsRanked(query)
        return results.length > 0 ? results[0] : null
    }
}
