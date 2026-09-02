import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    // Explicitly set as classic launcher
    readonly property bool isSpotlight: false
    readonly property var resultsProxy: LauncherSearch.results
    property int selectedIndex: 0
    // Fixed to 9 to match the precise width in Launcher.qml
    readonly property int gridColumns: 9
    property bool isKeyboardNavigation: false
    property alias emojiColumns: emojiContent.emojiColumns
    property alias emojiView: emojiContent.emojiView
    readonly property bool hasQuery: LauncherSearch.query !== ""

    function emojiNavigate(dx, dy) {
        return emojiContent.emojiNavigate(dx, dy);
    }
    function wallNavigate(dx, dy) {
        return wallContent.wallNavigate(dx, dy);
    }
    readonly property int wallColumns: 4

    function executeSelected() {
        if (LauncherSearch.isWallMode) {
            if (root.resultsProxy && root.resultsProxy.length > 0 && selectedIndex >= 0 && selectedIndex < root.resultsProxy.length) {
                const sel = root.resultsProxy[selectedIndex];
                sel.execute();
                if (!sel.keepOpen) GlobalStates.launcherOpen = false;
            }
            return;
        }
        if (LauncherSearch.isEmojiMode) {
            const flat = root.emojiView.flat;
            if (flat && flat.length > 0 && selectedIndex >= 0 && selectedIndex < flat.length) {
                LauncherSearch.useEmoji(flat[selectedIndex]);
                GlobalStates.launcherOpen = false;
            }
            return ;
        }
        if (root.resultsProxy && root.resultsProxy.length > 0 && selectedIndex >= 0 && selectedIndex < root.resultsProxy.length) {
            root.resultsProxy[selectedIndex].execute();
            GlobalStates.launcherOpen = false;
        }
    }

    color: Appearance.colors.colLayer1
    radius: 32 * Appearance.effectiveScale
    bottomLeftRadius: 0
    bottomRightRadius: 0
    onSelectedIndexChanged: {
        // Handled by LauncherEmojiContent

        if (!GlobalStates.launcherOpen)
            return ;

        if (LauncherSearch.isEmojiMode)
            return ;

        if (root.hasQuery) {
            if (isKeyboardNavigation)
                pluginList.positionViewAtIndex(selectedIndex, ListView.Contain);

            if (pluginList.count > 0 && selectedIndex >= pluginList.count - 5)
                Qt.callLater(() => {
                return pluginList.loadMoreKeepingPosition();
            });

        } else {
            // Only auto-scroll for keyboard to prevent jumping when mouse hovers partially visible items
            if (isKeyboardNavigation) {
                if (selectedIndex >= gridColumns)
                    appGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
                else if (selectedIndex >= 0 && selectedIndex < gridColumns)
                    appGrid.contentY = 0;
            }
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
        function onEffectiveScaleChanged() {
            // Force layout update when scale changes to fix grid column calculation lag
            Qt.callLater(() => {
                if (appGrid.visible)
                    appGrid.forceLayout();

            });
        }

        target: Appearance
    }

    Connections {
        function onLauncherOpenChanged() {
            if (GlobalStates.launcherOpen) {
                root.selectedIndex = 0;
                // Force scroll to top immediately and after a tiny delay to be sure
                appGrid.contentY = 0;
                appGrid.positionViewAtIndex(0, GridView.Beginning);
                Qt.callLater(() => {
                    appGrid.contentY = 0;
                    appGrid.positionViewAtIndex(0, GridView.Beginning);
                });
            } else {
                root.selectedIndex = 0;
            }
        }

        target: GlobalStates
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: 24 * Appearance.effectiveScale
        spacing: 16 * Appearance.effectiveScale

        LauncherSearchField {
            id: searchField

            Layout.fillWidth: true
            launcherContent: root
        }

        // ── Category Switcher ──
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 36 * Appearance.effectiveScale
            visible: !root.hasQuery && !LauncherSearch.isEmojiMode && Config.ready && Config.options.search && Config.options.search.enableGrouping

            ListView {
                id: categoryList

                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 8 * Appearance.effectiveScale
                model: LauncherSearch.categories
                boundsBehavior: Flickable.StopAtBounds

                delegate: RippleButton {
                    height: 36 * Appearance.effectiveScale
                    implicitWidth: catText.implicitWidth + 32 * Appearance.effectiveScale
                    buttonRadius: 18 * Appearance.effectiveScale
                    colBackground: LauncherSearch.selectedCategory === modelData ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerHigh
                    colRipple: Appearance.m3colors.m3onPrimary
                    onClicked: {
                        LauncherSearch.selectedCategory = modelData;
                        root.selectedIndex = 0;
                    }

                    StyledText {
                        id: catText

                        anchors.centerIn: parent
                        text: I18nService.tr(modelData)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: LauncherSearch.selectedCategory === modelData ? Font.DemiBold : Font.Normal
                        color: LauncherSearch.selectedCategory === modelData ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSurface
                    }

                }

            }

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

        // ── Main Content Container (Grid or List) ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !LauncherSearch.isEmojiMode && !LauncherSearch.isWallMode

            GridView {
                id: appGrid

                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: parent.height
                visible: !root.hasQuery
                interactive: true
                clip: true
                onVisibleChanged: {
                    if (visible) {
                        contentY = 0;
                        positionViewAtIndex(0, GridView.Beginning);
                    }
                }
                cellWidth: 100 * Appearance.effectiveScale
                cellHeight: (110 + 24) * Appearance.effectiveScale
                // Simplified margin calculation to be more robust
                leftMargin: Math.max(0, (width - (gridColumns * cellWidth)) / 2)
                rightMargin: leftMargin
                model: visible ? root.resultsProxy : []

                delegate: Item {
                    width: appGrid.cellWidth
                    height: appGrid.cellHeight

                    AppIcon {
                        anchors.centerIn: parent
                        app: modelData
                        selected: root.selectedIndex === index
                        onHoveredChanged: {
                            if (hovered && GlobalStates.launcherOpen && root.selectedIndex !== index) {
                                root.isKeyboardNavigation = false;
                                root.selectedIndex = index;
                            }
                        }
                    }

                }
                // currentIndex is REMOVED to prevent automatic scrolling artifacts

            }

            Item {
                anchors.fill: parent
                visible: root.hasQuery

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

        }

    }

}
