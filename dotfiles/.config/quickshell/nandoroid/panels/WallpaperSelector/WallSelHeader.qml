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

            Item {
                id: headerItem
                property Item mainSelector
                property Item targetBtn: targetSelectorBtn
                property Item sortBtnItem: sortBtn
                property Item weSettingsBtnItem: weSettingsBtn
                property alias searchFilterText: headerSearch.text
                
                property bool isSearchFocused: headerSearch.input.activeFocus
                signal searchArrowPressed(int key)
                function focusSearch() { headerSearch.forceActiveFocus(); }
                function defocusSearch() { headerSearch.input.focus = false; }
                
                Layout.fillWidth: true
                Layout.preferredHeight: 64 * Appearance.effectiveScale
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    anchors.rightMargin: 16 * Appearance.effectiveScale
                    spacing: 8 * Appearance.effectiveScale

                    // Left actions grouped tightly to match right side
                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0
                        RippleButton {
                            width: 48 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            buttonRadius: 24 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: mainSelector.sidebarExpanded = !mainSelector.sidebarExpanded
                            
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: mainSelector.sidebarExpanded ? "menu_open" : "menu"
                                iconSize: 24 * Appearance.effectiveScale
                                color: Appearance.colors.colOnLayer0
                            }
                        }

                        // Target Selector (Header)
                        RippleButton {
                            id: targetSelectorBtn
                            height: 48 * Appearance.effectiveScale
                            width: targetRow.implicitWidth + 24 * Appearance.effectiveScale
                            buttonRadius: 24 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: mainSelector.toggleTargetPopup()
                            
                            RowLayout {
                                id: targetRow
                                anchors.centerIn: parent
                                spacing: 8 * Appearance.effectiveScale
                                
                                StyledText {
                                    text: GlobalStates.wallpaperSelectorTarget === "desktop" ? "Desktop" : "Lockscreen"
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    font.family: Appearance.font.family.title
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colOnLayer0
                                }
                                
                                MaterialSymbol {
                                    text: "expand_more"
                                    iconSize: 20 * Appearance.effectiveScale
                                    color: Appearance.colors.colOnLayer0
                                    rotation: mainSelector.targetPopupVisible ? 180 : 0
                                    Behavior on rotation { NumberAnimation { duration: 200 } }
                                }
                            }
                        }
                    }

                    // Header Search Pill
                    Rectangle {
                        id: searchPill
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56 * Appearance.effectiveScale
                        radius: 28 * Appearance.effectiveScale
                        color: Appearance.colors.colLayer1
                        Layout.alignment: Qt.AlignVCenter
                        
                        readonly property bool isActive: headerSearch.input.activeFocus || headerSearch.text.length > 0

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
                                    headerSearch.text = ""
                                    headerSearch.focus = false
                                }
                                
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "chevron_left"
                                    iconSize: 24 * Appearance.effectiveScale
                                    color: Appearance.colors.colOnLayer1
                                }
                            }

                            // Centered Text Input
                            StyledTextInput {
                                id: headerSearch
                                yieldArrows: true
                                onArrowPressed: (key) => { headerItem.searchArrowPressed(key) }
                                Layout.fillWidth: true
                                horizontalAlignment: searchPill.isActive ? TextInput.AlignLeft : TextInput.AlignHCenter
                                inputRadius: 0
                                backgroundColor: "transparent"
                                borderInactiveWidth: 0
                                showActiveBorder: false
                                placeholder: mainSelector.wallhavenMode ? I18nService.tr("Search Wallhaven") : (mainSelector.naiveMode ? I18nService.tr("Search NA-ive Walls") : I18nService.tr("Search wallpapers"))
                                leftMargin: 0
                                rightMargin: 0
                                font.pixelSize: Appearance.font.pixelSize.normal
                                
                                onTextChanged: {
                                    if (mainSelector._switchingMode) return;
                                    
                                    if (mainSelector.wallhavenMode) mainSelector.wallhavenSearch = text;
                                    else if (mainSelector.naiveMode) mainSelector.naiveSearch = text;
                                    else if (mainSelector.liveMode) mainSelector.liveSearch = text;
                                    else mainSelector.localSearch = text;

                                    if (mainSelector.liveMode) {
                                        WallpaperEngineService.searchQuery = text;
                                    } else if (!mainSelector.wallhavenMode && !mainSelector.naiveMode) {
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
                            }

                            // Clear Button (X)
                            RippleButton {
                                visible: searchPill.isActive && headerSearch.text.length > 0
                                implicitWidth: 48 * Appearance.effectiveScale
                                implicitHeight: 48 * Appearance.effectiveScale
                                buttonRadius: 24 * Appearance.effectiveScale
                                colBackground: "transparent"
                                onClicked: {
                                    headerSearch.text = ""
                                    headerSearch.forceActiveFocus()
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

                    // Right action buttons outside the search pill
                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 0 // M3 groups trailing icons tightly, padding is built into the 48x48 size

                        // Sorting Button
                        Item {
                            id: sortBtnContainer
                            width: 48 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            visible: !mainSelector.wallhavenMode && !mainSelector.naiveMode
    
                            RippleButton {
                                id: sortBtn
                                anchors.fill: parent
                                buttonRadius: 24 * Appearance.effectiveScale 
                                colBackground: "transparent"
                                onClicked: mainSelector.toggleSortPopup()
                                
                                MaterialShapeWrappedMaterialSymbol {
                                    anchors.centerIn: parent
                                    implicitSize: 42 * Appearance.effectiveScale
                                    shapeString: "Sunny"
                                    color: Appearance.colors.colSecondary
                                    colSymbol: Appearance.colors.colOnSecondary
                                    text: "sort_by_alpha"
                                    iconSize: 20 * Appearance.effectiveScale
                                    rotation: mainSelector.sortPopupVisible ? 45 : 0
                                }
                                StyledToolTip { text: I18nService.tr("Sort Options") }
                            }
                        }
    
                        // Random Wallpaper Button
                        Item {
                            id: randBtnContainer
                            width: 48 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            visible: !mainSelector.wallhavenMode && !mainSelector.naiveMode && !mainSelector.liveMode
    
                            RippleButton {
                                id: randBtn
                                anchors.fill: parent
                                buttonRadius: 24 * Appearance.effectiveScale
                                colBackground: "transparent"
                                onClicked: mainSelector.triggerRandomWallpaper()
    
                                MaterialShapeWrappedMaterialSymbol {
                                    anchors.centerIn: parent
                                    implicitSize: 42 * Appearance.effectiveScale
                                    shapeString: "Pentagon"
                                    color: Appearance.colors.colTertiary
                                    colSymbol: Appearance.colors.colOnTertiary
                                    text: "shuffle"
                                    iconSize: 20 * Appearance.effectiveScale
                                }
                                StyledToolTip { text: I18nService.tr("Random Wallpaper") }
                            }
                        }
    
                        // Global Live Wallpaper Settings Button
                        Item {
                            id: weSettingsBtnContainer
                            width: 48 * Appearance.effectiveScale
                            height: 48 * Appearance.effectiveScale
                            visible: mainSelector.liveMode
    
                            RippleButton {
                                id: weSettingsBtn
                                anchors.fill: parent
                                buttonRadius: 24 * Appearance.effectiveScale 
                                colBackground: "transparent"
                                onClicked: {
                                    if (mainSelector.inVideoMode) {
                                        mainSelector.toggleMpvSettingsPopup();
                                    } else {
                                        mainSelector.toggleWeSettingsPopup();
                                    }
                                }
                                
                                MaterialShapeWrappedMaterialSymbol {
                                    anchors.centerIn: parent
                                    implicitSize: 42 * Appearance.effectiveScale
                                    shapeString: "Cookie6Sided"
                                    color: Appearance.colors.colSecondary
                                    colSymbol: Appearance.colors.colOnSecondary
                                    text: "settings"
                                    iconSize: 20 * Appearance.effectiveScale
                                    rotation: (mainSelector.weSettingsPopupVisible || mainSelector.mpvSettingsPopupVisible) ? 45 : 0
                                }
                                StyledToolTip { text: mainSelector.inVideoMode ? I18nService.tr("Video Wallpaper Settings") : I18nService.tr("Global Engine Settings") }
                            }
                        }
                        // Close Button
                        RippleButton {
                            Layout.alignment: Qt.AlignVCenter
                            implicitWidth: 48 * Appearance.effectiveScale
                            implicitHeight: 48 * Appearance.effectiveScale
                            buttonRadius: 24 * Appearance.effectiveScale
                            colBackground: "transparent"
                            onClicked: mainSelector.close()
                            MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 24 * Appearance.effectiveScale; color: Appearance.colors.colSubtext }
                        }
                    }
                }
            }
