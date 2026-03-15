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
    property int maxHeight: 240
    
    signal accepted(string value)
    
    implicitWidth: 200
    implicitHeight: 48
    z: isOpened ? 1000 : 1

    // Update internal search model when text changes or model changes
    property var filteredModel: {
        if (!searchable || !isFiltering || text === "") return model;
        let results = [];
        const lowerText = text.toLowerCase();
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
        radius: 12
        color: Appearance.colors.colLayer1
        border.width: root.isOpened ? 2 : 1
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
            anchors.margins: 12
            spacing: 8
            
            TextInput {
                id: input
                Layout.fillWidth: true
                text: root.text
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
                verticalAlignment: TextInput.AlignVCenter
                readOnly: !root.searchable
                focus: root.searchable
                selectByMouse: root.searchable
                clip: true
                
                onTextChanged: {
                    if (root.searchable && activeFocus && root.isOpened) {
                        root.text = text;
                        root.isFiltering = true;
                    }
                    if (!activeFocus) cursorPosition = 0;
                }
                onActiveFocusChanged: {
                    if (activeFocus && root.searchable) {
                        root.isOpened = true;
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
                            root.selectItem(root.filteredModel[listView.currentIndex]);
                            root.isOpened = false;
                            input.focus = false;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.isOpened = false;
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
                iconSize: 20
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
        y: bg.height + 4
        width: root.width
        visible: root.isOpened && filteredModel.length > 0
        padding: 0
        margins: 0
        z: 2000
        
        background: Rectangle {
            radius: 12
            color: Qt.darker(Appearance.colors.colLayer2, 1.05)
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant
            clip: true
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 200; easing.type: Easing.OutBack }
        }
        
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1; to: 0.95; duration: 150; easing.type: Easing.InCubic }
        }

        contentItem: ListView {
            id: listView
            implicitHeight: Math.min(root.maxHeight, contentHeight + 8)
            model: root.filteredModel
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            anchors.margins: 4
            highlightFollowsCurrentItem: true
            highlight: Rectangle {
                color: Appearance.colors.colLayer2Hover
                radius: 8
                z: 0
            }
            
            delegate: RippleButton {
                id: delegateRoot
                width: listView.width
                implicitHeight: 40
                buttonRadius: 8
                colBackground: "transparent"
                colBackgroundHover: "transparent" // Use Listview highlight instead
                colRipple: Appearance.colors.colLayer2Active
                
                property bool isCurrent: ListView.isCurrentItem

                contentItem: StyledText {
                    text: modelData
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    verticalAlignment: Text.AlignVCenter
                    color: delegateRoot.isCurrent ? (Appearance.m3colors.m3primary || Appearance.colors.colPrimary) : Appearance.colors.colOnLayer2
                    font.family: root.searchable ? text : Appearance.font.family.main
                    font.weight: delegateRoot.isCurrent ? Font.Bold : Font.Normal
                }
                
                onClicked: {
                    root.selectItem(modelData);
                    root.isOpened = false;
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
    
    onIsOpenedChanged: {
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
