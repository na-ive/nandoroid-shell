import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../core"
import "../core/functions" as Functions
import "."

/**
 * StyledComboBox: A high-fidelity, searchable dropdown component.
 * Features:
 * - Searchable (typing updates results)
 * - Material 3 aesthetics
 * - Modern open/close animations
 * - Custom scrollbar and ripple feedback
 * - Optional footer action row (e.g. "+ New ...")
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
    
    // Custom styling properties
    property color colBackground: Appearance.m3colors.m3surfaceContainer || Appearance.colors.colLayer1
    property color colBorder: root.isOpened ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
    property color colText: Appearance.colors.colOnLayer1
    property real borderWidth: root.isOpened ? Math.max(2, 2 * Appearance.effectiveScale) : 0
    property real bgRadius: 12 * Appearance.effectiveScale

    property string activeFont: {
        if (root.isOpened && listView.currentIndex >= 0 && listView.currentIndex < root.filteredModel.length) {
            return root.filteredModel[listView.currentIndex];
        }
        return root.text;
    }
    
    signal accepted(string value)

    // Optional footer action (e.g. "+ New board"); empty hides it.
    property string actionText: ""
    property string actionIcon: "add"
    signal actionTriggered()
    
    implicitWidth: 200 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale
    z: isOpened ? 1000 : 1

    // Guard to suppress reopening/filtering during item selection
    property bool _selecting: false

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
        radius: root.bgRadius
        color: root.colBackground
        border.width: root.borderWidth
        border.color: root.colBorder
        
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
            anchors.leftMargin: 16 * Appearance.effectiveScale
            anchors.rightMargin: 16 * Appearance.effectiveScale
            spacing: 8 * Appearance.effectiveScale
            
            TextInput {
                id: input
                Layout.fillWidth: true
                text: root.text
                font.family: Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                color: root.colText
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignLeft
                leftPadding: 0
                rightPadding: 0
                readOnly: !root.searchable
                selectByMouse: root.searchable
                clip: true
                
                onTextChanged: {
                    if (root.searchable && activeFocus && root.isOpened && !root._selecting) {
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
                    if (activeFocus && root.searchable && !root._selecting) {
                        root.isOpened = true;
                        input.selectAll();
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
                            root._selecting = true;
                            root.isOpened = false;
                            input.text = selectedVal;
                            input.focus = false;
                            root.selectItem(selectedVal);
                            Qt.callLater(() => { root._selecting = false; });
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
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                }
            }
            
            MaterialSymbol {
                text: root.isOpened ? "keyboard_arrow_up" : "keyboard_arrow_down"
                iconSize: 20 * Appearance.effectiveScale
                color: root.colText
                
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
        y: root.computePopupY()
        width: root.width
        padding: 4 * Appearance.effectiveScale
        margins: 0
        z: 2000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent | Popup.CloseOnPressOutside
        
        background: Item {
            visible: root.filteredModel.length > 0 || root.actionText !== ""
            
            StyledRectangularShadow {
                target: popupBgRect
                radius: popupBgRect.radius
            }

            Rectangle {
                id: popupBgRect
                anchors.fill: parent
                radius: 12 * Appearance.effectiveScale
                color: Appearance.m3colors.m3surfaceContainerHigh || Qt.darker(Appearance.colors.colLayer2, 1.05)
                clip: true
            }
        }

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 200; easing.type: Easing.OutBack }
        }
        
        // exit transition removed to prevent Wayland click grab bugs during fade out

        Component {
            id: actionFooter

            Column {
                width: listView.width

                Rectangle {
                    width: parent.width - 24 * Appearance.effectiveScale
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1 * Appearance.effectiveScale
                    color: Functions.ColorUtils.applyAlpha(Appearance.m3colors.m3outlineVariant, 0.5)
                }

                RippleButton {
                    width: parent.width
                    implicitHeight: 40 * Appearance.effectiveScale
                    buttonRadius: 12 * Appearance.effectiveScale
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.m3colors.m3secondaryContainer
                    onClicked: {
                        root._selecting = true;
                        // Close first so the grab releases before firing.
                        root.isOpened = false;
                        input.text = root.text;
                        input.focus = false;
                        root.actionTriggered();
                        Qt.callLater(() => {
                            root._selecting = false;
                        });
                    }

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * Appearance.effectiveScale
                        anchors.rightMargin: 16 * Appearance.effectiveScale
                        spacing: 8 * Appearance.effectiveScale

                        MaterialSymbol {
                            text: root.actionIcon
                            iconSize: 20 * Appearance.effectiveScale
                            color: Appearance.colors.colPrimary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            text: root.actionText
                            color: Appearance.colors.colPrimary
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }

        contentItem: ListView {
            id: listView
            footer: root.actionText !== "" ? actionFooter : null
            implicitHeight: Math.min(root.maxHeight - 8 * Appearance.effectiveScale, contentHeight)
            model: root.filteredModel
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            highlightFollowsCurrentItem: true
            highlight: Rectangle {
                color: Appearance.m3colors.m3secondaryContainer || Appearance.colors.colLayer2Hover
                radius: 12 * Appearance.effectiveScale
                z: 0
            }
            
            delegate: RippleButton {
                id: delegateRoot
                width: listView.width
                implicitHeight: 40 * Appearance.effectiveScale
                buttonRadius: 12 * Appearance.effectiveScale
                colBackground: "transparent"
                colBackgroundHover: "transparent" // Use Listview highlight instead
                colRipple: Appearance.colors.colLayer2Active
                
                property bool isCurrent: ListView.isCurrentItem

                onRealHoveredChanged: {
                    if (delegateRoot.realHovered) listView.currentIndex = index;
                }

                contentItem: StyledText {
                    text: modelData
                    anchors.fill: parent
                    anchors.leftMargin: 16 * Appearance.effectiveScale
                    verticalAlignment: Text.AlignVCenter
                    color: delegateRoot.isCurrent ? (Appearance.m3colors.m3onSecondaryContainer || Appearance.m3colors.m3primary) : Appearance.colors.colOnLayer2
                    font.family: root.searchable ? text : Appearance.font.family.main
                    font.weight: Font.Normal
                }
                
                onClicked: {
                    root._selecting = true;
                    // Close synchronously BEFORE firing accepted so the popup
                    // grab is released before any external handler runs.
                    root.isOpened = false;
                    input.text = modelData;
                    input.focus = false;
                    root.selectItem(modelData);
                    // Reset guard after event loop settles
                    Qt.callLater(() => { root._selecting = false; });
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
    
    function findViewport() {
        var p = root.parent;
        while (p !== null && p !== undefined) {
            if (p instanceof Flickable) return p;
            p = p.parent;
        }
        return null;
    }

    function popupHeight() {
        return Math.min(root.maxHeight, listView.contentHeight + 8 * Appearance.effectiveScale);
    }

    function computePopupY() {
        const gap = 4 * Appearance.effectiveScale;
        const h = root.popupHeight();
        const vp = root.findViewport();
        if (vp) {
            const contentY = vp.contentY;
            const topInContent = root.mapToItem(vp.contentItem, 0, 0).y;
            const bottomInContent = root.mapToItem(vp.contentItem, 0, bg.height).y;
            const spaceAbove = topInContent - contentY;
            const spaceBelow = vp.height - (bottomInContent - contentY);
            if (spaceBelow >= h) return bg.height + gap;
            if (spaceAbove >= h) return -(h + gap);
            return (spaceBelow >= spaceAbove) ? (bg.height + gap) : -(h + gap);
        }
        const win = root.Window;
        if (win) {
            const spaceBelow = win.height - root.mapToItem(null, 0, bg.height).y;
            if (spaceBelow >= h) return bg.height + gap;
        }
        return -(h + gap);
    }

    function syncPopup() {
        if (root.isOpened) {
            dropdownPopup.open();
        } else {
            dropdownPopup.close();
        }
    }

    onFilteredModelChanged: {
        if (root.isOpened && !root._selecting) syncPopup();
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
    
    property bool _windowActive: Window.active
    on_WindowActiveChanged: {
        if (!_windowActive) {
            root.isOpened = false;
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
