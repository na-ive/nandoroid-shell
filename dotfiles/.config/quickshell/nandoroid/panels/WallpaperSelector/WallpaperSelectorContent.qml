import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

/**
 * High-Fidelity Settings-Style Wallpaper Selector.
 * Robust Scoping Fix (Phase 5) - Reliable ID referencing and cursor behavior.
 */
Item {
    id: mainSelector
    
    // Explicit reference for child components to avoid ReferenceError
    readonly property Item selectorItem: mainSelector

    // Responsive sizing
    width: Math.min(1100, (parent ? parent.width : 1200) * 0.9)
    height: Math.min(800, (parent ? parent.height : 900) * 0.85)
    
    implicitWidth: width
    implicitHeight: height
    
    focus: true
    Keys.onEscapePressed: close()

    signal closed()
    
    property bool favMode: false
    property bool wallhavenMode: false
    property alias searchFilter: headerSearch.text
    
    onSearchFilterChanged: {
        if (wallhavenMode) {
            if (searchFilter.startsWith("wallhaven-")) {
                const id = searchFilter.substring(10).trim();
                if (id !== "" && id.length > 3) WallhavenService.search(id, true);
            }
        } else {
            Wallpapers.searchQuery = searchFilter
        }
    }

    function close() { 
        WallhavenService.results.clear();
        mainSelector.closed() 
    }

    function selectWallpaper(path) {
        if (GlobalStates.wallpaperSelectorTarget === "desktop") {
            Wallpapers.select(path)
        } else {
            Wallpapers.selectForLockscreen(path)
        }
        mainSelector.close()
    }

    function normalizePath(p) {
        let s = p.toString();
        if (s.startsWith("file://")) s = s.substring(7);
        if (s.endsWith("/")) s = s.substring(0, s.length - 1);
        return s;
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

        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            // ── Header ──
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

                    // Header Search Pill
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
                                
                                onTextChanged: {
                                    if (!mainSelector.wallhavenMode) {
                                        Wallpapers.searchQuery = text
                                    } else if (text === "") {
                                        WallhavenService.search("");
                                    }
                                }
                                
                                onAccepted: {
                                    if (mainSelector.wallhavenMode) {
                                        if (text.startsWith("wallhaven-")) {
                                            const id = text.substring(10).trim();
                                            WallhavenService.search(id, true);
                                        } else {
                                            WallhavenService.search(text);
                                        }
                                    }
                                }

                                StyledText {
                                    visible: !headerSearch.text && !headerSearch.activeFocus
                                    text: mainSelector.wallhavenMode ? "Search Wallhaven..." : "Search wallpapers..."
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
                        onClicked: mainSelector.close()
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 22; color: Appearance.colors.colSubtext }
                    }
                }
            }

            // ── Main Body ──
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

                        // --- Top Special Button (Wallhaven - Online) ---
                        RippleButton {
                            id: wallhavenSideBtn
                            Layout.fillWidth: true
                            implicitHeight: 52
                            buttonRadius: 16
                            toggled: mainSelector.wallhavenMode
                            colBackground: toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                            colBackgroundHover: toggled ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                            
                            onClicked: {
                                mainSelector.wallhavenMode = true;
                                mainSelector.favMode = false;
                                // Always search for fresh random results
                                WallhavenService.search("");
                            }

                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 20; spacing: 16
                                MaterialSymbol { 
                                    text: "travel_explore"; iconSize: 22
                                    color: wallhavenSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                }
                                StyledText { 
                                    text: "Wallhaven"; Layout.fillWidth: true; 
                                    font.weight: wallhavenSideBtn.toggled ? Font.Bold : Font.Normal
                                    color: wallhavenSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                }
                            }
                        }

                        Item { Layout.preferredHeight: 12 } // Gap separator

                        // --- Local Group (Folders & Favourites) ---
                        Repeater {
                            model: [
                                { icon: "home", name: "Home", path: Directories.home },
                                { icon: "image_search", name: "Pictures", path: Directories.pictures },
                                { icon: "wallpaper", name: "Wallpapers", path: Directories.home + "/Pictures/Wallpapers" },
                                { icon: "favorite", name: "Favourites", path: "FAV_MODE" }
                            ]
                            delegate: RippleButton {
                                id: folderBtn
                                Layout.fillWidth: true
                                implicitHeight: 52
                                buttonRadius: 26
                                
                                readonly property bool isFavBtn: modelData.path === "FAV_MODE"
                                readonly property bool isActive: {
                                    if (mainSelector.wallhavenMode) return false;
                                    if (isFavBtn) return mainSelector.favMode;
                                    return !mainSelector.favMode && mainSelector.normalizePath(Wallpapers.directory) === mainSelector.normalizePath(modelData.path);
                                }
                                
                                toggled: isActive
                                colBackground: "transparent"
                                colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                                
                                onClicked: {
                                    mainSelector.wallhavenMode = false;
                                    if (isFavBtn) {
                                        mainSelector.favMode = true;
                                    } else {
                                        mainSelector.favMode = false;
                                        Wallpapers.directory = "file://" + mainSelector.normalizePath(modelData.path);
                                    }
                                }
                                
                                contentItem: RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 20; spacing: 16
                                    MaterialSymbol { 
                                        text: modelData.icon; iconSize: 22
                                        color: folderBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                    }
                                    StyledText { 
                                        text: modelData.name; Layout.fillWidth: true; 
                                        font.weight: folderBtn.toggled ? Font.Bold : Font.Normal
                                        color: folderBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                    }
                                }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }

                        // Mode Switcher
                        Row {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            Layout.margins: 4
                            spacing: 4
                            SegmentedButton {
                                width: (parent.width - 4) / 2; height: parent.height
                                buttonText: "Desktop"; isHighlighted: GlobalStates.wallpaperSelectorTarget === "desktop"
                                colInactive: Appearance.colors.colLayer2; colActive: Appearance.m3colors.m3primary
                                onClicked: GlobalStates.wallpaperSelectorTarget = "desktop"
                            }
                            SegmentedButton {
                                width: (parent.width - 4) / 2; height: parent.height
                                buttonText: "Lock"; isHighlighted: GlobalStates.wallpaperSelectorTarget === "lock"
                                enabled: Config.ready && (Config.options.lock ? Config.options.lock.useSeparateWallpaper : true)
                                opacity: enabled ? 1 : 0.4; colInactive: Appearance.colors.colLayer2; colActive: Appearance.m3colors.m3primary
                                onClicked: GlobalStates.wallpaperSelectorTarget = "lock"
                            }
                        }
                    }
                }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12
                        color: Appearance.colors.colLayer1; radius: 28; clip: true; opacity: 0.98

                        GridView {
                            id: grid
                            anchors.fill: parent; anchors.margins: 20
                            cellWidth: width / 3; cellHeight: cellWidth * 9/16 + 40
                            clip: true; interactive: true
                            
                            // Memory optimization: Load only what's necessary (about 1.5 extra screen heights)
                            cacheBuffer: height * 1.5
                            
                            model: mainSelector.wallhavenMode ? WallhavenService.results : (mainSelector.favMode ? favModel : Wallpapers.folderModel)
                            
                            onContentYChanged: {
                                if (mainSelector.wallhavenMode && !WallhavenService.loading && contentY > contentHeight - height - 400) {
                                    if (WallhavenService.results.count < WallhavenService.totalResults) {
                                        WallhavenService.search(WallhavenService.lastQuery, false, WallhavenService.currentPage + 1);
                                    }
                                }
                            }

                            footer: Item {
                                width: grid.width; height: 80
                                visible: mainSelector.wallhavenMode && WallhavenService.loading && grid.count > 0
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12
                                    MaterialSymbol {
                                        text: "progress_activity"; iconSize: 24; color: Appearance.colors.colPrimary
                                        RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                                    }
                                    StyledText { text: "Loading more..."; color: Appearance.colors.colSubtext }
                                }
                            }

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
                                
                                // EXPLICIT PROXY PROPERTIES TO FIX REFERENCE ERRORS
                                readonly property Item selector: mainSelector.selectorItem
                                readonly property bool inWallhavenMode: delegateRoot.selector.wallhavenMode
                                readonly property bool inFavMode: delegateRoot.selector.favMode
                                
                                readonly property string currentFilePath: delegateRoot.inWallhavenMode ? (model.full || "") : (delegateRoot.inFavMode ? (model.filePath || "") : (filePath || ""))
                                readonly property string currentFileName: delegateRoot.inWallhavenMode ? ("wallhaven-" + (model.id || "")) : (delegateRoot.inFavMode ? (model.fileName || "") : (fileName || ""))
                                readonly property string previewPath: delegateRoot.inWallhavenMode ? (model.preview || "") : ("file://" + currentFilePath)
                                
                                readonly property string wallhavenId: {
                                    if (delegateRoot.inWallhavenMode) return model.id || "";
                                    // Robust detection from local filename (e.g. wallhaven-XXXXX.jpg)
                                    let name = delegateRoot.currentFileName.toLowerCase();
                                    if (name.startsWith("wallhaven-")) {
                                        let parts = name.split("-");
                                        if (parts.length > 1) {
                                            let idWithExt = parts[1];
                                            return idWithExt.split(".")[0];
                                        }
                                    }
                                    return "";
                                }

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
                                                anchors.fill: parent
                                                sourcePath: currentFilePath 
                                                visible: !delegateRoot.inWallhavenMode && currentFilePath !== ""
                                            }

                                            Image {
                                                anchors.fill: parent; source: delegateRoot.inWallhavenMode ? previewPath : ""
                                                fillMode: Image.PreserveAspectCrop
                                                visible: delegateRoot.inWallhavenMode && source != ""
                                                asynchronous: true; cache: true
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                gradient: Gradient {
                                                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.0) } 
                                                    GradientStop { position: 0.6; color: Qt.rgba(0,0,0, 0.15) } 
                                                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.45) } 
                                                }
                                            }
                                            
                                            Rectangle {
                                                anchors.fill: parent; color: Appearance.colors.colPrimary; opacity: (mArea.containsMouse || imgHover.hovered) ? 0.15 : 0
                                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                            }
                                            
                                            MouseArea {
                                                id: mArea; anchors.fill: parent; hoverEnabled: true
                                                // Arrow cursor in wallhaven mode as requested
                                                cursorShape: delegateRoot.inWallhavenMode ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                enabled: !delegateRoot.inWallhavenMode
                                                onClicked: {
                                                    if (currentFilePath !== "") {
                                                        delegateRoot.selector.selectWallpaper("file://" + currentFilePath)
                                                    }
                                                }
                                            }
                                            
                                            RowLayout {
                                                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 4; spacing: 2

                                                RippleButton {
                                                    id: similarBtn
                                                    visible: delegateRoot.wallhavenId !== ""
                                                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18; colBackground: "transparent"
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "auto_awesome"; iconSize: 20; color: "white"
                                                        fill: parent.hovered ? 1 : 0
                                                    }
                                                    onClicked: {
                                                        let s = delegateRoot.selector;
                                                        s.wallhavenMode = true;
                                                        s.favMode = false;
                                                        s.searchFilter = "wallhaven-" + delegateRoot.wallhavenId;
                                                        WallhavenService.search(delegateRoot.wallhavenId, true);
                                                    }
                                                    StyledToolTip { text: "Search similar on Wallhaven" }
                                                }

                                                RippleButton {
                                                    id: favBtn
                                                    visible: !delegateRoot.inWallhavenMode && currentFilePath !== ""
                                                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18; colBackground: "transparent"
                                                    readonly property bool isFav: currentFilePath !== "" && Wallpapers.isFavorite(currentFilePath)
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "favorite"; iconSize: 20
                                                        fill: (favBtn.isFav || favBtn.hovered) ? 1 : 0
                                                        color: favBtn.isFav ? "#ff4081" : "#FFFFFF"
                                                        Behavior on color { ColorAnimation { duration: 200 } }
                                                    }
                                                    onClicked: Wallpapers.toggleFavorite(currentFilePath)
                                                    StyledToolTip { text: favBtn.isFav ? "Remove from favorites" : "Add to favorites" }
                                                }

                                                RippleButton {
                                                    id: downloadOnlyBtn
                                                    visible: delegateRoot.inWallhavenMode && (model.full || "") !== ""
                                                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18; colBackground: "transparent"
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "download"; iconSize: 20; color: "white"
                                                        fill: parent.hovered ? 1 : 0
                                                    }
                                                    onClicked: WallhavenService.download(model.full, model.id, model.file_type, false)
                                                    StyledToolTip { text: "Download to folder" }
                                                }

                                                RippleButton {
                                                    id: downloadApplyBtn
                                                    visible: delegateRoot.inWallhavenMode && (model.full || "") !== ""
                                                    implicitWidth: 36; implicitHeight: 36; buttonRadius: 18; colBackground: "transparent"
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "wallpaper"; iconSize: 20; color: "white"
                                                        fill: parent.hovered ? 1 : 0
                                                    }
                                                    onClicked: WallhavenService.download(model.full, model.id, model.file_type, true)
                                                    StyledToolTip { text: "Download and Apply" }
                                                }
                                            }

                                            Rectangle {
                                                visible: delegateRoot.inWallhavenMode && (model.resolution || "") !== ""
                                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8
                                                width: resText.implicitWidth + 12; height: 20; radius: 10; color: Qt.rgba(0,0,0, 0.5)
                                                StyledText {
                                                    id: resText; anchors.centerIn: parent; text: model.resolution || ""
                                                    font.pixelSize: 10; font.weight: Font.Bold; color: "white"
                                                }
                                            }
                                        }
                                    }
                                    StyledText {
                                        Layout.fillWidth: true; text: currentFileName; horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: Appearance.font.pixelSize.smallest; elide: Text.ElideRight; color: Appearance.colors.colOnLayer1; opacity: 0.7
                                    }
                                }
                            }
                            
                            ScrollBar.vertical: StyledScrollBar {}

                            ColumnLayout {
                                anchors.centerIn: parent; visible: grid.count === 0; spacing: 12
                                MaterialSymbol {
                                    visible: mainSelector.wallhavenMode && WallhavenService.loading
                                    text: "progress_activity"; iconSize: 32; color: Appearance.colors.colPrimary
                                    Layout.alignment: Qt.AlignHCenter
                                    RotationAnimation on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                                }
                                StyledText {
                                    text: {
                                        if (mainSelector.wallhavenMode) {
                                            if (WallhavenService.errorMessage !== "") return WallhavenService.errorMessage;
                                            if (WallhavenService.loading) return "Searching Wallhaven...";
                                            return "No online wallpapers found";
                                        }
                                        return mainSelector.favMode ? "No favorite wallpapers" : "No wallpapers found";
                                    }
                                    color: WallhavenService.errorMessage !== "" ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
            }
        }
    }
}
