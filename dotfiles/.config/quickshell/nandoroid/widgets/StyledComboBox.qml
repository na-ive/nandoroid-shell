import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"
import "."

/**
 * StyledComboBox: A high-fidelity, searchable dropdown component.
 * Features:
 * - Searchable (typing updates results)
 * - Material 3 aesthetics
 * - Modern open/close animations
 * - Custom scrollbar and ripple feedback
 */
Item {
    id: root
    property string text: ""
    property var model: []
    property string placeholder: "Select or type..."
    property bool searchable: true
    property bool isOpened: false
    property bool isFiltering: false // Only filter when user starts typing
    property int maxHeight: 240 * Appearance.effectiveScale
    
    signal accepted(string value)
    
    implicitWidth: 200 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale
    z: isOpened ? 1000 : 1

    // Update internal search model when text changes or model changes
    property var filteredModel: {
        if (!searchable || !isFiltering || input.text === "") return model;
        let results = [];
        const lowerText = input.text.toLowerCase();
        for (let i = 0; i < model.length; i++) {
            if (model[i].toLowerCase().includes(lowerText)) {
                results.push(model[i]);
            }
        }
        return results;
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 12 * Appearance.effectiveScale
        color: Appearance.colors.colLayer1
        border.width: root.isOpened ? Math.max(2, 2 * Appearance.effectiveScale) : Math.max(1, 1 * Appearance.effectiveScale)
        border.color: root.isOpened ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
        
        Behavior on border.color { ColorAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            visible: !root.searchable
            cursorShape: Qt.PointingHandCursor
            z: 10
            onClicked: {
                root.isOpened = !root.isOpened;
                if (root.isOpened) input.focus = true;
            }
        }
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            
            TextInput {
                id: input
                Layout.fillWidth: true
                text: root.text
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
                verticalAlignment: TextInput.AlignVCenter
                readOnly: !root.searchable
                selectByMouse: root.searchable
                clip: true
                
                onTextChanged: {
                    if (root.searchable && activeFocus && root.isOpened) {
                        root.isFiltering = true;
                    }
                    if (!activeFocus) cursorPosition = 0;
                }
                
                Connections {
                    target: root
                    function onTextChanged() {
                        if (!input.activeFocus) {
                            input.text = root.text;
                        }
                    }
                }

                onActiveFocusChanged: {
                    if (activeFocus && root.searchable) {
                        root.isOpened = true;
                        input.selectAll(); // Select all text so typing immediately replaces it
                    }
                }

                Keys.onPressed: (event) => {
                    if (!root.isOpened) {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                            root.isOpened = true;
                            event.accepted = true;
                        }
                        return;
                    }

                    if (event.key === Qt.Key_Down) {
                        listView.currentIndex = Math.min(listView.count - 1, listView.currentIndex + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        listView.currentIndex = Math.max(0, listView.currentIndex - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (listView.currentIndex >= 0 && listView.currentIndex < listView.count) {
                            let selectedVal = root.filteredModel[listView.currentIndex];
                            input.text = selectedVal; // Manually update input text to fix visual lag
                            input.focus = false; // Drop focus synchronously
                            root.selectItem(selectedVal);
                            Qt.callLater(() => {
                                root.isOpened = false;
                            });
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        input.text = root.text; // Restore original text
                        input.focus = false;
                        Qt.callLater(() => {
                            root.isOpened = false;
                        });
                        event.accepted = true;
                    }
                }

                Text {
                    text: root.placeholder
                    color: Appearance.colors.colSubtext
                    visible: !parent.text && !parent.activeFocus
                    font: parent.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            MaterialSymbol {
                text: root.isOpened ? "expand_less" : "expand_more"
                iconSize: 20 * Appearance.effectiveScale
                color: Appearance.colors.colSubtext
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.isOpened = !root.isOpened;
                        if (root.isOpened && root.searchable) input.forceActiveFocus();
                    }
                }
            }
        }
    }

    // Dropdown Popup
    Popup {
        id: dropdownPopup
        y: bg.height + 4 * Appearance.effectiveScale
        width: root.width
        padding: 0
        margins: 0
        z: 2000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside
        
        background: Rectangle {
            radius: 12 * Appearance.effectiveScale
            color: Qt.darker(Appearance.colors.colLayer2, 1.05)
            border.width: Math.max(1, 1 * Appearance.effectiveScale)
            border.color: Appearance.colors.colOutlineVariant
            clip: true
            visible: root.filteredModel.length > 0
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 200; easing.type: Easing.OutBack }
        }
        
        // exit transition removed to prevent Wayland click grab bugs during fade out

        contentItem: ListView {
            id: listView
            implicitHeight: Math.min(root.maxHeight, contentHeight + 8 * Appearance.effectiveScale)
            model: root.filteredModel
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            anchors.margins: 4 * Appearance.effectiveScale
            highlightFollowsCurrentItem: true
            highlight: Rectangle {
                color: Appearance.colors.colLayer2Hover
                radius: 8 * Appearance.effectiveScale
                z: 0
            }
            
            delegate: RippleButton {
                id: delegateRoot
                width: listView.width
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 8 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: "transparent" // Use Listview highlight instead
                colRipple: Appearance.colors.colLayer2Active
                
                property bool isCurrent: ListView.isCurrentItem

                contentItem: StyledText {
                    text: modelData
                    anchors.fill: parent
                    anchors.leftMargin: 12 * Appearance.effectiveScale
                    verticalAlignment: Text.AlignVCenter
                    color: delegateRoot.isCurrent ? (Appearance.m3colors.m3primary || Appearance.colors.colPrimary) : Appearance.colors.colOnLayer2
                    font.family: root.searchable ? text : Appearance.font.family.main
                    font.weight: delegateRoot.isCurrent ? Font.DemiBold : Font.Normal
                }
                
                onClicked: {
                    input.text = modelData;
                    input.focus = false; // Drop focus synchronously
                    root.selectItem(modelData);
                    Qt.callLater(() => {
                        root.isOpened = false;
                    });
                }
            }
            
            ScrollBar.vertical: StyledScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
        
        onClosed: {
            root.isOpened = false;
        }
    }
    
    function syncPopup() {
        if (root.isOpened) {
            dropdownPopup.open();
        } else {
            dropdownPopup.close();
        }
    }

    onFilteredModelChanged: {
        if (root.isOpened) syncPopup();
    }

    onIsOpenedChanged: {
        syncPopup();
        
        if (isOpened) {
            // Mutual exclusion: Close other open dropdowns
            if (GlobalStates.activeComboBox && GlobalStates.activeComboBox !== root) {
                GlobalStates.activeComboBox.isOpened = false;
            }
            GlobalStates.activeComboBox = root;
            
            // Reset filtering state on open
            root.isFiltering = false;

            // Find current text in model to set highlight
            // We do this after a tiny delay to ensure model is stable
            Qt.callLater(() => {
                let idx = -1;
                for (let i = 0; i < filteredModel.length; i++) {
                    let val = root.text === "" ? "Default" : root.text;
                    if (filteredModel[i] === val || filteredModel[i] === root.text) {
                        idx = i;
                        break;
                    }
                }
                if (idx !== -1) {
                    listView.currentIndex = idx;
                    listView.positionViewAtIndex(idx, ListView.Center);
                }
            });
        } else {
            if (GlobalStates.activeComboBox === root) {
                GlobalStates.activeComboBox = null;
            }
            root.isFiltering = false;
            // VERY IMPORTANT: Clear focus so it doesn't reopen when the window regains focus
            input.focus = false;
        }
    }
    
    Connections {
        target: Window.window
        ignoreUnknownSignals: true
        function onActiveChanged() {
            if (Window.window && !Window.window.active) {
                root.isOpened = false;
            }
        }
    }

    Component.onDestruction: {
        if (GlobalStates.activeComboBox === root) {
            GlobalStates.activeComboBox = null;
        }
    }

    function selectItem(val) {
        // Remove manual assignment to not break external bindings:
        // root.text = val;
        root.accepted(val);
    }
}
