pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../../services"
import "../../core"

Item {
    id: root

    anchors.fill: parent
    property color color: Appearance.colors.colOnSecondaryContainer
    property real angleStep: 12 * Math.PI / 180
    property string dateText: {
        const _ = DateTime.currentDate; // reactive
        return Qt.formatDate(new Date(), "ddd dd");
    }

    readonly property bool timeIndicators: Config.options.appearance.clock.analog.timeIndicators

    property real radius: 90
    Behavior on radius {
        animation: ({duration: 300})
    }

    rotation: (360 / 60 * DateTime.seconds) + 180 - (angleStep / Math.PI * 180 * dateText.length) / 2

    Repeater {
        model: root.dateText.length

        delegate: Text {
            required property int index
            property real angle: index * root.angleStep - Math.PI / 2
            x: root.width / 2 + root.radius * Math.cos(angle) - width / 2
            y: root.height / 2 + root.radius * Math.sin(angle) - height / 2
            rotation: angle * 180 / Math.PI + 90

            color: root.color
            font {
                family: Appearance.font.family.expressive
                pixelSize: 30
                weight: Font.Black
                variableAxes: Appearance.font.variableAxes.expressive
            }

            text: root.dateText.charAt(index)
        }
    }
}
