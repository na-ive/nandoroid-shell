import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool isSpotlight: false
    property var launcherContent: null
    property int selectedIndex: 0
    property bool isKeyboardNavigation: false

    readonly property int wallColumns: isSpotlight ? 2 : 4
    readonly property real wallSpacing: 8 * Appearance.effectiveScale
    readonly property var wallResults: LauncherSearch.isWallMode ? LauncherSearch.results : []

    function wallNavigate(dx, dy) {
        const total = root.wallResults.length;
        if (total <= 0) return 0;
        const from = Math.min(Math.max(0, root.selectedIndex), total - 1);
        let target = from;
        if (dx !== 0) {
            // Left/right: move 1 step, clamp row
            const row = Math.floor(from / wallColumns);
            const col = from % wallColumns;
            let newCol = col + dx;
            if (newCol < 0) newCol = 0;
            if (newCol >= wallColumns) newCol = wallColumns - 1;
            target = row * wallColumns + newCol;
            if (target >= total) target = total - 1;
        } else if (dy !== 0) {
            target = from + dy * wallColumns;
            if (target < 0) target = 0;
            if (target >= total) target = total - 1;
        }
        return target;
    }

    onSelectedIndexChanged: {
        if (!visible) return;
        if (GlobalStates.launcherOpen || GlobalStates.spotlightOpen) {
            if (root.isKeyboardNavigation && wallGrid.count > 0) {
                wallGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
            }
        }
    }

    Connections {
        target: LauncherSearch
        function onQueryChanged() {
            if (LauncherSearch.isWallMode) {
                Qt.callLater(() => {
                    if (wallGrid.model && wallGrid.model.length > 0)
                        wallGrid.positionViewAtIndex(0, GridView.Beginning);
                });
            }
        }
    }

    GridView {
        id: wallGrid
        anchors.fill: parent
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        clip: true
        cellWidth: width / wallColumns
        cellHeight: cellWidth * 0.75 + 23 * Appearance.effectiveScale
        interactive: true
        model: root.visible ? root.wallResults : []

        // Keep loadMore working for wall browsing
        onContentYChanged: {
            if (!visible) return;
            if (contentHeight - contentY - height < 120) {
                Qt.callLater(() => LauncherSearch.loadMoreWallpapers());
            }
        }
        onCountChanged: {
            if (visible && root.selectedIndex >= count - 6 && count > 0) {
                Qt.callLater(() => LauncherSearch.loadMoreWallpapers());
            }
        }

        delegate: Item {
            width: wallGrid.cellWidth
            height: wallGrid.cellHeight
            property var wallData: modelData
            property bool isSelected: root.selectedIndex === index

            RippleButton {
                anchors.fill: parent
                anchors.margins: 2 * Appearance.effectiveScale
                padding: 0
                buttonRadius: Appearance.rounding.small
                colBackground: isSelected ? Appearance.m3colors.m3primary : Appearance.colors.colLayer2
                colBackgroundHover: isSelected ? Appearance.m3colors.m3primary : Appearance.colors.colLayer2Hover
                colBackgroundToggled: Appearance.m3colors.m3primary
                colBackgroundToggledHover: Appearance.m3colors.m3primary
                toggled: isSelected
                onClicked: {
                    if (wallData && wallData.execute) {
                        wallData.execute();
                        if (!wallData.keepOpen) {
                            GlobalStates.launcherOpen = false;
                            GlobalStates.spotlightOpen = false;
                        }
                    }
                }
                onHoveredChanged: {
                    if (hovered && (GlobalStates.launcherOpen || GlobalStates.spotlightOpen)) {
                        root.isKeyboardNavigation = false;
                        root.selectedIndex = index;
                    }
                }

                contentItem: ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4 * Appearance.effectiveScale
                    spacing: 4 * Appearance.effectiveScale

                    // Image 4:3 like WallpaperSelector - keep narrow padding (6 total = 2+4) as before
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: (wallGrid.cellWidth - 12 * Appearance.effectiveScale) * 0.75
                        Rectangle {
                            id: imgPlate
                            anchors.fill: parent
                            radius: 10 * Appearance.effectiveScale
                            color: Appearance.colors.colLayer2
                            clip: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle { width: imgPlate.width; height: imgPlate.height; radius: 10 * Appearance.effectiveScale }
                            }

                            ThumbnailImage {
                                anchors.fill: parent
                                sourcePath: wallData && wallData.isImage ? wallData.imagePath : ""
                                visible: !!(wallData && wallData.isImage && wallData.imagePath)
                                fillMode: Image.PreserveAspectCrop
                                radius: 10 * Appearance.effectiveScale
                            }

                            // Fallback icon
                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: !(wallData && wallData.isImage)
                                text: wallData ? (wallData.icon || "wallpaper") : "wallpaper"
                                iconSize: 24 * Appearance.effectiveScale
                                color: isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                            }

                            // Selected border on image
                            Rectangle {
                                anchors.fill: parent
                                radius: 10 * Appearance.effectiveScale
                                color: "transparent"
                                border.width: isSelected ? 2 * Appearance.effectiveScale : 0
                                border.color: Appearance.m3colors.m3primary
                                visible: isSelected
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16 * Appearance.effectiveScale
                        text: wallData ? wallData.name : ""
                        font.pixelSize: Math.round(10 * Appearance.effectiveScale)
                        font.weight: isSelected ? Font.DemiBold : Font.Medium
                        color: isSelected ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                        elide: Text.ElideMiddle
                        horizontalAlignment: Text.AlignHCenter
                        visible: !!(wallData && wallData.name)
                    }
                }
            }
        }
    }
}
