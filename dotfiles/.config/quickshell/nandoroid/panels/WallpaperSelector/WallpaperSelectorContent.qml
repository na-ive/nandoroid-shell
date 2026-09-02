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
    
    Item {
        id: focusStealer
        width: 0; height: 0
        visible: true
        focus: true
    }
    
    property bool cheatsheetOpen: false

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Slash) {
            mainSelector.cheatsheetOpen = !mainSelector.cheatsheetOpen;
            event.accepted = true;
        } else if (mainSelector.cheatsheetOpen && event.key === Qt.Key_Escape) {
            mainSelector.cheatsheetOpen = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            close();
            event.accepted = true;
        } else if (event.key === Qt.Key_X) {
            headerComponent.focusSearch();
            event.accepted = true;
        } else if (event.key === Qt.Key_C) {
            if (!headerComponent.isSearchFocused) {
                GlobalStates.wallpaperSelectorTarget = (GlobalStates.wallpaperSelectorTarget === "desktop") ? "lock" : "desktop";
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_D) {
            if (!headerComponent.isSearchFocused && Config.ready && GlobalStates.wallpaperSelectorTarget === "lock") {
                Config.options.lock.useSeparateWallpaper = !Config.options.lock.useSeparateWallpaper;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_V) {
            if (!headerComponent.isSearchFocused) {
                mainSelector.sortMode = (mainSelector.sortMode === "name_asc") ? "name_desc" : "name_asc";
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_F) {
            if (!headerComponent.isSearchFocused) {
                gridComponent.toggleFavoriteCurrent();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Z) {
            if (!headerComponent.isSearchFocused && mainSelector.onlineMode) {
                let nextIdx = (mainSelector.onlineProviderIndex === 0) ? 1 : 0;
                mainSelector.switchOnlineProvider(nextIdx);
            } else if (!headerComponent.isSearchFocused && mainSelector.liveMode) {
                let nextIdx = (mainSelector.liveBackendIndex === 0) ? 1 : 0;
                mainSelector.switchLiveBackend(nextIdx);
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_A) {
            if (!headerComponent.isSearchFocused) {
                gridComponent.downloadOnlyCurrent();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            if (!headerComponent.isSearchFocused) {
                gridComponent.searchSimilarCurrent();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            if (!headerComponent.isSearchFocused) {
                sidebarComponent.cycleTab(event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier));
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            if (!headerComponent.isSearchFocused) {
                gridComponent.focusGrid();
                // Let the grid handle the event if possible, though setting focus here might swallow the first press
            }
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            gridComponent.focusGrid();
        } else {
            mainSelector.cheatsheetOpen = false;
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (!GlobalStates.wallpaperSelectorOpen) mainSelector.cheatsheetOpen = false;
        }
    }
    
    // Explicit reference for child components to avoid ReferenceError
    readonly property Item selectorItem: mainSelector

    ListModel {
        id: globalCustomFoldersModel
    }

    ListModel {
        id: globalFavModel
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
        function onFavoritesChanged() { globalFavModel.refresh(); }
    }


    function refreshCustomFolders() {
        globalCustomFoldersModel.clear();
        const folders = Config.options.appearance.background.customFolders || [];
        for (let i = 0; i < folders.length; i++) {
            const path = folders[i];
            const name = path.split('/').pop() || path;
            globalCustomFoldersModel.append({ "name": name, "path": path });
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

    // NA-ive collection is fully local after fetch, so search = local filename filter
    ListModel {
        id: globalNaiveFilteredModel
        function refresh() {
            clear();
            const q = mainSelector.naiveSearch.trim().toLowerCase();
            for (let i = 0; i < NaIveWallpaperService.results.count; i++) {
                const item = NaIveWallpaperService.results.get(i);
                if (q === "" || (item.filename || "").toLowerCase().indexOf(q) !== -1)
                    append(item);
            }
        }
    }

    onNaiveSearchChanged: globalNaiveFilteredModel.refresh()

    Connections {
        target: NaIveWallpaperService
        function onFetchFinished() { globalNaiveFilteredModel.refresh(); }
    }

    // Responsive sizing
    width: Math.min(1380 * Appearance.effectiveScale, (parent ? parent.width : 1500) * 0.95)
    height: Math.min(840 * Appearance.effectiveScale, (parent ? parent.height : 900) * 0.85)
    
    implicitWidth: width
    implicitHeight: height
    
    focus: true

    signal closed()
    
    property bool favMode: false
    property bool onlineMode: false
    property int onlineProviderIndex: 0 // 0 = Wallhaven, 1 = NA-ive
    readonly property bool wallhavenMode: mainSelector.onlineMode && mainSelector.onlineProviderIndex === 0
    readonly property bool naiveMode: mainSelector.onlineMode && mainSelector.onlineProviderIndex === 1
    property bool liveMode: false

    // Live wallpaper backend tab: 0 = mpvpaper (Video), 1 = Wallpaper Engine
    property int liveBackendIndex: 0
    readonly property bool showBackendTabs: MpvpaperService.isInstalled && WallpaperEngineService.isInstalled
    readonly property bool inVideoMode: liveMode && liveBackendIndex === 0
    
    // Selection state for right sidebar
    property var selectedWallpaper: null
    property bool showDetails: (liveMode && liveBackendIndex === 1) || (!liveMode && selectedWallpaper !== null)
    property bool sidebarExpanded: true

    // Popup state management
    property alias targetPopupVisible: targetPopup.visible
    property alias sortPopupVisible: sortPopup.visible
    property alias weSettingsPopupVisible: weSettingsPopup.visible
    property alias mpvSettingsPopupVisible: mpvSettingsPopup.visible

    function toggleTargetPopup() { targetPopup.visible = !targetPopup.visible }
    function toggleSortPopup() { sortPopup.visible = !sortPopup.visible }
    function toggleWeSettingsPopup() { 
        weSettingsPopup.visible = !weSettingsPopup.visible;
        if (weSettingsPopup.visible) mpvSettingsPopup.visible = false;
    }
    function toggleMpvSettingsPopup() { 
        mpvSettingsPopup.visible = !mpvSettingsPopup.visible;
        if (mpvSettingsPopup.visible) weSettingsPopup.visible = false;
    }
    
    // Independent search states
    property string localSearch: ""
    property string wallhavenSearch: ""
    property string naiveSearch: ""
    property string liveSearch: ""
    
    // Sorting state
    property string sortMode: "name_asc" // name_asc, name_desc
    
    // Lockscreen sync state (single source of truth: Config.options.lock.useSeparateWallpaper)
    readonly property bool lockSyncEnabled: Config.ready ? (Config.options.lock ? !Config.options.lock.useSeparateWallpaper : false) : false
    readonly property bool lockSelectionDisabled: GlobalStates.wallpaperSelectorTarget === "lock" && mainSelector.lockSyncEnabled
    
    // Internal lock to prevent recursion during switching
    property bool _switchingMode: false

    function applySorting() {
        if (wallhavenMode || naiveMode) return;

        if (favMode) {
            globalFavModel.refresh();
            return;
        }

        // Local sorting via global Wallpapers service
        if (sortMode === "name_asc") {
            Wallpapers.sortField = FolderListModel.Name;
            Wallpapers.sortReversed = false;
            WallpaperEngineService.sortReversed = false;
            MpvpaperService.sortReversed = false;
        } else if (sortMode === "name_desc") {
            Wallpapers.sortField = FolderListModel.Name;
            Wallpapers.sortReversed = true;
            WallpaperEngineService.sortReversed = true;
            MpvpaperService.sortReversed = true;
        }
    }

    onSortModeChanged: applySorting()

    function switchMode(mode) {
        if (_switchingMode) return;
        _switchingMode = true;
        
        // Save current search state
        if (onlineMode) {
            if (onlineProviderIndex === 0) wallhavenSearch = searchFilter;
            else naiveSearch = searchFilter;
        } else if (liveMode) liveSearch = searchFilter;
        else localSearch = searchFilter;
        
        // Update modes
        onlineMode = (mode === "online");
        favMode = (mode === "fav");
        liveMode = (mode === "live");
        
        // Clear selection when switching modes
        selectedWallpaper = null;
        
        // Restore search state
        if (onlineMode) {
            if (onlineProviderIndex === 0) {
                searchFilter = wallhavenSearch;
                // If empty, fetch defaults
                if (searchFilter === "") WallhavenService.search("");
            } else {
                searchFilter = naiveSearch;
                NaIveWallpaperService.fetch();
                globalNaiveFilteredModel.refresh();
            }
        } else if (liveMode) {
            // Resolve to an available backend
            if (liveBackendIndex === 0 && !MpvpaperService.isInstalled) liveBackendIndex = 1;
            else if (liveBackendIndex === 1 && !WallpaperEngineService.isInstalled) liveBackendIndex = 0;
            searchFilter = liveSearch;
            if (liveBackendIndex === 0) {
                MpvpaperService.searchQuery = liveSearch;
                MpvpaperService.fetch();
            } else {
                WallpaperEngineService.searchQuery = liveSearch;
                WallpaperEngineService.fetch();
            }
        } else {
            searchFilter = localSearch;
            if (!favMode && !liveMode) {
                Wallpapers.searchQuery = localSearch;
            }
        }
        
        applySorting();
        _switchingMode = false;
    }

    function switchOnlineProvider(index) {
        if (onlineMode && index === onlineProviderIndex) return;
        _switchingMode = true;
        // Save current search state of the active provider
        if (onlineMode) {
            if (onlineProviderIndex === 0) wallhavenSearch = searchFilter;
            else naiveSearch = searchFilter;
        }
        onlineProviderIndex = index;
        onlineMode = true;
        selectedWallpaper = null;
        // Restore + fetch for the new provider
        if (onlineProviderIndex === 0) {
            searchFilter = wallhavenSearch;
            if (searchFilter === "") WallhavenService.search("");
        } else {
            searchFilter = naiveSearch;
            NaIveWallpaperService.fetch();
            globalNaiveFilteredModel.refresh();
        }
        applySorting();
        _switchingMode = false;
    }

    property alias searchFilter: headerComponent.searchFilterText
    
    onSearchFilterChanged: {
        if (_switchingMode) return;
        
        if (wallhavenMode) {
            if (searchFilter.startsWith("wallhaven-")) {
                const id = searchFilter.substring(10).trim();
                if (id !== "" && id.length > 3) WallhavenService.search(id, true);
            }
        } else if (naiveMode) {
            // ...
        } else if (liveMode) {
            if (liveBackendIndex === 0) MpvpaperService.searchQuery = searchFilter
            else WallpaperEngineService.searchQuery = searchFilter
        } else {
            Wallpapers.searchQuery = searchFilter
        }
    }

    onSelectedWallpaperChanged: {
        if (selectedWallpaper && mainSelector.liveMode && !mainSelector.inVideoMode) {
            WallpaperEngineService.fetchProperties(selectedWallpaper.folder, selectedWallpaper.id);
        }
    }

    function close() {
        Wallpapers.searchQuery = "";
        WallpaperEngineService.searchQuery = "";
        MpvpaperService.searchQuery = "";
        localSearch = "";
        wallhavenSearch = "";
        naiveSearch = "";
        liveSearch = "";
        WallhavenService.results.clear();
        NaIveWallpaperService.results.clear();
        globalNaiveFilteredModel.clear();
        mainSelector.closed()
    }
    function selectWallpaper(path) {
        // Lockscreen wallpaper selection is disabled while it is synced to the desktop wallpaper
        if (mainSelector.lockSelectionDisabled) return;

        // Stop live wallpaper backends if switching to static on desktop
        if (GlobalStates.wallpaperSelectorTarget === "desktop") {
            WallpaperEngineService.stop();
            MpvpaperService.stop();
            Wallpapers.select(path)
        } else {
            Wallpapers.selectForLockscreen(path)
        }
        mainSelector.close()
    }

    function switchLiveBackend(index) {
        if (index === liveBackendIndex) return;
        liveBackendIndex = index;
        selectedWallpaper = null;
        if (index === 0) {
            MpvpaperService.searchQuery = searchFilter;
            MpvpaperService.fetch();
        } else {
            WallpaperEngineService.searchQuery = searchFilter;
            WallpaperEngineService.fetch();
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorTargetChanged() {
            // Revert to local mode if target becomes lockscreen while in live mode
            if (GlobalStates.wallpaperSelectorTarget === "lock" && mainSelector.liveMode) {
                mainSelector.switchMode("local");
            }
        }
    }

    function normalizePath(p) {
        let s = p.toString();
        if (s.startsWith("file://")) s = s.substring(7);
        if (s.endsWith("/")) s = s.substring(0, s.length - 1);
        return s;
    }

    // ── Main UI Frame ──
    StyledRectangularShadow {
        target: bgContainer
        radius: bgContainer.radius
        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.2)
    }

    Rectangle {
        id: bgContainer
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: 32 * Appearance.effectiveScale
        clip: true

        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // ── Header ──
            WallSelHeader {
                id: headerComponent
                mainSelector: mainSelector
                onSearchArrowPressed: {
                    focusStealer.forceActiveFocus();
                    headerComponent.defocusSearch();
                    gridComponent.focusGrid();
                }
                Layout.fillWidth: true
                Layout.preferredHeight: 64 * Appearance.effectiveScale
            }

            // ── Main Body ──
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12 * Appearance.effectiveScale
                anchors.margins: 4 * Appearance.effectiveScale

                // Left Sidebar (Navigation)
                WallSelSidebar {
                    id: sidebarComponent
                    mainSelector: mainSelector
                    customFoldersModel: globalCustomFoldersModel
                }

                // Grid Island
                WallSelGridIsland {
                    id: gridComponent
                    mainSelector: mainSelector
                    naiveFilteredModel: globalNaiveFilteredModel
                    favModel: globalFavModel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                // Details Sidebar Island
                WallSelDetailsIsland {
                    mainSelector: mainSelector
                    Layout.fillHeight: true
                    Layout.preferredWidth: mainSelector.showDetails ? 320 * Appearance.effectiveScale : 0
                }
            }
        }

        // --- Target Selector Popup ---
        MouseArea {
            anchors.fill: parent
            visible: targetPopup.visible
            z: 99
            onPressed: targetPopup.visible = false
        }

        StyledRectangularShadow {
            target: targetPopup
            radius: targetPopup.radius
            visible: targetPopup.visible
            z: 99
        }

        Rectangle {
            id: targetPopup
            visible: false
            z: 100
            width: 180 * Appearance.effectiveScale
            height: targetCol.implicitHeight + (16 * Appearance.effectiveScale)
            
            x: {
                let _ = visible;
                let _w = bgContainer.width;
                let p = headerComponent.targetBtn.mapToItem(bgContainer, 0, 0);
                return p.x;
            }
            y: {
                let _ = visible;
                let _h = bgContainer.height;
                let p = headerComponent.targetBtn.mapToItem(bgContainer, 0, 0);
                return p.y + headerComponent.targetBtn.height + (8 * Appearance.effectiveScale);
            }

            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: 12 * Appearance.effectiveScale
            
            ColumnLayout {
                id: targetCol
                anchors.fill: parent
                anchors.margins: 8 * Appearance.effectiveScale
                spacing: 4 * Appearance.effectiveScale
                
                Repeater {
                    model: [
                        { id: "desktop", name: "Desktop", icon: "desktop_windows" },
                        { id: "lock", name: "Lockscreen", icon: "lock" }
                    ]
                    delegate: RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 36 * Appearance.effectiveScale
                        buttonRadius: 8 * Appearance.effectiveScale
                        toggled: GlobalStates.wallpaperSelectorTarget === modelData.id
                        colBackground: "transparent"
                        colBackgroundToggled: Appearance.m3colors.m3primaryContainer
                        
                        onClicked: {
                            GlobalStates.wallpaperSelectorTarget = modelData.id;
                            targetPopup.visible = false;
                        }
                        
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12 * Appearance.effectiveScale; spacing: 12 * Appearance.effectiveScale
                            MaterialSymbol { 
                                text: modelData.icon; iconSize: 18 * Appearance.effectiveScale
                                color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                            }
                            StyledText { 
                                text: modelData.name; Layout.fillWidth: true; 
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: parent.parent.toggled ? Font.DemiBold : Font.Normal
                                color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
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

        StyledRectangularShadow {
            target: sortPopup
            radius: sortPopup.radius
            visible: sortPopup.visible
            z: 99
        }

        Rectangle {
            id: sortPopup
            visible: false
            z: 100
            width: 180 * Appearance.effectiveScale
            height: sortCol.implicitHeight + (16 * Appearance.effectiveScale)
            
            // Map absolute position relative to the button
            x: {
                let _ = visible;
                let _w = bgContainer.width;
                let p = headerComponent.sortBtnItem.mapToItem(bgContainer, 0, 0);
                return p.x + headerComponent.sortBtnItem.width - width;
            }
            y: {
                let _ = visible;
                let _h = bgContainer.height;
                let p = headerComponent.sortBtnItem.mapToItem(bgContainer, 0, 0);
                return p.y + headerComponent.sortBtnItem.height + (8 * Appearance.effectiveScale);
            }

            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: 12 * Appearance.effectiveScale
            
            ColumnLayout {
                id: sortCol
                anchors.fill: parent
                anchors.margins: 8 * Appearance.effectiveScale
                spacing: 4 * Appearance.effectiveScale
                
                Repeater {
                    model: [
                        { id: "name_asc",  name: I18nService.tr("Name (A-Z)"), icon: "sort_by_alpha" },
                        { id: "name_desc", name: I18nService.tr("Name (Z-A)"), icon: "sort_by_alpha" }
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
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: parent.parent.toggled ? Font.DemiBold : Font.Normal
                                color: parent.parent.toggled ? Appearance.m3colors.m3onPrimaryContainer : Appearance.colors.colOnLayer0
                            }
                        }
                    }
                }
            }
        }

        // --- Global Wallpaper Engine Settings Popup ---
        MouseArea {
            id: weSettingsOverlay
            anchors.fill: parent
            visible: weSettingsPopup.visible
            z: 99
            onPressed: weSettingsPopup.visible = false
        }

        StyledRectangularShadow {
            target: weSettingsPopup
            radius: weSettingsPopup.radius
            visible: weSettingsPopup.visible
            z: 99
        }

        Rectangle {
            id: weSettingsPopup
            visible: false
            z: 100
            width: 280 * Appearance.effectiveScale
            height: weSettingsCol.implicitHeight + (24 * Appearance.effectiveScale)
            
            x: {
                let _ = visible;
                let _w = bgContainer.width;
                let p = headerComponent.weSettingsBtnItem.mapToItem(bgContainer, 0, 0);
                return Math.min(bgContainer.width - width - 12 * Appearance.effectiveScale, p.x + headerComponent.weSettingsBtnItem.width - width);
            }
            y: {
                let _ = visible;
                let _h = bgContainer.height;
                let p = headerComponent.weSettingsBtnItem.mapToItem(bgContainer, 0, 0);
                return p.y + headerComponent.weSettingsBtnItem.height + (8 * Appearance.effectiveScale);
            }

            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: 12 * Appearance.effectiveScale
            
            ColumnLayout {
                id: weSettingsCol
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale
                
                StyledText {
                    text: I18nService.tr("Global Engine Settings")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                // FPS Slider
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Target FPS"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        StyledText { text: Math.round(fpsSlider.value); font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colPrimary; font.weight: Font.Bold }
                    }
                    StyledSlider {
                        id: fpsSlider
                        Layout.fillWidth: true
                        from: 10; to: 144
                        value: Config.ready ? Config.options.wallpaperEngine.fps : 30
                        onMoved: if (Config.ready) Config.options.wallpaperEngine.fps = Math.round(value)
                    }
                }

                // Volume Slider
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Global Volume"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        StyledText { text: Math.round(volSlider.value) + "%"; font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colPrimary; font.weight: Font.Bold }
                    }
                    StyledSlider {
                        id: volSlider
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: Config.ready ? Config.options.wallpaperEngine.volume : 15
                        onMoved: if (Config.ready) Config.options.wallpaperEngine.volume = Math.round(value)
                    }
                }

                // Scaling Mode
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Scaling Mode"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                    StyledComboBox {
                        id: scalingCombo
                        Layout.fillWidth: true
                        searchable: false
                        text: Config.ready ? Config.options.wallpaperEngine.scaling.charAt(0).toUpperCase() + Config.options.wallpaperEngine.scaling.slice(1) : "Fill"
                        model: ["Fill", "Stretch", "Fit", "Cover"]
                        onAccepted: (val) => {
                            if (Config.ready) Config.options.wallpaperEngine.scaling = val.toLowerCase();
                        }
                    }
                }

                // Toggles
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                    
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Mute Audio"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.silent : false
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.silent = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Disable Audio Processing"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.disableAudioProcessing : false
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.disableAudioProcessing = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Auto-Pause (Windows)"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.autoPause : true
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.autoPause = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Disable Particles"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.disableParticles : true
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.disableParticles = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Disable Parallax"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.disableParallax : false
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.disableParallax = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Disable Mouse Interaction"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.disableMouse : false
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.disableMouse = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Disable PBO (Texture Fix)"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.wallpaperEngine.noPbo : true
                            onToggled: if (Config.ready) Config.options.wallpaperEngine.noPbo = !checked
                        }
                    }
                }
                
                Item { Layout.preferredHeight: 4 * Appearance.effectiveScale }
                
                StyledText {
                    text: I18nService.tr("* Requires Apply to take full effect")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                }
            }
        }
        MouseArea {
            id: mpvSettingsOverlay
            anchors.fill: parent
            visible: mpvSettingsPopup.visible
            z: 99
            onPressed: mpvSettingsPopup.visible = false
        }


        StyledRectangularShadow {
            target: mpvSettingsPopup
            radius: mpvSettingsPopup.radius
            visible: mpvSettingsPopup.visible
            z: 99
        }

        Rectangle {
            id: mpvSettingsPopup
            visible: false
            z: 100
            width: 280 * Appearance.effectiveScale
            height: mpvSettingsCol.implicitHeight + (24 * Appearance.effectiveScale)
            
            x: {
                let _ = visible;
                let _w = bgContainer.width;
                let p = headerComponent.weSettingsBtnItem.mapToItem(bgContainer, 0, 0);
                return Math.min(bgContainer.width - width - 12 * Appearance.effectiveScale, p.x + headerComponent.weSettingsBtnItem.width - width);
            }
            y: {
                let _ = visible;
                let _h = bgContainer.height;
                let p = headerComponent.weSettingsBtnItem.mapToItem(bgContainer, 0, 0);
                return p.y + headerComponent.weSettingsBtnItem.height + (8 * Appearance.effectiveScale);
            }

            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: 12 * Appearance.effectiveScale
            
            ColumnLayout {
                id: mpvSettingsCol
                anchors.fill: parent
                anchors.margins: 16 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale
                
                StyledText {
                    text: I18nService.tr("Video Wallpaper Settings")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }

                // Volume Slider
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Global Volume"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        StyledText { text: Math.round((Config.ready ? Config.options.mpvpaper.volume : 15)) + "%"; font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colPrimary; font.weight: Font.Bold }
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: Config.ready ? Config.options.mpvpaper.volume : 15
                        onMoved: if (Config.ready) Config.options.mpvpaper.volume = Math.round(value)
                    }
                }

                // Playback Speed Slider
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Playback Speed"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        StyledText { text: (Config.ready ? Config.options.mpvpaper.speed : 1.0).toFixed(1) + "x"; font.pixelSize: 12 * Appearance.effectiveScale; color: Appearance.colors.colPrimary; font.weight: Font.Bold }
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        from: 0.5; to: 2.0
                        stepSize: 0.1
                        value: Config.ready ? Config.options.mpvpaper.speed : 1.0
                        onMoved: if (Config.ready) Config.options.mpvpaper.speed = value
                    }
                }

                // Scaling Mode
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 4 * Appearance.effectiveScale
                    StyledText { text: I18nService.tr("Scaling Mode"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1 }
                    StyledComboBox {
                        id: mpvScalingCombo
                        Layout.fillWidth: true
                        searchable: false
                        text: Config.ready ? (Config.options.mpvpaper.scaling === "fill" ? "Fill" : "Fit") : "Fill"
                        model: ["Fill", "Fit"]
                        onAccepted: (val) => {
                            if (Config.ready) Config.options.mpvpaper.scaling = val.toLowerCase();
                        }
                    }
                }

                // Toggles
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8 * Appearance.effectiveScale
                    
                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Mute Audio"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.mpvpaper.mute : false
                            onToggled: if (Config.ready) Config.options.mpvpaper.mute = !checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText { text: I18nService.tr("Auto-Pause (Windows)"); font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer1; Layout.fillWidth: true }
                        AndroidToggle {
                            checked: Config.ready ? Config.options.mpvpaper.autoPause : true
                            onToggled: if (Config.ready) Config.options.mpvpaper.autoPause = !checked
                        }
                    }
                }
                
                Item { Layout.preferredHeight: 4 * Appearance.effectiveScale }
                
                StyledText {
                    text: I18nService.tr("* Requires Apply to take full effect")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    horizontalAlignment: Text.AlignRight; Layout.fillWidth: true
                }
            }
        }
    }

    DialogCheatsheet {
        visible: mainSelector.cheatsheetOpen
        onClosed: mainSelector.cheatsheetOpen = false
        shortcuts: [
            { key: "Enter", action: "Apply / Download & Apply" },
            { key: "Tab / Shift+Tab", action: "Cycle Sidebar Tabs" },
            { key: "↑ ↓ ← →", action: "Navigate Grid" },
            { key: "X", action: "Focus Search" },
            { key: "C", action: "Toggle Target (Desktop/Lockscreen)" },
            { key: "D", action: "Toggle Separate Lockscreen Wallpaper" },
            { key: "V", action: "Toggle Sort Mode" },
            { key: "F", action: "Toggle Favorite" },
            { key: "Z", action: "Switch Online/Live Provider" },
            { key: "A", action: "Download Only" },
            { key: "S", action: "Search Similar (Online)" }
        ]
    }
}
