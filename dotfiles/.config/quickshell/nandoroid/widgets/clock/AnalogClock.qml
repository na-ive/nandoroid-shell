import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Widgets
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import ".."
import "."
import "../shapes"

Item {
    id: root
    
    property bool isLockscreen: false

    // Resolve which config object to use:
    // lockscreen with independent style → analogLocked, otherwise → analog
    readonly property var cfg: {
        if (Config.ready && isLockscreen && !Config.options.appearance.clock.useSameStyle)
            return Config.options.appearance.clock.analogLocked
        return Config.options.appearance.clock.analog
    }

    readonly property int configSize: Config.ready ? cfg.size : 240 * Appearance.effectiveScale
    width: configSize
    height: configSize
    implicitWidth: configSize
    implicitHeight: configSize

    property var m3: isLockscreen ? Appearance.lockM3colors : Appearance.m3colors

    property color colBackground:     m3.m3primaryContainer
    property color colOnBackground:    Functions.ColorUtils.mix(m3.m3secondary, m3.m3primaryContainer, 0.15)
    property color colBackgroundInfo:  Functions.ColorUtils.mix(m3.m3primary, m3.m3primaryContainer, 0.55)
    property color colHourHand:        m3.m3primary
    property color colMinuteHand:      m3.m3tertiary
    property color colSecondHand:      m3.m3primary

    readonly property bool showDate: Config.ready ? (root.isLockscreen ? (Config.options.appearance.clock.useSameStyle ? Config.options.appearance.clock.showDesktopDate : Config.options.appearance.clock.showLockscreenDate) : Config.options.appearance.clock.showDesktopDate) : true
    readonly property bool showMarks: Config.ready && cfg.showMarks
    readonly property string backgroundStyle: Config.ready ? (cfg.backgroundStyle || "shape") : "shape"
    
    readonly property int clockHour: DateTime.hours % 12
    readonly property int clockMinute: DateTime.minutes
    readonly property int clockSecond: DateTime.seconds

    // Rotating shadow / background
    Item {
        id: rotateContainer
        anchors.fill: parent
        
        RotationAnimation on rotation {
            running: Config.ready && root.cfg.constantlyRotate
            duration: 30000
            easing.type: Easing.Linear
            loops: Animation.Infinite
            from: 360
            to: 0
        }

        Loader {
            id: sineBG
            anchors.fill: parent
            active: backgroundStyle === "sine"
            sourceComponent: SineCookie {
                implicitSize: root.width
                sides: Config.ready ? root.cfg.sides : 12
                color: root.colBackground
                constantlyRotate: Config.ready && root.cfg.constantlyRotate
            }
        }

        Loader {
            id: polyBG
            anchors.fill: parent
            active: backgroundStyle === "cookie"
            sourceComponent: MaterialCookie {
                implicitSize: root.width
                sides: Config.ready ? root.cfg.sides : 12
                color: root.colBackground
            }
        }

        Loader {
            id: shapeBG
            anchors.fill: parent
            active: backgroundStyle === "shape"
            sourceComponent: MaterialShape {
                implicitSize: root.width
                color: root.colBackground
                shapeString: Config.ready ? root.cfg.shape : "Circle"
                borderWidth: 0
                borderColor: root.m3.m3outlineVariant
            }
        }
    }

    // Marks (outer ring: dots / numbers / lines)
    MinuteMarks {
        id: marks
        anchors.fill: parent
        visible: root.showMarks
        color: root.colOnBackground
        style: Config.ready ? root.cfg.dialStyle : "dots"
        isLockscreen: root.isLockscreen
    }

    // Hour Marks (inner ring: 12 tick marks around center)
    HourMarks {
        anchors.centerIn: parent
        visible: Config.ready && root.cfg.hourMarks
        color: root.colOnBackground
        colOnBackground: Functions.ColorUtils.mix(root.colBackgroundInfo, root.colOnBackground, 0.5)
    }

    // Time indicators (H:MM digits in the center)
    TimeColumn {
        anchors.centerIn: parent
        visible: Config.ready && root.cfg.timeIndicators
        color: root.colBackgroundInfo
        isLockscreen: root.isLockscreen
    }

    // Minute Hand
    MinuteHand {
        anchors.fill: parent
        clockMinute: root.clockMinute
        style: Config.ready ? (root.cfg.minuteHandStyle || "bold") : "bold"
        color: root.colMinuteHand
    }

    // Hour Hand
    HourHand {
        anchors.fill: parent
        clockHour: root.clockHour
        clockMinute: root.clockMinute
        style: Config.ready ? (root.cfg.hourHandStyle || "fill") : "fill"
        color: root.colHourHand
    }

    // Second Hand
    SecondHand {
        anchors.fill: parent
        clockSecond: root.clockSecond
        visible: Config.ready && root.cfg.secondHandStyle !== "none"
        style: Config.ready ? (root.cfg.secondHandStyle || "dot") : "dot"
        color: root.colSecondHand
    }

    // Date
    DateIndicator {
        anchors.fill: parent
        visible: root.showDate
        style: Config.ready ? (root.cfg.dateStyle || "bubble") : "bubble"
        color: root.colBackgroundInfo
        isLockscreen: root.isLockscreen
    }

    // Center Pin
    Rectangle {
        width: 8 * Appearance.effectiveScale; height: 8 * Appearance.effectiveScale
        radius: 4 * Appearance.effectiveScale
        color: root.m3.m3surface
        anchors.centerIn: parent
        border.width: Math.max(1, 1.5 * Appearance.effectiveScale)
        border.color: root.colSecondHand
    }
}
