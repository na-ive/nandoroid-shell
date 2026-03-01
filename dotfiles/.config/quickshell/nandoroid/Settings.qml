import "core"
import "core/functions" as Functions
import "services"
import "widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

/**
 * Main Settings Application Window.
 * Central hub for system configuration.
 */
Scope {
    id: root

    FloatingWindow {
        id: settingsWindow
        visible: GlobalStates.settingsOpen
        title: "Settings"
        
        readonly property var screen: Quickshell.screens[0]

        color: "transparent"

        // Since it's a real window, it defaults to a reasonable size:
        width: Math.min(1100, screen.width * 0.85)
        height: Math.min(800, screen.height * 0.8)

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
                }
            }
        }

        Component.onCompleted: {
            MaterialThemeLoader.reapplyTheme()
        }

        // Main Panel Background
        Rectangle {
            id: contentContainer
            anchors.fill: parent

            focus: visible
            Keys.onEscapePressed: GlobalStates.settingsOpen = false

            color: Appearance.colors.colLayer0
            border.color: Appearance.colors.colOutlineVariant
            border.width: 1

            // Trap clicks inside
            TapHandler {}

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // ── Global Header ──
                Item {
                    id: headerWrapper
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52 // Reduced from 64

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 0
                        spacing: 20

                        StyledText {
                            text: "Settings"
                            font.pixelSize: Appearance.font.pixelSize.huge
                            font.weight: Font.Bold
                            color: Appearance.colors.colOnLayer0
                            Layout.preferredWidth: 200
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        // Truly Centered Search pill
                        Rectangle {
                            Layout.preferredWidth: 360
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignVCenter
                            radius: 22
                            color: Appearance.colors.colLayer1 // Using colLayer1 for search as it sits on colLayer0
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                spacing: 12
                                MaterialSymbol {
                                    text: "search"
                                    iconSize: 22
                                    color: Appearance.colors.colSubtext
                                }
                                TextInput {
                                    id: searchInput
                                    Layout.fillWidth: true
                                    Layout.rightMargin: 16
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: Appearance.colors.colOnLayer1
                                    clip: true
                                    
                                    property bool hasNoResults: false
                                    
                                    onTextChanged: hasNoResults = false
                                    
                                    onAccepted: {
                                        let best = SearchRegistry.getBestResult(text)
                                        if (best) {
                                            GlobalStates.settingsPageIndex = best.pageIndex
                                            hasNoResults = false
                                            searchInput.focus = false
                                        } else {
                                            hasNoResults = true
                                        }
                                    }

                                    StyledText {
                                        visible: !searchInput.text && !searchInput.activeFocus
                                        text: searchInput.hasNoResults ? "No results found" : "Search all settings.."
                                        font: searchInput.font
                                        color: searchInput.hasNoResults ? Appearance.m3colors.m3error : Appearance.colors.colSubtext
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Item {
                            Layout.preferredWidth: 200
                            Layout.fillHeight: true

                            RippleButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: 18
                                colBackground: "transparent"
                                onClicked: GlobalStates.settingsOpen = false
                                
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 22
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }


                // ── Main Content Area ──
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    SettingsSidebar {
                        id: sidebar
                        Layout.fillHeight: true
                        currentIndex: GlobalStates.settingsPageIndex
                        onPageSelected: (index) => {
                            GlobalStates.settingsPageIndex = index
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Appearance.colors.colLayer1
                        radius: 28 

                        Item {
                            anchors.fill: parent
                            clip: true

                            // Page Loader
                            Loader {
                                id: pageLoader
                                anchors.fill: parent
                                anchors.margins: 24
                                Component.onCompleted: source = pages[root.currentIndex].component
                                
                                // Error handling
                                TextEdit {
                                    visible: pageLoader.status === Loader.Error
                                    anchors.centerIn: parent
                                    width: Math.min(800, parent.width - 40)
                                    wrapMode: TextEdit.Wrap
                                    readOnly: true
                                    selectByMouse: true
                                    text: "Error loading page: " + pageLoader.source + "\n\n" + (pageLoader.sourceComponent ? pageLoader.sourceComponent.errorString() : "Unknown component error")
                                    color: "#FF5555"
                                    font.pixelSize: 14
                                    font.family: "monospace"
                                }
                                
                                // Transition animations
                                property real opacityVal: 1.0
                                property real yOffset: 0
                                
                                opacity: opacityVal
                                transform: Translate { y: pageLoader.yOffset }
                                
                                Connections {
                                    target: SearchRegistry
                                    function onCurrentSearchChanged() {
                                        // This empty connection block might help trigger re-evaluations
                                    }
                                }

                                SequentialAnimation {
                                    id: transitionAnim
                                    NumberAnimation { 
                                        target: pageLoader
                                        property: "opacityVal"
                                        to: 0
                                        duration: 150
                                        easing.type: Easing.OutQuad
                                    }
                                    PropertyAction { target: pageLoader; property: "yOffset"; value: 20 }
                                    PropertyAction { 
                                        target: pageLoader
                                        property: "source"
                                        value: pages[GlobalStates.settingsPageIndex].component 
                                    }
                                    ParallelAnimation {
                                        NumberAnimation { 
                                            target: pageLoader
                                            property: "opacityVal"
                                            to: 1
                                            duration: 250
                                            easing.type: Easing.OutBack
                                        }
                                        NumberAnimation { 
                                            target: pageLoader
                                            property: "yOffset"
                                            to: 0
                                            duration: 250
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property int currentIndex: GlobalStates.settingsPageIndex

    onCurrentIndexChanged: {
        if (settingsWindow.visible && pageLoader.status !== Loader.Null) {
            transitionAnim.restart()
        } else {
            pageLoader.source = pages[currentIndex].component
        }
    }
    readonly property var pages: [
        { name: "Network", component: "panels/Settings/pages/NetworkSettings.qml" },
        { name: "Bluetooth", component: "panels/Settings/pages/BluetoothSettings.qml" },
        { name: "Audio", component: "panels/Settings/pages/AudioSettings.qml" },
        { name: "Display", component: "panels/Settings/pages/DisplaySettings.qml" },
        { name: "Wallpaper & Style", component: "panels/Settings/pages/WallpaperStyleSettings.qml" },
        { name: "Services", component: "panels/Settings/pages/ServicesSettings.qml" },
        { name: "About", component: "panels/Settings/pages/AboutSettings.qml" }
    ]
}
