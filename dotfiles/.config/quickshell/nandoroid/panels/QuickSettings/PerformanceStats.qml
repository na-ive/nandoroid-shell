import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"

/**
 * Performance monitor island for the Quick Settings panel.
 * Displays real-time CPU, RAM, Swap, Temperature, and Multiple Disk usage via SystemData.
 * Metric cards reuse the liquid MaterialShape fill style from the desktop
 * System Monitor widget, ordered like the status bar (CPU, RAM, SWAP, TEMP).
 */
Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight + (20 * Appearance.effectiveScale)
    radius: Appearance.rounding.large
    color: Appearance.colors.colLayer1

    // ── Disk carousel model (capped at 2, kept fresh to mirror SystemData.diskStats) ──
    readonly property int carouselCount: Math.min(SystemData.diskStats.count, 2)
    property ListModel diskCarouselModel: ListModel {}
    property string _diskSig: ""

    function rebuildDiskModel() {
        const count = Math.min(SystemData.diskStats.count, 2)
        const identity = []
        for (let i = 0; i < count; i++) {
            const d = SystemData.diskStats.get(i)
            identity.push(`${d.path}|${d.label}|${d.hasAlias}`)
        }
        const sig = identity.join("#")
        if (sig !== root._diskSig) {
            root._diskSig = sig
            root.diskCarouselModel.clear()
            for (let i = 0; i < count; i++) {
                const d = SystemData.diskStats.get(i)
                root.diskCarouselModel.append({ path: d.path, label: d.label, hasAlias: d.hasAlias, usage: d.usage, total: d.total, used: d.used })
            }
            return
        }
        // Disk list unchanged: refresh usage/used/total roles in place so the
        // carousel delegates are NOT recreated (avoids the per-second blink).
        for (let i = 0; i < count; i++) {
            const d = SystemData.diskStats.get(i)
            const row = root.diskCarouselModel.get(i)
            if (row && (row.usage !== d.usage || row.used !== d.used || row.total !== d.total)) {
                root.diskCarouselModel.set(i, { usage: d.usage, used: d.used, total: d.total })
            }
        }
    }

    // Rebuild the carousel model the instant SystemData refreshes its disk list.
    // SystemData emits this after every poll cycle while relevant panels are
    // visible, so no fallback timer is needed here.
    Connections {
        target: SystemData
        function onDiskStatsUpdated() {
            root.rebuildDiskModel()
        }
    }

    // Restore the carousel to the first item whenever the Quick Settings reopens,
    // otherwise the clicked disk stays widened/active after returning (stuck).
    Connections {
        target: GlobalStates
        function onQuickSettingsOpenChanged() {
            if (GlobalStates.quickSettingsOpen) diskCarousel.currentIndex = 0
        }
    }

    Component.onCompleted: root.rebuildDiskModel()

    ColumnLayout {
        id: mainLayout
        anchors {
            fill: parent
            margins: 10 * Appearance.effectiveScale
        }
        spacing: 4 * Appearance.effectiveScale

        // ── Metric Cards: 4 liquid MaterialShape cards in a tight row ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 4 * Appearance.effectiveScale

            StatShapeCard {
                statIcon: "monitoring"
                label: I18nService.tr("CPU")
                value: SystemData.cpuUsage
                shape: MaterialShape.Shape.Gem
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 1;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatShapeCard {
                statIcon: "memory"
                label: I18nService.tr("RAM")
                value: SystemData.memUsage
                shape: MaterialShape.Shape.Cookie4Sided
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 3;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatShapeCard {
                statIcon: "swap_horiz"
                label: I18nService.tr("SWAP")
                value: SystemData.swapUsage
                shape: MaterialShape.Shape.Cookie12Sided
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 3;
                    GlobalStates.activateSystemMonitor();
                }
            }

            StatShapeCard {
                statIcon: "thermostat"
                label: I18nService.tr("TEMP")
                value: SystemData.cpuTemperature
                isTemperature: true
                shape: MaterialShape.Shape.Squircle
                Layout.fillWidth: true
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 1;
                    GlobalStates.activateSystemMonitor();
                }
            }
        }

        // ── Disk Monitors: carousel of up to 2 cards + "more" arrow when > 2 ──
        RowLayout {
            Layout.fillWidth: true
            visible: SystemData.diskStats.count > 0
            spacing: 4 * Appearance.effectiveScale

            Carousel {
                id: diskCarousel
                Layout.fillWidth: true
                implicitHeight: 56 * Appearance.effectiveScale
                model: root.diskCarouselModel
                fitMode: true
                baseItemWidth: root.carouselCount > 0
                    ? (diskCarousel.width - (root.carouselCount - 1) * diskCarousel.itemSpacing - diskCarousel.activeBonusWidth) / root.carouselCount
                    : 0
                activeBonusWidth: 16 * Appearance.effectiveScale
                itemSpacing: 4 * Appearance.effectiveScale
                wheelEnabled: false
                dragEnabled: false
                hoverSelectsIndex: false
                showCurrentIndicator: false
                showFooter: false
                clipRadius: Appearance.rounding.normal
                cardBackgroundRadius: Appearance.rounding.normal
                cardBackgroundColor: Appearance.colors.colLayer2

                delegate: Component {
                    Item {
                        readonly property bool isHovered: index === diskCarousel.hoveredIndex

                        Rectangle {
                            anchors.fill: parent
                            radius: Appearance.rounding.normal
                            color: isHovered ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10 * Appearance.effectiveScale
                                anchors.rightMargin: 10 * Appearance.effectiveScale
                                spacing: 10 * Appearance.effectiveScale

                                LiquidShape {
                                    size: 30 * Appearance.effectiveScale
                                    shape: MaterialShape.Shape.ClamShell
                                    fillLevel: modelData ? modelData.usage : 0
                                    iconText: "storage"
                                    iconSize: 13 * Appearance.effectiveScale
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2 * Appearance.effectiveScale

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8 * Appearance.effectiveScale

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: modelData
                                                ? (modelData.hasAlias ? modelData.label : `"${modelData.label}"`)
                                                : ""
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colSubtext
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            text: modelData ? `${Math.round(modelData.usage * 100)}%` : ""
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            font.weight: Font.DemiBold
                                            font.family: Appearance.font.family.numbers
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                    }

                                    StyledText {
                                        text: modelData && modelData.total > 0
                                            ? `${Math.round(modelData.used / (1024*1024*1024))}/${Math.round(modelData.total / (1024*1024*1024))} GB`
                                            : "--"
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.family: Appearance.font.family.numbers
                                        color: Appearance.colors.colSubtext
                                        opacity: 0.8
                                    }
                                }
                            }
                        }
                    }
                }

                onItemSelected: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 5;
                    GlobalStates.activateSystemMonitor();
                }
            }

            MoreCard {
                visible: SystemData.diskStats.count > 2
                onClicked: {
                    GlobalStates.systemMonitorIndex = 0;
                    GlobalStates.performanceSubIndex = 5;
                    GlobalStates.activateSystemMonitor();
                }
            }
        }
    }

    // StatShapeCard: liquid MaterialShape fill + centered icon + value/label below
    component StatShapeCard: RippleButton {
        id: statCard
        property string statIcon
        property string label
        property real value: 0
        property bool isTemperature: false
        property int shape: MaterialShape.Shape.Gem

        implicitHeight: 92 * Appearance.effectiveScale
        buttonRadius: Appearance.rounding.normal
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active

        readonly property real fillLevel: statCard.isTemperature
            ? Math.min(statCard.value / 100, 1.0)
            : statCard.value

        readonly property string displayValue: statCard.isTemperature
            ? (statCard.value > 0 ? `${Math.round(statCard.value)}°C` : "--")
            : `${Math.round(statCard.value * 100)}%`

        contentItem: Item {
            anchors.fill: parent

            LiquidShape {
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 10 * Appearance.effectiveScale
                }
                size: 38 * Appearance.effectiveScale
                shape: statCard.shape
                fillLevel: statCard.fillLevel
                iconText: statCard.statIcon
            }

            // Value + label (bottom)
            ColumnLayout {
                spacing: -2 * Appearance.effectiveScale
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 8 * Appearance.effectiveScale
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: statCard.displayValue
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    font.family: Appearance.font.family.numbers
                    color: Appearance.m3colors.m3onSurface
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: statCard.label
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.m3colors.m3onSurface
                    opacity: 0.6
                }
            }
        }
    }

    // MoreCard: "more" arrow shown when the disk count exceeds the 2-card cap.
    // Widens on hover to match the carousel items around it.
    component MoreCard: RippleButton {
        id: moreCard
        implicitWidth: (moreCard.realHovered ? 64 : 44) * Appearance.effectiveScale
        implicitHeight: 56 * Appearance.effectiveScale
        buttonRadius: Appearance.rounding.normal
        colBackground: Appearance.colors.colLayer2
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(moreCard)
        }

        contentItem: Item {
            anchors.fill: parent

            MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_right"
                iconSize: 20 * Appearance.effectiveScale
                color: Appearance.m3colors.m3onSurface
                opacity: 0.7
            }
        }

        StyledToolTip {
            text: I18nService.tr("More")
        }
    }

    // LiquidShape: reusable liquid MaterialShape fill with centered icon
    component LiquidShape: Item {
        id: liquidShape
        property real size: 38 * Appearance.effectiveScale
        property int shape: MaterialShape.Shape.Gem
        property real fillLevel: 0
        property string iconText: ""
        property int iconSize: 16 * Appearance.effectiveScale
        property color accent: Appearance.colors.colPrimary
        property color accentOn: Appearance.colors.colOnPrimary

        implicitWidth: size
        implicitHeight: size

        MaterialShape {
            id: shapeMask
            anchors.fill: parent
            shape: liquidShape.shape
            color: "black"
            visible: false
        }

        Item {
            id: shapeContent
            anchors.fill: parent
            visible: false

            MaterialShape {
                anchors.fill: parent
                shape: liquidShape.shape
                color: Functions.ColorUtils.applyAlpha(liquidShape.accent, 0.15)
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: parent.height * liquidShape.fillLevel
                color: liquidShape.accent
            }
        }

        OpacityMask {
            anchors.fill: parent
            source: shapeContent
            maskSource: shapeMask
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: liquidShape.iconText
            iconSize: liquidShape.iconSize
            color: liquidShape.fillLevel > 0.55 ? liquidShape.accentOn : liquidShape.accent
        }
    }
}
