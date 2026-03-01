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
    implicitWidth: 1100
    implicitHeight: 800
    
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
                        Layout.preferredWidth: 260
                    }

                    // Segmented Breadcrumbs (True high-fidelity style)
                    RowLayout {
                        id: breadcrumbRow
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        visible: !root.favMode
                        spacing: 2
                        
                        property var parts: Wallpapers.directory.toString().replace("file://", "").split("/").filter(v => v !== "")
                        
                        Item { Layout.fillWidth: true } // Center the breadcrumbs

                        Row {
                            spacing: 2
                            Repeater {
                                model: breadcrumbRow.parts
                                delegate: SegmentedButton {
                                    // Segmented Breadcrumbs Fix
                                    implicitWidth: Math.max(64, label.implicitWidth + 32)
                                    
                                    buttonText: modelData
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    smallRadius: 4 // Match the desired sharp inner edge look
                                    pillOnActive: false // Keep it as a segment even when active
                                    
                                    // Highlight the "active" (last) segment
                                    isHighlighted: index === breadcrumbRow.parts.length - 1
                                    colInactive: Appearance.colors.colLayer2
                                    colActive: Appearance.m3colors.m3primary
                                    colActiveText: Appearance.m3colors.m3onPrimary
                                    colInactiveText: Appearance.colors.colOnLayer0
                                    
                                    onClicked: {
                                        const newPath = "/" + breadcrumbRow.parts.slice(0, index + 1).join("/");
                                        Wallpapers.directory = "file://" + newPath;
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true } // Center the breadcrumbs
                    }

                    Item { Layout.fillWidth: true }

                    // Header Search Pill
                    Rectangle {
                        Layout.preferredWidth: 240
                        Layout.preferredHeight: 36
                        radius: 18
                        color: Appearance.colors.colLayer2
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 8
                            MaterialSymbol {
                                text: "search"; iconSize: 18; color: Appearance.colors.colSubtext
                            }
                            TextInput {
                                id: headerSearch
                                Layout.fillWidth: true
                                color: Appearance.colors.colOnLayer0
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                verticalAlignment: TextInput.AlignVCenter
                                // onTextChanged: root.searchFilter = text
                                StyledText {
                                    anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                                    text: "Search wallpapers..."; color: Appearance.colors.colSubtext
                                    visible: headerSearch.text === "" && !headerSearch.activeFocus
                                }
                            }
                        }
                    }

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
                        model: Wallpapers.folderModel
                        
                        delegate: Item {
                            width: grid.cellWidth; height: grid.cellHeight
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

                                        ThumbnailImage {
                                            anchors.fill: parent; sourcePath: "file://" + filePath
                                        }
                                        
                                        Rectangle {
                                            anchors.fill: parent; color: Appearance.colors.colPrimary; opacity: mArea.containsMouse ? 0.15 : 0
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }
                                        
                                        MouseArea {
                                            id: mArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectWallpaper("file://" + filePath)
                                        }
                                    }
                                }
                                
                                StyledText {
                                    Layout.fillWidth: true; text: fileName; horizontalAlignment: Text.AlignHCenter
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
                            text: "No wallpapers found"
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
}
