pragma ComponentBehavior: Bound

import QtQuick
import "../../core"
import "../../core/functions" as Functions
import ".."
import "."

Item {
    id: indicatorRoot
    property string style: "bubble"
    property color color: Appearance.colors.colOnSecondaryContainer
    property real dateSquareSize: 64

    // Rotating date
    FadeLoader {
        anchors.fill: parent
        shown: indicatorRoot.style === "border"
        sourceComponent: RotatingDate {
            color: indicatorRoot.color
        }
    }

    // Rectangle date (only today's number) in right side of the clock
    FadeLoader {
        id: rectLoader
        shown: indicatorRoot.style === "rect"
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 40 - rectLoader.opacity * 30
        }

        sourceComponent: RectangleDate {
            color: Appearance.colors.colSecondaryContainerHover
            textColor: indicatorRoot.color
            radius: Appearance.rounding.small
            implicitWidth: 45 * rectLoader.opacity
            implicitHeight: 30 * rectLoader.opacity
        }
    }

    // Bubble style: day of month
    FadeLoader {
        id: dayBubbleLoader
        shown: indicatorRoot.style === "bubble"
        property real targetSize: indicatorRoot.dateSquareSize * opacity
        anchors {
            left: parent.left
            top: parent.top
        }

        sourceComponent: BubbleDate {
            implicitWidth: dayBubbleLoader.targetSize
            implicitHeight: dayBubbleLoader.targetSize
            isMonth: false
            targetSize: dayBubbleLoader.targetSize
        }
    }

    // Bubble style: month
    FadeLoader {
        id: monthBubbleLoader
        shown: indicatorRoot.style === "bubble"
        property real targetSize: indicatorRoot.dateSquareSize * opacity
        anchors {
            right: parent.right
            bottom: parent.bottom
        }

        sourceComponent: BubbleDate {
            implicitWidth: monthBubbleLoader.targetSize
            implicitHeight: monthBubbleLoader.targetSize
            isMonth: true
            targetSize: monthBubbleLoader.targetSize
        }
    }
}
