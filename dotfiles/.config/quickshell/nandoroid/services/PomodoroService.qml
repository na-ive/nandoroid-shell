pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property double startTimestamp: Date.now()
    property int duration: focusTime
    property int remainingTime: duration
    
    property bool active: false
    property int mode: 0 // 0: Focus, 1: Short Break, 2: Long Break
    
    property int rotations: 0
    property bool autoContinue: true
    property int nextBreakMode: 1 // 1: Short, 2: Long
    
    readonly property bool isSessionRunning: active || (remainingTime < duration && remainingTime > 0)
    
    readonly property int focusTime: 1500 // 25 min
    readonly property int shortBreakTime: 300 // 5 min
    readonly property int longBreakTime: 15 * 60

    readonly property string timeString: {
        const mins = Math.floor(remainingTime / 60);
        const secs = remainingTime % 60;
        return `${mins}:${secs.toString().padStart(2, '0')}`;
    }

    readonly property string modeName: {
        switch (mode) {
            case 0: return "Focus";
            case 1: return "Short Break";
            case 2: return "Long Break";
            default: return "";
        }
    }

    property double elapsedMs: 0
    readonly property real progress: (duration > 0) ? Math.min(1.0, elapsedMs / (duration * 1000)) : 0

    function start() { 
        if (remainingTime === duration) {
            // New session, start fresh
            startTimestamp = Date.now();
        } else {
            // Resume from pause
            startTimestamp = Date.now() - (duration - remainingTime) * 1000;
        }
        active = true; 
    }
    function pause() { active = false; }
    function stop() {
        active = false;
        reset();
    }

    function reset() {
        active = false;
        if (mode === 0) duration = focusTime;
        else if (mode === 1) duration = shortBreakTime;
        else if (mode === 2) duration = longBreakTime;
        remainingTime = duration;
        startTimestamp = Date.now();
        elapsedMs = 0;
    }

    function setMode(newMode) {
        mode = newMode;
        active = false;
        reset();
    }

    // Comprehensive session completion logic
    function completeSession() {
        // Prevent race condition: stop timer immediately
        active = false;

        // 1. Feedback (Sound)
        Audio.playSystemSound("message");

        // 2. State update & Rotation logic
        const wasFocus = (mode === 0);
        if (wasFocus) {
            mode = nextBreakMode;
        } else {
            rotations++;
            mode = 0;
        }
        
        // 3. Reset (updates duration, remainingTime, startTimestamp)
        reset(); 
        
        // 4. Auto-continue handling
        if (autoContinue) {
            active = true;
        }
    }

    Timer {
        id: timer
        interval: 1000 // 1 tick per second optimization
        repeat: true
        running: root.active
        onTriggered: {
            const now = Date.now();
            root.elapsedMs = now - root.startTimestamp;
            const elapsed = Math.floor(root.elapsedMs / 1000);
            
            if (elapsed > root.duration) {
                root.completeSession();
            } else {
                const newRemaining = Math.max(0, root.duration - elapsed);
                if (newRemaining !== root.remainingTime) {
                    root.remainingTime = newRemaining;
                }
            }
        }
    }
}
