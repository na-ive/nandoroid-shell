pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../core"
import "."

Item {
    id: root

    property var sections: []
    property string currentSearch: ""
    property bool isIndexing: pageFile.currentIndex < pageFile.files.length && pageFile.files.length > 0

    function startIndexing() {
        sections = []
        pageFile.startIndex([
            "panels/Settings/pages/NetworkSettings.qml",
            "panels/Settings/pages/BluetoothSettings.qml",
            "panels/Settings/pages/AudioSettings.qml",
            "panels/Settings/pages/DisplaySettings.qml",
            "panels/Settings/pages/WallpaperStyleSettings.qml",
            "panels/Settings/pages/ServicesSettings.qml",
            "panels/Settings/pages/AboutSettings.qml"
        ])
    }

    Component.onCompleted: startIndexing()

    // Listen for language changes
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
            path = Quickshell.shellPath(files[currentIndex])
            reload()
        }

        onLoaded: {
            console.log("[SearchRegistry] Loaded page file:", path)
            root.indexQmlFile(text(), currentIndex)
            console.log("[SearchRegistry] Indexed", currentIndex + 1, "/", files.length)
            currentIndex++
            if (currentIndex < files.length) {
                Qt.callLater(() => loadNext())
            } else {
                console.log("[SearchRegistry] Indexing complete. Total sections:", sections.length)
            }
        }
    }

    function indexQmlFile(qmlText, pageIndex) {
        if (!qmlText) return

        let propRegex = /(?:title|text|buttonText|placeholderText|mainText|label|name)\s*:\s*(?:Translation\.tr\()?\s*["']([^"']+)["']/g
        let propMatch
        let searchStrings = []
        while ((propMatch = propRegex.exec(qmlText)) !== null) {
            let str = propMatch[1]
            if (str.length > 2 && !searchStrings.includes(str)) searchStrings.push(str)
        }
        
        if (searchStrings.length > 0) {
            registerSection({
                pageIndex: pageIndex,
                title: getPageName(pageIndex),
                searchStrings: searchStrings
            })
        }
    }

    function getPageName(index) {
        const names = ["Network", "Bluetooth", "Audio", "Display", "Wallpaper & Style", "Services", "About"]
        return names[index] || "Unknown"
    }

    function registerSection(data) {
        // Build search tokens
        let searchStringsLower = data.searchStrings.map(s => s.toLowerCase())
        let translatedStringsLower = data.searchStrings.map(s => Translation.tr(s).toLowerCase())
        let titleLower = data.title.toLowerCase()
        let translatedTitleLower = Translation.tr(data.title).toLowerCase()

        let tokens = []
        let allStrings = [titleLower, translatedTitleLower, ...searchStringsLower, ...translatedStringsLower]
        for (let str of allStrings) {
            tokens.push(...tokenize(str))
        }
        
        data.tokens = Array.from(new Set(tokens)) // unique tokens
        data.translatedTitle = Translation.tr(data.title)
        data.translatedStrings = data.searchStrings.map(s => Translation.tr(s))
        
        let newSections = sections.slice()
        newSections.push(data)
        sections = newSections
    }

    function tokenize(text) {
        if (!text) return []
        // Split by non-alphanumeric and underscores, keep only words > 2 chars
        return text.toLowerCase().split(/[^a-z0-9_]+/).filter(t => t.length > 2)
    }

    function fuzzyMatch(query, text) {
        if (!query || !text) return 0
        if (text.includes(query)) return 100 // Direct substring match
        
        let score = 0
        let queryIdx = 0
        for (let i = 0; i < text.length && queryIdx < query.length; i++) {
            if (text[i] === query[queryIdx]) {
                queryIdx++
                score += 10
            } else {
                score -= 1
            }
        }
        return queryIdx === query.length ? Math.max(0, score) : 0
    }

    function getResultsRanked(query) {
        if (!query || query.trim() === "") return []
        query = query.toLowerCase().trim()
        let queryTokens = tokenize(query)
        
        let results = []
        for (let section of sections) {
            let score = 0
            
            // 1. Exact or partial title match
            let titleLower = section.translatedTitle.toLowerCase()
            if (titleLower === query) score += 2000
            else if (titleLower.includes(query)) score += 1000
            
            // 2. Token matches
            for (let qToken of queryTokens) {
                for (let sToken of section.tokens) {
                    if (sToken === qToken) score += 500
                    else if (sToken.includes(qToken)) score += 200
                }
            }
            
            // 3. String matches
            let bestStr = ""
            if (section.translatedStrings) {
                for (let str of section.translatedStrings) {
                    let lower = str.toLowerCase()
                    if (lower === query) {
                        score += 800
                        bestStr = str
                        break
                    } else if (lower.includes(query)) {
                        score += 400
                        if (bestStr === "") bestStr = str
                    }
                }
            }

            // 4. Fuzzy match fallback
            if (score === 0 && query.length > 3) {
                let fuzzy = fuzzyMatch(query, section.translatedTitle.toLowerCase())
                if (fuzzy > 20) score += fuzzy
            }
            
            if (score > 0) {
                results.push({
                    pageIndex: section.pageIndex,
                    title: section.translatedTitle,
                    matchedString: bestStr || section.translatedTitle,
                    score: score
                })
            }
        }
        
        results.sort((a, b) => b.score - a.score)
        return results
    }

    function getBestResult(query) {
        let results = getResultsRanked(query)
        return results.length > 0 ? results[0] : null
    }
}
