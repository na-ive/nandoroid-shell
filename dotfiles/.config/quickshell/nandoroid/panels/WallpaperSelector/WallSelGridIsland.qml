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

                Rectangle {
                    function focusGrid() {
                        grid.forceActiveFocus();
                    }
                    
                    function toggleFavoriteCurrent() {
                        if (grid.currentItem && grid.currentItem.currentFilePath) {
                            Wallpapers.toggleFavorite(grid.currentItem.currentFilePath);
                        }
                    }
                    
                    function downloadOnlyCurrent() {
                        if (grid.currentItem && grid.currentItem.downloadOnly) {
                            grid.currentItem.downloadOnly();
                        }
                    }

                    function searchSimilarCurrent() {
                        if (grid.currentItem && grid.currentItem.searchSimilar) {
                            grid.currentItem.searchSimilar();
                        }
                    }

                    property Item mainSelector
                    property ListModel naiveFilteredModel
                    property ListModel favModel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Appearance.colors.colLayer1
                    radius: 28 * Appearance.effectiveScale
                    clip: true
                    opacity: 0.98

                    // Live backend switcher (only when BOTH backends are installed)
                    StyledTabBar {
                        id: backendTabs
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        visible: mainSelector.liveMode && mainSelector.showBackendTabs
                        showIcon: true
                        iconOnTop: true
                        currentTab: mainSelector.liveBackendIndex
                        onTabClicked: (index) => mainSelector.switchLiveBackend(index)
                        tabModel: [
                            { name: I18nService.tr("Video"), icon: "movie" },
                            { name: I18nService.tr("Wallpaper Engine"), icon: "desktop_windows" }
                        ]
                    }

                    // Online provider switcher (Wallhaven / NA-ive)
                    StyledTabBar {
                        id: onlineTabs
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        visible: mainSelector.onlineMode
                        showIcon: true
                        iconOnTop: true
                        currentTab: mainSelector.onlineProviderIndex
                        onTabClicked: (index) => mainSelector.switchOnlineProvider(index)
                        tabModel: [
                            { name: I18nService.tr("Wallhaven"), icon: "travel_explore" },
                            { name: I18nService.tr("NA-ive Walls"), icon: "collections" }
                        ]
                    }

                    // Lockscreen sync setting row (contextual — shown only for the Lockscreen target)
                    Rectangle {
                        id: lockscreenSyncRow
                        visible: GlobalStates.wallpaperSelectorTarget === "lock"
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: backendTabs.visible ? backendTabs.bottom : (onlineTabs.visible ? onlineTabs.bottom : parent.top)
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        anchors.topMargin: 12 * Appearance.effectiveScale
                        height: lockscreenSyncBody.implicitHeight + (24 * Appearance.effectiveScale)
                        radius: 18 * Appearance.effectiveScale
                        color: Appearance.m3colors.m3surfaceContainerHigh

                        RowLayout {
                            id: lockscreenSyncBody
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 16 * Appearance.effectiveScale
                            anchors.rightMargin: 12 * Appearance.effectiveScale
                            spacing: 16 * Appearance.effectiveScale

                            MaterialSymbol {
                                text: "link"
                                iconSize: 22 * Appearance.effectiveScale
                                color: Appearance.colors.colPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2 * Appearance.effectiveScale

                                StyledText {
                                    text: I18nService.tr("Use desktop wallpaper")
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer1
                                    Layout.fillWidth: true
                                }

                                StyledText {
                                    text: mainSelector.lockSyncEnabled
                                        ? I18nService.tr("The current desktop wallpaper will be used for the lockscreen")
                                        : I18nService.tr("Choose a different wallpaper for the lockscreen")
                                    font.pixelSize: Appearance.font.pixelSize.smallest
                                    color: Appearance.colors.colSubtext
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            AndroidToggle {
                                id: lockscreenSyncToggle
                                Layout.alignment: Qt.AlignVCenter
                                checked: Config.ready && (Config.options.lock ? !Config.options.lock.useSeparateWallpaper : false)
                                onToggled: {
                                    if (Config.ready && Config.options.lock) {
                                        const current = Config.options.lock.useSeparateWallpaper
                                        Config.options.lock.useSeparateWallpaper = !current
                                        if (current) { // Was true (separate), now false (synced)
                                            // Sync to the desktop wallpaper (live backends use their captured frame)
                                            let targetPath = Config.options.appearance.background.wallpaperPath;
                                            if (WallpaperEngineService.active) {
                                                targetPath = "file://" + WallpaperEngineService.screenshotPath;
                                            } else if (MpvpaperService.active) {
                                                targetPath = "file://" + MpvpaperService.framePath;
                                            }
                                            Wallpapers.selectForLockscreen(targetPath, false)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    GridView {
                        id: grid
                        focus: true
                        keyNavigationEnabled: true
                        keyNavigationWraps: false
                        Keys.onReturnPressed: (event) => { if (currentItem && currentItem.activate) { currentItem.activate(); event.accepted = true; } }
                        Keys.onEnterPressed: (event) => { if (currentItem && currentItem.activate) { currentItem.activate(); event.accepted = true; } }
                        Keys.onSpacePressed: (event) => { if (currentItem && currentItem.activate) { currentItem.activate(); event.accepted = true; } }
                        
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.top: lockscreenSyncRow.visible ? lockscreenSyncRow.bottom : (backendTabs.visible ? backendTabs.bottom : (onlineTabs.visible ? onlineTabs.bottom : parent.top))
                        anchors.topMargin: lockscreenSyncRow.visible ? 8 * Appearance.effectiveScale : (backendTabs.visible ? 8 * Appearance.effectiveScale : (onlineTabs.visible ? 8 * Appearance.effectiveScale : 8 * Appearance.effectiveScale))
                        anchors.leftMargin: 8 * Appearance.effectiveScale
                        anchors.rightMargin: 8 * Appearance.effectiveScale
                        anchors.bottomMargin: 8 * Appearance.effectiveScale
                        opacity: mainSelector.lockSelectionDisabled ? 0.6 : 1
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        cellWidth: width / (mainSelector.showDetails ? 3 : 4)
                        property bool hideText: mainSelector.wallhavenMode || mainSelector.naiveMode
                        cellHeight: cellWidth * 3/4 + (hideText ? (24 * Appearance.effectiveScale) : (40 * Appearance.effectiveScale))
                        clip: true; interactive: true
                        
                        // Memory optimization: Load only what's necessary (about 1.5 extra screen heights)
                        cacheBuffer: Math.max(0, height * 1.5)
                        
                        model: {
                            if (mainSelector.wallhavenMode) return WallhavenService.results;
                            if (mainSelector.naiveMode) return naiveFilteredModel;
                            if (mainSelector.favMode) return favModel;
                            if (mainSelector.liveMode) return mainSelector.liveBackendIndex === 0 ? MpvpaperService.results : WallpaperEngineService.results;
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
                                MaterialLoadingIndicator {
                                    id: loadMoreIcon
                                    loading: parent.visible
                                }
                                StyledText { text: I18nService.tr("Loading more..."); color: Appearance.colors.colSubtext }
                            }
                        }

                        
                        onVisibleChanged: { if (visible) favModel.refresh(); }
                        
                        delegate: Item {
                            id: delegateRoot
                            width: grid.cellWidth; height: grid.cellHeight
                            
                            function activate() {
                                if (delegateRoot.inLiveMode) {
                                    if (delegateRoot.selector.liveBackendIndex === 1) {
                                        // Wallpaper Engine needs the details sidebar
                                        delegateRoot.selector.selectedWallpaper = {
                                            "id": model.id,
                                            "title": model.title,
                                            "folder": model.folder,
                                            "metadata": model.metadata,
                                            "preview": model.preview
                                        };
                                    } else {
                                        // mpvpaper applies immediately
                                        MpvpaperService.apply(model.folder);
                                        WallpaperEngineService.stop();
                                        delegateRoot.selector.close();
                                    }
                                } else if (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) {
                                    if ((model.full || "") !== "" && !delegateRoot.gridLocked) {
                                        if (delegateRoot.inWallhavenMode) {
                                            WallhavenService.download(model.full, model.id, model.file_type, true);
                                        } else {
                                            NaIveWallpaperService.download(model.full, model.filename, true);
                                        }
                                    }
                                } else if (currentFilePath !== "") {
                                    if (!delegateRoot.gridLocked)
                                        delegateRoot.selector.selectWallpaper("file://" + currentFilePath)
                                }
                            }
                            
                            function downloadOnly() {
                                if ((delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) && (model.full || "") !== "") {
                                    if (delegateRoot.inWallhavenMode) {
                                        WallhavenService.download(model.full, model.id, model.file_type, false);
                                    } else {
                                        NaIveWallpaperService.download(model.full, model.filename, false);
                                    }
                                }
                            }
                            
                            function searchSimilar() {
                                if (delegateRoot.wallhavenId !== "") {
                                    let s = delegateRoot.selector;
                                    s.switchMode("online");
                                    s.switchOnlineProvider(0);
                                    s.searchFilter = "wallhaven-" + delegateRoot.wallhavenId;
                                    WallhavenService.search(delegateRoot.wallhavenId, true);
                                }
                            }
                            
                            // EXPLICIT PROXY PROPERTIES TO FIX REFERENCE ERRORS
                            readonly property Item selector: mainSelector.selectorItem
                            readonly property bool inWallhavenMode: delegateRoot.selector.wallhavenMode
                            readonly property bool inNaiveMode: delegateRoot.selector.naiveMode
                            readonly property bool inFavMode: delegateRoot.selector.favMode
                            readonly property bool inLiveMode: delegateRoot.selector.liveMode
                            readonly property bool inVideoMode: delegateRoot.selector.inVideoMode
                            readonly property bool gridLocked: delegateRoot.selector.lockSelectionDisabled
                            
                            readonly property string currentFilePath: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) ? (model.full || "") : (delegateRoot.inFavMode ? (model.filePath || "") : (delegateRoot.inLiveMode ? (model.folder || "") : (filePath || "")))
                            readonly property string currentFileName: delegateRoot.inWallhavenMode ? ("wallhaven-" + (model.id || "")) : (delegateRoot.inNaiveMode ? model.filename : (delegateRoot.inFavMode ? (model.fileName || "") : (delegateRoot.inLiveMode ? (model.title || "") : (fileName || ""))))
                            readonly property string previewPath: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || delegateRoot.inLiveMode) ? (model.preview || "") : ("file://" + currentFilePath)
                            
                            readonly property bool isSelected: delegateRoot.selector.selectedWallpaper !== null && (delegateRoot.inLiveMode ? delegateRoot.selector.selectedWallpaper.id === model.id : delegateRoot.selector.selectedWallpaper.filePath === currentFilePath)
                            readonly property bool isCurrentWallpaper: {
                                if (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) return false;
                                if (delegateRoot.inLiveMode) {
                                    let livePath = Config.ready ? Config.options.appearance.background.liveWallpaperPath : "";
                                    return GlobalStates.wallpaperSelectorTarget === "desktop" && livePath !== "" && mainSelector.normalizePath(livePath) === mainSelector.normalizePath(model.folder);
                                }
                                if (!Config.ready || currentFilePath === "") return false;
                                // A live wallpaper is currently applied on desktop: no static
                                // wallpaper should be highlighted as "current"
                                if (GlobalStates.wallpaperSelectorTarget === "desktop"
                                    && (MpvpaperService.active || WallpaperEngineService.active)) return false;
                                if (GlobalStates.wallpaperSelectorTarget === "lock") {
                                    if (!Config.options.lock.useSeparateWallpaper) return false;
                                    return mainSelector.normalizePath(Config.options.lock.wallpaperPath) === mainSelector.normalizePath("file://" + currentFilePath);
                                }
                                return mainSelector.normalizePath(Config.options.appearance.background.wallpaperPath) === mainSelector.normalizePath("file://" + currentFilePath);
                            }
                            
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
                                anchors.fill: parent; anchors.margins: 8 * Appearance.effectiveScale; spacing: 8 * Appearance.effectiveScale
                                
                                Item {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                        Rectangle {
                                            id: imgPlate
                                            anchors.fill: parent; radius: Appearance.rounding.large; color: delegateRoot.inNaiveMode ? (model.color || Appearance.colors.colLayer2) : Appearance.colors.colLayer2
                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: Rectangle { width: imgPlate.width; height: imgPlate.height; radius: Appearance.rounding.large }
                                            }

                                        HoverHandler { id: imgHover }

                                        ThumbnailImage {
                                            anchors.fill: parent
                                            sourcePath: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || delegateRoot.inLiveMode) ? "" : currentFilePath
                                            visible: sourcePath !== ""
                                        }

                                        VideoThumbnail {
                                            anchors.fill: parent
                                            videoPath: delegateRoot.inVideoMode ? currentFilePath : ""
                                            visible: delegateRoot.inVideoMode && videoPath !== ""
                                        }

                                        AnimatedImage {
                                            anchors.fill: parent; source: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || (delegateRoot.inLiveMode && !delegateRoot.inVideoMode)) ? previewPath : ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || (delegateRoot.inLiveMode && !delegateRoot.inVideoMode)) && source != ""
                                            asynchronous: true; cache: true; playing: true
                                        }

                                        // Highlight border: selected (live preview) or currently applied wallpaper
                                        Rectangle {
                                            anchors.fill: parent
                                            border.width: 3 * Appearance.effectiveScale
                                            border.color: Appearance.colors.colPrimary
                                            radius: Appearance.rounding.large
                                            color: "transparent"
                                            antialiasing: true
                                            visible: delegateRoot.isSelected || delegateRoot.isCurrentWallpaper
                                        }
                                        // Active wallpaper checkmark badge
                                        Rectangle {
                                            visible: delegateRoot.isCurrentWallpaper && !delegateRoot.isSelected
                                            anchors.top: parent.top; anchors.left: parent.left
                                            anchors.margins: 8 * Appearance.effectiveScale
                                            width: 28 * Appearance.effectiveScale; height: 28 * Appearance.effectiveScale
                                            radius: 14 * Appearance.effectiveScale
                                            color: Appearance.colors.colPrimary

                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: "check"
                                                iconSize: 18 * Appearance.effectiveScale
                                                color: Appearance.colors.colOnPrimary
                                                fill: 1
                                            }

                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                            opacity: visible ? 1 : 0
                                        }
                                        
                                        // Keyboard focus highlight matching Quick Settings
                                        Rectangle {
                                            anchors.fill: parent
                                            border.width: Math.max(1, 2 * Appearance.effectiveScale)
                                            border.color: Appearance.colors.colPrimary
                                            radius: Appearance.rounding.large
                                            color: "transparent"
                                            visible: delegateRoot.GridView.isCurrentItem && grid.activeFocus
                                            z: 999
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
                                            anchors.fill: parent; color: Appearance.colors.colPrimary; opacity: (mArea.containsMouse || imgHover.hovered) && !delegateRoot.gridLocked ? 0.15 : 0
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }
                                        
                                        MouseArea {
                                            id: mArea; anchors.fill: parent; hoverEnabled: true
                                            // Arrow cursor in online modes as requested
                                            cursorShape: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode || delegateRoot.gridLocked) ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            onClicked: delegateRoot.activate()
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
                                                onClicked: delegateRoot.searchSimilar()
                                                StyledToolTip { text: I18nService.tr("Search similar on Wallhaven") }
                                            }

                                            RippleButton {
                                                id: favBtn
                                                visible: !delegateRoot.inWallhavenMode && !delegateRoot.inNaiveMode && !delegateRoot.inLiveMode && currentFilePath !== ""
                                                implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale; colBackground: "transparent"
                                                readonly property bool isFav: currentFilePath !== "" && Wallpapers.isFavorite(currentFilePath)
                                                MaterialSymbol {
                                                    anchors.centerIn: parent; text: "favorite"; iconSize: 20 * Appearance.effectiveScale
                                                    fill: (favBtn.isFav || favBtn.hovered) ? 1 : 0
                                                    color: favBtn.isFav ? "#ff4081" : "#FFFFFF"
                                                    Behavior on color { ColorAnimation { duration: 200 } }
                                                }
                                                onClicked: Wallpapers.toggleFavorite(currentFilePath)
                                                StyledToolTip { text: favBtn.isFav ? I18nService.tr("Remove from favorites") : I18nService.tr("Add to favorites") }
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
                                                StyledToolTip { text: I18nService.tr("Download to folder") }
                                            }

                                            RippleButton {
                                                id: downloadApplyBtn
                                                visible: (delegateRoot.inWallhavenMode || delegateRoot.inNaiveMode) && (model.full || "") !== ""
                                                enabled: !delegateRoot.gridLocked
                                                implicitWidth: 36 * Appearance.effectiveScale; implicitHeight: 36 * Appearance.effectiveScale; buttonRadius: 18 * Appearance.effectiveScale; colBackground: "transparent"
                                                MaterialSymbol {
                                                    anchors.centerIn: parent; text: "wallpaper"; iconSize: 20 * Appearance.effectiveScale; color: "white"
                                                    fill: (parent.enabled && parent.hovered) ? 1 : 0
                                                }
                                                onClicked: {
                                                    if (delegateRoot.gridLocked) return;
                                                    if (delegateRoot.inWallhavenMode) {
                                                        WallhavenService.download(model.full, model.id, model.file_type, true);
                                                    } else {
                                                        NaIveWallpaperService.download(model.full, model.filename, true);
                                                    }
                                                }
                                                StyledToolTip { text: I18nService.tr("Download and Apply") }
                                            }
                                        }

                                        Rectangle {
                                            visible: delegateRoot.inWallhavenMode && (model.resolution || "") !== ""
                                            anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 8 * Appearance.effectiveScale
                                            width: resText.implicitWidth + (12 * Appearance.effectiveScale); height: 20 * Appearance.effectiveScale; radius: 10 * Appearance.effectiveScale; color: Qt.rgba(0,0,0, 0.5)
                                            StyledText {
                                                id: resText; anchors.centerIn: parent; text: model.resolution || ""
                                                font.pixelSize: Appearance.font.pixelSize.smallest; font.weight: Font.DemiBold; color: "white"
                                            }
                                        }
                                    }
                                }
                                StyledText {
                                    visible: !delegateRoot.inWallhavenMode && !delegateRoot.inNaiveMode
                                    Layout.fillWidth: true; text: currentFileName; horizontalAlignment: Text.AlignHCenter
                                    font.pixelSize: Appearance.font.pixelSize.smaller; elide: Text.ElideRight; color: delegateRoot.isCurrentWallpaper ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer0; opacity: 1
                                }
                            }
                        }
                        
                        ScrollBar.vertical: StyledScrollBar {}

                        ColumnLayout {
                            anchors.centerIn: parent; visible: grid.count === 0; spacing: 12 * Appearance.effectiveScale
                            MaterialLoadingIndicator {
                                id: mainLoadIcon
                                visible: (mainSelector.wallhavenMode && WallhavenService.loading) || (mainSelector.naiveMode && NaIveWallpaperService.loading) || (mainSelector.inVideoMode && MpvpaperService.loading) || (mainSelector.liveMode && !mainSelector.inVideoMode && WallpaperEngineService.loading)
                                implicitSize: 60 * Appearance.effectiveScale
                                loading: parent.visible
                                Layout.alignment: Qt.AlignHCenter
                            }
                            StyledText {
                                text: {
                                    if (mainSelector.wallhavenMode) {
                                        if (WallhavenService.errorMessage !== "") return WallhavenService.errorMessage;
                                        if (WallhavenService.loading) return I18nService.tr("Searching Wallhaven...");
                                        return I18nService.tr("No online wallpapers found");
                                    }
                                    if (mainSelector.naiveMode) {
                                        if (NaIveWallpaperService.errorMessage !== "") return NaIveWallpaperService.errorMessage;
                                        if (NaIveWallpaperService.loading) return I18nService.tr("Fetching Na-ive collection...");
                                        return I18nService.tr("No wallpapers in collection");
                                    }
                                    if (mainSelector.liveMode) {
                                        if (mainSelector.inVideoMode) {
                                            if (MpvpaperService.errorMessage !== "") return MpvpaperService.errorMessage;
                                            if (MpvpaperService.loading) return I18nService.tr("Scanning for videos...");
                                            return I18nService.tr("No videos found");
                                        }
                                        if (!WallpaperEngineService.isInstalled) return I18nService.tr("linux-wallpaperengine-git is required for this feature");
                                        if (WallpaperEngineService.errorMessage !== "") return WallpaperEngineService.errorMessage;
                                        if (WallpaperEngineService.loading) return I18nService.tr("Scanning Steam Workshop...");
                                        return I18nService.tr("No Wallpaper Engine wallpapers found");
                                    }
                                    return mainSelector.favMode ? I18nService.tr("No favorite wallpapers") : I18nService.tr("No wallpapers found");
                                }
                                color: (WallhavenService.errorMessage !== "" || NaIveWallpaperService.errorMessage !== "" || WallpaperEngineService.errorMessage !== "" || MpvpaperService.errorMessage !== "") ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
