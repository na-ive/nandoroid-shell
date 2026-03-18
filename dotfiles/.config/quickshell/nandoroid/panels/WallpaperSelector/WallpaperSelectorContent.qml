import "../../core"
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

/**
 * High-Fidelity Settings-Style Wallpaper Selector.
 * Mirrors the main Settings UI with a unified sidebar-menubar background, 
 * a rounded colLayer1 content card, and segmented breadcrumbs.
 */
Item {
    id: root
    
    // Responsive sizing
    width: Math.min(1100, (parent ? parent.width : 1200) * 0.9)
    height: Math.min(800, (parent ? parent.height : 900) * 0.85)
    
    implicitWidth: width
    implicitHeight: height
    
    focus: true
    Keys.onEscapePressed: close()

    signal closed()
    
    property bool favMode: false
    property alias searchFilter: headerSearch.text
    onSearchFilterChanged: Wallpapers.searchQuery = searchFilter

    function close() { root.closed() }

    function selectWallpaper(path) {
        if (GlobalStates.wallpaperSelectorTarget === "desktop") {
            Wallpapers.select(path)
        } else {
            Wallpapers.selectForLockscreen(path)
        }
        root.closed()
    }

    // ── Main UI Frame ──
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: 32
        border.width: 1
        border.color: Appearance.colors.colOutlineVariant
        clip: true

        // Trap clicks inside to prevent reaching the outside-click MouseArea
        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            // ── Header (Menubar Area) ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 12
                    spacing: 20

                    StyledText {
                        text: (GlobalStates.wallpaperSelectorTarget === "desktop" ? "Desktop Wallpaper" : "Lock Screen Wallpaper")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.Bold
                        color: Appearance.colors.colOnLayer0
                        Layout.preferredWidth: 200
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    // Header Search Pill (Centered and Matched with Settings)
                    Rectangle {
                        Layout.preferredWidth: 360
                        Layout.preferredHeight: 44
                        radius: 22
                        color: Appearance.colors.colLayer1
                        Layout.alignment: Qt.AlignVCenter
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            spacing: 12
                            MaterialSymbol {
                                text: "search"; iconSize: 22; color: Appearance.colors.colSubtext
                            }
                            TextInput {
                                id: headerSearch
                                Layout.fillWidth: true
                                Layout.rightMargin: 16
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.normal
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                
                                onTextChanged: Wallpapers.searchQuery = text

                                StyledText {
                                    visible: !headerSearch.text && !headerSearch.activeFocus
                                    text: "Search wallpapers..."
                                    font.pixelSize: headerSearch.font.pixelSize
                                    color: Appearance.colors.colSubtext
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        implicitWidth: 36; implicitHeight: 36; buttonRadius: 18
                        colBackground: "transparent"
                        onClicked: root.closed()
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 22; color: Appearance.colors.colSubtext }
                    }
                }
            }

            // ── Main Body (Sidebar + Card) ──
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Sidebar area
                Item {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 240
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Repeater {
                            model: [
                                { icon: "home", name: "Home", path: Directories.home },
                                { icon: "image_search", name: "Pictures", path: Directories.pictures },
                                { icon: "wallpaper", name: "Wallpapers", path: Directories.home + "/Pictures/Wallpapers" },
                                { icon: "favorite", name: "Favourites", path: "FAV_MODE" }
                            ]
                            delegate: RippleButton {
                                Layout.fillWidth: true
                                implicitHeight: 52
                                buttonRadius: 26
                                
                                readonly property bool isFav: modelData.path === "FAV_MODE"
                                readonly property bool isActive: isFav ? root.favMode : (!root.favMode && Wallpapers.directory.toString() === "file://" + modelData.path)
                                
                                toggled: isActive
                                colBackground: "transparent"
                                colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                                
                                onClicked: {
                                    if (isFav) {
                                        root.favMode = true;
                                    } else {
                                        root.favMode = false;
                                        Wallpapers.directory = "file://" + modelData.path;
                                    }
                                }
                                
                                contentItem: RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; spacing: 16
                                    MaterialSymbol { 
                                        text: modelData.icon; iconSize: 22
                                        color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                    }
                                    StyledText { 
                                        text: modelData.name; Layout.fillWidth: true; 
                                        font.weight: parent.parent.toggled ? Font.Bold : Font.Normal
                                        color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }

                        // Mode Switcher (Desktop / Lockscreen)
                        Row {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            Layout.margins: 4
                            spacing: 4
                            
                            SegmentedButton {
                                width: (parent.width - 4) / 2
                                height: parent.height
                                
                                buttonText: "Desktop"
                                isHighlighted: GlobalStates.wallpaperSelectorTarget === "desktop"
                                colInactive: Appearance.colors.colLayer2
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactiveText: Appearance.colors.colOnLayer0
                                
                                onClicked: GlobalStates.wallpaperSelectorTarget = "desktop"
                            }
                            
                            SegmentedButton {
                                width: (parent.width - 4) / 2
                                height: parent.height
                                
                                buttonText: "Lock"
                                // Disable if "Use same wallpaper" is on
                                enabled: Config.ready && (Config.options.lock ? Config.options.lock.useSeparateWallpaper : true)
                                opacity: enabled ? 1 : 0.4
                                
                                isHighlighted: GlobalStates.wallpaperSelectorTarget === "lock"
                                colInactive: Appearance.colors.colLayer2
                                colActive: Appearance.m3colors.m3primary
                                colActiveText: Appearance.m3colors.m3onPrimary
                                colInactiveText: Appearance.colors.colOnLayer0
                                
                                onClicked: GlobalStates.wallpaperSelectorTarget = "lock"
                            }
                        }
                    }
                }

                // Main Content Card (L1)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 12
                    color: Appearance.colors.colLayer1
                    radius: 28
                    clip: true
                    
                    // border.width: 1
                    // border.color: Appearance.colors.colOutlineVariant
                    opacity: 0.98

                    GridView {
                        id: grid
                        anchors.fill: parent
                        anchors.margins: 20
                        cellWidth: width / 3
                        cellHeight: cellWidth * 9/16 + 40 // True 16:9 + space for label
                        clip: true
                        interactive: true
                        
                        // Use a custom model for favorites, otherwise use folder model
                        model: root.favMode ? favModel : Wallpapers.folderModel
                        
                        ListModel {
                            id: favModel
                            function refresh() {
                                clear();
                                const favs = Wallpapers.favorites;
                                for (let i = 0; i < favs.length; i++) {
                                    const path = favs[i];
                                    const name = path.split('/').pop();
                                    append({ "filePath": path, "fileName": name });
                                }
                            }
                            Component.onCompleted: refresh()
                        }
                        
                        Connections {
                            target: Wallpapers
                            function onFavoritesChanged() { favModel.refresh(); }
                        }
                        
                        onVisibleChanged: { if (visible) favModel.refresh(); }
                        
                        delegate: Item {
                            id: delegateRoot
                            width: grid.cellWidth; height: grid.cellHeight
                            
                            readonly property string currentFilePath: root.favMode ? model.filePath : filePath
                            readonly property string currentFileName: root.favMode ? model.fileName : fileName

                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 8
                                
                                Item {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    Rectangle {
                                        id: imgPlate
                                        anchors.fill: parent; radius: 18; color: Appearance.colors.colLayer2
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle { width: imgPlate.width; height: imgPlate.height; radius: 18 }
                                        }

                                        HoverHandler { id: imgHover }

                                        ThumbnailImage {
                                            anchors.fill: parent; sourcePath: "file://" + currentFilePath
                                        }

                                        // Lightweight Gradient Overlay for better icon legibility (Focused on bottom-right)
                                        Rectangle {
                                            anchors.fill: parent
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.0) } 
                                                GradientStop { position: 0.6; color: Qt.rgba(0,0,0, 0.15) } // Start darkening
                                                GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.45) } // Darkest at bottom
                                            }
                                        }
                                        
                                        Rectangle {
                                            anchors.fill: parent; color: Appearance.colors.colPrimary; opacity: (mArea.containsMouse || imgHover.hovered) ? 0.15 : 0
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }
                                        
                                        MouseArea {
                                            id: mArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectWallpaper("file://" + currentFilePath)
                                        }
                                        
                                        // Clean Favorite Button (Moved to Bottom-Right)
                                        RippleButton {
                                            id: favBtn
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.margins: 4 // More tucked into the corner
                                            implicitWidth: 40; implicitHeight: 40; buttonRadius: 20
                                            colBackground: "transparent"
                                            
                                            readonly property bool isFav: Wallpapers.isFavorite(currentFilePath)
                                            
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "favorite"
                                                iconSize: 22
                                                // 1 (solid) when active or when the button itself is hovered
                                                fill: (favBtn.isFav || favBtn.hovered) ? 1 : 0
                                                // Red when active, pure white when inactive
                                                color: favBtn.isFav ? "#ff4081" : "#FFFFFF"
                                                
                                                Behavior on color { ColorAnimation { duration: 200 } }
                                            }
                                            
                                            onClicked: Wallpapers.toggleFavorite(currentFilePath)
                                        }
                                    }
                                }
                                
                                StyledText {
                                    Layout.fillWidth: true; text: currentFileName; horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.smallest; elide: Text.ElideRight; color: Appearance.colors.colOnLayer1
                                    opacity: 0.7
                                }
                            }
                        }
                        
                        ScrollBar.vertical: StyledScrollBar {}

                        // Empty State if no wallpapers found
                        StyledText {
                            visible: grid.count === 0
                            anchors.centerIn: parent
                            text: root.favMode ? "No favorite wallpapers" : "No wallpapers found"
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
