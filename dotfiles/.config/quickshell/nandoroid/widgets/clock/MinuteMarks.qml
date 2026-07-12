pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../core"

Item {
    id: root

    property color color: Appearance.colors.colOnSecondaryContainer
    property string style: Config.options.appearance.clock.analog.dialStyle // "dots", "numbers", "full", "hide"
    property string dateStyle : Config.options.appearance.clock.analog.dateStyle
    property bool isLockscreen: false

    // 12 Dots
    FadeLoader {
        id: dotsLoader
        anchors {
            fill: parent
            margins: 10 * Appearance.effectiveScale
        }
        shown: root.style === "dots"
        sourceComponent: Dots {
            color: root.color
            margins: (46 * Appearance.effectiveScale) - dotsLoader.opacity * (34 * Appearance.effectiveScale)
        }
    }

    // 3-6-9-12 hour numbers (pls don't realize you can have more than 4 numbers)
    FadeLoader {
        id: bigHourNumbersLoader
        anchors.fill: parent
        shown: root.style === "numbers"
        sourceComponent: BigHourNumbers {
            numberSize: 80 * Appearance.effectiveScale
            color: root.color
            margins: (20 * Appearance.effectiveScale) - (10 * Appearance.effectiveScale) * bigHourNumbersLoader.opacity
            isLockscreen: root.isLockscreen
        }
    }

    // Lines
    FadeLoader {
        id: linesLoader
        anchors {
            fill: parent
            margins: 10 * Appearance.effectiveScale
        }
        shown: root.style === "full"
        sourceComponent: Lines {
            color: root.color
            margins: (46 * Appearance.effectiveScale) - linesLoader.opacity * (34 * Appearance.effectiveScale)
        }
    }
    
}
