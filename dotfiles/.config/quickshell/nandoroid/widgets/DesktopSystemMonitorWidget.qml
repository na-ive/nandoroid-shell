import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../core"
import "../core/functions" as Functions
import "../services"
import "."

Item {
    id: root
    
    // Read orientation from config
    property bool isVertical: Config.ready ? Config.options.appearance.systemMonitor.vertical : false

    // Scale dimensions cleanly based on Choice A (Grid: 132x108, Gap: 12)
    // Horizontal 3x1: 420 x 108
    // Vertical 1x3: 132 x 348 (108 * 3 + 12 * 2)
    property real baseWidth: isVertical ? 132 : 420
    property real baseHeight: isVertical ? 348 : 108
    implicitWidth: baseWidth * Appearance.effectiveScale
    implicitHeight: baseHeight * Appearance.effectiveScale

    // Spacings and sizes
    property real cardSpacing: 12 * Appearance.effectiveScale
    property real cardHeight: isVertical ? (108 * Appearance.effectiveScale) : (108 * Appearance.effectiveScale)
    property real cardWidth: isVertical ? (132 * Appearance.effectiveScale) : ((420 * Appearance.effectiveScale - cardSpacing * 2) / 3)

    Grid {
        id: gridLayout
        columns: root.isVertical ? 1 : 3
        spacing: root.cardSpacing

        // CARD 1: CPU (Split-Level Centered Layout)
        Rectangle {
            id: cpuCard
            implicitWidth: root.cardWidth
            implicitHeight: root.cardHeight
            radius: Appearance.rounding.large
            color: Appearance.colors.colPrimaryContainer

            // Sisi Atas: Liquid Gem (Centered Top)
            Item {
                id: cpuVisualContainer
                width: 38 * Appearance.effectiveScale
                height: 38 * Appearance.effectiveScale
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 12 * Appearance.effectiveScale
                }

                MaterialShape {
                    id: cpuMask
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Gem
                    color: "black"
                    visible: false
                }

                Item {
                    id: cpuContent
                    anchors.fill: parent
                    visible: false

                    MaterialShape {
                        anchors.fill: parent
                        shape: MaterialShape.Shape.Gem
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.15)
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: parent.height * SystemData.cpuUsage
                        color: Appearance.colors.colPrimary
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: cpuContent
                    maskSource: cpuMask
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "planner_review"
                    iconSize: 16 * Appearance.effectiveScale
                    color: SystemData.cpuUsage > 0.55 ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                }
            }

            // Sisi Bawah: Text Info (Centered Bottom)
            ColumnLayout {
                spacing: -2 * Appearance.effectiveScale
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 10 * Appearance.effectiveScale
                }
                
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(SystemData.cpuUsage * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnPrimaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "CPU"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnPrimaryContainer
                    opacity: 0.6
                }
            }
        }

        // CARD 2: RAM (Split-Level Centered Layout)
        Rectangle {
            id: ramCard
            implicitWidth: root.cardWidth
            implicitHeight: root.cardHeight
            radius: Appearance.rounding.large
            color: Appearance.colors.colSecondaryContainer

            // Sisi Atas: Liquid Cookie4Sided (Centered Top)
            Item {
                id: ramVisualContainer
                width: 38 * Appearance.effectiveScale
                height: 38 * Appearance.effectiveScale
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 12 * Appearance.effectiveScale
                }

                MaterialShape {
                    id: ramMask
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Cookie4Sided
                    color: "black"
                    visible: false
                }

                Item {
                    id: ramContent
                    anchors.fill: parent
                    visible: false

                    MaterialShape {
                        anchors.fill: parent
                        shape: MaterialShape.Shape.Cookie4Sided
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colSecondary, 0.15)
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: parent.height * SystemData.memUsage
                        color: Appearance.colors.colSecondary
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: ramContent
                    maskSource: ramMask
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "memory"
                    iconSize: 16 * Appearance.effectiveScale
                    color: SystemData.memUsage > 0.55 ? Appearance.colors.colOnSecondary : Appearance.colors.colSecondary
                }
            }

            // Sisi Bawah: Text Info (Centered Bottom)
            ColumnLayout {
                spacing: -2 * Appearance.effectiveScale
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 10 * Appearance.effectiveScale
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.round(SystemData.memUsage * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "RAM"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSecondaryContainer
                    opacity: 0.6
                }
            }
        }

        // CARD 3: DISK (Split-Level Centered Layout)
        Rectangle {
            id: diskCard
            implicitWidth: root.cardWidth
            implicitHeight: root.cardHeight
            radius: Appearance.rounding.large
            color: Appearance.colors.colTertiaryContainer

            // Sisi Atas: Liquid Cookie12Sided (Centered Top)
            Item {
                id: diskVisualContainer
                width: 38 * Appearance.effectiveScale
                height: 38 * Appearance.effectiveScale
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: 12 * Appearance.effectiveScale
                }

                MaterialShape {
                    id: diskMask
                    anchors.fill: parent
                    shape: MaterialShape.Shape.Cookie12Sided
                    color: "black"
                    visible: false
                }

                Item {
                    id: diskContent
                    anchors.fill: parent
                    visible: false

                    MaterialShape {
                        anchors.fill: parent
                        shape: MaterialShape.Shape.Cookie12Sided
                        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colTertiary, 0.15)
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: {
                            if (SystemData.diskStats && SystemData.diskStats.length > 0) {
                                return parent.height * SystemData.diskStats[0].usage;
                            }
                            return 0;
                        }
                        color: Appearance.colors.colTertiary
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: diskContent
                    maskSource: diskMask
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "storage"
                    iconSize: 16 * Appearance.effectiveScale
                    color: {
                        let usage = 0;
                        if (SystemData.diskStats && SystemData.diskStats.length > 0) {
                            usage = SystemData.diskStats[0].usage;
                        }
                        return usage > 0.55 ? Appearance.colors.colOnTertiary : Appearance.colors.colTertiary;
                    }
                }
            }

            // Sisi Bawah: Text Info (Centered Bottom)
            ColumnLayout {
                spacing: -2 * Appearance.effectiveScale
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: 10 * Appearance.effectiveScale
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (SystemData.diskStats && SystemData.diskStats.length > 0) {
                            return Math.round(SystemData.diskStats[0].usage * 100) + "%";
                        }
                        return "0%";
                    }
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: Appearance.colors.colOnTertiaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Disk"
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnTertiaryContainer
                    opacity: 0.6
                }
            }
        }
    }

    // Toggle Handle to switch layout direction (only visible when hovered and not locked)
    Rectangle {
        id: toggleHandle
        z: 10 // Lift button above the passthrough widgetMouseArea
        width: 24 * Appearance.effectiveScale
        height: 24 * Appearance.effectiveScale
        radius: 8 * Appearance.effectiveScale
        color: Appearance.m3colors.darkmode ? Appearance.colors.colOnTertiaryContainer : Appearance.colors.colSecondaryContainer
        
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: -8 * Appearance.effectiveScale
        }
        
        opacity: (widgetMouseArea.containsMouse || toggleArea.containsMouse) && (!Config.ready || !Config.options.appearance.systemMonitor.locked) ? 0.9 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "screen_rotation"
            iconSize: 15 * Appearance.effectiveScale
            color: Appearance.m3colors.darkmode ? Appearance.colors.colTertiaryContainer : Appearance.colors.colOnSecondaryContainer
        }

        MouseArea {
            id: toggleArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (Config.ready) {
                    let nextVertical = !Config.options.appearance.systemMonitor.vertical;
                    Config.options.appearance.systemMonitor.vertical = nextVertical;
                }
            }
        }
    }

    // Outer hover area to trigger handles
    MouseArea {
        id: widgetMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Passthrough clicks
        cursorShape: (Config.ready && Config.options.appearance.systemMonitor.locked) ? Qt.ArrowCursor : Qt.SizeAllCursor
    }
}
