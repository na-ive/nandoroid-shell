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

    readonly property int configSize: Config.ready ? cfg.size : 240
    width: configSize
    height: configSize
    implicitWidth: configSize
    implicitHeight: configSize

    property color colBackground:     Appearance.colors.colPrimaryContainer
    property color colOnBackground:    Functions.ColorUtils.mix(Appearance.colors.colSecondary, Appearance.colors.colPrimaryContainer, 0.15)
    property color colBackgroundInfo:  Functions.ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colPrimaryContainer, 0.55)
    property color colHourHand:        Appearance.colors.colPrimary
    property color colMinuteHand:      Appearance.colors.colTertiary
    property color colSecondHand:      Appearance.colors.colPrimary

    readonly property bool showDate: Config.ready && Config.options.appearance.clock.showDate
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
                borderWidth: 2
                borderColor: Appearance.colors.colOutlineVariant
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
    }

    // Center Pin
    Rectangle {
        width: 8; height: 8
        radius: 4
        color: Appearance.m3colors.m3surface
        anchors.centerIn: parent
        border.width: 1.5
        border.color: root.colSecondHand
    }
}
