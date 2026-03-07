import "../../core"
import "../../core/functions" as Functions
import "../../services"
import "../../widgets"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * Quick Settings toggle button — supports size 1 (icon-only) and size 2 (expanded with label).
 *
 * Normal mode:
 *   - Left-click: toggle action (or open detail panel if expanded + hasDetails)
 *   - Right-click: open detail panel (for icon-only toggles with details)
 *
 * Edit mode (handled by blocking MouseArea on top):
 *   - Left-click: enable/disable toggle (add/remove from list)
 *   - Right-click: cycle size (1 ↔ 2)
 *   - Scroll: reorder position
 */
RippleButton {
    id: root

    // Data from repeater
    required property int buttonIndex
    required property var buttonData
    required property var allToggles
    required property bool editMode
    required property real baseCellWidth
    required property real baseCellHeight
    required property real cellSpacing

    // Signals
    signal openDetails()

    // Resolved toggle info
    property var toggleData: allToggles ? (allToggles[buttonData.type] ?? null) : null
    property bool isToggled: toggleData?.toggled ?? false
    property bool expandedSize: (buttonData?.size ?? 1) > 1
    property bool hasMenu: !editMode && expandedSize && (toggleData?.hasDetails ?? false)

    // Sizing
    property int cellSize: buttonData?.size ?? 1
    Layout.preferredWidth: Math.floor(baseCellWidth * cellSize + cellSpacing * (cellSize - 1))
    Layout.preferredHeight: baseCellHeight

    visible: toggleData !== null && (editMode || (toggleData?.available ?? true))
    enabled: (toggleData?.available ?? true) || editMode
    padding: 6

    // Styling
    toggled: hasMenu ? false : isToggled
    colBackground: Appearance.colors.colLayer2
    colBackgroundHover: Appearance.colors.colLayer2Hover
    colBackgroundToggled: (hasMenu) ? Appearance.colors.colLayer2 : Appearance.colors.colPrimary
    colBackgroundToggledHover: (hasMenu) ? Appearance.colors.colLayer2Hover : Appearance.colors.colPrimary
    
    buttonRadius: isToggled ? 16 : height / 2

    property color colText: (isToggled && !hasMenu && enabled) ? Appearance.colors.colOnPrimary : Functions.ColorUtils.transparentize(Appearance.colors.colOnLayer2, enabled ? 0 : 0.7)
    property color colIcon: expandedSize ? (isToggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer3) : colText

    // ── Normal mode click handling ──
    onClicked: {
        if (hasMenu) {
            root.openDetails();
        } else {
            if (toggleData?.action) toggleData.action();
        }
    }

    altAction: {
        if (!editMode) {
            if (!expandedSize && (toggleData?.hasDetails ?? false)) return (() => root.openDetails());
            if (toggleData?.altAction) return toggleData.altAction;
        }
        return null;
    }

    // Content
    contentItem: Item {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.padding
            anchors.rightMargin: root.padding
            spacing: 6
            
            // Spacers for 1x centering
            Item { Layout.fillWidth: true; visible: !root.expandedSize }

            // Icon area (clickable toggle zone for expanded+hasDetails buttons)
            MouseArea {
                id: iconMouseArea
                hoverEnabled: root.hasMenu
                propagateComposedEvents: true
                acceptedButtons: (root.hasMenu) ? Qt.LeftButton : Qt.NoButton
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 36
                Layout.preferredWidth: 36
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (root.toggleData?.action) root.toggleData.action();
                }

                Rectangle {
                    id: iconBackground
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: (root.hasMenu && root.isToggled) ? 12 : width / 2
                    color: {
                        const isActive = root.isToggled
                        const baseColor = isActive ? Appearance.colors.colPrimary : Appearance.colors.colLayer3
                        const transparentizeAmount = (root.hasMenu && isActive) ? 0 : 1
                        return Functions.ColorUtils.transparentize(baseColor, transparentizeAmount)
                    }

                    Behavior on color { ColorAnimation { duration: 150 } }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        fill: root.isToggled ? 1 : 0
                        iconSize: root.expandedSize ? 20 : 22
                        color: root.colIcon
                        text: root.isToggled 
                            ? (root.toggleData?.icon ?? "check") 
                            : (root.toggleData?.iconOff ?? root.toggleData?.icon ?? "circle")
                    }

                    // Hover state layer for icon area when it acts as a button
                    Rectangle {
                        anchors.fill: parent
                        radius: iconBackground.radius
                        visible: root.hasMenu
                        color: Functions.ColorUtils.transparentize(
                            root.colIcon, 
                            iconMouseArea.containsPress ? 0.88 : iconMouseArea.containsMouse ? 0.95 : 1
                        )
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }

            // Text column — only shown when expanded
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                visible: root.expandedSize
                spacing: -2

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.toggleData?.name ?? ""
                }

                StyledText {
                    visible: (root.toggleData?.statusText ?? "") !== ""
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colText
                    elide: Text.ElideRight
                    text: root.toggleData?.statusText ?? ""
                }
            }

            // Spacers for 1x centering
            Item { Layout.fillWidth: true; visible: !root.expandedSize }
        }
    }

    // ── Edit mode: blocking MouseArea (exactly like the example) ──
    // Sits on top of everything and handles all edit interactions via direct mutation
    MouseArea {
        id: editModeInteraction
        visible: root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons

        function toggleEnabled() {
            var toggleList = Config.options.quickSettings?.toggles;
            
            if (!toggleList) return;
            var buttonType = root.buttonData.type;
            var found = false;
            var foundIndex = -1;
            
            for (var i = 0; i < toggleList.length; i++) {
                if (toggleList[i].type === buttonType) { 
                    found = true; 
                    foundIndex = i;
                    break; 
                }
            }

            if (found) {
                toggleList.splice(foundIndex, 1);
            } else {
                toggleList.push({ type: buttonType, size: 1 });
            }
        }

        function toggleSize() {
            var toggleList = Config.options.quickSettings?.toggles;
            if (!toggleList) return;
            var idx = root.buttonIndex;
            if (idx < 0 || idx >= toggleList.length) return;
            var currentSize = toggleList[idx].size || 1;
            toggleList[idx].size = (currentSize === 1) ? 2 : 1;
            
            // Force re-evaluation of the list to trigger signals
            Config.options.quickSettings.toggles = toggleList;
        }

        function movePositionBy(offset) {
            var toggleList = Config.options.quickSettings?.toggles;
            if (!toggleList) return;
            var idx = root.buttonIndex;
            if (idx < 0) return;
            var targetIndex = idx + offset;
            if (targetIndex < 0 || targetIndex >= toggleList.length) return;
            var temp = toggleList[idx];
            toggleList[idx] = toggleList[targetIndex];
            toggleList[targetIndex] = temp;
        }

        onReleased: (event) => {
            if (event.button === Qt.LeftButton)
                toggleEnabled();
        }
        onPressed: (event) => {
            if (event.button === Qt.RightButton) toggleSize();
        }
        onWheel: (event) => {
            if (event.angleDelta.y < 0) {
                movePositionBy(1);
            } else if (event.angleDelta.y > 0) {
                movePositionBy(-1);
            }
            event.accepted = true;
        }
    }

    // Edit mode visual overlay (purely visual, behind the MouseArea)
    Rectangle {
        visible: root.editMode
        anchors.fill: parent
        radius: root.buttonRadius
        // Active toggles get red remove overlay; unused get green add overlay
        property bool isActive: root.buttonIndex >= 0
        color: Functions.ColorUtils.transparentize(
            isActive ? Appearance.m3colors.m3error : Appearance.colors.colPrimary,
            0.85
        )

        MaterialSymbol {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            text: parent.isActive ? "remove_circle" : "add_circle"
            color: parent.isActive ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
            iconSize: 18
            fill: 1
        }
        // Size indicator — only for active toggles
        StyledText {
            visible: parent.isActive
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 6
            text: root.cellSize === 1 ? "1×" : "2×"
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.weight: Font.Bold
            color: Appearance.m3colors.m3error
        }
    }

    // Tooltip
    ToolTip {
        id: toggleTooltip
        visible: !root.editMode && (root.hovered || root.realHovered) && (text !== "")
        delay: 300
        text: {
            const data = root.toggleData;
            if (!data) return "";
            if (data.tooltipText) return data.tooltipText;
            if (data.name) {
                return (data.statusText && data.statusText !== "") 
                    ? data.name + ": " + data.statusText
                    : data.name;
            }
            return "";
        }
        
        contentItem: StyledText {
            text: toggleTooltip.text
            color: Appearance.m3colors.m3onSurface
            font.pixelSize: Appearance.font.pixelSize.smaller
            horizontalAlignment: Text.AlignHCenter
        }

        background: Rectangle {
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: 8
            border.color: Appearance.m3colors.m3outlineVariant
            border.width: 1
        }
    }
}
