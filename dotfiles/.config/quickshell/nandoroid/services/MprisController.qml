pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../core"
import "../core/functions" as Functions
import "../widgets"

/**
 * Simplified MPRIS controller — wraps Quickshell's Mpris service
 * for easy access to the active media player.
 */
Singleton {
    id: root
    property MprisPlayer activePlayer: trackedPlayer ?? Mpris.players.values[0] ?? null
    property MprisPlayer trackedPlayer: null
    property bool isPlaying: activePlayer && activePlayer.isPlaying
    property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    property bool canGoNext: activePlayer?.canGoNext ?? false

    property string trackTitle: activePlayer?.trackTitle || "No media"
    property string trackArtist: activePlayer?.trackArtist || ""
    property string trackArtUrl: activePlayer?.trackArtUrl ?? ""
    property string desktopEntry: activePlayer?.desktopEntry ?? ""

    property real position: activePlayer?.position ?? 0
    property real length: activePlayer?.length ?? 0

    // --- Persistent Art & Color Logic ---
    property string _artDownloadLocation: Functions.FileUtils.trimFileProtocol(Directories.cache) + "/nandoroid/coverArt"
    property string _activeArtPath: ""
    property bool _artDownloaded: false
    property double _cacheBuster: 0
    property string displayedArtFilePath: _artDownloaded ? ((_activeArtPath.startsWith("/") ? `file://${_activeArtPath}` : _activeArtPath) + "?t=" + _cacheBuster) : ""

    property string _pendingUrl: ""
    property string _pendingDest: ""

    property color artDominantColor: {
        // Initial fallback
        if (!_artDownloaded && _activeArtPath === "") return Appearance.colors.colPrimaryContainer

        let raw = (colorQuantizer.colors && colorQuantizer.colors.length > 0) ? colorQuantizer.colors[0] : Appearance.colors.colPrimary
        return Functions.ColorUtils.mix(raw, Appearance.colors.colPrimaryContainer, 0.8) || Appearance.m3colors.m3secondaryContainer
    }

    // --- Dynamic Color Tokens (Persistent) ---
    property bool _colorIsDark: artDominantColor.hslLightness < 0.5
    
    property color dynLayer0: Functions.ColorUtils.mix(Appearance.colors.colLayer0, artDominantColor, (_colorIsDark && Appearance.m3colors.darkmode) ? 0.6 : 0.5)
    property color dynOnLayer0: Functions.ColorUtils.mix(Appearance.colors.colOnLayer0, artDominantColor, 0.5)
    property color dynSubtext: Functions.ColorUtils.mix(Appearance.colors.colOnLayer1, artDominantColor, 0.5)

    property color dynPrimary: Functions.ColorUtils.mix(Functions.ColorUtils.adaptToAccent(Appearance.colors.colPrimary, artDominantColor), artDominantColor, 0.5)
    property color dynSecondaryContainer: Functions.ColorUtils.mix(Appearance.m3colors.m3secondaryContainer, artDominantColor, 0.15)
    property color dynOnSecondaryContainer: Functions.ColorUtils.mix(Appearance.m3colors.m3onSecondaryContainer, artDominantColor, 0.5)
    property color dynPrimaryActive: Functions.ColorUtils.mix(Functions.ColorUtils.adaptToAccent(Appearance.colors.colPrimaryActive, artDominantColor), artDominantColor, 0.3)
    property color dynSecondaryContainerActive: Functions.ColorUtils.mix(Appearance.colors.colSecondaryContainerActive, artDominantColor, 0.5)
    property color dynOnPrimary: Functions.ColorUtils.mix(Functions.ColorUtils.adaptToAccent(Appearance.m3colors.m3onPrimary, artDominantColor), artDominantColor, 0.5)

    property color dynPrimaryHover: Functions.ColorUtils.mix(dynPrimary, Appearance.colors.colOnLayer0, 0.9)
    property color dynSecondaryContainerHover: Functions.ColorUtils.mix(dynSecondaryContainer, Appearance.colors.colOnLayer0, 0.9)

    onActivePlayerChanged: updateArtFile()
    
    Connections {
        target: activePlayer
        function onTrackArtUrlChanged() { root.updateArtFile() }
        function onPostTrackChanged() { root.updateArtFile() }
    }

    function updateArtFile() {
        if (!activePlayer || !activePlayer.trackArtUrl || activePlayer.trackArtUrl === "") {
            _artDownloaded = false
            _activeArtPath = ""
            return;
        }

        const url = activePlayer.trackArtUrl
        if (url.startsWith("file://")) {
            _activeArtPath = Functions.FileUtils.trimFileProtocol(url)
            _cacheBuster = Date.now()
            _artDownloaded = true
        } else {
            let dest = `${_artDownloadLocation}/${Qt.md5(url)}`
            if (_activeArtPath === dest && _artDownloaded) return;

            _artDownloaded = false
            _activeArtPath = dest
            
            _pendingUrl = url
            _pendingDest = dest

            if (!coverArtDownloader.running) {
                startNextDownload()
            }
        }
    }

    function startNextDownload() {
        if (_pendingUrl === "") return;
        coverArtDownloader.targetUrl = _pendingUrl
        coverArtDownloader.targetDest = _pendingDest
        _pendingUrl = "" 
        coverArtDownloader.running = true
    }

    Process {
        id: coverArtDownloader
        property string targetUrl: ""
        property string targetDest: ""
        command: [ "bash", "-c", `[ -f '${targetDest}' ] || curl -sSL '${targetUrl}' -o '${targetDest}'` ]
        onExited: (exitCode, exitStatus) => {
            if (targetDest === root._activeArtPath) {
                root._cacheBuster = Date.now();
                root._artDownloaded = true;
            }
            if (root._pendingUrl !== "") {
                root.startNextDownload();
            }
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", _artDownloadLocation])
        updateArtFile()
    }
    // ------------------------------------

    Timer {
        id: positionTimer
        interval: 200
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (root.activePlayer) root.activePlayer.positionChanged();
        }
    }

    function togglePlaying() {
        if (canTogglePlaying) activePlayer.togglePlaying();
    }
    function previous() {
        if (canGoPrevious) activePlayer.previous();
    }
    function next() {
        if (canGoNext) activePlayer.next();
    }

    property bool _manualOverride: false
    Timer { id: manualOverrideTimer; interval: 10000; onTriggered: root._manualOverride = false }
    onTrackedPlayerChanged: { if (root._manualOverride) manualOverrideTimer.restart(); }

    property bool hasPlasmaIntegration: false
    Process {
        id: plasmaIntegrationAvailabilityCheckProc
        running: true
        command: ["bash", "-c", "command -v plasma-browser-integration-host"]
        onExited: (exitCode, exitStatus) => {
            root.hasPlasmaIntegration = (exitCode === 0);
        }
    }

    function getValidPlayers() {
        if (!Mpris.players || !Mpris.players.values) return [];
        let valid = Mpris.players.values.filter(p => {
            if (p.dbusName && p.dbusName.startsWith('org.mpris.MediaPlayer2.playerctld')) return false;
            // Native browsers without integration or duplicates
            if (root.hasPlasmaIntegration && p.dbusName && (p.dbusName.startsWith('org.mpris.MediaPlayer2.firefox') || p.dbusName.startsWith('org.mpris.MediaPlayer2.chromium') || p.dbusName.startsWith('org.mpris.MediaPlayer2.brave'))) return false;
            // Ghost buses from chromium/brave usually have entirely blank metadata
            if ((p.trackTitle || "") === "" && (p.trackArtist || "") === "" && (p.trackArtUrl || "") === "") return false;
            return true;
        });

        // Deduplicate browser proxy buses (e.g. native brave vs plasma-browser-integration)
        let unique = [];
        for (let i = 0; i < valid.length; i++) {
            let p = valid[i];
            let title = p.trackTitle || "";
            if (title === "") {
                unique.push(p);
                continue;
            }

            let existingIdx = unique.findIndex(up => (up.trackTitle || "") === title);
            
            if (existingIdx !== -1) {
                // Duplicate track title found. Keep the bus with better metadata.
                let existing = unique[existingIdx];
                let existingScore = (existing.trackArtUrl && existing.trackArtUrl !== "" ? 2 : 0) + (existing.trackArtist && existing.trackArtist !== "" ? 1 : 0);
                let newScore = (p.trackArtUrl && p.trackArtUrl !== "" ? 2 : 0) + (p.trackArtist && p.trackArtist !== "" ? 1 : 0);
                
                if (newScore > existingScore) {
                    unique[existingIdx] = p; // Replace with the richer metadata bus
                }
            } else {
                unique.push(p);
            }
        }
        return unique;
    }

    function cyclePlayer() {
        let players = getValidPlayers();
        if (players.length === 0) return;
        let currentIndex = root.trackedPlayer ? players.indexOf(root.trackedPlayer) : -1;
        let nextIndex = (currentIndex + 1) % players.length;
        root._manualOverride = true;
        root.trackedPlayer = players[nextIndex];
    }

    function autoReevaluatePlayer() {
        if (root._manualOverride) return;
        
        let players = getValidPlayers();
        if (players.length === 0) {
            root.trackedPlayer = null;
            return;
        }
        
        let rawPriority = (Config.ready && Config.options.media && Config.options.media.priority) ? Config.options.media.priority : "";
        let priorities = rawPriority.split(',').map(s => s.trim().toLowerCase()).filter(s => s.length > 0);
        
        let bestScore = -1;
        let bestPlayer = null;
        
        for (let i = 0; i < players.length; i++) {
            let player = players[i];
            let identity = (player.identity || "").toLowerCase();
            let entry = (player.desktopEntry || "").toLowerCase();
            
            let priorityIndex = -1;
            for (let j = 0; j < priorities.length; j++) {
                if (identity.includes(priorities[j]) || entry.includes(priorities[j])) {
                    priorityIndex = priorities.length - j; 
                    break;
                }
            }
            
            let score = 0;
            if (player.isPlaying) score += 1000;
            if (priorityIndex > -1) score += (priorityIndex + 1) * 10000;
            
            if (score > bestScore) {
                bestScore = score;
                bestPlayer = player;
            }
        }
        
        if (bestPlayer && bestPlayer !== root.trackedPlayer) {
            root.trackedPlayer = bestPlayer;
        }
    }

    function raisePlayer() {
        if (!activePlayer) return;
        
        let entry = (activePlayer.desktopEntry || "").toLowerCase();
        let identity = (activePlayer.identity || "").toLowerCase();
        
        if (entry !== "" || identity !== "") {
            let target = entry.replace(".desktop", "") || identity;
            
            // Try focusing by class (most reliable)
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", `class:${target}`]);
            
            // Also try focusing by title/name as a fallback (some apps don't match entry to class)
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", `title:${target}`]);
            
            // Close the notification center to show the window
            GlobalStates.notificationCenterOpen = false;
        }
    }

    Instantiator {
        model: Mpris.players
        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                Qt.callLater(() => { root.autoReevaluatePlayer(); });
                // Aggressive discovery: ensure we check for art as soon as a player exists
                root.updateArtFile();
            }

            Component.onDestruction: {
                Qt.callLater(() => { root.autoReevaluatePlayer(); });
            }

            function onPlaybackStateChanged() {
                root.autoReevaluatePlayer();
            }
        }
    }
}
