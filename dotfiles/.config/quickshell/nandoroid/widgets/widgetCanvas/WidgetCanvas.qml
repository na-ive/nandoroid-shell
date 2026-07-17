import QtQuick
import "../../core"

Item {
    id: root
    property int gridSize: 12
    property bool showGrid: false
    readonly property bool isWidgetCanvas: true

    // Center line active states
    property bool activeCenterX: false
    property bool activeCenterY: false

    // Guide lines shown during drag
    property var guideLinesV: []
    property var guideLinesH: []

    // Widget alignment
    property bool hasWidgetAlignment: false
    property var widgetAlignmentData: { "xAligned": false, "yAligned": false }

    // Gap hints (text labels showing pixel distances)
    property var gapHints: []

    function setDragging(active) {
        root.showGrid = active
        if (!active) {
            root.activeCenterX = false;
            root.activeCenterY = false;
            root.clearWidgetAlignment();
            root.clearGuides();
            root.clearGapHints();
        }
    }

    // ── Grid lines ──

    Repeater {
        model: root.showGrid ? Math.ceil(root.width / root.gridSize) : 0
        delegate: Rectangle {
            required property int index
            x: index * root.gridSize
            width: 1
            height: root.height
            color: Appearance.m3colors.m3outlineVariant
            opacity: 0.3
        }
    }

    Repeater {
        model: root.showGrid ? Math.ceil(root.height / root.gridSize) : 0
        delegate: Rectangle {
            required property int index
            y: index * root.gridSize
            width: root.width
            height: 1
            color: Appearance.m3colors.m3outlineVariant
            opacity: 0.3
        }
    }

    // ── Center lines ──

    Rectangle {
        id: centerLineV
        x: Math.round(root.width / 2)
        y: 0
        width: 2
        height: root.height
        color: Appearance.m3colors.m3primary
        opacity: root.showGrid && root.activeCenterX ? 1.0 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Rectangle {
        id: centerLineH
        x: 0
        y: Math.round(root.height / 2)
        width: root.width
        height: 2
        color: Appearance.m3colors.m3primary
        opacity: root.showGrid && root.activeCenterY ? 1.0 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    // ── Snap guide lines (vertical) ──

    Repeater {
        id: guidesV
        model: root.guideLinesV
        delegate: Rectangle {
            required property real modelData
            x: modelData - 1
            width: 2
            height: root.height
            color: Appearance.m3colors.m3tertiary
            opacity: root.showGrid ? 0.85 : 0
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }
    }

    // ── Snap guide lines (horizontal) ──

    Repeater {
        id: guidesH
        model: root.guideLinesH
        delegate: Rectangle {
            required property real modelData
            y: modelData - 1
            width: root.width
            height: 2
            color: Appearance.m3colors.m3tertiary
            opacity: root.showGrid ? 0.85 : 0
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }
    }

    // ── Gap hint labels ──

    Repeater {
        id: gapHintRepeater
        model: root.showGrid ? root.gapHints : []

        delegate: Rectangle {
            required property var modelData
            id: hintLabel

            x: modelData.isVertical
               ? modelData.pos - hintText.implicitWidth / 2 - 6
               : modelData.perpPos - hintText.implicitWidth / 2 - 6
            y: modelData.isVertical
               ? modelData.perpPos - hintText.implicitHeight / 2 - 2
               : modelData.pos - hintText.implicitHeight / 2 - 2

            implicitWidth: hintText.implicitWidth + 12
            implicitHeight: hintText.implicitHeight + 6
            radius: 4
            color: Appearance.m3colors.m3surfaceContainerHigh
            border.color: Appearance.m3colors.m3tertiary
            border.width: 1
            z: 999

            Text {
                id: hintText
                anchors.centerIn: parent
                text: modelData.gap + "px"
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }

    // ── Public API ──

    function updateGuides(verticalLines, horizontalLines) {
        root.guideLinesV = verticalLines || [];
        root.guideLinesH = horizontalLines || [];
    }

    function clearGuides() {
        root.guideLinesV = [];
        root.guideLinesH = [];
    }

    function updateGapHints(hints) {
        root.gapHints = hints || [];
    }

    function clearGapHints() {
        root.gapHints = [];
    }

    function setWidgetAlignment(data) {
        root.hasWidgetAlignment = true;
        root.widgetAlignmentData = data;
    }

    function clearWidgetAlignment() {
        root.hasWidgetAlignment = false;
        root.widgetAlignmentData = { "xAligned": false, "yAligned": false };
    }

    // ── Flash effects ──

    Component {
        id: flashLineComp
        Rectangle {
            property bool isVertical: true
            property real linePos: 0
            color: Appearance.m3colors.m3tertiary
            x: isVertical ? linePos - 1 : 0
            y: isVertical ? 0 : linePos - 1
            width: isVertical ? 2 : root.width
            height: isVertical ? root.height : 2

            NumberAnimation on opacity {
                from: 1
                to: 0
                duration: 600
                running: true
                onFinished: parent.destroy()
            }
        }
    }

    function flashLines(verticalPositions, horizontalPositions) {
        if (!root.showGrid) return;
        var seen = new Set();
        (verticalPositions || []).forEach(pos => {
            var k = Math.round(pos);
            if (!seen.has("v" + k)) { seen.add("v" + k); flashLineComp.createObject(root, { isVertical: true, linePos: k }); }
        });
        (horizontalPositions || []).forEach(pos => {
            var k = Math.round(pos);
            if (!seen.has("h" + k)) { seen.add("h" + k); flashLineComp.createObject(root, { isVertical: false, linePos: k }); }
        });
    }
}
