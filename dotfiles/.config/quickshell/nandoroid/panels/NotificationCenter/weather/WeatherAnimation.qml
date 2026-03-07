import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../../core"
import "../../../services"

/**
 * Animated Weather Background - Overlay version for Android 16.
 * Improved logic ported from Ambxst for stability and aesthetics.
 */
Item {
    id: root

    property bool animationsEnabled: visible
    property bool backgroundEnabled: false 
    
    // Internal Time Calculation (Synced with system)
    property real currentHour: DateTime.hours + DateTime.minutes / 60
    
    // Internal Time Blending Logic (Ambxst style)
    function calculateTimeBlend(hour) {
        var d = 0, e = 0, n = 0;
        if (hour >= 9 && hour <= 17) { d = 1.0; } 
        else if (hour > 8 && hour < 9) { var t = hour - 8; e = 1.0 - t; d = t; } 
        else if (hour > 17 && hour < 18) { var t = hour - 17; d = 1.0 - t; e = t; } 
        else if (hour >= 6 && hour <= 8) { e = 1.0; } 
        else if (hour >= 18 && hour <= 20) { e = 1.0; } 
        else if (hour > 5 && hour < 6) { var t2 = hour - 5; n = 1.0 - t2; e = t2; } 
        else if (hour > 20 && hour < 21) { var t3 = hour - 20; e = 1.0 - t3; n = t3; } 
        else { n = 1.0; }
        return { d: d, e: e, n: n };
    }

    readonly property var blend: calculateTimeBlend(currentHour)
    
    function blendColors(c1, c2, c3, b) {
        var r = c1.r * b.d + c2.r * b.e + c3.r * b.n;
        var g = c1.g * b.d + c2.g * b.e + c3.g * b.n;
        var bv = c1.b * b.d + c2.b * b.e + c3.b * b.n;
        return Qt.rgba(r, g, bv, 1);
    }

    // Sky Colors (Only used if backgroundEnabled is true)
    readonly property color dayTop: "#87CEEB"; readonly property color dayBot: "#E0F6FF"
    readonly property color eveTop: "#1a1a2e"; readonly property color eveBot: "#ffeaa7"
    readonly property color nigTop: "#0f0f23"; readonly property color nigBot: "#2d2d5a"
    readonly property color topC: blendColors(dayTop, eveTop, nigTop, blend)
    readonly property color botC: blendColors(dayBot, eveBot, nigBot, blend)

    readonly property string weatherEffect: {
        let icon = (Weather.current.icon || "").toLowerCase();
        if (icon.indexOf("clear") !== -1) return "clear";
        if (icon.indexOf("cloudy") !== -1 || icon.indexOf("clouds") !== -1) return "clouds";
        if (icon.indexOf("rain") !== -1 || icon.indexOf("drizzle") !== -1 || icon.indexOf("showers") !== -1) return "rain";
        if (icon.indexOf("snow") !== -1 || icon.indexOf("flurries") !== -1) return "snow";
        if (icon.indexOf("thunder") !== -1) return "thunderstorm";
        if (icon.indexOf("haze") !== -1 || icon.indexOf("fog") !== -1) return "fog";
        return "clouds"; 
    }
    
    readonly property real weatherIntensity: {
        let cond = (Weather.current.condition || "").toLowerCase();
        if (cond.indexOf("heavy") !== -1) return 1.0;
        if (cond.indexOf("moderate") !== -1) return 0.6;
        return 0.4;
    }

    Item {
        id: rootContents
        anchors.fill: parent

        // --- Optional Sky Background ---
        Rectangle {
            anchors.fill: parent
            visible: root.backgroundEnabled
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.topC }
                GradientStop { position: 1.0; color: root.botC }
            }
        }

        // --- Weather Elements Layer ---
        Item {
            anchors.fill: parent

            // 1. Stars (Visible at night when weather is clear)
            Item {
                id: starsEffect; anchors.fill: parent
                // blend.n is night blend
                opacity: (root.blend.n > 0.3 && root.weatherEffect === "clear") ? Math.min(1, (root.blend.n - 0.3) / 0.4) : 0
                visible: opacity > 0
                
                Repeater {
                    model: 30
                    Rectangle {
                        property real baseX: Math.random() * starsEffect.width
                        property real baseY: Math.random() * (starsEffect.height * 0.7)
                        x: baseX; y: baseY; width: 1.5 + Math.random(); height: width; radius: width/2; color: "white"
                        opacity: 0.5 + Math.random() * 0.5
                        
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: starsEffect.visible && root.animationsEnabled
                            NumberAnimation { to: 0.2; duration: 1000 + Math.random() * 2000; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 1000 + Math.random() * 2000; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            // 2. Clouds (Layered and more visible)
            Item {
                id: cloudEffect; anchors.fill: parent
                visible: ["clouds", "rain", "snow", "thunderstorm", "fog"].includes(root.weatherEffect)
                
                // Cloud color follows M3 onSurface for perfect theme integration
                property color cloudColor: Appearance.m3colors.m3onSurface

                // Background Layer (Slower, alternating directions)
                Repeater {
                    model: 3
                    Item {
                        required property int index
                        readonly property bool fromRight: index % 2 !== 0
                        width: 250; height: 90
                        x: fromRight ? cloudEffect.width + 100 : -300
                        y: 10 + (index * 30)
                        Rectangle {
                            anchors.fill: parent; radius: height/2; color: cloudEffect.cloudColor; opacity: 0.12
                        }
                        NumberAnimation on x {
                            from: index % 2 !== 0 ? cloudEffect.width + 100 : -300
                            to: index % 2 !== 0 ? -300 : cloudEffect.width + 100
                            duration: 35000 + (index * 6000); loops: Animation.Infinite
                            running: cloudEffect.visible && root.animationsEnabled
                        }
                    }
                }

                // Foreground Layer (Faster, alternating directions)
                Repeater {
                    model: 4
                    Item {
                        required property int index
                        readonly property bool fromRight: index % 2 !== 0
                        width: 150; height: 55
                        x: fromRight ? cloudEffect.width + 50 : -200
                        y: 50 + (index * 25)
                        Rectangle {
                            anchors.fill: parent; radius: height/2; color: cloudEffect.cloudColor; opacity: 0.18
                        }
                        NumberAnimation on x {
                            from: index % 2 !== 0 ? cloudEffect.width + 50 : -200
                            to: index % 2 !== 0 ? -200 : cloudEffect.width + 50
                            duration: 25000 + (index * 4000); loops: Animation.Infinite
                            running: cloudEffect.visible && root.animationsEnabled
                        }
                    }
                }
            }

            // 3. Rain (Vertical and Thinner)
            Item {
                id: rainEffect; anchors.fill: parent
                visible: root.weatherEffect === "rain" || root.weatherEffect === "thunderstorm"
                
                property color dropColor: Appearance.m3colors.m3onSurface
                
                Repeater {
                    model: 40
                    Rectangle {
                        id: rainDrop
                        property real initialX: Math.random() * rainEffect.width
                        property real fallSpeed: 450 + Math.random() * 200
                        property real delay: Math.random() * 1000

                        x: initialX; y: -30; width: 1.2; height: 16; radius: 0.6
                        color: rainEffect.dropColor; opacity: 0.25; rotation: 0

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: rainEffect.visible && root.animationsEnabled
                            PauseAnimation { duration: rainDrop.delay }
                            NumberAnimation { target: rainDrop; property: "y"; from: -30; to: rainEffect.height + 30; duration: rainDrop.fallSpeed; easing.type: Easing.Linear }
                            ScriptAction { script: { rainDrop.initialX = Math.random() * rainEffect.width; } }
                        }
                    }
                }
            }

            // 4. Snow
            Item {
                id: snowEffect; anchors.fill: parent
                visible: root.weatherEffect === "snow"
                Repeater {
                    model: 30
                    Rectangle {
                        id: snowFlake
                        property real initialX: Math.random() * snowEffect.width
                        property real fallSpeed: 5000 + Math.random() * 2000
                        x: initialX; y: -10; width: 5 + Math.random() * 4; height: width; radius: width/2
                        color: "white"; opacity: 0.7

                        SequentialAnimation on y {
                            loops: Animation.Infinite
                            running: snowEffect.visible && root.animationsEnabled
                            NumberAnimation { from: -20; to: snowEffect.height + 20; duration: snowFlake.fallSpeed; easing.type: Easing.Linear }
                        }
                        SequentialAnimation on x {
                            loops: Animation.Infinite
                            running: snowEffect.visible && root.animationsEnabled
                            NumberAnimation { to: snowFlake.initialX + 30; duration: snowFlake.fallSpeed / 2; easing.type: Easing.InOutSine }
                            NumberAnimation { to: snowFlake.initialX - 30; duration: snowFlake.fallSpeed / 2; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            // 5. Thunderstorm Lightning
            Rectangle {
                id: lightningFlash
                anchors.fill: parent
                color: "white"
                opacity: 0
                visible: root.weatherEffect === "thunderstorm"
                
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: lightningFlash.visible && root.animationsEnabled
                    PauseAnimation { duration: 4000 + Math.random() * 6000 }
                    NumberAnimation { target: lightningFlash; property: "opacity"; to: 0.5; duration: 60 }
                    NumberAnimation { target: lightningFlash; property: "opacity"; to: 0; duration: 120 }
                    NumberAnimation { target: lightningFlash; property: "opacity"; to: 0.3; duration: 60 }
                    NumberAnimation { target: lightningFlash; property: "opacity"; to: 0; duration: 300 }
                    PauseAnimation { duration: 2500 }
                }
            }
        }
    }
}
