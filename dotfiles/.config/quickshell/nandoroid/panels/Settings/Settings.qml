import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

/**
 * Main Settings Application Window.
 * Central hub for system configuration.
 */
Scope {
    id: root
    
    property string pendingSearchQuery: ""
    property var searchResults: []
    property int currentResultIndex: 0
    property string lastQuery: ""

    function navigateToResult(index) {
        if (searchResults.length === 0) return;
        if (index < 0) index = searchResults.length - 1;
        if (index >= searchResults.length) index = 0;
        
        currentResultIndex = index;
        let result = searchResults[index];
        
        const targetPage = result.pageIndex;
        const query = result.matchedString || lastQuery;
        


        if (GlobalStates.settingsPageIndex === targetPage) {
            // Trigger search handler in the current page
            SearchRegistry.currentSearch = ""; // Reset first
            SearchRegistry.currentSearch = query;
        } else {
            root.pendingSearchQuery = query;
            GlobalStates.settingsPageIndex = targetPage;
        }
    }

    // Jumps requested from the launcher (< prefix): same navigation path as
    // the in-window search, so the target page highlights and scrolls into view.
    Connections {
        target: SearchRegistry
        function onPendingJumpChanged() {
            const jump = SearchRegistry.pendingJump;
            SearchRegistry.pendingJump = null;
            if (!jump || jump.pageIndex === undefined) return;
            if (GlobalStates.settingsPageIndex === jump.pageIndex) {
                SearchRegistry.currentSearch = "";
                SearchRegistry.currentSearch = jump.query;
            } else {
                root.pendingSearchQuery = jump.query;
                GlobalStates.settingsPageIndex = jump.pageIndex;
            }
        }
    }

    FloatingWindow {
        id: settingsWindow
        visible: GlobalStates.settingsOpen
        title: "Settings"
        
        readonly property var screen: Quickshell.screens[0]

        color: "transparent"

        // Since it's a real window, it defaults to a reasonable size:
        implicitWidth: Math.min(1100 * Appearance.effectiveScale, screen.width * 0.85)
        implicitHeight: Math.min(800 * Appearance.effectiveScale, screen.height * 0.8)

        onVisibleChanged: {
            if (!visible) {
                GlobalStates.settingsOpen = false;
            }
        }

        // Reset to first page whenever Settings closes
        Connections {
            target: GlobalStates
            function onSettingsOpenChanged() {
                if (!GlobalStates.settingsOpen) {
                    GlobalStates.settingsPageIndex = 0;
                    GlobalStates.settingsBluetoothPairMode = false;
                    SearchRegistry.currentSearch = ""; // Clear active search to allow re-triggering the same query next time
                    searchInput.text = ""; // Reset search text
                    searchInput.hasNoResults = false;
                }
            }
        }

        Component.onCompleted: {
            MaterialThemeLoader.reapplyTheme()
        }

        StyledRectangularShadow {
            target: contentContainer
            radius: contentContainer.radius
            color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.2)
        }

        // Main Panel Background
        Rectangle {
            id: contentContainer
            anchors.fill: parent

            focus: visible
            Keys.onEscapePressed: GlobalStates.settingsOpen = false

            color: Appearance.colors.colLayer0
            radius: Appearance.rounding.panel

            // Trap clicks inside
            TapHandler {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12 * Appearance.effectiveScale
                spacing: 12 * Appearance.effectiveScale

                // ── Header ──
                Item {
                    id: headerItem
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64 * Appearance.effectiveScale

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 48 * Appearance.effectiveScale
                            implicitHeight: 48 * Appearance.effectiveScale
                            buttonRadius: 24 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: GlobalStates.settingsPageIndex = 9

                            Image {
                                id: headerAvatar
                                anchors.fill: parent
                                source: {
                                    const profPath = Config.options.profile?.avatarPicture;
                                    if (profPath && profPath !== "") return "file://" + profPath;
                                    const cfgPath = Config.options.bar?.avatar_path;
                                    if (cfgPath && cfgPath !== "") return "file://" + cfgPath;
                                    if (SystemInfo.userAvatarValid) return "file://" + SystemInfo.userAvatarPath;
                                    return "";
                                }
                                sourceSize: Qt.size(width, height)
                                fillMode: Image.PreserveAspectCrop
                                visible: false
                            }

                            Rectangle {
                                id: headerAvatarMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                            }

                            OpacityMask {
                                anchors.fill: parent
                                source: headerAvatar
                                maskSource: headerAvatarMask
                                visible: headerAvatar.status === Image.Ready
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: headerAvatar.status !== Image.Ready
                                text: "person"
                                iconSize: 24 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                            StyledToolTip { text: I18nService.tr("Profile"); extraVisibleCondition: parent.hovered || parent.realHovered }
                        }

                        // Search pill
                        Rectangle {
                            id: searchPill
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56 * Appearance.effectiveScale
                            Layout.alignment: Qt.AlignVCenter
                            radius: height / 2
                            color: Appearance.colors.colLayer1 // Using colLayer1 for search as it sits on colLayer0
                            
                            readonly property bool isActive: searchInput.input.activeFocus || searchInput.text.length > 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: searchPill.isActive ? (4 * Appearance.effectiveScale) : (16 * Appearance.effectiveScale)
                                anchors.rightMargin: searchPill.isActive ? (4 * Appearance.effectiveScale) : (16 * Appearance.effectiveScale)
                                spacing: searchPill.isActive ? (4 * Appearance.effectiveScale) : (12 * Appearance.effectiveScale)

                                // Back Button (<)
                                RippleButton {
                                    visible: searchPill.isActive
                                    implicitWidth: 48 * Appearance.effectiveScale
                                    implicitHeight: 48 * Appearance.effectiveScale
                                    buttonRadius: 24 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: {
                                        searchInput.text = ""
                                        searchInput.focus = false
                                    }
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "chevron_left"
                                        iconSize: 24 * Appearance.effectiveScale
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }

                                StyledTextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    inputRadius: 0
                                    horizontalAlignment: searchPill.isActive ? TextInput.AlignLeft : TextInput.AlignHCenter
                                    backgroundColor: "transparent"
                                    borderInactiveWidth: 0
                                    showActiveBorder: false
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    placeholder: searchInput.hasNoResults ? I18nService.tr("No results found") : I18nService.tr("Search settings")
                                    placeholderColor: searchInput.hasNoResults ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                    leftMargin: 0
                                    rightMargin: 0
                                    
                                    property bool hasNoResults: false
                                    
                                    onTextChanged: hasNoResults = false
                                    
                                    onAccepted: {
                                        const query = text.trim();
                                        if (query === "") return;

                                        if (query.toLowerCase() === root.lastQuery.toLowerCase() && root.searchResults.length > 0) {
                                            root.navigateToResult(root.currentResultIndex + 1);
                                        } else {
                                            root.lastQuery = query;
                                            let results = SearchRegistry.getResultsRanked(query);
                                            
                                            if (results && results.length > 0) {
                                                root.searchResults = results;
                                                root.currentResultIndex = 0;
                                                root.navigateToResult(0);
                                                hasNoResults = false;
                                            } else {
                                                root.searchResults = [];
                                                root.currentResultIndex = 0;
                                                hasNoResults = true;
                                            }
                                        }
                                    }
                                }

                                // Search Indicator (X/Y)
                                StyledText {
                                    visible: root.searchResults.length > 0 && searchInput.text === root.lastQuery
                                    text: (root.currentResultIndex + 1) + "/" + root.searchResults.length
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colPrimary
                                }

                                // Clear Button (X)
                                RippleButton {
                                    visible: searchPill.isActive && searchInput.text.length > 0
                                    implicitWidth: 40 * Appearance.effectiveScale
                                    implicitHeight: 40 * Appearance.effectiveScale
                                    buttonRadius: 20 * Appearance.effectiveScale
                                    colBackground: "transparent"
                                    onClicked: {
                                        searchInput.text = ""
                                        searchInput.forceActiveFocus()
                                    }
                                    
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: "close"
                                        iconSize: 24 * Appearance.effectiveScale
                                        color: Appearance.colors.colOnLayer1
                                    }
                                }
                            }
                        }

                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 48 * Appearance.effectiveScale
                            implicitHeight: 48 * Appearance.effectiveScale
                            buttonRadius: 24 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: GlobalStates.settingsOpen = false
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "close"
                                iconSize: 24 * Appearance.effectiveScale
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }


                // ── Main Content Area ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    SettingsSidebar {
                        id: sidebar
                        Layout.fillHeight: true
                        Layout.rightMargin: 12 * Appearance.effectiveScale
                        currentIndex: GlobalStates.settingsPageIndex
                        onPageSelected: (index) => {
                            GlobalStates.settingsPageIndex = index
                        }
                    }

                    Item {
                        id: subSidebarWrapper
                        
                        readonly property bool shouldShow: subSidebar.hasSections && settingsWindow.width >= 850 * Appearance.effectiveScale

                        Layout.fillHeight: true
                        implicitWidth: shouldShow ? (1 + 12 + 192 + 12) * Appearance.effectiveScale : 0
                        clip: true

                        Rectangle {
                            id: divider
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: 16 * Appearance.effectiveScale
                            anchors.bottomMargin: 16 * Appearance.effectiveScale
                            width: 1 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3outlineVariant
                            opacity: subSidebarWrapper.shouldShow ? 1 : 0
                            
                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }
                        }

                        SettingsSubSidebar {
                            id: subSidebar
                            anchors.left: divider.right
                            anchors.leftMargin: 12 * Appearance.effectiveScale
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 192 * Appearance.effectiveScale
                            
                            // Let SubSidebar handle sections from SearchRegistry
                            pageIndex: GlobalStates.settingsPageIndex
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Appearance.colors.colLayer1
                        radius: 28 * Appearance.effectiveScale

                        Item {
                            anchors.fill: parent
                            clip: true

                            // Keep-alive page loaders (end4-pC style):
                            // Each page is loaded on first visit and stays alive afterwards,
                            // so switching pages never re-parses QML.
                            Repeater {
                                id: pagesRepeater
                                model: root.pages
                                delegate: Loader {
                                    id: pageLoader
                                    required property var modelData
                                    required property int index
                                    active: GlobalStates.settingsPageIndex === index || item !== null
                                    anchors.fill: parent
                                    anchors.bottomMargin: 24 * Appearance.effectiveScale
                                    anchors.leftMargin: 24 * Appearance.effectiveScale
                                    anchors.rightMargin: 0
                                    source: modelData.component

                                    readonly property bool isActive: GlobalStates.settingsPageIndex === index

                                    anchors.topMargin: (isActive ? 24 : 44) * Appearance.effectiveScale
                                    opacity: isActive ? 1 : 0
                                    enabled: isActive
                                    visible: opacity > 0

                                    Behavior on anchors.topMargin {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }

                                    onLoaded: {
                                        if (isActive && root.pendingSearchQuery !== "") {
                                            applyPendingSearch()
                                        }
                                    }

                                    onIsActiveChanged: {
                                        if (isActive && item && root.pendingSearchQuery !== "") {
                                            applyPendingSearch()
                                        }
                                    }

                                    function applyPendingSearch() {
                                        if (root.pendingSearchQuery !== "") {
                                            SearchRegistry.currentSearch = "";
                                            SearchRegistry.currentSearch = root.pendingSearchQuery;
                                            root.pendingSearchQuery = "";
                                        }
                                    }

                                    TextEdit {
                                        visible: pageLoader.status === Loader.Error
                                        anchors.centerIn: parent
                                        width: Math.min(800 * Appearance.effectiveScale, parent.width - (40 * Appearance.effectiveScale))
                                        wrapMode: TextEdit.Wrap
                                        readOnly: true
                                        selectByMouse: true
                                        text: I18nService.tr("Error loading page: ") + pageLoader.source + "\n\n" + (pageLoader.sourceComponent ? pageLoader.sourceComponent.errorString() : I18nService.tr("Unknown component error"))
                                        color: "#FF5555"
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        font.family: "monospace"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    readonly property var pages: [
        { name: "Network", component: "pages/Network/NetworkSettings.qml" },
        { name: "Bluetooth", component: "pages/Bluetooth/BluetoothSettings.qml" },
        { name: "Audio", component: "pages/Audio/AudioSettings.qml" },
        { name: "Display", component: "pages/Display/DisplaySettings.qml" },
        { name: "Customize", component: "pages/WallpaperStyle/WallpaperStyleSettings.qml" },
        { name: "Widgets", component: "pages/Widgets/WidgetsSettings.qml" },
        { name: "System", component: "pages/System/SystemSettings.qml" },
        { name: "Services", component: "pages/Services/ServicesSettings.qml" },
        { name: "About", component: "pages/About/AboutSettings.qml" },
        { name: "Profile", component: "pages/Profile/ProfileSettings.qml" }
    ]
}
