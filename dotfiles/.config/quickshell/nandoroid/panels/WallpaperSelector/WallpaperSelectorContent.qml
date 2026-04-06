import "../../core"
import "../../services"
import "../../widgets"
import "../../core/functions" as Functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
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

    ListModel {
        id: customFoldersModel
    }

    function refreshCustomFolders() {
        customFoldersModel.clear();
        const folders = Config.options.appearance.background.customFolders || [];
        for (let i = 0; i < folders.length; i++) {
            const path = folders[i];
            const name = path.split('/').pop() || path;
            customFoldersModel.append({ "name": name, "path": path });
        }
    }

    Component.onCompleted: {
        refreshCustomFolders();
        applySorting();
    }

    Connections {
        target: Wallpapers
        function onCustomFoldersChanged() { mainSelector.refreshCustomFolders(); }
    }

    // Responsive sizing
    width: Math.min(1380 * Appearance.effectiveScale, (parent ? parent.width : 1500) * 0.95)
    height: Math.min(840 * Appearance.effectiveScale, (parent ? parent.height : 900) * 0.85)
    
    implicitWidth: width
    implicitHeight: height
    
    focus: true
    Keys.onEscapePressed: close()

    signal closed()
    
    property bool favMode: false
    property bool wallhavenMode: false
    property bool naiveMode: false
    property bool liveMode: false
    
    // Selection state for right sidebar
    property var selectedWallpaper: null
    property bool showDetails: liveMode && selectedWallpaper !== null
    
    // Independent search states
    property string localSearch: ""
    property string wallhavenSearch: ""
    property string naiveSearch: ""
    
    // Sorting state
    property string sortMode: "name_asc" // name_asc, name_desc
    
    // Internal lock to prevent recursion during switching
    property bool _switchingMode: false

    function applySorting() {
        if (wallhavenMode || naiveMode) return;

        if (favMode) {
            favModel.refresh();
            return;
        }

        // Local sorting via global Wallpapers service
        if (sortMode === "name_asc") {
            Wallpapers.sortField = FolderListModel.Name;
            Wallpapers.sortReversed = false;
        } else if (sortMode === "name_desc") {
            Wallpapers.sortField = FolderListModel.Name;
            Wallpapers.sortReversed = true;
        }
    }

    onSortModeChanged: applySorting()

    function switchMode(mode) {
        if (_switchingMode) return;
        _switchingMode = true;
        
        // Save current search state
        if (wallhavenMode) wallhavenSearch = headerSearch.text;
        else if (naiveMode) naiveSearch = headerSearch.text;
        else localSearch = headerSearch.text;
        
        // Update modes
        wallhavenMode = (mode === "wallhaven");
        naiveMode = (mode === "naive");
        favMode = (mode === "fav");
        liveMode = (mode === "live");
        
        // Clear selection when switching modes
        selectedWallpaper = null;
        
        // Restore search state
        if (wallhavenMode) {
            headerSearch.text = wallhavenSearch;
            // If empty, fetch defaults
            if (headerSearch.text === "") WallhavenService.search("");
        } else if (naiveMode) {
            headerSearch.text = naiveSearch;
            NaIveWallpaperService.fetch();
        } else if (liveMode) {
            headerSearch.text = "";
            WallpaperEngineService.fetch();
        } else {
            headerSearch.text = localSearch;
            if (!favMode && !liveMode) {
                Wallpapers.searchQuery = localSearch;
            }
        }
        
        applySorting();
        _switchingMode = false;
    }

    property alias searchFilter: headerSearch.text
    
    onSearchFilterChanged: {
        if (_switchingMode) return;
        
        if (wallhavenMode) {
            if (searchFilter.startsWith("wallhaven-")) {
                const id = searchFilter.substring(10).trim();
                if (id !== "" && id.length > 3) WallhavenService.search(id, true);
            }
        } else if (naiveMode) {
            // ...
        } else {
            Wallpapers.searchQuery = searchFilter
        }
    }

    function close() { 
        WallhavenService.results.clear();
        NaIveWallpaperService.results.clear();
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
        radius: 32 * Appearance.effectiveScale
        border.width: Math.max(1, 1 * Appearance.effectiveScale)
        border.color: Appearance.colors.colOutlineVariant
        clip: true

        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 0

            // ── Header ──
            Item {
                id: headerItem
                Layout.fillWidth: true
                Layout.preferredHeight: 64 * Appearance.effectiveScale
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20 * Appearance.effectiveScale
                    anchors.rightMargin: 12 * Appearance.effectiveScale
                    spacing: 20 * Appearance.effectiveScale

                    StyledText {
                        text: (GlobalStates.wallpaperSelectorTarget === "desktop" ? "Desktop Wallpaper" : "Lock Screen Wallpaper")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                        Layout.preferredWidth: 200 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    // Header Search Pill
                    Rectangle {
                        Layout.preferredWidth: 360 * Appearance.effectiveScale
                        Layout.preferredHeight: 44 * Appearance.effectiveScale
                        radius: 22 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1
                        Layout.alignment: Qt.AlignVCenter
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            spacing: 12 * Appearance.effectiveScale
                            MaterialSymbol {
                                text: "search"; iconSize: 22 * Appearance.effectiveScale; color: Appearance.colors.colSubtext
                            }
                            TextInput {
                                id: headerSearch
                                Layout.fillWidth: true
                                Layout.rightMargin: 16 * Appearance.effectiveScale
                                color: Appearance.colors.colOnLayer1
                                font.pixelSize: Appearance.font.pixelSize.normal
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                
                                onTextChanged: {
                                    if (mainSelector._switchingMode) return;
                                    
                                    // Save state immediately on change
                                    if (mainSelector.wallhavenMode) mainSelector.wallhavenSearch = text;
                                    else if (mainSelector.naiveMode) mainSelector.naiveSearch = text;
                                    else mainSelector.localSearch = text;

                                    if (!mainSelector.wallhavenMode && !mainSelector.naiveMode) {
                                        Wallpapers.searchQuery = text
                                    } else if (text === "" && mainSelector.wallhavenMode) {
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
                                    text: mainSelector.wallhavenMode ? "Search Wallhaven..." : (mainSelector.naiveMode ? "Search NA-ive Walls..." : "Search wallpapers...")
                                    font.pixelSize: headerSearch.font.pixelSize
                                    color: Appearance.colors.colSubtext
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: 1 * Appearance.effectiveScale
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }

                    // Sorting Button
                    Item {
                        id: sortBtnContainer
                        Layout.preferredWidth: 44 * Appearance.effectiveScale
                        Layout.preferredHeight: 44 * Appearance.effectiveScale
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: -12 * Appearance.effectiveScale // Negative margin to bring it closer
                        visible: !mainSelector.wallhavenMode && !mainSelector.naiveMode

                        RippleButton {
                            id: sortBtn
                            anchors.fill: parent
                            buttonRadius: 8 * Appearance.effectiveScale // Even smaller to match Sunny shape
                            colBackground: "transparent"
                            onClicked: sortPopup.visible = !sortPopup.visible
                            
                            MaterialShapeWrappedMaterialSymbol {
                                anchors.centerIn: parent
                                implicitSize: 42 * Appearance.effectiveScale
                                shapeString: "Sunny"
                                color: Appearance.colors.colSecondary
                                colSymbol: Appearance.colors.colOnSecondary
                                text: "sort_by_alpha"
                                iconSize: 20 * Appearance.effectiveScale
                                rotation: sortPopup.visible ? 45 : 0
                            }
                            StyledToolTip { text: "Sort Options" }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RippleButton {
                        implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale
                        colBackground: "transparent"
                        onClicked: mainSelector.close()
                        MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 22 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
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
                    Layout.preferredWidth: 240 * Appearance.effectiveScale
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        ScrollView {
                            id: sidebarScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            ScrollBar.vertical: StyledScrollBar {}

                            Column {
                                width: sidebarScroll.availableWidth
                                spacing: 4 * Appearance.effectiveScale

                                // --- Live Wallpaper (Engine) ---
                                RippleButton {
                                    id: liveSideBtn
                                    width: parent.width
                                    implicitHeight: 52 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    toggled: mainSelector.liveMode
                                    colBackground: toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                    colBackgroundHover: toggled ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                    
                                    onClicked: mainSelector.switchMode("live")

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                        MaterialSymbol { 
                                            text: "movie"; iconSize: 22 * Appearance.effectiveScale
                                            color: liveSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                        }
                                        StyledText { 
                                            text: "Live Wallpaper"; Layout.fillWidth: true; 
                                            font.weight: liveSideBtn.toggled ? Font.DemiBold : Font.Normal
                                            color: liveSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                        }
                                    }
                                }

                                // --- Top Special Button (Wallhaven - Online) ---
                                RippleButton {
                                    id: wallhavenSideBtn
                                    width: parent.width
                                    implicitHeight: 52 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    toggled: mainSelector.wallhavenMode
                                    colBackground: toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                    colBackgroundHover: toggled ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                    
                                    onClicked: mainSelector.switchMode("wallhaven")

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                        MaterialSymbol { 
                                            text: "travel_explore"; iconSize: 22 * Appearance.effectiveScale
                                            color: wallhavenSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                        }
                                        StyledText { 
                                            text: "Wallhaven"; Layout.fillWidth: true; 
                                            font.weight: wallhavenSideBtn.toggled ? Font.DemiBold : Font.Normal
                                            color: wallhavenSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                        }
                                    }
                                }

                                // --- NA-ive Walls Collection Button ---
                                RippleButton {
                                    id: naiveSideBtn
                                    width: parent.width
                                    implicitHeight: 52 * Appearance.effectiveScale
                                    buttonRadius: 16 * Appearance.effectiveScale
                                    toggled: mainSelector.naiveMode
                                    colBackground: toggled ? Appearance.colors.colPrimary : Appearance.colors.colLayer1
                                    colBackgroundHover: toggled ? Appearance.colors.colPrimaryHover : Appearance.colors.colLayer1Hover
                                    
                                    onClicked: mainSelector.switchMode("naive")

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                        MaterialSymbol { 
                                            text: "collections"; iconSize: 22 * Appearance.effectiveScale
                                            color: naiveSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colPrimary
                                        }
                                        StyledText { 
                                            text: "NA-ive Walls"; Layout.fillWidth: true; 
                                            font.weight: naiveSideBtn.toggled ? Font.DemiBold : Font.Normal
                                            color: naiveSideBtn.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer0
                                        }
                                    }
                                }

                                Item { width: parent.width; height: 12 * Appearance.effectiveScale } // Gap separator

                                // --- Favourites (Now at the top of local) ---
                                RippleButton {
                                    id: favSideBtn
                                    width: parent.width
                                    implicitHeight: 52 * Appearance.effectiveScale
                                    buttonRadius: 26 * Appearance.effectiveScale
                                    toggled: mainSelector.favMode
                                    colBackground: "transparent"
                                    colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                                    
                                    onClicked: mainSelector.switchMode("fav")
                                    
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                        MaterialSymbol { 
                                            text: "favorite"; iconSize: 22 * Appearance.effectiveScale
                                            color: favSideBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                        }
                                        StyledText { 
                                            text: "Favourites"; Layout.fillWidth: true; 
                                            font.weight: favSideBtn.toggled ? Font.DemiBold : Font.Normal
                                            color: favSideBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                        }
                                    }
                                }

                                // --- Local Group (Standard Folders) ---
                                Repeater {
                                    model: [
                                        { icon: "home", name: "Home", path: Directories.home },
                                        { icon: "image", name: "Pictures", path: Directories.pictures },
                                        { icon: "wallpaper", name: "Wallpapers", path: Directories.home + "/Pictures/Wallpapers" }
                                    ]
                                    delegate: RippleButton {
                                        id: folderBtn
                                        width: parent.width
                                        implicitHeight: 52 * Appearance.effectiveScale
                                        buttonRadius: 26 * Appearance.effectiveScale

                                        readonly property bool isActive: !mainSelector.wallhavenMode && !mainSelector.naiveMode && !mainSelector.favMode && !mainSelector.liveMode && mainSelector.normalizePath(Wallpapers.directory) === mainSelector.normalizePath(modelData.path)

                                        toggled: isActive

                                        colBackground: "transparent"
                                        colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                                        
                                        onClicked: {
                                            mainSelector.switchMode("local");
                                            Wallpapers.directory = "file://" + mainSelector.normalizePath(modelData.path);
                                        }
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                            MaterialSymbol { 
                                                text: modelData.icon; iconSize: 22 * Appearance.effectiveScale
                                                color: folderBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                            }
                                            StyledText { 
                                                text: modelData.name; Layout.fillWidth: true; 
                                                font.weight: folderBtn.toggled ? Font.DemiBold : Font.Normal
                                                color: folderBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                            }
                                        }
                                    }
                                }

                                // --- Custom Folders ---
                                Repeater {
                                    model: customFoldersModel
                                    delegate: RippleButton {
                                        id: customFolderBtn
                                        width: parent.width
                                        implicitHeight: 52 * Appearance.effectiveScale
                                        buttonRadius: 26 * Appearance.effectiveScale
                                        
                                        readonly property bool isActive: !mainSelector.wallhavenMode && !mainSelector.naiveMode && !mainSelector.favMode && !mainSelector.liveMode && mainSelector.normalizePath(Wallpapers.directory) === mainSelector.normalizePath(model.path)
                                        
                                        toggled: isActive
                                        colBackground: "transparent"
                                        colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                                        
                                        onClicked: {
                                            mainSelector.switchMode("local");
                                            Wallpapers.directory = "file://" + mainSelector.normalizePath(model.path);
                                        }
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; anchors.rightMargin: 8 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                            MaterialSymbol { 
                                                text: "folder"; iconSize: 22 * Appearance.effectiveScale
                                                color: customFolderBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                            }
                                            StyledText { 
                                                text: model.name; Layout.fillWidth: true; elide: Text.ElideRight
                                                font.weight: customFolderBtn.toggled ? Font.DemiBold : Font.Normal
                                                color: customFolderBtn.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                                            }
                                            
                                            RippleButton {
                                                visible: customFolderBtn.hovered || customFolderBtn.toggled
                                                implicitWidth: 32 * Appearance.effectiveScale; implicitHeight: 32 * Appearance.effectiveScale; buttonRadius: 16 * Appearance.effectiveScale
                                                colBackground: "transparent"
                                                onClicked: {
                                                    let current = (Config.options.appearance.background.customFolders || []).slice();
                                                    const idx = current.indexOf(model.path);
                                                    if (idx !== -1) {
                                                        current.splice(idx, 1);
                                                        Config.options.appearance.background.customFolders = current;
                                                        mainSelector.refreshCustomFolders();
                                                    }
                                                }
                                                MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 18 * Appearance.effectiveScale; color: Appearance.m3colors.m3error }
                                            }
                                        }
                                        StyledToolTip { text: model.path }
                                    }
                                }

                                // --- Add Folder Button ---
                                RippleButton {
                                    width: parent.width
                                    implicitHeight: 52 * Appearance.effectiveScale
                                    buttonRadius: 26 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: Wallpapers.browseFolder()
                                    
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 20 * Appearance.effectiveScale; spacing: 16 * Appearance.effectiveScale
                                        MaterialSymbol { text: "add"; iconSize: 22 * Appearance.effectiveScale; color: Appearance.colors.colPrimary }
                                        StyledText { text: "Add Folder"; color: Appearance.colors.colOnLayer0 }
                                    }
                                }
                            }
                        }

                        // Mode Switcher (Sticky at bottom)
                        Row {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48 * Appearance.effectiveScale
                            spacing: 4 * Appearance.effectiveScale
                            SegmentedButton {
                                width: (parent.width - (4 * Appearance.effectiveScale)) / 2; height: parent.height
                                buttonText: "Desktop"; isHighlighted: GlobalStates.wallpaperSelectorTarget === "desktop"
                                colInactive: Appearance.colors.colLayer2; colActive: Appearance.m3colors.m3primary
                                onClicked: GlobalStates.wallpaperSelectorTarget = "desktop"
                            }
                            SegmentedButton {
                                width: (parent.width - (4 * Appearance.effectiveScale)) / 2; height: parent.height
                                buttonText: "Lock"; isHighlighted: GlobalStates.wallpaperSelectorTarget === "lock"
                                enabled: Config.ready && (Config.options.lock ? Config.options.lock.useSeparateWallpaper : true)
                                opacity: enabled ? 1 : 0.4; colInactive: Appearance.colors.colLayer2; colActive: Appearance.m3colors.m3primary
                                onClicked: GlobalStates.wallpaperSelectorTarget = "lock"
                            }
                        }
                    }
                }

                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 12 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1; radius: 28 * Appearance.effectiveScale; clip: true; opacity: 0.98

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            GridView {
                                id: grid
                                Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 20 * Appearance.effectiveScale
                                cellWidth: width / 4; cellHeight: cellWidth * 9/16 + (40 * Appearance.effectiveScale)
                                clip: true; interactive: true
                                
                                // Memory optimization: Load only what's necessary (about 1.5 extra screen heights)
                                cacheBuffer: Math.max(0, height * 1.5)
                                
                                model: {
                                    if (mainSelector.wallhavenMode) return WallhavenService.results;
                                    if (mainSelector.naiveMode) return NaIveWallpaperService.results;
                                    if (mainSelector.favMode) return favModel;
                                    if (mainSelector.liveMode) return WallpaperEngineService.results;
                                    return Wallpapers.folderModel;
                                }

                                Connections {
                                    target: WallpaperEngineService
                                    function onLoadingChanged() {
                                        if (!WallpaperEngineService.loading) {
                                            // Force a tiny refresh if needed, though results is a ListModel
                                            // so GridView should handle it.
                                        }
                                    }
                                }
                            
                            onContentYChanged: {
                                if (mainSelector.wallhavenMode && !WallhavenService.loading && contentY > contentHeight - height - (400 * Appearance.effectiveScale)) {
                                    if (WallhavenService.results.count < WallhavenService.totalResults) {
                                        WallhavenService.search(WallhavenService.lastQuery, false, WallhavenService.currentPage + 1);
                                    }
                                }
                            }

                            footer: Item {
                                width: grid.width; height: 80 * Appearance.effectiveScale
                                visible: (mainSelector.wallhavenMode && WallhavenService.loading && grid.count > 0) || (mainSelector.naiveMode && NaIveWallpaperService.loading && grid.count > 0)
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 12 * Appearance.effectiveScale
                                    MaterialSymbol {
                                        text: "progress_activity"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colPrimary
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
                                    let data = [];
                                    for (let i = 0; i < favs.length; i++) {
                                        const path = favs[i];
                                        const name = path.split('/').pop();
                                        data.push({ "filePath": path, "fileName": name });
                                    }

                                    // Apply sorting
                                    data.sort((a, b) => {
                                        if (mainSelector.sortMode === "name_asc") return a.fileName.localeCompare(b.fileName);
                                        if (mainSelector.sortMode === "name_desc") return b.fileName.localeCompare(a.fileName);
                                        return 0;
                                    });

                                    for (let item of data) append(item);
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
                                readonly property bool inNaiveMode: delegateRoot.selector.naiveMode
                                readonly property bool inFavMode: delegateRoot.selector.favMode
                                readonly property bool inLiveMode: delegateRoot.selector.liveMode
                                
                                readonly property string currentFilePath: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) ? (model.full || "") : (delegateRoot.inFavMode ? (model.filePath || "") : (delegateRoot.inLiveMode ? (model.folder || "") : (filePath || "")))
                                readonly property string currentFileName: delegateRoot.inWallhavenMode ? ("wallhaven-" + (model.id || "")) : (delegateRoot.inNaiveMode ? model.filename : (delegateRoot.inFavMode ? (model.fileName || "") : (delegateRoot.inLiveMode ? (model.title || "") : (fileName || ""))))
                                readonly property string previewPath: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || delegateRoot.inLiveMode) ? (model.preview || "") : ("file://" + currentFilePath)
                                
                                readonly property bool isSelected: delegateRoot.selector.selectedWallpaper !== null && (delegateRoot.inLiveMode ? delegateRoot.selector.selectedWallpaper.id === model.id : delegateRoot.selector.selectedWallpaper.filePath === currentFilePath)
                                
                                readonly property string wallhavenId: {
                                    if (delegateRoot.inWallhavenMode) return model.id || "";
                                    if (delegateRoot.inNaiveMode) return model.wallhaven_id || "";
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
                                    anchors.fill: parent; anchors.margins: 12 * Appearance.effectiveScale; spacing: 8 * Appearance.effectiveScale
                                    
                                    Item {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        Rectangle {
                                            id: imgPlate
                                            anchors.fill: parent; radius: 18 * Appearance.effectiveScale; color: delegateRoot.inNaiveMode ? (model.color || Appearance.colors.colLayer2) : Appearance.colors.colLayer2
                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: Rectangle { width: imgPlate.width; height: imgPlate.height; radius: 18 * Appearance.effectiveScale }
                                            }

                                            HoverHandler { id: imgHover }

                                            ThumbnailImage {
                                                anchors.fill: parent
                                                sourcePath: currentFilePath 
                                                visible: !delegateRoot.inWallhavenMode && !delegateRoot.inNaiveMode && currentFilePath !== ""
                                            }

                                            Image {
                                                anchors.fill: parent; source: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || delegateRoot.inLiveMode) ? previewPath : ""
                                                fillMode: Image.PreserveAspectCrop
                                                visible: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || delegateRoot.inLiveMode) && source != ""
                                                asynchronous: true; cache: true
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                border.width: 3 * Appearance.effectiveScale
                                                border.color: Appearance.colors.colPrimary
                                                radius: 18 * Appearance.effectiveScale
                                                color: "transparent"
                                                visible: delegateRoot.isSelected
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
                                                // Arrow cursor in online modes as requested
                                                cursorShape: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                onClicked: {
                                                    if (delegateRoot.inLiveMode) {
                                                        delegateRoot.selector.selectedWallpaper = {
                                                            "id": model.id,
                                                            "title": model.title,
                                                            "folder": model.folder,
                                                            "metadata": model.metadata,
                                                            "preview": model.preview
                                                        };
                                                    } else if (!delegateRoot.inWallhavenMode && !delegateRoot.inNaiveMode) {
                                                        if (currentFilePath !== "") {
                                                            delegateRoot.selector.selectWallpaper("file://" + currentFilePath)
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            RowLayout {
                                                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 4 * Appearance.effectiveScale; spacing: 2 * Appearance.effectiveScale

                                                RippleButton {
                                                    id: similarBtn
                                                    visible: delegateRoot.wallhavenId !== ""
                                                    implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale; colBackground: "transparent"
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "auto_awesome"; iconSize: 20 * Appearance.effectiveScale; color: "white"
                                                        fill: parent.hovered ? 1 : 0
                                                    }
                                                    onClicked: {
                                                        let s = delegateRoot.selector;
                                                        s.switchMode("wallhaven");
                                                        s.searchFilter = "wallhaven-" + delegateRoot.wallhavenId;
                                                        WallhavenService.search(delegateRoot.wallhavenId, true);
                                                    }
                                                    StyledToolTip { text: "Search similar on Wallhaven" }
                                                }

                                                RippleButton {
                                                    id: favBtn
                                                    visible: !delegateRoot.inWallhavenMode && !delegateRoot.inNaiveMode && currentFilePath !== ""
                                                    implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale; colBackground: "transparent"
                                                    readonly property bool isFav: currentFilePath !== "" && Wallpapers.isFavorite(currentFilePath)
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "favorite"; iconSize: 20 * Appearance.effectiveScale
                                                        fill: (favBtn.isFav || favBtn.hovered) ? 1 : 0
                                                        color: favBtn.isFav ? "#ff4081" : "#FFFFFF"
                                                        Behavior on color { ColorAnimation { duration: 200 } }
                                                    }
                                                    onClicked: Wallpapers.toggleFavorite(currentFilePath)
                                                    StyledToolTip { text: favBtn.isFav ? "Remove from favorites" : "Add to favorites" }
                                                }

                                                RippleButton {
                                                    id: downloadOnlyBtn
                                                    visible: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) && (model.full || "") !== ""
                                                    implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale; colBackground: "transparent"
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "download"; iconSize: 20 * Appearance.effectiveScale; color: "white"
                                                        fill: parent.hovered ? 1 : 0
                                                    }
                                                    onClicked: {
                                                        if (delegateRoot.inWallhavenMode) {
                                                            WallhavenService.download(model.full, model.id, model.file_type, false);
                                                        } else {
                                                            NaIveWallpaperService.download(model.full, model.filename, false);
                                                        }
                                                    }
                                                    StyledToolTip { text: "Download to folder" }
                                                }

                                                RippleButton {
                                                    id: downloadApplyBtn
                                                    visible: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) && (model.full || "") !== ""
                                                    implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale; colBackground: "transparent"
                                                    MaterialSymbol {
                                                        anchors.centerIn: parent; text: "wallpaper"; iconSize: 20 * Appearance.effectiveScale; color: "white"
                                                        fill: parent.hovered ? 1 : 0
                                                    }
                                                    onClicked: {
                                                        if (delegateRoot.inWallhavenMode) {
                                                            WallhavenService.download(model.full, model.id, model.file_type, true);
                                                        } else {
                                                            NaIveWallpaperService.download(model.full, model.filename, true);
                                                        }
                                                    }
                                                    StyledToolTip { text: "Download and Apply" }
                                                }
                                            }

                                            Rectangle {
                                                visible: delegateRoot.inWallhavenMode && (model.resolution || "") !== ""
                                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8 * Appearance.effectiveScale
                                                width: resText.implicitWidth + (12 * Appearance.effectiveScale); height: 20 * Appearance.effectiveScale; radius: 10 * Appearance.effectiveScale; color: Qt.rgba(0,0,0, 0.5)
                                                StyledText {
                                                    id: resText; anchors.centerIn: parent; text: model.resolution || ""
                                                    font.pixelSize: 10 * Appearance.effectiveScale; font.weight: Font.DemiBold; color: "white"
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
                                anchors.centerIn: parent; visible: grid.count === 0; spacing: 12 * Appearance.effectiveScale
                                MaterialSymbol {
                                    visible: (mainSelector.wallhavenMode && WallhavenService.loading) || (mainSelector.naiveMode && NaIveWallpaperService.loading) || (mainSelector.liveMode && WallpaperEngineService.loading)
                                    text: "progress_activity"; iconSize: 32 * Appearance.effectiveScale; color: Appearance.colors.colPrimary
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
                                        if (mainSelector.naiveMode) {
                                            if (NaIveWallpaperService.errorMessage !== "") return NaIveWallpaperService.errorMessage;
                                            if (NaIveWallpaperService.loading) return "Fetching Na-ive collection...";
                                            return "No wallpapers in collection";
                                        }
                                        if (mainSelector.liveMode) {
                                            if (WallpaperEngineService.errorMessage !== "") return WallpaperEngineService.errorMessage;
                                            if (WallpaperEngineService.loading) return "Scanning Steam Workshop...";
                                            return "No Wallpaper Engine wallpapers found";
                                        }
                                        return mainSelector.favMode ? "No favorite wallpapers" : "No wallpapers found";
                                    }
                                    color: (WallhavenService.errorMessage !== "" || NaIveWallpaperService.errorMessage !== "" || WallpaperEngineService.errorMessage !== "") ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }

                                    }

                                    // ── Vertical Divider ──
                                    Rectangle {
                                    Layout.fillHeight: true
                                    width: mainSelector.showDetails ? 1 : 0
                                    color: Appearance.colors.colOutlineVariant
                                    visible: mainSelector.showDetails
                                    }

                                    // ── Right Sidebar (Details & Settings) ──
                                    Item {
                                    id: detailsSidebar
                                    Layout.fillHeight: true
                                    Layout.preferredWidth: mainSelector.showDetails ? 320 * Appearance.effectiveScale : 0
                                    visible: mainSelector.showDetails
                                    clip: true

                                    Behavior on Layout.preferredWidth {
                                    NumberAnimation { duration: 250; easing.type: Easing.OutQuart }
                                    }

                                    ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16 * Appearance.effectiveScale
                                    spacing: 16 * Appearance.effectiveScale

                                    StyledText {
                                        text: mainSelector.selectedWallpaper ? mainSelector.selectedWallpaper.title : "Wallpaper Details"
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: Font.DemiBold
                                        color: Appearance.colors.colOnLayer1
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Preview & Info
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 180 * Appearance.effectiveScale
                                        radius: 12 * Appearance.effectiveScale
                                        color: Appearance.colors.colLayer2
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: mainSelector.selectedWallpaper ? mainSelector.selectedWallpaper.preview : ""
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            gradient: Gradient {
                                                GradientStop { position: 0.0; color: "transparent" }
                                                GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.5) }
                                            }
                                        }

                                        StyledText {
                                            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.margins: 12 * Appearance.effectiveScale
                                            text: mainSelector.selectedWallpaper ? mainSelector.selectedWallpaper.id : ""
                                            color: "white"
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            opacity: 0.8
                                        }
                                    }
                                    ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    ColumnLayout {
                                        width: parent.width
                                        spacing: 12 * Appearance.effectiveScale

                                        StyledText {
                                            text: "Properties"
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.Medium
                                            color: Appearance.colors.colSubtext
                                        }

                                        // This will be dynamic based on --list-properties
                                        StyledText {
                                            text: "No properties available yet."
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: Appearance.colors.colSubtext
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                    }

                                    RippleButton {
                                    Layout.fillWidth: true
                                    implicitHeight: 44 * Appearance.effectiveScale
                                    buttonText: "Apply Wallpaper"
                                    colBackground: Appearance.colors.colPrimary
                                    colText: Appearance.colors.colOnPrimary
                                    onClicked: {
                                        // TODO: Implement apply logic for Wallpaper Engine
                                    }
                                    }
                                    }
                                    }
                                    }
                                    }
                                    }
                                    }

        // --- Sorting Overlay & Popup (drawn last for z-index) ---
        MouseArea {
            id: sortOverlay
            anchors.fill: parent
            visible: sortPopup.visible
            z: 99
            onPressed: sortPopup.visible = false
        }

        Rectangle {
            id: sortPopup
            visible: false
            z: 100
            width: 180 * Appearance.effectiveScale
            height: sortCol.implicitHeight + (16 * Appearance.effectiveScale)
            
            // Map absolute position relative to the button
            x: {
                let p = sortBtn.mapToItem(bgContainer, 0, 0);
                return p.x + sortBtn.width - width;
            }
            y: {
                let p = sortBtn.mapToItem(bgContainer, 0, 0);
                return p.y + sortBtn.height + (8 * Appearance.effectiveScale);
            }

            color: Appearance.colors.colLayer1
            radius: 16 * Appearance.effectiveScale
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            
            ColumnLayout {
                id: sortCol
                anchors.fill: parent
                anchors.margins: 8 * Appearance.effectiveScale
                spacing: 4 * Appearance.effectiveScale
                
                Repeater {
                    model: [
                        { id: "name_asc",  name: "Name (A-Z)", icon: "sort_by_alpha" },
                        { id: "name_desc", name: "Name (Z-A)", icon: "sort_by_alpha" }
                    ]
                    delegate: RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 8 * Appearance.effectiveScale
                        toggled: mainSelector.sortMode === modelData.id
                        colBackground: "transparent"
                        colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                        
                        onClicked: {
                            mainSelector.sortMode = modelData.id;
                            sortPopup.visible = false;
                        }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12 * Appearance.effectiveScale; spacing: 12 * Appearance.effectiveScale
                            MaterialSymbol { 
                                text: modelData.icon; iconSize: 18 * Appearance.effectiveScale
                                color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                            }
                            StyledText { 
                                text: modelData.name; Layout.fillWidth: true; 
                                font.pixelSize: 12 * Appearance.effectiveScale
                                font.weight: parent.parent.toggled ? Font.DemiBold : Font.Normal
                                color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }
    }
}
