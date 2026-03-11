pragma Singleton
pragma ComponentBehavior: Bound
import "../core"
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    
    // Convenience properties for UI
    property real volume: sink?.audio.volume ?? 0
    property real microphoneVolume: source?.audio.volume ?? 0
    property bool muted: sink?.audio.muted ?? false
    property bool microphoneMuted: source?.audio.muted ?? false

    // Setters that update hardware (safely)
    function setVolume(v) { if (sink && sink.audio) sink.audio.volume = v }
    function setMicrophoneVolume(v) { if (source && source.audio) source.audio.volume = v }
    function setMuted(m) { if (sink && sink.audio) sink.audio.muted = m }
    function setMicrophoneMuted(m) { if (source && source.audio) source.audio.muted = m }

    readonly property real hardMaxValue: 2.00 
    property string audioTheme: (Config.options.sounds && Config.options.sounds.theme) ? Config.options.sounds.theme : "freedesktop"
    
    // For backward compatibility or internal use
    property real value: volume

    function friendlyDeviceName(node) {
        return (node.nickname || node.description || qsTr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    // Lists for UI
    function getNodesByType(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return (node.isSink === isSink) && node.audio && !node.isStream
        })
    }

    readonly property list<var> outputDevices: getNodesByType(true)
    readonly property list<var> inputDevices: getNodesByType(false)
    readonly property list<var> sinks: outputDevices // alias
    readonly property list<var> sources: inputDevices // alias

    // Selection
    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() { setMuted(!muted) }
    function toggleMicMute() { setMicrophoneMuted(!microphoneMuted) }

    function incrementVolume() {
        setVolume(Math.min(1.0, volume + (volume < 0.1 ? 0.01 : 0.02)));
    }
    
    function decrementVolume() {
        setVolume(Math.max(0, volume - (volume < 0.1 ? 0.01 : 0.02)));
    }

    // Internals
    PwObjectTracker {
        objects: [sink, source]
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", ogaPath]);
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", oggPath]);
    }
}
