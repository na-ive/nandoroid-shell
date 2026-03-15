import QtQuick
import "../../services"
import "../../core"

/**
 * Overview View Switcher
 * Switches between Standard Grid and Scrolling Tape overview layouts.
 */
Item {
    id: root
    property var currentScreen

    readonly property bool isScrollingLayout: GlobalStates.hyprlandLayout === "scrolling"

    width: implicitWidth
    height: implicitHeight
    implicitWidth: overviewLoader.item ? overviewLoader.item.implicitWidth : 400
    implicitHeight: overviewLoader.item ? overviewLoader.item.implicitHeight : 300

    readonly property var flickable: overviewLoader.item ? overviewLoader.item.flickable : null
    readonly property bool needsScrollbar: overviewLoader.item ? (overviewLoader.item.needsScrollbar ?? false) : false

    property bool isManualScrolling: false
    onIsManualScrollingChanged: {
        if (overviewLoader.item) {
            overviewLoader.item.isManualScrolling = isManualScrolling;
        }
    }

    Behavior on implicitWidth { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
    Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

    Loader {
        id: overviewLoader
        anchors.fill: parent
        active: true
        sourceComponent: isScrollingLayout ? scrollingOverviewComponent : standardOverviewComponent
    }

    Component {
        id: standardOverviewComponent
        Overview { currentScreen: root.currentScreen }
    }

    Component {
        id: scrollingOverviewComponent
        ScrollingOverview { currentScreen: root.currentScreen }
    }
}
