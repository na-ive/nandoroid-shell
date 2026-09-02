import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    // Explicitly set as spotlight
    readonly property bool isSpotlight: true
    readonly property var resultsProxy: LauncherSearch.results
    property int selectedIndex: 0
    property int gridColumns: 1
    property bool isKeyboardNavigation: false
    property bool jumpPending: false
    property string jumpSectionLabel: ""
    readonly property bool hasQuery: LauncherSearch.query !== ""
    property bool cheatsheetOpen: false
    property alias emojiColumns: emojiContent.emojiColumns
    property alias emojiView: emojiContent.emojiView

    function emojiNavigate(dx, dy) {
        return emojiContent.emojiNavigate(dx, dy);
    }
    function wallNavigate(dx, dy) {
        return wallContent.wallNavigate(dx, dy);
    }
    readonly property int wallColumns: 2

    function executeSelected() {
        if (LauncherSearch.isWallMode) {
            if (root.resultsProxy && root.resultsProxy.length > 0 && selectedIndex >= 0 && selectedIndex < root.resultsProxy.length) {
                const sel = root.resultsProxy[selectedIndex];
                sel.execute();
                if (!sel.keepOpen) {
                    GlobalStates.launcherOpen = false;
                    GlobalStates.spotlightOpen = false;
                }
            }
            return;
        }
        if (LauncherSearch.isEmojiMode) {
            const flat = root.emojiView.flat;
            if (flat && flat.length > 0 && selectedIndex >= 0 && selectedIndex < flat.length) {
                LauncherSearch.useEmoji(flat[selectedIndex]);
                GlobalStates.launcherOpen = false;
                GlobalStates.spotlightOpen = false;
            }
            return ;
        }
        if (root.resultsProxy && root.resultsProxy.length > 0 && selectedIndex >= 0 && selectedIndex < root.resultsProxy.length) {
            const selected = root.resultsProxy[selectedIndex];
            selected.execute();
            if (!selected.keepOpen) {
                GlobalStates.launcherOpen = false;
                GlobalStates.spotlightOpen = false;
            }
        }
    }

    color: Appearance.colors.colLayer1
    radius: Appearance.rounding.large
    width: (LauncherSearch.isClipboardMode ? 760 : 560) * Appearance.effectiveScale
    height: 480 * Appearance.effectiveScale
    implicitHeight: 480 * Appearance.effectiveScale
    onSelectedIndexChanged: {
        // Handled by LauncherEmojiContent

        if (!GlobalStates.spotlightOpen)
            return ;

        if (LauncherSearch.isEmojiMode && root.isKeyboardNavigation) {
        }
    }
    // Backup grid navigation in case focus isn't on the search field
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Slash) {
            root.cheatsheetOpen = !root.cheatsheetOpen;
            event.accepted = true;
            return;
        }
        if (root.cheatsheetOpen && event.key === Qt.Key_Escape) {
            root.cheatsheetOpen = false;
            event.accepted = true;
            return;
        }
        const isEmoji = LauncherSearch.isEmojiMode;
        const isWall = LauncherSearch.isWallMode;
        if (!isEmoji && !isWall) return;
        const total = isEmoji ? root.emojiView.flat.length : root.resultsProxy.length;
        if (total <= 0) return;
        if (event.key === Qt.Key_Up) {
            root.isKeyboardNavigation = true;
            root.selectedIndex = isEmoji ? root.emojiNavigate(0, -1) : root.wallNavigate(0, -1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.isKeyboardNavigation = true;
            root.selectedIndex = isEmoji ? root.emojiNavigate(0, 1) : root.wallNavigate(0, 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.isKeyboardNavigation = true;
            root.selectedIndex = isEmoji ? root.emojiNavigate(-1, 0) : root.wallNavigate(-1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            root.isKeyboardNavigation = true;
            root.selectedIndex = isEmoji ? root.emojiNavigate(1, 0) : root.wallNavigate(1, 0);
            event.accepted = true;
        }
    }

    StyledRectangularShadow {
        target: root
        radius: root.radius
        color: Functions.ColorUtils.applyAlpha(Appearance.colors.colShadow, 0.2)
        z: -1
    }

    Connections {
        function onQueryChanged() {
            root.selectedIndex = 0;
        }

        target: LauncherSearch
    }

    Connections {
        target: GlobalStates
        function onSpotlightOpenChanged() {
            if (!GlobalStates.spotlightOpen) root.cheatsheetOpen = false;
        }
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 16 * Appearance.effectiveScale
        spacing: 12 * Appearance.effectiveScale

        LauncherSearchField {
            id: searchField

            Layout.fillWidth: true
            launcherContent: root
        }

        LauncherEmojiContent {
            id: emojiContent

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LauncherSearch.isEmojiMode
            isSpotlight: root.isSpotlight
            launcherContent: root
            selectedIndex: root.selectedIndex
            onSelectedIndexChanged: {
                if (root.selectedIndex !== selectedIndex)
                    root.selectedIndex = selectedIndex;

            }
            isKeyboardNavigation: root.isKeyboardNavigation
            onIsKeyboardNavigationChanged: {
                if (root.isKeyboardNavigation !== isKeyboardNavigation)
                    root.isKeyboardNavigation = isKeyboardNavigation;

            }
        }

        LauncherWallContent {
            id: wallContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: LauncherSearch.isWallMode
            isSpotlight: root.isSpotlight
            launcherContent: root
            selectedIndex: root.selectedIndex
            onSelectedIndexChanged: {
                if (root.selectedIndex !== selectedIndex)
                    root.selectedIndex = selectedIndex;
            }
            isKeyboardNavigation: root.isKeyboardNavigation
            onIsKeyboardNavigationChanged: {
                if (root.isKeyboardNavigation !== isKeyboardNavigation)
                    root.isKeyboardNavigation = isKeyboardNavigation;
            }
        }

        // ── Spotlight Content Container (Result List) ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !LauncherSearch.isEmojiMode && !LauncherSearch.isWallMode

            ListView {
                id: pluginList

                property real _savedY: -1

                function loadMoreKeepingPosition() {
                    if (pluginList.contentY > 0)
                        pluginList._savedY = pluginList.contentY;

                    LauncherSearch.loadMoreWallpapers();
                    if (pluginList._savedY >= 0) {
                        pluginList.contentY = pluginList._savedY;
                        Qt.callLater(() => {
                            if (pluginList._savedY >= 0) {
                                pluginList.contentY = pluginList._savedY;
                                pluginList._savedY = -1;
                            }
                        });
                    }
                }

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: LauncherSearch.isClipboardMode ? Math.floor(parent.width * 0.4) : parent.width
                interactive: true
                clip: true
                spacing: 4 * Appearance.effectiveScale
                model: visible ? root.resultsProxy : []
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: {
                    if (visible && currentIndex >= 0) {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                        if (count > 0 && currentIndex >= count - 5)
                            Qt.callLater(() => {
                            return pluginList.loadMoreKeepingPosition();
                        });

                    }
                }
                onMovementEnded: {
                    if (contentHeight - contentY - height < 100)
                        Qt.callLater(() => {
                        return pluginList.loadMoreKeepingPosition();
                    });

                }

                Behavior on width {
                    enabled: root.opacity === 1 && LauncherSearch.query !== ""

                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
                    }

                }

                delegate: LauncherListView {
                    result: modelData
                    selected: root.selectedIndex === index
                    onHoveredChanged: {
                        if (hovered) {
                            root.selectedIndex = index;
                            root.isKeyboardNavigation = false;
                        }
                    }
                }

            }

            ClipboardPreview {
                id: clipboardPreview

                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: pluginList.right
                anchors.leftMargin: LauncherSearch.isClipboardMode ? 12 * Appearance.effectiveScale : 0
                anchors.right: parent.right
                visible: opacity > 0
                opacity: LauncherSearch.isClipboardMode ? 1 : 0
                selectedItem: root.resultsProxy[root.selectedIndex] || null

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutExpo
                    }

                }

            }

        }

        // ── Vicinae Footer ──
        RowLayout {
            id: footer

            Layout.fillWidth: true
            spacing: 12 * Appearance.effectiveScale

            // Mode Indicator (Prefix-based)
            StyledText {
                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
                opacity: 0.6
                text: {
                    const q = LauncherSearch.query;
                    const search = Config.ready && Config.options.search;
                    if (LauncherSearch.isEmojiMode)
                        return I18nService.tr("Emoji Picker");

                    if (search.webPrefix && q.startsWith(search.webPrefix))
                        return I18nService.tr("Web Search");

                    if (search.mathPrefix && q.startsWith(search.mathPrefix))
                        return I18nService.tr("Calculator");

                    if (search.clipboardPrefix && q.startsWith(search.clipboardPrefix))
                        return I18nService.tr("Clipboard History");

                    if (search.filePrefix && q.startsWith(search.filePrefix))
                        return I18nService.tr("File Search");

                    if (search.commandPrefix && q.startsWith(search.commandPrefix))
                        return I18nService.tr("Quick Commands");

                    if (search.toolsPrefix && q.startsWith(search.toolsPrefix))
                        return I18nService.tr("Quick Tools");

                    if (search.settingsPrefix && q.startsWith(search.settingsPrefix))
                        return I18nService.tr("Settings Search");

                    return q ? I18nService.tr("Spotlight Search") : I18nService.tr("Applications");
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 16 * Appearance.effectiveScale
                opacity: 0.7

                // Help / prefix cheatsheet trigger
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Help")
                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                        color: Appearance.colors.colOnLayer1
                    }

                    Rectangle {
                        Layout.preferredWidth: 20 * Appearance.effectiveScale
                        Layout.preferredHeight: 20 * Appearance.effectiveScale
                        radius: 4 * Appearance.effectiveScale
                        color: root.cheatsheetOpen ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceVariant

                        StyledText {
                            anchors.centerIn: parent
                            text: "/"
                            font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            font.weight: Font.DemiBold
                            color: root.cheatsheetOpen ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurfaceVariant
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cheatsheetOpen = !root.cheatsheetOpen
                        }
                    }
                }

                // Navigate
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Navigate")
                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                        color: Appearance.colors.colOnLayer1
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2 * Appearance.effectiveScale

                        Rectangle {
                            Layout.preferredWidth: 20 * Appearance.effectiveScale
                            Layout.preferredHeight: 20 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant

                            StyledText {
                                anchors.centerIn: parent
                                text: "↑"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            }

                        }

                        Rectangle {
                            Layout.preferredWidth: 20 * Appearance.effectiveScale
                            Layout.preferredHeight: 20 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant

                            StyledText {
                                anchors.centerIn: parent
                                text: "↓"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            }

                        }

                    }

                }

                // Execute (generic: open app, copy clipboard, select wallpaper, etc.)
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 6 * Appearance.effectiveScale

                    StyledText {
                        text: I18nService.tr("Execute")
                        font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                        color: Appearance.colors.colOnLayer1
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            Layout.preferredWidth: 26 * Appearance.effectiveScale
                            Layout.preferredHeight: 20 * Appearance.effectiveScale
                            radius: 4 * Appearance.effectiveScale
                            color: Appearance.m3colors.m3surfaceVariant

                            StyledText {
                                anchors.centerIn: parent
                                text: "↵"
                                font.pixelSize: Math.round(11 * Appearance.effectiveScale)
                            }

                        }

                    }

                }

            }

        }

    }

    DialogCheatsheet {
        visible: root.cheatsheetOpen
        onClosed: root.cheatsheetOpen = false
        columns: 2
        iconName: "search"
        titleText: I18nService.tr("Search Prefixes")
        shortcuts: [
            { key: (Config.ready && Config.options.search) ? Config.options.search.webPrefix : "!", action: I18nService.tr("Web Search") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.mathPrefix : "=", action: I18nService.tr("Calculator") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.emojiPrefix : ":", action: I18nService.tr("Emoji Picker") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.clipboardPrefix : ";", action: I18nService.tr("Clipboard History") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.filePrefix : "?", action: I18nService.tr("File Search") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.commandPrefix : ">", action: I18nService.tr("Quick Commands") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.toolsPrefix : ".", action: I18nService.tr("Quick Tools") },
            { key: (Config.ready && Config.options.search) ? Config.options.search.settingsPrefix : "<", action: I18nService.tr("Settings Search") }
        ]
    }

    Behavior on width {
        enabled: root.opacity === 1 && LauncherSearch.query !== ""

        NumberAnimation {
            duration: 300
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }

    }

    // Smooth appearance animation
    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }

    }

}
